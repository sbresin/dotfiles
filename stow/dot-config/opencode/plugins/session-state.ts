import type { Event, Message, Part, Session, SessionStatus } from "@opencode-ai/sdk"
import type { Plugin } from "@opencode-ai/plugin"
import { mkdir, readFile, readdir, rename, unlink, writeFile } from "fs/promises"
import { appendFileSync } from "fs"
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
	version: 2
	session_id: string
	directory: string
	worktree: string
	state: RuntimeState
	reason?: RuntimeReason
	title: string
	time_updated: number
	updated_at: number
	server_url: string
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

type SessionTree = {
	parents: Map<string, string>
	children: Map<string, Set<string>>
}

function treeRebuild(sessions: Session[]): SessionTree {
	const parents = new Map<string, string>()
	const children = new Map<string, Set<string>>()
	for (const session of sessions) {
		if (session.parentID != null) {
			parents.set(session.id, session.parentID)
			const siblings = children.get(session.parentID) ?? new Set<string>()
			siblings.add(session.id)
			children.set(session.parentID, siblings)
		}
	}
	return { parents, children }
}

function treeRoot(tree: SessionTree, sessionID: string): string {
	let current = sessionID
	const visited = new Set<string>()
	while (tree.parents.has(current)) {
		if (visited.has(current)) {
			break
		}
		visited.add(current)
		current = tree.parents.get(current)!
	}
	return current
}

function treeDescendants(tree: SessionTree, sessionID: string): string[] {
	const result: string[] = []
	const stack = [...(tree.children.get(sessionID) ?? [])]
	while (stack.length > 0) {
		const child = stack.pop()!
		result.push(child)
		for (const grandchild of tree.children.get(child) ?? []) {
			stack.push(grandchild)
		}
	}
	return result
}

function treeIsChild(tree: SessionTree, sessionID: string): boolean {
	return tree.parents.has(sessionID)
}

function treeRemove(tree: SessionTree, sessionID: string): void {
	const parentID = tree.parents.get(sessionID)
	if (parentID != null) {
		const siblings = tree.children.get(parentID)
		if (siblings) {
			siblings.delete(sessionID)
			if (siblings.size === 0) {
				tree.children.delete(parentID)
			}
		}
		tree.parents.delete(sessionID)
	}
	// Also remove any children that pointed to this session as parent.
	const kids = tree.children.get(sessionID)
	if (kids) {
		for (const kid of kids) {
			tree.parents.delete(kid)
		}
		tree.children.delete(sessionID)
	}
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

function debugLog(data: unknown): void {
	try {
		const debugPath = join(RUNTIME_DIR, "_debug.log")
		const line = `${new Date().toISOString()} ${JSON.stringify(data)}\n`
		appendFileSync(debugPath, line)
	} catch {
		// Ignore debug failures
	}
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

async function gcStaleFiles(liveSessionIDs: Set<string>, serverURL: string): Promise<void> {
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
			.map(async (sessionID) => {
				try {
					const content = await readFile(statePath(sessionID), "utf-8")
					const data = JSON.parse(content) as Partial<RuntimeStateFile>
					if (data.server_url !== serverURL) {
						return
					}
				} catch {
					return
				}

				await removeStateFile(sessionID)
			}),
	)
}

export const SessionStatePlugin: Plugin = async ({ client, worktree, serverUrl }) => {
	// DEBUG: Log plugin initialization
	debugLog({
		event: "pluginInit",
		worktree,
		serverUrl: serverUrl.toString(),
	})

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

		sessionTree = treeRebuild(allSessions)

		// Filter to root sessions in this worktree only - prevents cross-instance interference
		const sessions = allSessions
			.filter((session) => session.parentID == null)
			.filter((session) => sessionWorktree(session, worktree) === worktree)
		const statuses = statusResponse.data ?? {}

		// DEBUG: Log the raw status response
		debugLog({
			event: "collectSessionRecords",
			statusResponseDataType: typeof statusResponse.data,
			statusResponseData: statusResponse.data,
			statusesKeys: Object.keys(statuses),
			sessionCount: sessions.length,
			sessionIds: sessions.map((s) => s.id),
		})

		// For each root session, inspect its own messages and — only when the
		// parent is actively working — also all descendants' messages. This
		// ensures child state can bump the parent *upward* (e.g. permission
		// request) but stale child errors don't linger once the parent is idle.
		const assistantStates = new Map(
			await Promise.all(
				sessions.map(async (session) => {
					const parentActive =
						isRunning(statuses[session.id]) || hasRecentActivity(session.id) || pendingPermissions.has(session.id)
					const allIDs = parentActive
						? [session.id, ...treeDescendants(sessionTree, session.id)]
						: [session.id]
					const states = await Promise.all(allIDs.map((id) => latestAssistantState(id)))
					return [
						session.id,
						{
							has_question: states.some((s) => s.has_question),
							has_error: states.some((s) => s.has_error),
						},
					] as const
				}),
			),
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
			} else if (isRunning(statuses[session.id]) || hasRecentActivity(session.id)) {
				state = "running"
				reason = hasRecentActivity(session.id) ? "busy" : runningReason(statuses[session.id])
			} else if (assistantState.has_error) {
				state = "error"
				reason = "error"
			} else if (doneSessions.has(session.id)) {
				const isRecent = Date.now() - session.time.updated < STALE_SESSION_MS
				if (isRecent) {
					state = "done"
					reason = "done"
				}
			}

			// DEBUG: Log the state check for each session
			debugLog({
				event: "sessionStateCheck",
				sessionId: session.id,
				statusValue: statuses[session.id],
				isRunningResult: isRunning(statuses[session.id]),
				hasRecentActivity: hasRecentActivity(session.id),
				lastActivityMs: sessionLastActivity.get(session.id)
					? Date.now() - sessionLastActivity.get(session.id)!
					: undefined,
				pendingPermissions: pendingPermissions.has(session.id),
				hasQuestion: assistantState.has_question,
				hasError: assistantState.has_error,
				inDoneSessions: doneSessions.has(session.id),
				finalState: state,
				finalReason: reason,
			})

			return {
				info: session,
				state,
				reason,
				worktree: sessionWorktree(session, worktree),
			}
		})
	}

	async function syncStates(): Promise<void> {
		debugLog({ event: "syncStatesStart", serverUrl: serverUrl.toString() })
		await processDismissals()
		const records = await collectSessionRecords()
		const now = Date.now()
		const liveSessionIDs = new Set(records.map((record) => record.info.id))

		await Promise.all(
			records.map((record) => {
				return writeStateFile({
					version: 2,
					session_id: record.info.id,
					directory: record.info.directory,
					worktree: record.worktree,
					state: record.state,
					reason: record.reason,
					title: record.info.title,
					time_updated: record.info.time.updated,
					updated_at: now,
					server_url: serverUrl.toString(),
				})
			}),
		)

		await gcStaleFiles(liveSessionIDs, serverUrl.toString())
	}

	let syncQueued = false
	let syncRunning: Promise<void> | undefined
	const pendingPermissions = new Map<string, Set<string>>()
	// const busySessions = new Set<string>() // Commented out: session.status events are too transient (~40ms)
	const doneSessions = new Set<string>()
	let sessionTree: SessionTree = { parents: new Map(), children: new Map() }

	// Activity-based tracking: track when sessions last received message.part.updated events
	// This is a much more reliable signal than session.status events
	const ACTIVITY_TIMEOUT_MS = 5000 // Consider session "running" if activity within last 5 seconds
const STALE_SESSION_MS = 6 * 60 * 60 * 1000 // Don't mark sessions older than 6 hours as "done"
	const sessionLastActivity = new Map<string, number>() // sessionId -> timestamp

	function hasRecentActivity(sessionID: string): boolean {
		const lastActivity = sessionLastActivity.get(sessionID)
		if (!lastActivity) return false
		return Date.now() - lastActivity < ACTIVITY_TIMEOUT_MS
	}

	async function resolveRoot(sessionID: string): Promise<string> {
		if (!treeIsChild(sessionTree, sessionID) && !sessionTree.children.has(sessionID)) {
			// Session is completely unknown — refresh the tree from the server.
			try {
				const response = await client.session.list({ throwOnError: true })
				const allSessions = response.data ?? []
				sessionTree = treeRebuild(allSessions)
			} catch (error) {
				await log("warn", "Failed to refresh session tree for root resolution", {
					sessionID,
					error: error instanceof Error ? error.message : String(error),
				})
			}
		}
		return treeRoot(sessionTree, sessionID)
	}

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
					debugLog({
						event: "syncStatesError",
						error: error instanceof Error ? error.message : String(error),
						stack: error instanceof Error ? error.stack : undefined,
					})
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

	// Perform initial sync on startup so state files exist immediately.
	scheduleSync()

	return {
		event: async ({ event }) => {
			const runtimeEvent = event as RuntimeEvent

			// DEBUG: Log all events
			if (RELEVANT_EVENTS.has(runtimeEvent.type)) {
				debugLog({
					event: "receivedEvent",
					type: runtimeEvent.type,
					sessionID: extractSessionID(runtimeEvent),
					properties: runtimeEvent.type === "session.status" 
						? (runtimeEvent as { properties: { status: unknown } }).properties.status
						: undefined,
				})
			}

			if (!RELEVANT_EVENTS.has(runtimeEvent.type)) {
				return
			}

			const eventSessionID = extractSessionID(runtimeEvent)
			const isChild = eventSessionID != null && treeIsChild(sessionTree, eventSessionID)

			if (isChild) {
				// Child sessions may only bump the parent state *upward*.
				// Permission events and message.part.updated (for activity tracking) escalate;
				// everything else is ignored.
				if (
					runtimeEvent.type !== "permission.asked" &&
					runtimeEvent.type !== "permission.replied" &&
					runtimeEvent.type !== "message.part.updated"
				) {
					return
				}
			}

			if (runtimeEvent.type === "permission.asked") {
				const rootID = await resolveRoot(runtimeEvent.properties.sessionID)
				addPendingPermission(rootID, runtimeEvent.properties.id)
			}

			if (runtimeEvent.type === "permission.replied") {
				const rootID = await resolveRoot(runtimeEvent.properties.sessionID)
				const requestID = permissionReplyID(runtimeEvent)
				if (requestID) {
					removePendingPermission(rootID, requestID)
				}
			}

			// Commented out: session.status events are too transient (~40ms) to be useful
			// if (runtimeEvent.type === "session.status") {
			// 	const { sessionID, status } = runtimeEvent.properties
			// 	if (status.type === "busy" || status.type === "retry") {
			// 		busySessions.add(sessionID)
			// 		doneSessions.delete(sessionID)
			// 	}
			// }

			// Track activity based on message.part.updated events - much more reliable
			if (runtimeEvent.type === "message.part.updated") {
				const sessionID = extractSessionID(runtimeEvent)
				if (sessionID) {
					const rootID = await resolveRoot(sessionID)
					const wasActive = hasRecentActivity(rootID)
					sessionLastActivity.set(rootID, Date.now())
					doneSessions.delete(rootID)

					// Only trigger sync if this is a state change (becoming active) or it's a tool part
					if (!wasActive || runtimeEvent.properties.part.type === "tool") {
						// State changed from idle to running, or tool part needs sync
						await scheduleSync()
					}
					return
				}
			}

			if (runtimeEvent.type === "session.idle") {
				const { sessionID } = runtimeEvent.properties
				// Clear activity tracking immediately on idle
				sessionLastActivity.delete(sessionID)
				doneSessions.add(sessionID)
			}

			if (runtimeEvent.type === "session.deleted") {
				const id = runtimeEvent.properties.info.id
				pendingPermissions.delete(id)
				sessionLastActivity.delete(id)
				doneSessions.delete(id)
				treeRemove(sessionTree, id)
				await removeStateFile(id)
				return
			}

			await scheduleSync()
		},
	}
}
