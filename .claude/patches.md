# OpenClaw Fork Patches

We maintain a fork at Merit-Systems/openclaw with source-level patches on top
of upstream openclaw/openclaw. The fork is kept close to upstream — patches are
minimal and documented here.

## Current fork patches (on top of upstream 2026.3.7)

### feat(discord): auto-resolve guild emoji names (PR #3)

**Problem:** When the agent reacts with a plain custom emoji name like `fatbiden`,
Discord requires the `name:id` format. Without resolution, custom emoji reactions
fail silently.

**Fix:** New `src/discord/guild-emoji-cache.ts` resolves plain emoji names by
looking up guild emojis via the Discord API. Cache TTL is 5 minutes per guild.
Integrated in `reactMessageDiscord()` before `normalizeReactionEmoji()`.

### feat: send Discord notification before memory compaction (PR #4)

**Problem:** Memory flush + compaction blocks the agent for 30-60+ seconds.
Discord users see no response and may think the bot crashed.

**Fix:** Fire-and-forget `sendMessageDiscord()` call in `agent-runner-memory.ts`
right before compaction starts. Picks a random Biden-flavored message from a
10-item pool. Only fires for Discord sessions. Never blocks compaction.

## Dropped patches (fixed upstream as of 2026.3.7)

- **Billing error false positive** — upstream removed `shouldRewriteBillingText`
  from `sanitizeUserFacingText` (commit `5e423b596`)
- **currentMessageId for react/reactions** — upstream extracted shared
  `resolveReactionMessageId()` used by all channels (commit `d9fdec12a` + handler)
- **Discord media send timeouts** — upstream hardened media timeouts
- **String(undefined) coercion** — was already an upstream commit

## Bumping upstream

To sync with a newer upstream version:

1. `cd Merit-Systems/openclaw && git fetch upstream`
2. `git reset --hard upstream/main && git push origin main --force-with-lease`
3. Re-apply patches as PRs (check if they're still needed first)
4. Update `deploy/openclaw-pin` in CraigClaw to new fork HEAD
