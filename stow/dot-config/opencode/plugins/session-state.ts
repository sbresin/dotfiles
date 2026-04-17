import type { Event, Message, Part, Session, SessionStatus } from "@opencode-ai/sdk"
import type { Plugin } from "@opencode-ai/plugin"
import { mkdir, readdir, rename, unlink, writeFile } from "fs/promises"
import { join } from "path"

const SERVICE = "session-state"
const DISMISS_SUFFIX = ".dismiss"
const RUNTIME_DIR = join(
	process.env.XDG_RUNTIME_DIR ?? `/run/user/${process.getuid?.() ?? 0}`,
	"opencode",
	"session-state",
)

const RELEVANT_EVENTS = new Set<string>([
	"session.created",
	"session.updated",
	"session.deleted",
	"session.status",
	"session.idle",
	"session.error",
	"permission.asked",
	"permission.replied",
	"message.part.updated",
])

type RuntimeState = "idle" | "running" | "question" | "error" | "done"
type RuntimeReason = "busy" | "retry" | "question" | "permission" | "error" | "done"

type RuntimeStateFile = {
	version: 1
	session_id: string
	directory: string
	worktree: string
	state: RuntimeState
	reason?: RuntimeReason
	updated_at: number
}

type SessionRecord = {
	info: Session
	state: RuntimeState
	reason?: RuntimeReason
	worktree: string
}

type AssistantState = {
	has_question: boolean
	has_error: boolean
}

type PermissionAskedEvent = {
	type: "permission.asked"
	properties: {
		id: string
		sessionID: string
	}
}

type PermissionRepliedEvent = {
	type: "permission.replied"
	properties: {
		sessionID: string
		requestID?: string
		permissionID?: string
	}
}

type RuntimeEvent = Event | PermissionAskedEvent | PermissionRepliedEvent

function extractSessionID(event: RuntimeEvent): string | undefined {
	const props = event.properties as Record<string, unknown>
	if (typeof props.sessionID === "string") {
		return props.sessionID
	}
	if (typeof props.info === "object" && props.info !== null && "id" in props.info) {
		return (props.info as { id: string }).id
	}
	if (typeof props.part === "object" && props.part !== null && "sessionID" in props.part) {
		return (props.part as { sessionID: string }).sessionID
	}
	return undefined
}

function statePath(sessionID: string): string {
	return join(RUNTIME_DIR, `${sessionID}.json`)
}

function isRunning(status?: SessionStatus): boolean {
	return status?.type === "busy" || status?.type === "retry"
}

function runningReason(status?: SessionStatus): RuntimeReason {
	return status?.type === "retry" ? "retry" : "busy"
}

function sessionWorktree(session: Session, worktree: string): string {
	if (session.directory === worktree || session.directory.startsWith(`${worktree}/`)) {
		return worktree
	}
	return session.directory
}

function hasRealToolError(parts: Part[]): boolean {
	return parts.some((part) => {
		if (part.type !== "tool" || part.state.status !== "error") {
			return false
		}
		if (part.tool === "question") {
			return false
		}
		if (part.state.error.startsWith("The user rejected permission")) {
			return false
		}
		return true
	})
}

function isRealMessageError(error?: { name: string }): boolean {
	return error != null && error.name !== "MessageAbortedError"
}

function latestMessageTime(entry: { info: Message }): number {
	if (entry.info.role === "assistant") {
		return entry.info.time.completed ?? entry.info.time.created
	}
	return entry.info.time.created
}

function permissionReplyID(event: PermissionRepliedEvent): string | undefined {
	return event.properties.requestID ?? event.properties.permissionID
}

async function writeStateFile(record: RuntimeStateFile): Promise<void> {
	await mkdir(RUNTIME_DIR, { recursive: true })
	const target = statePath(record.session_id)
	const tmp = `${target}.${process.pid}.tmp`
	await writeFile(tmp, `${JSON.stringify(record)}\n`)
	await rename(tmp, target)
}

async function removeStateFile(sessionID: string): Promise<void> {
	try {
		await unlink(statePath(sessionID))
	} catch (error) {
		if (
			typeof error !== "object" ||
			error === null ||
			!("code" in error) ||
			error.code !== "ENOENT"
		) {
			throw error
		}
	}
}

async function gcStaleFiles(liveSessionIDs: Set<string>): Promise<void> {
	let entries: string[]

	try {
		entries = await readdir(RUNTIME_DIR)
	} catch (error) {
		if (
			typeof error !== "object" ||
			error === null ||
			!("code" in error) ||
			error.code !== "ENOENT"
		) {
			throw error
		}
		return
	}

	await Promise.all(
		entries
			.filter((entry) => entry.endsWith(".json"))
			.map((entry) => entry.slice(0, -5))
			.filter((sessionID) => !liveSessionIDs.has(sessionID))
			.map((sessionID) => removeStateFile(sessionID)),
	)
}

export const SessionStatePlugin: Plugin = async ({ client, worktree }) => {
	async function log(level: "warn" | "error", message: string, extra?: Record<string, unknown>) {
		try {
			await client.app.log({
				body: {
					service: SERVICE,
					level,
					message,
					extra,
				},
			})
		} catch {
			// Logging failures should never break the plugin.
		}
	}

	async function latestAssistantState(sessionID: string): Promise<AssistantState> {
		try {
			const response = await client.session.messages({
				path: { id: sessionID },
				query: { limit: 20 },
				throwOnError: true,
			})
			const data = response.data ?? []

			const latestAssistant = data
				.filter((message) => message.info.role === "assistant")
				.sort((left, right) => latestMessageTime(right) - latestMessageTime(left))[0]

			if (!latestAssistant || latestAssistant.info.role !== "assistant") {
				return { has_question: false, has_error: false }
			}

			const hasQuestion = latestAssistant.parts.some((part) => {
				return (
					part.type === "tool" &&
					part.tool === "question" &&
					(part.state.status === "pending" || part.state.status === "running")
				)
			})

			return {
				has_question: hasQuestion,
				has_error:
					isRealMessageError(latestAssistant.info.error) || hasRealToolError(latestAssistant.parts),
			}
		} catch (error) {
			await log("warn", "Failed to inspect latest session message", {
				sessionID,
				error: error instanceof Error ? error.message : String(error),
			})
			return { has_question: false, has_error: false }
		}
	}

	async function collectSessionRecords(): Promise<SessionRecord[]> {
		const [sessionResponse, statusResponse] = await Promise.all([
			client.session.list({ throwOnError: true }),
			client.session.status({ throwOnError: true }),
		])
		const allSessions = sessionResponse.data ?? []

		childSessionIDs.clear()
		for (const session of allSessions) {
			if (session.parentID != null) {
				childSessionIDs.add(session.id)
			}
		}

		const sessions = allSessions.filter((session) => session.parentID == null)
		const statuses = statusResponse.data ?? {}

		const assistantStates = new Map(
			(
				await Promise.all(
					sessions.map(async (session) => {
						return [session.id, await latestAssistantState(session.id)] as const
					}),
				)
			).map(([sessionID, state]) => [sessionID, state]),
		)

		return sessions.map((session) => {
			let state: RuntimeState = "idle"
			let reason: RuntimeReason | undefined
			const assistantState = assistantStates.get(session.id) ?? {
				has_question: false,
				has_error: false,
			}

			if (pendingPermissions.has(session.id)) {
				state = "question"
				reason = "permission"
			} else if (assistantState.has_question) {
				state = "question"
				reason = "question"
			} else if (isRunning(statuses[session.id])) {
				state = "running"
				reason = runningReason(statuses[session.id])
			} else if (assistantState.has_error) {
				state = "error"
				reason = "error"
			} else if (doneSessions.has(session.id)) {
				state = "done"
				reason = "done"
			}

			return {
				info: session,
				state,
				reason,
				worktree: sessionWorktree(session, worktree),
			}
		})
	}

	async function syncStates(): Promise<void> {
		await processDismissals()
		const records = await collectSessionRecords()
		const now = Date.now()
		const liveSessionIDs = new Set(records.map((record) => record.info.id))

		await Promise.all(
			records.map((record) => {
				return writeStateFile({
					version: 1,
					session_id: record.info.id,
					directory: record.info.directory,
					worktree: record.worktree,
					state: record.state,
					reason: record.reason,
					updated_at: now,
				})
			}),
		)

		await gcStaleFiles(liveSessionIDs)
	}

	let syncQueued = false
	let syncRunning: Promise<void> | undefined
	const pendingPermissions = new Map<string, Set<string>>()
	const busySessions = new Set<string>()
	const doneSessions = new Set<string>()
	const childSessionIDs = new Set<string>()

	function addPendingPermission(sessionID: string, permissionID: string): void {
		const ids = pendingPermissions.get(sessionID) ?? new Set<string>()
		ids.add(permissionID)
		pendingPermissions.set(sessionID, ids)
	}

	function removePendingPermission(sessionID: string, permissionID: string): void {
		const ids = pendingPermissions.get(sessionID)
		if (!ids) {
			return
		}

		ids.delete(permissionID)
		if (ids.size === 0) {
			pendingPermissions.delete(sessionID)
		}
	}

	async function processDismissals(): Promise<void> {
		let entries: string[]

		try {
			entries = await readdir(RUNTIME_DIR)
		} catch {
			return
		}

		await Promise.all(
			entries
				.filter((entry) => entry.endsWith(DISMISS_SUFFIX))
				.map(async (entry) => {
					const sessionID = entry.slice(0, -DISMISS_SUFFIX.length)
					doneSessions.delete(sessionID)
					try {
						await unlink(join(RUNTIME_DIR, entry))
					} catch {
						// Dismiss file already removed — fine.
					}
				}),
		)
	}

	function scheduleSync(): Promise<void> {
		syncQueued = true
		if (syncRunning) {
			return syncRunning
		}

		syncRunning = (async () => {
			while (syncQueued) {
				syncQueued = false
				try {
					await syncStates()
				} catch (error) {
					await log("error", "Failed to sync session state", {
						error: error instanceof Error ? error.message : String(error),
					})
				}
			}
		})().finally(() => {
			syncRunning = undefined
		})

		return syncRunning
	}

	return {
		event: async ({ event }) => {
			const runtimeEvent = event as RuntimeEvent

			if (!RELEVANT_EVENTS.has(runtimeEvent.type)) {
				return
			}

			const eventSessionID = extractSessionID(runtimeEvent)
			if (eventSessionID && childSessionIDs.has(eventSessionID)) {
				return
			}

			if (
				runtimeEvent.type === "message.part.updated" &&
				runtimeEvent.properties.part.type !== "tool"
			) {
				return
			}

			if (runtimeEvent.type === "permission.asked") {
				addPendingPermission(runtimeEvent.properties.sessionID, runtimeEvent.properties.id)
			}

			if (runtimeEvent.type === "permission.replied") {
				const requestID = permissionReplyID(runtimeEvent)
				if (requestID) {
					removePendingPermission(runtimeEvent.properties.sessionID, requestID)
				}
			}

			if (runtimeEvent.type === "session.status") {
				const { sessionID, status } = runtimeEvent.properties
				if (status.type === "busy" || status.type === "retry") {
					busySessions.add(sessionID)
					doneSessions.delete(sessionID)
				}
			}

			if (runtimeEvent.type === "session.idle") {
				const { sessionID } = runtimeEvent.properties
				if (busySessions.has(sessionID)) {
					busySessions.delete(sessionID)
					doneSessions.add(sessionID)
				}
			}

			if (runtimeEvent.type === "session.deleted") {
				const id = runtimeEvent.properties.info.id
				pendingPermissions.delete(id)
				busySessions.delete(id)
				doneSessions.delete(id)
				await removeStateFile(id)
				return
			}

			await scheduleSync()
		},
	}
}
