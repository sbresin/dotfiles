import { type Plugin, tool } from "@opencode-ai/plugin"
import { homedir } from "os"
import { join } from "path"

// ── Constants ───────────────────────────────────────────────────────

const AUTH_PATH = join(homedir(), ".local", "share", "opencode", "auth.json")

// Claude (Anthropic)
const CLAUDE_USAGE_URL = "https://api.anthropic.com/api/oauth/usage"
const CLAUDE_TOKEN_URL = "https://console.anthropic.com/v1/oauth/token"
const CLAUDE_CLIENT_ID = "9d1c250a-e61b-44d9-88ed-5944d1962f5e"

// Codex (OpenAI/ChatGPT)
const CODEX_USAGE_URL = "https://chatgpt.com/backend-api/wham/usage"

const WARN_THRESHOLD = 60
const ALERT_THRESHOLD = 85
const WEEKLY_WARN_THRESHOLD = 75

// ── Types ───────────────────────────────────────────────────────────

interface AuthEntry {
	type: string
	access: string
	refresh: string
	expires: number
}

interface AuthStore {
	anthropic?: AuthEntry
	openai?: AuthEntry
	[key: string]: unknown
}

interface UsageWindow {
	label: string
	utilization: number
	resetsInSeconds: number
}

interface ProviderUsage {
	name: string
	windows: UsageWindow[]
	error?: string
}

// ── Token Management ────────────────────────────────────────────────

async function readAuth(providerKey: string): Promise<AuthEntry | null> {
	try {
		const raw = await Bun.file(AUTH_PATH).text()
		const data: AuthStore = JSON.parse(raw)
		const auth = data[providerKey] as AuthEntry | undefined
		if (!auth || auth.type !== "oauth") {
			return null
		}
		return auth
	} catch {
		return null
	}
}

async function refreshClaudeToken(auth: AuthEntry): Promise<string> {
	const resp = await fetch(CLAUDE_TOKEN_URL, {
		method: "POST",
		headers: { "Content-Type": "application/json" },
		body: JSON.stringify({
			grant_type: "refresh_token",
			refresh_token: auth.refresh,
			client_id: CLAUDE_CLIENT_ID,
		}),
	})
	if (!resp.ok) {
		throw new Error(`Token refresh failed: ${resp.status} ${resp.statusText}`)
	}
	const tokenData = await resp.json()

	const newAuth: AuthEntry = {
		type: "oauth",
		refresh: tokenData.refresh_token,
		access: tokenData.access_token,
		expires: Date.now() + tokenData.expires_in * 1000,
	}

	// Atomic write-back
	const raw = await Bun.file(AUTH_PATH).text()
	const fullData: AuthStore = JSON.parse(raw)
	fullData.anthropic = newAuth

	const tmpPath = AUTH_PATH + ".tmp"
	await Bun.write(tmpPath, JSON.stringify(fullData, null, 2) + "\n")
	const { rename } = await import("fs/promises")
	await rename(tmpPath, AUTH_PATH)

	return tokenData.access_token
}

async function getClaudeToken(): Promise<string | null> {
	const auth = await readAuth("anthropic")
	if (!auth) return null
	if (!auth.access || auth.expires < Date.now()) {
		try {
			return await refreshClaudeToken(auth)
		} catch {
			return null
		}
	}
	return auth.access
}

async function getCodexToken(): Promise<string | null> {
	const auth = await readAuth("openai")
	if (!auth) return null
	return auth.access || null
}

// ── Usage Fetch ─────────────────────────────────────────────────────

async function fetchClaudeUsage(): Promise<ProviderUsage> {
	const token = await getClaudeToken()
	if (!token) {
		return { name: "Claude", windows: [], error: "No auth" }
	}

	try {
		const resp = await fetch(CLAUDE_USAGE_URL, {
			headers: {
				Authorization: `Bearer ${token}`,
				"anthropic-beta": "oauth-2025-04-20",
			},
		})
		if (!resp.ok) {
			throw new Error(`${resp.status} ${resp.statusText}`)
		}
		const data = await resp.json()

		const windows: UsageWindow[] = []
		const windowMap: [string, string][] = [
			["five_hour", "5-hour"],
			["seven_day", "7-day"],
			["seven_day_sonnet", "Sonnet"],
			["seven_day_opus", "Opus"],
		]

		for (const [key, label] of windowMap) {
			const w = data[key]
			if (w) {
				let resetsInSeconds = 0
				if (w.resets_at) {
					const resetTime = new Date(w.resets_at).getTime()
					resetsInSeconds = Math.max(0, Math.floor((resetTime - Date.now()) / 1000))
				}
				windows.push({
					label,
					utilization: w.utilization ?? 0,
					resetsInSeconds,
				})
			}
		}

		return { name: "Claude", windows }
	} catch (e) {
		return { name: "Claude", windows: [], error: String(e) }
	}
}

async function fetchCodexUsage(): Promise<ProviderUsage> {
	const token = await getCodexToken()
	if (!token) {
		return { name: "Codex", windows: [], error: "No auth" }
	}

	try {
		const resp = await fetch(CODEX_USAGE_URL, {
			headers: { Authorization: `Bearer ${token}` },
		})
		if (!resp.ok) {
			throw new Error(`${resp.status} ${resp.statusText}`)
		}
		const data = await resp.json()

		const windows: UsageWindow[] = []
		const rateLimit = data.rate_limit || {}

		const windowMap: [string, string][] = [
			["primary_window", "5-hour"],
			["secondary_window", "7-day"],
		]

		for (const [key, label] of windowMap) {
			const w = rateLimit[key]
			if (w) {
				windows.push({
					label,
					utilization: w.used_percent ?? 0,
					resetsInSeconds: w.reset_after_seconds ?? 0,
				})
			}
		}

		return { name: "Codex", windows }
	} catch (e) {
		return { name: "Codex", windows: [], error: String(e) }
	}
}

async function fetchAllUsage(): Promise<ProviderUsage[]> {
	return Promise.all([fetchClaudeUsage(), fetchCodexUsage()])
}

// ── Formatting ──────────────────────────────────────────────────────

function formatRemaining(seconds: number): string {
	if (seconds <= 0) return "<1m"

	const days = Math.floor(seconds / 86400)
	const hours = Math.floor((seconds % 86400) / 3600)
	const minutes = Math.floor((seconds % 3600) / 60)

	if (days > 0) return `${days}d${hours}h`
	if (hours > 0) return `${hours}h${String(minutes).padStart(2, "0")}m`
	if (minutes > 0) return `${minutes}m`
	return "<1m"
}

function formatBar(pct: number, width = 16): string {
	const filled = Math.max(0, Math.min(width, Math.round((pct / 100) * width)))
	return "\u2588".repeat(filled) + "\u2591".repeat(width - filled)
}

function formatUsageTable(providers: ProviderUsage[]): string {
	const lines: string[] = []

	for (let i = 0; i < providers.length; i++) {
		const provider = providers[i]
		if (i > 0) lines.push("")

		lines.push(provider.name)
		lines.push("\u2500".repeat(48))

		if (provider.error) {
			lines.push(`  Error: ${provider.error}`)
			continue
		}

		if (provider.windows.length === 0) {
			lines.push("  No data")
			continue
		}

		for (const window of provider.windows) {
			const pct = window.utilization
			const remaining = formatRemaining(window.resetsInSeconds)
			const bar = formatBar(pct)
			lines.push(
				`  ${window.label.padEnd(10)} ${bar}  ${String(Math.round(pct)).padStart(3)}%   resets in ${remaining}`,
			)
		}
	}

	return lines.join("\n")
}

function formatToastMessage(providers: ProviderUsage[]): string {
	const parts: string[] = []

	for (const provider of providers) {
		if (provider.error || provider.windows.length === 0) continue

		// Primary (5-hour) window
		const primary = provider.windows[0]
		if (primary) {
			const pct = Math.round(primary.utilization)
			const remaining = formatRemaining(primary.resetsInSeconds)
			parts.push(`${provider.name}: ${pct}% (${remaining})`)
		}

		// Weekly (7-day) window - only if >= 75%
		const weekly = provider.windows.find((w) => w.label === "7-day")
		if (weekly && weekly.utilization >= WEEKLY_WARN_THRESHOLD) {
			const pct = Math.round(weekly.utilization)
			parts.push(`${provider.name} 7d: ${pct}%`)
		}
	}

	return parts.join(" \u00b7 ") || "No usage data"
}

function toastVariant(providers: ProviderUsage[]): "info" | "warning" | "error" {
	let worstState: "info" | "warning" | "error" = "info"

	for (const provider of providers) {
		if (provider.error || provider.windows.length === 0) continue

		// Check primary (5-hour) window
		const primary = provider.windows[0]
		if (primary) {
			if (primary.utilization >= ALERT_THRESHOLD) {
				return "error" // Can't get worse
			}
			if (primary.utilization >= WARN_THRESHOLD && worstState === "info") {
				worstState = "warning"
			}
		}
	}

	return worstState
}

// ── Plugin ──────────────────────────────────────────────────────────

export const ClaudeUsagePlugin: Plugin = async ({ client }) => {
	async function showUsageToast(): Promise<void> {
		try {
			const providers = await fetchAllUsage()
			await client.tui.showToast({
				body: {
					title: "LLM Usage",
					message: formatToastMessage(providers),
					variant: toastVariant(providers),
					duration: 5000,
				},
			})
		} catch {
			// Silent failure — don't block session start
		}
	}

	// Show usage toast when a session is created
	return {
		event: async ({ event }) => {
			if (event.type === "session.created") {
				await showUsageToast()
			}
		},

		tool: {
			rage_limit: tool({
				description:
					"Check LLM subscription usage for Claude and Codex. Shows utilization " +
					"percentages and reset times for rate limit windows.",
				args: {},
				async execute() {
					const providers = await fetchAllUsage()
					return formatUsageTable(providers)
				},
			}),
		},
	}
}
