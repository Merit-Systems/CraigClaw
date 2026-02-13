# OpenClaw Bundle Patches

We patch the npm-installed OpenClaw bundle directly (not the source) to fix issues
and add features that upstream doesn't support yet. Each patch is an idempotent
bash script in `deploy/` that runs automatically during deploys via
`.github/workflows/deploy.yml`.

## deploy/patch-openclaw.sh — Disable billing error false positives

**Problem:** OpenClaw's `isBillingErrorMessage()` matches patterns like `/\b402\b/`,
"payment required", "credit balance", etc. in ALL outbound text. Because Craig uses
x402 MCP tools that return real HTTP 402 responses and payment-related text, this
triggers false "billing error" warnings constantly.

**Fix:** Makes `isBillingErrorMessage()` return `false` unconditionally. Actual
Anthropic API billing errors still surface as raw error text — they just don't get
the misleading rewrite.

**Target:** `$OPENCLAW_DIR/dist/pi-embedded-helpers-*.js`

**Sentinel:** `function isBillingErrorMessage(raw) { return false;` (checks for
already-applied patch via grep)

## deploy/patch-compaction-notify.sh — Discord notification before memory compaction

**Problem:** OpenClaw's memory flush + compaction cycle blocks the agent for 30-60+
seconds. During this time, Discord users see no response and may think the bot crashed.

**Fix:** Injects a fire-and-forget `sendMessageDiscord()` call right before compaction
starts. Picks a random Biden-flavored message from a 10-item pool so users know Craig
is still alive.

**Target:** The bundle file containing `runMemoryFlushIfNeeded` (e.g.
`$OPENCLAW_DIR/dist/reply-DptDUVRg.js`)

**Anchor:** `let memoryCompactionCompleted = false;` — code is injected immediately
after this line.

**Sentinel:** `__COMPACTION_NOTIFY_PATCHED__` comment in the injected code.

**Key design decisions:**
- Fire-and-forget: no `await`, promise has `.catch(() => {})` — never blocks compaction
- Outer `try/catch` swallows any synchronous errors
- Only fires when `Provider === "discord"` and `OriginatingTo` is truthy
- `sendMessageDiscord` is already in scope in the same bundle file

## Adding a new patch

1. Create `deploy/patch-<name>.sh` following the existing pattern:
   - `set -euo pipefail`
   - Locate the target file by searching for a known function/string
   - Check a sentinel to ensure idempotency
   - Apply the patch (prefer `node -e` for complex transforms, `sed -i` for simple ones)
   - Print a status message
2. Add `bash deploy/patch-<name>.sh` to `.github/workflows/deploy.yml` before the
   `systemctl --user restart openclaw-gateway` line
3. Document it in this file
