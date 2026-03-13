import { tool } from "@opencode-ai/plugin"

const CHROMIUM_BIN = "io.github.ungoogled_software.ungoogled_chromium"
const DEFAULT_PORT = 9222

async function isPortInUse(port: number): Promise<boolean> {
  try {
    await Bun.$`fuser ${port}/tcp`.quiet()
    return true
  } catch {
    return false
  }
}

async function getPidOnPort(port: number): Promise<number | null> {
  try {
    const result = await Bun.$`fuser ${port}/tcp`.quiet()
    const pid = parseInt(result.stdout.toString().trim(), 10)
    return isNaN(pid) ? null : pid
  } catch {
    return null
  }
}

async function waitForPort(port: number, timeoutMs: number = 5000): Promise<boolean> {
  const start = Date.now()
  while (Date.now() - start < timeoutMs) {
    if (await isPortInUse(port)) return true
    await Bun.sleep(250)
  }
  return false
}

export default tool({
  description:
    "Launch Ungoogled Chromium with remote debugging enabled, for use with the chrome-dev MCP. " +
    "Returns once the debugging port is confirmed listening.",
  args: {
    port: tool.schema
      .number()
      .optional()
      .describe(`Remote debugging port (default: ${DEFAULT_PORT})`),
  },
  async execute(args) {
    const port = args.port ?? DEFAULT_PORT

    if (await isPortInUse(port)) {
      return `Port ${port} is already in use — a debugging instance may already be running.`
    }

    const proc = Bun.spawn([CHROMIUM_BIN, `--remote-debugging-port=${port}`], {
      stdout: "ignore",
      stderr: "ignore",
    })
    proc.unref()

    const ready = await waitForPort(port)
    if (!ready) {
      return `Chromium was launched but port ${port} did not become available within 5 seconds. Check manually.`
    }

    return `Chromium launched with remote debugging on port ${port} (pid ${proc.pid}).`
  },
})

export const stop = tool({
  description: "Stop a running Chromium remote debugging instance by killing the process on the debugging port.",
  args: {
    port: tool.schema
      .number()
      .optional()
      .describe(`Remote debugging port to stop (default: ${DEFAULT_PORT})`),
  },
  async execute(args) {
    const port = args.port ?? DEFAULT_PORT

    const pid = await getPidOnPort(port)
    if (!pid) {
      return `Nothing is listening on port ${port} — no instance to stop.`
    }

    try {
      process.kill(pid, "SIGTERM")
    } catch (e: any) {
      throw new Error(`Failed to kill pid ${pid}: ${e.message}`)
    }

    // Wait briefly for the port to free up
    const start = Date.now()
    while (Date.now() - start < 3000) {
      if (!(await isPortInUse(port))) {
        return `Stopped Chromium debugging instance (pid ${pid}) on port ${port}.`
      }
      await Bun.sleep(250)
    }

    return `Sent SIGTERM to pid ${pid} but port ${port} is still in use after 3 seconds.`
  },
})
