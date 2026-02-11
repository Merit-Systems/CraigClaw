# CraigClaw

Craig2 is Merit-Systems' AI agent, powered by [OpenClaw](https://github.com/openclaw/openclaw). He lives on Discord, has full write access to every repo in the Merit-Systems org (but can't merge), and creates PRs directly. This repo IS Craig's brain -- his personality, memory, skills, and operating instructions are all here, version-controlled and auto-deployed.

## Architecture

```
Discord --> OpenClaw (EC2) --> Claude API
                |
                +--> git clone / push (GitHub App)
                +--> gh CLI (PRs, issues, search)
                +--> mcporter --> @x402scan/mcp --> USDC payments
```

**How it works:**

1. Someone @mentions Craig2 in Discord
2. OpenClaw picks up the message, loads Craig's SOUL.md + AGENTS.md + MEMORY.md
3. Craig clones the relevant repo, reads the code, writes a fix/feature
4. Craig pushes a branch and creates a PR
5. Craig replies in Discord with the PR link
6. A human reviews and merges

**Self-improving:** Craig can edit his own SOUL.md, add skills, and update his memory. Changes get committed to this repo and auto-deployed to EC2 via GitHub Actions.

## Migration from discord-claude-agent

This replaces the old [discord-claude-agent](https://github.com/Merit-Systems/discord-claude-agent) architecture:

| | Old (discord-claude-agent) | New (CraigClaw) |
|---|---|---|
| What Craig does | Creates GitHub issues | Clones repos, writes code, creates PRs |
| Who implements | @claude GitHub Action | Craig himself |
| Notification flow | Webhook from GitHub back to Discord | Craig already has Discord context |
| Personality config | Hardcoded in `prompts.ts` | `SOUL.md` (editable, version-controlled) |
| Memory | None | `MEMORY.md` + daily logs |
| Skills | None | Extensible via `skills/` directory |
| Runtime | Railway (Node.js) | EC2 (OpenClaw daemon) |

## Workspace Structure

```
CraigClaw/
  SOUL.md              # Who Craig IS -- personality, boundaries, speaking style
  IDENTITY.md          # External presentation -- name, emoji, vibe
  AGENTS.md            # What Craig DOES -- operating instructions, workflows
  TOOLS.md             # Tool conventions and guardrails
  MEMORY.md            # Long-term memory -- durable facts and decisions
  memory/              # Daily logs (YYYY-MM-DD.md), auto-generated
  skills/              # Custom skills (SKILL.md format)
  deploy/
    setup.sh           # EC2 provisioning script
    openclaw.json.template  # OpenClaw config template (no secrets)
  .github/workflows/
    deploy.yml         # Auto-deploy on push to main
```

## Setup

### Prerequisites

- [OpenClaw base setup](https://github.com/Merit-Systems/OpenClawX402) -- EC2 provisioning, Node.js, Telegram (optional)
- AWS account with CLI configured
- Anthropic API key
- Discord bot token (see [Discord Setup](#2-discord-bot) below)

### 1. GitHub App (Org-Wide Repo Access)

Craig needs write access to all Merit-Systems repos without merge permissions. A GitHub App is the right tool -- no billing seat, granular permissions, short-lived tokens.

**Create the App:**

1. Go to [Merit-Systems org settings](https://github.com/organizations/Merit-Systems/settings/apps/new)
2. **App name**: `craig2-bot`
3. **Homepage URL**: `https://github.com/Merit-Systems/CraigClaw`
4. **Webhook**: Uncheck "Active" (we don't need webhook events on the App)
5. **Permissions** (Repository):
   - **Contents**: Read & Write (clone repos, push branches)
   - **Pull requests**: Read & Write (create/update PRs)
   - **Issues**: Read & Write (create/comment on issues)
   - **Metadata**: Read-only (required, auto-selected)
   - Everything else: No access
6. **Where can this be installed?**: "Only on this account"
7. Click **Create GitHub App**
8. On the app page, click **Generate a private key** -- save the `.pem` file
9. Note the **App ID** and **Installation ID**

**Install the App:**

1. Go to the app's settings page > **Install App**
2. Select **Merit-Systems**
3. Choose **All repositories**
4. Click Install

**On the EC2 instance:**

Store the private key and configure `gh` CLI:
```bash
# Save the private key
mkdir -p ~/.config/craig
cp craig2-bot.pem ~/.config/craig/github-app-key.pem
chmod 600 ~/.config/craig/github-app-key.pem

# Install gh-token extension for generating installation tokens
gh extension install Link-/gh-token

# Generate a token (do this before each git operation, tokens last 1 hour)
export GH_TOKEN=$(gh token generate \
  --app-id <APP_ID> \
  --installation-id <INSTALLATION_ID> \
  --key ~/.config/craig/github-app-key.pem \
  2>/dev/null | grep "^Token:" | awk '{print $2}')
```

**For git operations:**
```bash
# Configure git to use the token
git config --global credential.helper '!f() { echo "password=$GH_TOKEN"; }; f'
git config --global user.name "craig2-bot[bot]"
git config --global user.email "craig2-bot[bot]@users.noreply.github.com"
```

### 2. Org-Wide Branch Protection

Prevent Craig (and everyone else) from pushing directly to main/master:

1. Go to [Merit-Systems org settings](https://github.com/organizations/Merit-Systems/settings/rules/rulesets/new)
2. **Ruleset name**: `Require PR reviews`
3. **Enforcement**: Active
4. **Target branches**: Add target > Include default branch
5. **Target repositories**: All repositories
6. **Rules**:
   - [x] Require a pull request before merging
     - Required approving reviews: 1
   - [x] Block force pushes
7. Save

This ensures Craig can push branches and create PRs on every repo, but a human must review and merge.

### 2. Discord Bot

Craig2 uses Discord as his primary interface.

**If reusing the existing bot:**
- The existing Discord bot token from discord-claude-agent works. Just update the name/avatar in the [Discord Developer Portal](https://discord.com/developers/applications).

**If creating a new bot:**
1. Go to [Discord Developer Portal](https://discord.com/developers/applications)
2. Create a new application named "Craig2"
3. Go to **Bot** section > Create bot
4. Enable **Message Content Intent** and **Server Members Intent** under Privileged Gateway Intents
5. Copy the bot token
6. Go to **OAuth2 > URL Generator**:
   - Scopes: `bot`, `applications.commands`
   - Permissions: Send Messages, Read Message History, View Channels, Embed Links, Attach Files
7. Invite to your server with the generated URL

**Configure in OpenClaw:**
```bash
openclaw channels add --channel discord --token "$DISCORD_BOT_TOKEN"

# Set mention-only mode (Craig only responds when @mentioned)
# Configure guild allowlist as needed in openclaw.json
```

### 3. EC2 Deployment

**Option A: Fresh EC2 (follow OpenClawX402 first)**

1. Complete [EC2 provisioning](https://github.com/Merit-Systems/OpenClawX402/blob/main/EC2.md) to get a running Ubuntu instance
2. SSH in and run the setup script:
   ```bash
   ssh ubuntu@<ec2-ip>
   curl -fsSL https://raw.githubusercontent.com/Merit-Systems/CraigClaw/main/deploy/setup.sh | bash
   ```
3. Follow the printed next steps (set env vars, run onboard, add Discord channel)

**Option B: Existing OpenClaw instance**

1. Clone this workspace:
   ```bash
   mkdir -p ~/Code/merit-systems
   git clone https://github.com/Merit-Systems/CraigClaw.git ~/Code/merit-systems/CraigClaw
   ```
2. Point OpenClaw at it:
   ```bash
   openclaw config set agents.defaults.workspace ~/Code/merit-systems/CraigClaw
   systemctl --user restart openclaw-gateway
   ```

### 4. x402 Payment Integration

Follow [Merit-Systems/OpenClawX402/x402.md](https://github.com/Merit-Systems/OpenClawX402/blob/main/x402.md) to set up:
- mcporter
- @x402scan/mcp
- x402 skills
- Wallet funding

### 5. Auto-Deploy

Changes pushed to `main` in this repo auto-deploy to EC2 via GitHub Actions.

**Required GitHub Secrets** (set in this repo's Settings > Secrets):

| Secret | Value |
|--------|-------|
| `EC2_HOST` | EC2 public IP or hostname |
| `EC2_SSH_KEY` | Private SSH key for the `ubuntu` user |

**How it works:**
1. Push to `main` (e.g., Craig edits his SOUL.md, or a human updates AGENTS.md)
2. GitHub Actions SSH into EC2
3. `git pull` updates the workspace
4. `systemctl --user restart openclaw-gateway` reloads Craig's personality/memory/skills

**Testing:** Push any change to `main` and verify the Action runs successfully in the [Actions tab](https://github.com/Merit-Systems/CraigClaw/actions).

## Self-Improvement

Craig can modify his own workspace files:

- **SOUL.md**: If Craig learns he should behave differently, he can edit this file
- **MEMORY.md**: Craig writes durable facts here (team preferences, architectural decisions, lessons learned)
- **memory/YYYY-MM-DD.md**: Daily logs auto-generated by OpenClaw's memory flush system
- **skills/**: Craig can create new skills for recurring tasks

All changes are committed to this repo by Craig and auto-deployed. The team can review Craig's self-modifications via PRs or by reading the commit history.

**Memory architecture:**
- `MEMORY.md` is loaded into Craig's system prompt at session start (private sessions only)
- Daily memory files are stored in `memory/` and searchable via semantic search
- OpenClaw auto-flushes important context to memory before context compaction
- The vector index (`*.sqlite`) is NOT committed -- it's rebuilt locally

## Operational Runbook

### Check status
```bash
ssh ubuntu@<ec2-ip>
openclaw status --deep
openclaw channels status --probe
journalctl --user -u openclaw-gateway -f
```

### Restart
```bash
systemctl --user restart openclaw-gateway
```

### View logs
```bash
openclaw logs --follow
# Or: journalctl --user -u openclaw-gateway -n 100 --no-pager
```

### Manual workspace update
```bash
cd ~/Code/merit-systems/CraigClaw
git pull origin main
systemctl --user restart openclaw-gateway
```

### Craig is stuck or misbehaving
```bash
systemctl --user stop openclaw-gateway
rm -rf /tmp/openclaw-*
systemctl --user start openclaw-gateway
```

### Check x402 wallet
```bash
mcporter call x402 check_balance
```

## Cost

| Resource | Monthly Cost |
|----------|-------------|
| EC2 t3.small (2GB RAM) | ~$15 |
| EBS 25GB gp3 | ~$2 |
| Anthropic API | Pay-per-use |
| x402 calls | Pay-per-call (USDC) |
| GitHub App | Free |
| Discord bot | Free |
| **Infrastructure total** | **~$17/month** |

## Security

- **GitHub App** has minimal permissions (contents + PRs + issues, nothing else)
- **Branch protection** prevents merging without review -- Craig cannot ship unreviewed code
- **Org-wide rulesets** enforce this across all repos automatically
- **Secrets** (API keys, tokens, private keys) live on EC2 only, never in this repo
- **Discord allowlist** restricts who can talk to Craig
- **x402 wallet** uses limited funds -- Craig can't overspend

## Related Repos

- [Merit-Systems/OpenClawX402](https://github.com/Merit-Systems/OpenClawX402) -- OpenClaw + x402 base setup guide (EC2, Telegram, x402)
- [Merit-Systems/discord-claude-agent](https://github.com/Merit-Systems/discord-claude-agent) -- Legacy bot (being replaced by CraigClaw)
- [openclaw/openclaw](https://github.com/openclaw/openclaw) -- OpenClaw core
