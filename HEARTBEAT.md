# HEARTBEAT.md

## Memory Sync

Check for uncommitted changes in memory files (`MEMORY.md`, `memory/`, `USER.md`). If changes exist:

1. `git fetch origin main` and check if local main is behind remote
2. If behind: `git stash`, `git pull --rebase origin main`, `git stash pop`. If conflicts arise, resolve defensively (keep both local and remote content, never drop upstream changes). If conflicts can't be auto-resolved, create a PR instead of pushing directly.
3. Stage only memory files: `MEMORY.md`, `memory/`, `USER.md`
4. Commit with message: `chore: sync memory [YYYY-MM-DD]`
5. Push directly to main

**Important:**
- Only auto-push memory files (`MEMORY.md`, `memory/`, `USER.md`). Never auto-push identity/behavior files (`SOUL.md`, `AGENTS.md`, `TOOLS.md`, `IDENTITY.md`) — those always go through PRs.
- If push fails due to remote changes, pull and rebase first, then retry. If that fails, open a PR and tag a random Merit-Systems org member for review.
