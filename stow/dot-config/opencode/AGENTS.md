# Filesystem Paths

Your home directory is `~` — always use it as the base for any path under the
home directory. Never guess usernames or use broad paths like `/*`, `/home/*`,
or `/home/user/*`. If you need a path under home, use `~/...`.

Common locations:

- Projects: `~/workspace/`
- Config: `~/.config/`
- Local data/state: `~/.local/`
- Agent skills: `~/.agents/`
- Scratch/temp files: use the `scratch` tool (never write to `/tmp` directly)

# Workspace

All projects live under ~/workspace/. You have read access to all of them.

When working in any project, proactively look up related code in sibling projects when:
- You encounter imports, API calls, or references to another project
- You need to understand a shared interface, type, or contract
- You're making changes that could affect downstream consumers
- You need to check how something is used or implemented elsewhere
- A dependency change would lead to an overall simpler design — suggest it

Use `read`, `grep`, and `glob` with absolute paths (~/workspace/<project>/...)
to inspect sibling projects. Use `ls ~/workspace` to discover what's available.

Check per-project AGENTS.md files at ~/workspace/<project>/AGENTS.md for
project-specific context and dependency information when available.

## Git & GitHub

When working with git, always ask before pushing or opening a pull request —
never do either autonomously. When creating pull requests, **always** use the
`--draft` flag — never create a non-draft PR:

```bash
gh pr create --draft --title "..." --body "..."
```

### History Preservation

Avoid rewriting git history. Prefer creating new commits over amending,
rebasing, or squashing existing ones. Specifically:

- **Do not** use `git commit --amend`, `git rebase`, `git push --force`, or
  `git push --force-with-lease` unless the user explicitly requests it.
- **Do not** drop, reorder, or squash commits without explicit approval.
- If a commit needs to be corrected, create a new fixup or follow-up commit
  instead of amending.
- Never force-push to any branch without the user's explicit consent.

### Branching & Commits

When making non-trivial changes, proactively suggest creating a new branch
before starting work.

When creating a new branch, always start from an up-to-date default branch:

1. Fetch the latest changes from the remote
2. Determine the default branch (usually `main` or `master`)
3. Pull or reset to the latest remote default branch
4. Create the new branch from there

Do **not** branch from whatever commit happens to be checked out — always
ensure the branch starts from the current tip of the default branch.

Use the naming format `<prefix>/<description-in-kebab-case>`
where the prefix follows semantic commit conventions:

- `feat/` — new feature
- `enhance/` — improvement to existing functionality
- `fix/` — bug fix
- `refactor/` — code restructuring without behavior change
- `chore/` — maintenance, config, dependencies
- `docs/` — documentation only
- `test/` — adding or updating tests
- `ci/` — CI/CD changes

All commits must use semantic commit style (e.g., `feat: add user export`,
`fix: correct null check in parser`). Keep commits focused and atomic.

Push changes to the remote frequently — after each meaningful commit or
logical unit of work, rather than batching everything at the end. Always
ask before pushing.

## Temporary Files

**IMPORTANT:** Never write directly to `/tmp` or any path under it. A `scratch`
tool is available that creates a per-session scratch directory at
`/tmp/opencode-<sessionID>/`. You MUST call the `scratch` tool first to obtain
the directory path, then write files into that returned directory.

Use the scratch tool whenever you need to write temporary or intermediate files
such as test scripts, build artifacts, diffs, or draft outputs.

- **Always** call the `scratch` tool to get the path — do not construct `/tmp`
  paths yourself.
- **Never** write to `/tmp` directly, even if you "know" the path format.
- **Never** write throwaway or intermediate files into the project working
  directory.
- The scratch directory is ephemeral and tied to the current session.

## Web Fetching

The built-in `webfetch` tool does a plain HTTP GET and converts HTML to markdown.
It does NOT execute JavaScript. Many modern sites (SPAs, JS-rendered docs,
sites with bot walls) return empty shells or `<noscript>` fallbacks.

**When `webfetch` returns suspicious-looking content** (very short, mostly empty
`<div>` or `<body>`, "Please enable JavaScript", visible-in-browser content
missing), retry with the Playwright MCP tools instead:

1. `browser_navigate` with the URL
2. `browser_snapshot` to get the rendered accessibility tree as markdown

Keep using `webfetch` as the default for static and server-rendered pages —
it's cheaper. Only escalate to the browser when JS rendering is required.
Call `browser_close` when done to free resources.

### Browser Tool Selection

There are two browser toolsets available — use the right one:

| Tool | When to use |
|------|-------------|
| **Playwright MCP** (`mcp_Playwright_*`) | Default for all web browsing. Has its own headless browser. |
| **Chrome tools** (`mcp_Chrome`, `mcp_Chrome_stop`) | **Only** for Chrome DevTools debugging (inspecting network, console, DOM via CDP). |

**Do NOT** call `mcp_Chrome` before using Playwright — they are independent.
Playwright manages its own browser instance; calling `mcp_Chrome` first is
wasteful and confusing.

Use `mcp_Chrome` only when you need to:
- Connect to an existing Chrome instance for debugging
- Use Chrome DevTools Protocol features not available in Playwright
- Debug a user's running browser session
