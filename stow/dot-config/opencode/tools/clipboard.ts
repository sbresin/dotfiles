import { tool } from "@opencode-ai/plugin"

// Note: Bun has no native clipboard API (PR #22956 was closed without merging).
// We use Bun.spawn() instead of Bun.$`` shell because wl-copy forks a background
// daemon to serve clipboard requests, and Bun shell waits for all child processes
// to exit, causing 45-60 second delays. Using Bun.spawn() with proc.unref()
// properly detaches from the forked daemon.

async function hasCommand(cmd: string): Promise<boolean> {
  try {
    await Bun.$`which ${cmd}`.quiet()
    return true
  } catch {
    return false
  }
}

async function copyToClipboard(text: string): Promise<string> {
  if (await hasCommand("wl-copy")) {
    const proc = Bun.spawn(["wl-copy"], {
      stdin: new Blob([text]),
    })
    proc.unref()
    await proc.exited
    return "Copied to clipboard using wl-copy (Wayland)"
  }
  if (await hasCommand("xclip")) {
    const proc = Bun.spawn(["xclip", "-selection", "clipboard"], {
      stdin: new Blob([text]),
    })
    proc.unref()
    await proc.exited
    return "Copied to clipboard using xclip (X11)"
  }
  if (await hasCommand("pbcopy")) {
    const proc = Bun.spawn(["pbcopy"], {
      stdin: new Blob([text]),
    })
    await proc.exited
    return "Copied to clipboard using pbcopy (macOS)"
  }
  throw new Error("No clipboard tool available. Install wl-copy (Wayland), xclip (X11), or use macOS (pbcopy).")
}

async function copyFileToClipboard(path: string): Promise<string> {
  if (await hasCommand("wl-copy")) {
    const proc = Bun.spawn(["wl-copy"], {
      stdin: Bun.file(path),
    })
    proc.unref()
    await proc.exited
    return `Copied contents of ${path} to clipboard using wl-copy (Wayland)`
  }
  if (await hasCommand("xclip")) {
    const proc = Bun.spawn(["xclip", "-selection", "clipboard"], {
      stdin: Bun.file(path),
    })
    proc.unref()
    await proc.exited
    return `Copied contents of ${path} to clipboard using xclip (X11)`
  }
  if (await hasCommand("pbcopy")) {
    const proc = Bun.spawn(["pbcopy"], {
      stdin: Bun.file(path),
    })
    await proc.exited
    return `Copied contents of ${path} to clipboard using pbcopy (macOS)`
  }
  throw new Error("No clipboard tool available. Install wl-copy (Wayland), xclip (X11), or use macOS (pbcopy).")
}

export default tool({
  description: "Copy text to the system clipboard. Uses wl-copy on Wayland, xclip on X11, or pbcopy on macOS.",
  args: {
    text: tool.schema.string().describe("The text to copy to the clipboard"),
  },
  async execute(args) {
    return copyToClipboard(args.text)
  },
})

export const file = tool({
  description: "Copy contents of a file to the system clipboard. Uses wl-copy on Wayland, xclip on X11, or pbcopy on macOS.",
  args: {
    path: tool.schema.string().describe("Path to the file whose contents to copy"),
  },
  async execute(args) {
    return copyFileToClipboard(args.path)
  },
})
