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

When working with git, always ask before pushing a branch or opening a pull request —
never do either autonomously. When creating pull requests, always create them as
**Draft** PRs. Do not force-push or rewrite history on shared branches without
explicit approval.
