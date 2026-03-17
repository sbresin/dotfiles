import { tool } from "@opencode-ai/plugin"
import { mkdir } from "fs/promises"
import path from "path"

export default tool({
  description:
    "Get a per-session scratch directory in /tmp that can be used without confirmation. " +
    "Creates /tmp/opencode-<sessionID>/ if it doesn't exist and returns the path. " +
    "Use this when you need to write temporary files.",
  args: {},
  async execute(_args, context) {
    const dir = path.join("/tmp", `opencode-${context.sessionID}`)
    await mkdir(dir, { recursive: true })
    return dir
  },
})
