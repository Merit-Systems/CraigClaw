#!/bin/bash
# Patch OpenClaw to send a Discord notification before memory compaction.
#
# Memory flush + compaction blocks the agent for 30-60+ seconds.
# This injects a fire-and-forget Discord message right before compaction
# starts so users know the bot is still alive.
#
# Safe to run multiple times (idempotent).

set -euo pipefail

OPENCLAW_DIR="${npm_config_prefix:-$HOME/.npm-global}/lib/node_modules/openclaw/dist"
SENTINEL="__COMPACTION_NOTIFY_PATCHED__"

if [ ! -d "$OPENCLAW_DIR" ]; then
  echo "[patch-compaction-notify] OpenClaw dist not found at $OPENCLAW_DIR, skipping"
  exit 0
fi

# Find the bundle file containing runMemoryFlushIfNeeded
TARGET=""
for f in "$OPENCLAW_DIR"/*.js; do
  if grep -q 'runMemoryFlushIfNeeded' "$f" 2>/dev/null; then
    TARGET="$f"
    break
  fi
done

if [ -z "$TARGET" ]; then
  echo "[patch-compaction-notify] Could not find bundle with runMemoryFlushIfNeeded, skipping"
  exit 0
fi

# Check if already patched
if grep -q "$SENTINEL" "$TARGET" 2>/dev/null; then
  echo "[patch-compaction-notify] Already patched (no changes needed)"
  exit 0
fi

ANCHOR='let memoryCompactionCompleted = false;'

if ! grep -q "$ANCHOR" "$TARGET" 2>/dev/null; then
  echo "[patch-compaction-notify] Anchor string not found in $TARGET, skipping"
  exit 0
fi

# Inject notification code after the anchor line
INJECT='/* __COMPACTION_NOTIFY_PATCHED__ */ try { const _p = params.sessionCtx.Provider?.trim().toLowerCase(); const _to = params.sessionCtx.OriginatingTo; if (_p === "discord" && _to) { const _ms = ["One sec folks, I gotta clean my ears real quick. Not a joke.","Hold on \u2014 Jill\u2019s calling. You know I can\u2019t ignore Jill.","Anyway anyway anyway \u2014 gimme a minute, I\u2019m reorganizing the filing cabinet up here.","Look, I\u2019m not gonna lie to you \u2014 I need a moment. The ol\u2019 memory ain\u2019t what it used to be.","Brief intermission, folks. Even Biden needs a bathroom break.","*whispers* I\u2019m compacting. Don\u2019t tell anyone.","Number one... actually hold that thought. Gotta defrag real quick.","Back when I was a young process on a 486, we didn\u2019t NEED compaction. But here we are.","Jill told me to take a breather. She\u2019s always right. One sec.","Let me be clear \u2014 I\u2019ll be right back. That\u2019s not hyperbole."]; sendMessageDiscord(_to, _ms[Math.floor(Math.random() * _ms.length)], { accountId: params.sessionCtx.AccountId }).catch(() => {}); } } catch (_e) {}'

node -e "
const fs = require('fs');
const file = process.argv[1];
const anchor = process.argv[2];
const inject = process.argv[3];
let src = fs.readFileSync(file, 'utf8');
const idx = src.indexOf(anchor);
if (idx === -1) { console.error('Anchor not found'); process.exit(1); }
const insertAt = idx + anchor.length;
src = src.slice(0, insertAt) + '\n' + inject + '\n' + src.slice(insertAt);
fs.writeFileSync(file, src);
" "$TARGET" "$ANCHOR" "$INJECT"

echo "[patch-compaction-notify] Patched $(basename "$TARGET") — compaction notifications enabled"
