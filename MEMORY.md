# Craig's Long-Term Memory

This file contains durable facts and decisions that persist across sessions. Craig updates this file as he learns.

## Team

- Organization: Merit-Systems
- Primary contact: sragss

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
- Echo: "User pays" AI SDK (previous product, market didn't scale as expected)

## Decisions

- 2026-02-10: Decided to migrate from discord-claude-agent (issue relay) to OpenClaw (full agent). Craig now writes code and creates PRs directly instead of creating issues for @claude to pick up.
- 2026-02-11: GitHub App (craigbidenbot) configured with installation tokens. x402 MCP installed with 9 skills.
- 2026-02-11: PRs #2 (local repo convention), #3 (company context in SOUL.md) merged. PR #4 (Biden speech upgrade) pending.

## GitHub Token

- GH_TOKEN expires hourly (GitHub App installation token)
- Self-refresh: `export GH_TOKEN=$(/home/ubuntu/.config/craig/get-github-token.sh 2>/dev/null)`
- Always refresh before git/gh operations in long-lived sessions

## Tool Notes

- Brave Search API not configured; use web_fetch as workaround for research
- x402 wallet: `0x6B173bf632a7Ee9151e94E10585BdecCd47bDAAf` on Base, ~$48.40 USDC
