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
before starting work. Use the naming format `<prefix>/<description-in-kebab-case>`
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
