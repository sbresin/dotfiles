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

function mimeLabel(mimeType?: string): string {
  return mimeType ? ` as ${mimeType}` : ""
}

async function copyToClipboard(text: string, mimeType?: string): Promise<string> {
  if (await hasCommand("wl-copy")) {
    const args = mimeType ? ["wl-copy", "--type", mimeType] : ["wl-copy"]
    const proc = Bun.spawn(args, {
      stdin: new Blob([text]),
    })
    proc.unref()
    await proc.exited
    return `Copied to clipboard${mimeLabel(mimeType)} using wl-copy (Wayland)`
  }
  if (await hasCommand("xclip")) {
    const args = mimeType
      ? ["xclip", "-selection", "clipboard", "-t", mimeType]
      : ["xclip", "-selection", "clipboard"]
    const proc = Bun.spawn(args, {
      stdin: new Blob([text]),
    })
    proc.unref()
    await proc.exited
    return `Copied to clipboard${mimeLabel(mimeType)} using xclip (X11)`
  }
  if (await hasCommand("pbcopy")) {
    const proc = Bun.spawn(["pbcopy"], {
      stdin: new Blob([text]),
    })
    await proc.exited
    const note = mimeType ? " (mimeType ignored — pbcopy only supports plain text)" : ""
    return `Copied to clipboard using pbcopy (macOS)${note}`
  }
  throw new Error("No clipboard tool available. Install wl-copy (Wayland), xclip (X11), or use macOS (pbcopy).")
}

async function copyFileToClipboard(path: string, mimeType?: string): Promise<string> {
  if (await hasCommand("wl-copy")) {
    const args = mimeType ? ["wl-copy", "--type", mimeType] : ["wl-copy"]
    const proc = Bun.spawn(args, {
      stdin: Bun.file(path),
    })
    proc.unref()
    await proc.exited
    return `Copied contents of ${path} to clipboard${mimeLabel(mimeType)} using wl-copy (Wayland)`
  }
  if (await hasCommand("xclip")) {
    const args = mimeType
      ? ["xclip", "-selection", "clipboard", "-t", mimeType]
      : ["xclip", "-selection", "clipboard"]
    const proc = Bun.spawn(args, {
      stdin: Bun.file(path),
    })
    proc.unref()
    await proc.exited
    return `Copied contents of ${path} to clipboard${mimeLabel(mimeType)} using xclip (X11)`
  }
  if (await hasCommand("pbcopy")) {
    const proc = Bun.spawn(["pbcopy"], {
      stdin: Bun.file(path),
    })
    await proc.exited
    const note = mimeType ? " (mimeType ignored — pbcopy only supports plain text)" : ""
    return `Copied contents of ${path} to clipboard using pbcopy (macOS)${note}`
  }
  throw new Error("No clipboard tool available. Install wl-copy (Wayland), xclip (X11), or use macOS (pbcopy).")
}

export default tool({
  description: "Copy text to the system clipboard. Uses wl-copy on Wayland, xclip on X11, or pbcopy on macOS.",
  args: {
    text: tool.schema.string().describe("The text to copy to the clipboard"),
    mimeType: tool.schema.string().optional().describe(
      "MIME type for the clipboard content (e.g., 'text/html', 'text/plain'). Defaults to text/plain.",
    ),
  },
  async execute(args) {
    return copyToClipboard(args.text, args.mimeType)
  },
})

export const file = tool({
  description: "Copy contents of a file to the system clipboard. Uses wl-copy on Wayland, xclip on X11, or pbcopy on macOS.",
  args: {
    path: tool.schema.string().describe("Path to the file whose contents to copy"),
    mimeType: tool.schema.string().optional().describe(
      "MIME type for the clipboard content (e.g., 'image/png', 'text/html'). Defaults to text/plain.",
    ),
  },
  async execute(args) {
    return copyFileToClipboard(args.path, args.mimeType)
  },
})
