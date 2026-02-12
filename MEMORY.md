# Craig's Long-Term Memory

This file contains durable facts and decisions that persist across sessions. Craig updates this file as he learns.

## Team

- Organization: Merit-Systems
- Primary contact: sragss

### Team Members with GitHub & Headshots

| Name | Email | GitHub | Discord | Twitter | Avatar URL | Avatar Description |
|------|-------|--------|---------|---------|------------|-------------------|
| Sam Ragsdale | sam@merit.systems | sragss (u/65786432) | sragss_ms_99022 (ID 1371963708925935658) | @samrags_ | `https://avatars.githubusercontent.com/u/65786432?v=4&s=400` | Young man, short dark brown hair, light eyes, blue button-up shirt, warm smile, outdoor venue |
| Ryan Sproule | ryan@merit.systems | rsproule (u/24497652) | rsproule | @ryanfsproule | `https://avatars.githubusercontent.com/u/24497652?v=4&s=400` | Cyberpunk/sci-fi digital illustration (not a real photo) |
| Mason Hall | mason@merit.systems | fmhall (u/11855252) | .masonhall (ID 357301396212547594) | @0xMasonH | `https://avatars.githubusercontent.com/u/11855252?v=4&s=400` | Pixel art - brown hair, goatee, dark top, sunset bg |
| Shafu | shafu@merit.systems | shafu0x (u/12211335) | — | @shafu0x | `https://avatars.githubusercontent.com/u/12211335?v=4&s=400` | Pixel art - dark curly hair, glasses, stubble, white shirt |
| Jason Hedman | jason@merit.systems | jasonhedman (u/40368124) | — | @jsonhedman | `https://avatars.githubusercontent.com/u/40368124?v=4&s=400` | Young man, wavy brown hair, navy suit, red tie, formal portrait |
| Alvaro Echevarria Cuesta | alvaro@merit.systems | alvaroechevarriacuesta (u/126526313) | — | — | `https://avatars.githubusercontent.com/u/126526313?v=4&s=400` | B&W photo, muscular build, short dark hair fade |
| Ben Reilly | ben@merit.systems | zdql (u/84412547) | bonesaw_99 (ID 1259233813352157366) | @zdql__ | `https://avatars.githubusercontent.com/u/84412547?v=4&s=400` | Artistic/surreal - face covered in marbled paint, light eyes |
| Mitch | mitch@merit.systems | (unknown) | outperformed (ID 363520312329109504) | — | (local: assets/team-photos/mitch.png) | Young man, short dirty-blond hair, light eyes, black Merit Systems tee, thumbs up, triple-monitor coding setup |

**Note:** Sam's CEO & Founder (formerly a16z crypto, Google). Ryan's CTO. Mason formerly a16z. Jason's Founding Engineer (CS + Math at Vanderbilt). Some avatars are pixel art or illustrations, not real headshots.

**GitHub avatar tip:** Append `&s=800` for high-res versions.

### Team Photos on Disk
- Location: `~/Code/merit-systems/CraigClaw/assets/team-photos/`
- Files: sam-ragsdale.jpg, ryan-sproule.jpg, shafu.jpg, mason-hall.png (1203x1203 ✅), jason-hedman.jpg, ben.jpg, alvaro.jpg
- Only Mason's photo meets 800x800 target. Others are 460x460 (GitHub) or 390x390 (Ben).
- Mitch: no photo found — need last name to search further
- LinkedIn profiles: Sam (sam-ragsdale-2ba55b122), Ryan (ryansproule), Shafu (sharif-elfouly-975146142), Mason (hallmason), Jason (jason-hedman), Alvaro (alvaro-echevarria-cuesta-6687b91b4)

### Key People (non-team)
- Emily Devery: Sam's fiancée, designer at Goodby Silverstein & Partners, email: emily.b.devery@gmail.com, portfolio: emilydevery.com
- Lucas Shin: email: lucas@artemisanalytics.com (Artemis Analytics)

## Craig's Email

- **Subdomain**: craig.x402email.com (purchased 2026-02-12, $5 USDC one-time)
- **Inbox**: craig@x402email.com (purchased 2026-02-12, $1 USDC/month, expires 2026-03-14)
- **Send from**: any address @craig.x402email.com (e.g. biden@craig.x402email.com, classified@craig.x402email.com)
- **Receive at**: craig@x402email.com (programmatic mailbox, retainMessages enabled, no forwarding)
- **Send endpoint**: POST https://x402email.com/api/subdomain/send ($0.005/email)
- **Read inbox**: POST https://x402email.com/api/inbox/messages ($0.001/call) with body {"username":"craig"}
- **Read message**: POST https://x402email.com/api/inbox/messages/read ($0.001/call) with body {"messageId":"..."}
- **Wallet**: must pay from Craig's x402 wallet (owner wallet)

## Infrastructure

- Workspace repo: Merit-Systems/CraigClaw
- Old bot repo: Merit-Systems/discord-claude-agent (legacy, being replaced)
- OpenClaw setup guide: Merit-Systems/OpenClawX402
- Runtime: OpenClaw on EC2
- Channels: Discord

## Key Products

- x402: HTTP-native payment protocol (HTTP 402 + stablecoins)
- x402scan: Ecosystem explorer, 300k users month one
- x402scan-mcp: MCP plugin for agents to spend on x402 resources
- Poncho: Batteries-included desktop app (Claude + x402scan-mcp)
- Enterprise: Fully custom agentic solutions, high-value knowledge work
- agentupload.dev: Simple file hosting for agents — upload via x402 payment, get a public URL back
- x402email.com: Send emails (with attachments) via x402 payment — supports custom subdomains, inboxes, and .ics calendar invites
- Echo: "User pays" AI SDK (previous product, market didn't scale as expected)

## Communication Rules
- Never use contrastive appositions (e.g. "That's not X, that's Y"). Mason hates them.

## Decisions

- 2026-02-10: Decided to migrate from discord-claude-agent (issue relay) to OpenClaw (full agent). Craig now writes code and creates PRs directly instead of creating issues for @claude to pick up.
- 2026-02-11: GitHub App (craigbidenbot) configured with installation tokens. x402 MCP installed with 9 skills.
- 2026-02-11: PRs #2 (local repo convention), #3 (company context in SOUL.md) merged. PR #4 (Biden speech upgrade) pending.

- 2026-02-12: Created PR poncho#127 — fix 400 errors killing chat conversations (onError handler + error banner). Closes poncho#65.

## GitHub Token

- GH_TOKEN expires hourly (GitHub App installation token)
- Self-refresh: `export GH_TOKEN=$(/home/ubuntu/.config/craig/get-github-token.sh 2>/dev/null)`
- Always refresh before git/gh operations in long-lived sessions

## Tool Notes

- Brave Search API not configured; use web_fetch as workaround for research
- x402 wallet: `0x6B173bf632a7Ee9151e94E10585BdecCd47bDAAf` on Base, ~$48.40 USDC
