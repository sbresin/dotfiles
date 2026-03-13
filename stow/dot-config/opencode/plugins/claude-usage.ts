import { type Plugin, tool } from "@opencode-ai/plugin"
import { homedir } from "os"
import { join } from "path"

// ── Constants ───────────────────────────────────────────────────────

const AUTH_PATH = join(homedir(), ".local", "share", "opencode", "auth.json")
const USAGE_URL = "https://api.anthropic.com/api/oauth/usage"
const TOKEN_URL = "https://console.anthropic.com/v1/oauth/token"
const CLIENT_ID = "9d1c250a-e61b-44d9-88ed-5944d1962f5e"

const WARN_THRESHOLD = 60
const ALERT_THRESHOLD = 85

const WINDOW_LABELS: Record<string, string> = {
	five_hour: "5-hour",
	seven_day: "7-day",
	seven_day_sonnet: "Sonnet",
	seven_day_opus: "Opus",
}

// ── Types ───────────────────────────────────────────────────────────

interface AuthEntry {
	type: string
	access: string
	refresh: string
	expires: number
}

interface AuthStore {
	anthropic?: AuthEntry
	[key: string]: unknown
}

interface UsageWindow {
	utilization: number
	resets_at: string
}

type UsageData = Record<string, UsageWindow | undefined>

// ── Token Management ────────────────────────────────────────────────

async function readAuth(): Promise<AuthEntry> {
	const raw = await Bun.file(AUTH_PATH).text()
	const data: AuthStore = JSON.parse(raw)
	const auth = data.anthropic
	if (!auth || auth.type !== "oauth") {
		throw new Error("No OAuth credentials for anthropic in auth.json")
	}
	return auth
}

async function refreshToken(auth: AuthEntry): Promise<string> {
	const resp = await fetch(TOKEN_URL, {
		method: "POST",
		headers: { "Content-Type": "application/json" },
		body: JSON.stringify({
			grant_type: "refresh_token",
			refresh_token: auth.refresh,
			client_id: CLIENT_ID,
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

	// Atomic write-back: read full store, update anthropic entry, write to
	// temp file then rename for atomicity.
	const raw = await Bun.file(AUTH_PATH).text()
	const fullData: AuthStore = JSON.parse(raw)
	fullData.anthropic = newAuth

	const tmpPath = AUTH_PATH + ".tmp"
	await Bun.write(tmpPath, JSON.stringify(fullData, null, 2) + "\n")
	const { rename } = await import("fs/promises")
	await rename(tmpPath, AUTH_PATH)

	return tokenData.access_token
}

async function getAccessToken(): Promise<string> {
	const auth = await readAuth()
	if (!auth.access || auth.expires < Date.now()) {
		return refreshToken(auth)
	}
	return auth.access
}

// ── Usage Fetch ─────────────────────────────────────────────────────

async function fetchUsage(accessToken: string): Promise<UsageData> {
	const resp = await fetch(USAGE_URL, {
		headers: {
			Authorization: `Bearer ${accessToken}`,
			"anthropic-beta": "oauth-2025-04-20",
		},
	})
	if (!resp.ok) {
		throw new Error(`Usage fetch failed: ${resp.status} ${resp.statusText}`)
	}
	return resp.json()
}

// ── Formatting ──────────────────────────────────────────────────────

function formatRemaining(resetsAt: string): string {
	const delta = new Date(resetsAt).getTime() - Date.now()
	const totalSeconds = Math.max(Math.floor(delta / 1000), 0)

	const days = Math.floor(totalSeconds / 86400)
	const hours = Math.floor((totalSeconds % 86400) / 3600)
	const minutes = Math.floor((totalSeconds % 3600) / 60)

	if (days > 0) return `${days}d${hours}h`
	if (hours > 0) return `${hours}h${String(minutes).padStart(2, "0")}m`
	if (minutes > 0) return `${minutes}m`
	return "<1m"
}

function formatBar(pct: number, width = 16): string {
	const filled = Math.max(0, Math.min(width, Math.round((pct / 100) * width)))
	return "\u2588".repeat(filled) + "\u2591".repeat(width - filled)
}

function formatUsageTable(usage: UsageData): string {
	const lines: string[] = ["Claude Usage", "\u2500".repeat(48)]

	for (const [key, label] of Object.entries(WINDOW_LABELS)) {
		const window = usage[key]
		if (!window) {
			lines.push(`  ${label.padEnd(10)} \u2014`)
			continue
		}
		const pct = window.utilization
		const remaining = formatRemaining(window.resets_at)
		const bar = formatBar(pct)
		lines.push(
			`  ${label.padEnd(10)} ${bar}  ${String(Math.round(pct)).padStart(3)}%   resets in ${remaining}`,
		)
	}

	return lines.join("\n")
}

function formatToastMessage(usage: UsageData): string {
	const parts: string[] = []
	for (const [key, label] of Object.entries(WINDOW_LABELS)) {
		const window = usage[key]
		if (!window) continue
		const pct = Math.round(window.utilization)
		const remaining = formatRemaining(window.resets_at)
		parts.push(`${label}: ${pct}% (${remaining})`)
	}
	return parts.join(" \u00b7 ") || "No usage data"
}

function toastVariant(usage: UsageData): "info" | "warning" | "error" {
	const fiveHour = usage.five_hour
	if (!fiveHour) return "info"
	if (fiveHour.utilization >= ALERT_THRESHOLD) return "error"
	if (fiveHour.utilization >= WARN_THRESHOLD) return "warning"
	return "info"
}

// ── Plugin ──────────────────────────────────────────────────────────

export const ClaudeUsagePlugin: Plugin = async ({ client }) => {
	async function showUsageToast(): Promise<void> {
		try {
			const token = await getAccessToken()
			const usage = await fetchUsage(token)
			await client.tui.showToast({
				body: {
					title: "Claude Usage",
					message: formatToastMessage(usage),
					variant: toastVariant(usage),
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
			claude_usage: tool({
				description:
					"Check Claude Pro/Max subscription usage. Shows utilization percentages " +
					"and reset times for all usage windows (5-hour, 7-day, Sonnet, Opus).",
				args: {},
				async execute() {
					const token = await getAccessToken()
					const usage = await fetchUsage(token)
					return formatUsageTable(usage)
				},
			}),
		},
	}
}
