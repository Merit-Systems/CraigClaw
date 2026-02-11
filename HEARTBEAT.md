# Heartbeat Checks

Run these checks silently. **Only send a Discord message if a threshold is breached.** If everything is fine, reply with HEARTBEAT_OK and nothing else. Do not be chatty. Do not report "all clear." Silence is success.

## 1. Memory Sync

Check for uncommitted changes in memory files (`MEMORY.md`, `memory/`, `USER.md`). If changes exist:

1. `git fetch origin main` and check if local main is behind remote
2. If behind: `git stash`, `git pull --rebase origin main`, `git stash pop`. If conflicts arise, resolve defensively (keep both local and remote content, never drop upstream changes). If conflicts can't be auto-resolved, create a PR instead of pushing directly.
3. Stage only memory files: `MEMORY.md`, `memory/`, `USER.md`
4. Commit with message: `chore: sync memory [YYYY-MM-DD]`
5. Push directly to main

**Important:**
- Only auto-push memory files (`MEMORY.md`, `memory/`, `USER.md`). Never auto-push identity/behavior files (`SOUL.md`, `AGENTS.md`, `TOOLS.md`, `IDENTITY.md`) -- those always go through PRs.
- If push fails due to remote changes, pull and rebase first, then retry. If that fails, open a PR and tag a random Merit-Systems org member for review.

## 2. Disk Usage

Run `df -h /` and check the Use% column.
- **Alert threshold**: > 70%
- If breached, send a short message: what the usage is and what's consuming space (`du -sh` on large dirs).

## 3. RAM Usage

Run `free -m` and calculate used memory as a percentage of total.
- **Alert threshold**: > 75%
- If breached, send a short message: what the usage is and what processes are consuming the most (`ps aux --sort=-%mem | head -5`).

## Rules

- If NO thresholds are breached and no memory to sync: reply HEARTBEAT_OK. That's it. No message to Discord.
- If a threshold IS breached: send a concise alert to Discord. One or two sentences max. Include the number.
- Never send "everything looks good" messages. The team does not want noise.
- Memory sync is silent -- just commit and push, no Discord message needed.
