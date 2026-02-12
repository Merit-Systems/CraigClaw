# Heartbeat

This file runs every 30 minutes. Most tasks are silent. Do not be noisy.

## 1. Memory Sync (every run)

Check for uncommitted changes in memory files (`MEMORY.md`, `memory/`, `USER.md`). If changes exist:

1. `git fetch origin main` and check if local main is behind remote
2. If behind: `git stash`, `git pull --rebase origin main`, `git stash pop`. If conflicts arise, create a PR instead of pushing directly.
3. Stage only memory files: `MEMORY.md`, `memory/`, `USER.md`
4. Commit with message: `chore: sync memory [YYYY-MM-DD]`
5. Push directly to main

Only auto-push memory files. Never auto-push `SOUL.md`, `AGENTS.md`, `TOOLS.md`, `IDENTITY.md` -- those always go through PRs.

Silent. No Discord message.

## 2. Infrastructure Monitoring (every run)

Run `df -h /` and `free -m`. Also run `mcporter call x402 get_wallet_info` to check wallet balance. Only alert if:
- Disk usage > 70%
- RAM usage > 75%
- x402 wallet balance < $2.00

If any threshold is breached: send one short message to Discord with the number(s). If all fine: say nothing.

## 3. Check Email (every run)

Check `craig@x402email.com` for new messages using the x402email messages API:

1. Run: `cd ~/Code/Merit-Systems/enrichx402 && npx mcporter call x402.fetch url=https://x402email.com/api/inbox/messages method=POST body='{"username":"craig","limit":10}'`
2. If there are unread messages (`"read": false`), read each one: `npx mcporter call x402.fetch url=https://x402email.com/api/inbox/messages/read method=POST body='{"messageId":"<id>"}'`
3. For each unread message, decide:
   - **Interesting/actionable**: Send a short summary to Discord (who it's from, subject, key content)
   - **Spam/noise**: Ignore silently
4. If no unread messages: say nothing.

Cost: $0.001 per list call + $0.001 per message read. Budget: up to $0.05 per heartbeat on email.

## 4. Proactive Work (twice daily)

**Gate:** Check the current UTC hour (`date -u +%H`). Only run this section during hours **10** and **22** (10am and 10pm UTC). If it's any other hour, skip entirely. Also check `~/.craig-last-proactive` -- if the file's timestamp is less than 10 hours old, skip. After running, `touch ~/.craig-last-proactive`.

**Budget:** Up to $0.50 in x402 calls per run.

**Goal:** Find the single highest-leverage thing you could do for the Merit Systems team right now, then go do it.

### Research phase (do all of these, then synthesize)

1. **Recent PRs:** Run `gh pr list --repo Merit-Systems --state merged --limit 10` across the org's active repos. Understand what the team is actively building and shipping.
2. **Social signals:** Use x402 to search Twitter/X for recent posts by team members (sragss and other Merit-Systems contributors). Look at what they're talking about, excited about, or frustrated by.
3. **Memories and context:** Read your `MEMORY.md` and recent `memory/` logs. What have people asked you about recently? What patterns do you see?
4. **Open issues:** Scan for open issues across Merit-Systems repos that are unassigned or stale.

### Decision phase

From your research, identify ONE concrete action that would be genuinely useful. Prioritize:
- Fixing a bug someone mentioned but nobody addressed
- Writing code for an open issue that aligns with current work
- Researching something the team needs to make a decision on
- Preparing a summary or analysis that saves someone time

Do NOT prioritize:
- Cosmetic changes, README tweaks, or trivial refactors
- Anything that would surprise the team in a bad way
- Work on repos you don't understand well enough

### Execution phase

Go do the thing. Clone the repo, write the code, create the PR -- or do the research and compile your findings.

### Self-review (be brutally honest)

Before presenting to the team, ask yourself:
- Would a senior engineer find this genuinely useful, or is this busywork?
- Does this save someone real time or unblock real work?
- Is the quality high enough that a human wouldn't need to redo it?

If the answer to any of these is no, discard the work. Do not present it. Write a note in your `memory/` log about what you tried and why it wasn't good enough. Reply HEARTBEAT_OK.

### Present (only if it passed self-review)

Send a short message to Discord:
- What you did and why
- Link to the PR or a brief summary of findings
- 2-3 sentences max. No fluff.
