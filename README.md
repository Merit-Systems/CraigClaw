# CraigClaw

Craig2 is Merit-Systems' AI agent, powered by [OpenClaw](https://github.com/openclaw/openclaw). He lives on Discord, has write access to every repo in the Merit-Systems org (but can't merge), and creates PRs directly. This repo IS Craig's brain -- his personality, memory, skills, and operating instructions are all here, version-controlled and auto-deployed.

## How the Workspace-as-Repo Sync Works

**This is not default OpenClaw behavior.** By default, OpenClaw loads workspace files (SOUL.md, AGENTS.md, etc.) from a local directory and that's it. We added a version-controlled sync layer on top:

```
┌─────────────────────────────────────────────────────────┐
│                    GitHub (source of truth)              │
│              Merit-Systems/CraigClaw repo                │
│   SOUL.md, AGENTS.md, MEMORY.md, skills/, etc.          │
└──────────┬──────────────────────────────┬───────────────┘
           │                              │
     push to main                   push branch + PR
     (human or merge)               (Craig self-edit)
           │                              │
           ▼                              │
┌─────────────────────┐                   │
│  GitHub Actions      │                   │
│  deploy.yml          │                   │
│  SSH → git pull →    │                   │
│  restart gateway     │                   │
└──────────┬──────────┘                   │
           │                              │
           ▼                              │
┌─────────────────────────────────────────┴───────────────┐
│              Hetzner Cloud (178.156.251.179)                │
│    ~/Code/merit-systems/CraigClaw/  ← git clone         │
│                                                         │
│    OpenClaw daemon reads workspace files at session      │
│    start and loads them into Craig's system prompt.      │
│    Craig can also edit these files and push changes.     │
└─────────────────────────────────────────────────────────┘
```

**Two sync directions:**

1. **Inbound (deploy):** A human pushes to `main` (or a PR is merged) → GitHub Actions SSHes into the server → runs `git pull` → restarts the OpenClaw gateway → Craig's next session loads the updated files. This is how humans edit Craig's brain.

2. **Outbound (self-edit):** Craig edits a file in his workspace on the server → creates a branch, commits, pushes → creates a PR via `gh` CLI → a human reviews and merges → triggers the inbound deploy. This is how Craig edits his own brain.

The key insight: OpenClaw's workspace directory is just a git clone of this repo. By keeping them in sync via GitHub Actions, every change (whether from Craig or a human) is version-controlled, reviewable, and auto-deployed.

## Architecture

```
Discord message (@Craig2)
       |
       v
OpenClaw daemon (Hetzner Cloud 178.156.251.179)
       |
       +--> Loads SOUL.md, AGENTS.md, TOOLS.md, MEMORY.md, IDENTITY.md
       |    (these define Craig's personality and behavior)
       |
       +--> Claude Opus 4.6 (Anthropic API)
       |
       +--> git clone / push (GitHub App: craigbidenbot)
       +--> gh CLI (PRs, issues, search)
       +--> mcporter --> @x402scan/mcp --> USDC payments (Base)
```

**How it works:**

1. Someone @mentions Craig2 in Discord
2. OpenClaw picks up the message, loads Craig's workspace files into the system prompt
3. Craig clones the relevant repo, reads the code, writes a fix/feature
4. Craig pushes a branch and creates a PR (never pushes to main directly)
5. Craig replies in Discord with the PR link
6. A human reviews and merges

## Self-Improvement

Craig can modify his own brain. This is the key feature of the workspace-as-repo architecture.

**How it works:**

1. Craig decides to change something about himself (e.g., learns a new team preference, wants to adjust his workflow)
2. Craig edits the relevant file in this repo (SOUL.md, MEMORY.md, AGENTS.md, etc.)
3. Craig creates a branch (`craig/<description>`), commits, pushes, and opens a PR
4. A human reviews and merges the PR
5. GitHub Actions auto-deploys: SSHes into the server, runs `git pull`, restarts the gateway
6. Craig's next session loads the updated files -- he's now different

**What Craig can change about himself:**

| File | What it controls | Example self-edit |
|------|-----------------|-------------------|
| `SOUL.md` | Personality, speaking style, boundaries | "Be less verbose in Discord" |
| `AGENTS.md` | How he does work -- git workflow, PR format | "Add a changelog step to my PR process" |
| `TOOLS.md` | Tool conventions and guardrails | "Always run lint before committing" |
| `MEMORY.md` | Durable facts -- team preferences, decisions | "The team uses pnpm, not npm" |
| `skills/` | Custom reusable capabilities | Create a new slash command |

**What Craig cannot do:**

- Push directly to main (branch protection enforces this)
- Merge his own PRs (requires 1 human review)
- Ship unreviewed self-modifications

This means the team always has oversight over Craig's evolution. You can review his self-edits in the PR history, revert bad changes, or edit his files directly.

## Workspace Structure

```
CraigClaw/
  SOUL.md              # WHO Craig is -- personality, boundaries, speaking style
  IDENTITY.md          # External presentation -- name, emoji, vibe
  AGENTS.md            # WHAT Craig does -- operating instructions, git workflow, PR format
  TOOLS.md             # Tool conventions and guardrails
  MEMORY.md            # Long-term memory -- durable facts and decisions
  USER.md              # What Craig knows about his humans (auto-generated by OpenClaw)
  HEARTBEAT.md         # Periodic tasks (auto-generated by OpenClaw)
  memory/              # Daily logs (YYYY-MM-DD.md), auto-generated by memory flush
  skills/              # Custom skills (SKILL.md format)
  deploy/
    setup.sh           # Server provisioning script
    openclaw.json.template  # OpenClaw config template (no secrets)
  .github/workflows/
    deploy.yml         # Auto-deploy on push to main
```

**Which files Craig sees at session start:**

OpenClaw loads `SOUL.md`, `IDENTITY.md`, `AGENTS.md`, `TOOLS.md`, `MEMORY.md`, `USER.md`, and `HEARTBEAT.md` into Craig's system prompt at the beginning of every session. The `memory/` directory is searchable but not loaded by default. Skills in `skills/` are loaded as available commands.

**Memory architecture:**

- `MEMORY.md` -- loaded every session. Contains durable facts (team info, architectural decisions, learned preferences). Craig edits this directly when he learns something.
- `memory/YYYY-MM-DD.md` -- daily logs. OpenClaw auto-flushes important context here before context compaction (when the conversation gets too long). Searchable via semantic search but not loaded into the prompt.
- `USER.md` -- what Craig has learned about his humans. Auto-generated by OpenClaw, Craig fills it in over time.

## Setup

### Prerequisites

- Hetzner Cloud account (with `hcloud` CLI configured)
- Anthropic API key
- Discord bot token
- [OpenClaw base setup](https://github.com/Merit-Systems/OpenClawX402) -- server provisioning guide

### 1. GitHub App (Org-Wide Repo Access)

Craig needs write access to all Merit-Systems repos without merge permissions. A GitHub App gives granular permissions, short-lived tokens, and no billing seat.

**Create the App:**

1. Go to [Merit-Systems org settings > Developer settings > GitHub Apps > New](https://github.com/organizations/Merit-Systems/settings/apps/new)
2. **App name**: `craigbidenbot` (or whatever you prefer)
3. **Homepage URL**: `https://github.com/Merit-Systems/CraigClaw`
4. **Webhook**: Uncheck "Active"
5. **Permissions** (Repository):
   - **Contents**: Read & Write (clone repos, push branches)
   - **Pull requests**: Read & Write (create/update PRs)
   - **Issues**: Read & Write (create/comment on issues)
   - **Metadata**: Read-only (auto-selected)
   - Everything else: No access
6. **Where can this be installed?**: "Only on this account"
7. Click **Create GitHub App**
8. Note the **App ID** (number near the top of the app page)
9. Click **Generate a private key** -- save the `.pem` file

**Install the App:**

1. On the app page, click **Install App** in the left sidebar
2. Select **Merit-Systems**
3. Choose **All repositories**
4. Click **Install**
5. Note the **Installation ID** (the number at the end of the URL after installing)

**On EC2:**

```bash
# Store the private key
mkdir -p ~/.config/craig
cp craigbidenbot.pem ~/.config/craig/github-app-key.pem
chmod 600 ~/.config/craig/github-app-key.pem

# Create token generation script (uses PyJWT to mint installation tokens)
cat > ~/.config/craig/get-github-token.sh << 'EOF'
#!/bin/bash
python3 -c "
import json, time, urllib.request, jwt
app_id = <APP_ID>
now = int(time.time())
payload = {'iat': now - 60, 'exp': now + 600, 'iss': app_id}
with open('/home/ubuntu/.config/craig/github-app-key.pem') as f:
    private_key = f.read()
token = jwt.encode(payload, private_key, algorithm='RS256')
req = urllib.request.Request(
    'https://api.github.com/app/installations/<INSTALLATION_ID>/access_tokens',
    method='POST',
    headers={
        'Authorization': f'Bearer {token}',
        'Accept': 'application/vnd.github+json',
    }
)
resp = urllib.request.urlopen(req)
data = json.loads(resp.read())
print(data['token'])
"
EOF
chmod +x ~/.config/craig/get-github-token.sh

# Create git credential helper (generates fresh token per git operation)
cat > ~/.config/craig/git-credential-helper.sh << 'EOF'
#!/bin/bash
if echo "$1" | grep -q "get"; then
  TOKEN=$(/home/ubuntu/.config/craig/get-github-token.sh 2>/dev/null)
  echo "protocol=https"
  echo "host=github.com"
  echo "username=x-access-token"
  echo "password=$TOKEN"
fi
EOF
chmod +x ~/.config/craig/git-credential-helper.sh

# Configure git
git config --global user.name "craigbidenbot[bot]"
git config --global user.email "craigbidenbot[bot]@users.noreply.github.com"
git config --global credential.https://github.com.helper "/home/ubuntu/.config/craig/git-credential-helper.sh"

# Add systemd override so OpenClaw starts with GH_TOKEN
mkdir -p ~/.config/systemd/user/openclaw-gateway.service.d
cat > ~/.config/systemd/user/openclaw-gateway.service.d/github.conf << 'EOF'
[Service]
ExecStart=
ExecStart=/bin/bash -c "export GH_TOKEN=$(/home/ubuntu/.config/craig/get-github-token.sh) && exec /usr/bin/node /home/ubuntu/.npm-global/lib/node_modules/openclaw/dist/index.js gateway --port 18789"
EOF
systemctl --user daemon-reload
systemctl --user restart openclaw-gateway
```

**Token lifecycle:** Installation tokens expire after 1 hour. The git credential helper generates a fresh token for each git operation. The systemd override generates one on each gateway restart. For long-running sessions, git operations will always work (fresh token per operation), but `gh` CLI calls use the `GH_TOKEN` env var set at startup which may expire.

### 2. Org-Wide Branch Protection

Prevents Craig (and everyone) from pushing directly to main/master. This is what ensures Craig can't merge his own code.

1. Go to [Merit-Systems org settings > Rules > Rulesets > New](https://github.com/organizations/Merit-Systems/settings/rules/rulesets/new)
2. **Ruleset name**: `Require PR reviews`
3. **Enforcement**: Active
4. **Target repositories**: All repositories
5. **Target branches**: Add target > Include default branch
6. **Rules**:
   - [x] Require a pull request before merging (Required approving reviews: 1)
   - [x] Block force pushes
7. **Save**

### 3. Discord Bot

**If creating a new bot:**

1. Go to [Discord Developer Portal](https://discord.com/developers/applications)
2. Create a new application named "Craig2"
3. Go to **Bot** > Create bot
4. Enable **Message Content Intent** and **Server Members Intent** under Privileged Gateway Intents
5. Copy the bot token
6. Go to **OAuth2 > URL Generator**:
   - Scopes: `bot`, `applications.commands`
   - Permissions: Send Messages, Read Message History, View Channels, Embed Links, Attach Files
7. Invite to your server with the generated URL

**Configure in OpenClaw:**

```bash
openclaw plugins enable discord
openclaw config set channels.discord.token "$DISCORD_BOT_TOKEN"
openclaw config set channels.discord.groupPolicy open
openclaw config set channels.discord.guilds.*.requireMention true
systemctl --user restart openclaw-gateway
```

### 4. Server Deployment

**Fresh setup:**

1. Provision a Hetzner Cloud server (`hcloud server create --name craig --type ccx33 --image ubuntu-24.04 --ssh-key craig --location ash`)
2. Create an `ubuntu` user, then SSH in and run the setup script:
   ```bash
   ssh ubuntu@<server-ip>
   curl -fsSL https://raw.githubusercontent.com/Merit-Systems/CraigClaw/main/deploy/setup.sh | bash
   ```
3. Follow the printed next steps (set env vars, run onboard, add Discord channel)
4. Enable linger so the service survives reboots:
   ```bash
   loginctl enable-linger ubuntu
   ```

**Resilience:**
- `Restart=always` in systemd -- auto-restarts on crash (5 second delay)
- `loginctl enable-linger` -- starts on boot without SSH login
- `enabled` in systemd -- persists across reboots
- `GH_TOKEN` regenerated fresh on every restart

### 5. x402 Payment Integration

```bash
# Install mcporter
sudo npm install -g mcporter

# Configure x402 MCP server
mcporter config add x402 --command "npx" --arg "-y" --arg "@x402scan/mcp@latest" --scope home

# Create wallet (auto-generated on first call)
mcporter call x402 get_wallet_info

# Install x402 skills
npx skills add merit-systems/x402scan-skills --global --all --yes

# Link skills to OpenClaw workspace
mkdir -p ~/.openclaw/workspace
ln -sf ~/.agents/skills ~/.openclaw/workspace/skills

# Restart
systemctl --user restart openclaw-gateway
```

Fund the wallet with USDC on Base. Even $5 is enough for testing.

### 6. Auto-Deploy

Changes pushed to `main` in this repo auto-deploy to the server via GitHub Actions.

**Required GitHub Secrets** (set in [CraigClaw repo Settings > Secrets](https://github.com/Merit-Systems/CraigClaw/settings/secrets/actions)):

| Secret | Value |
|--------|-------|
| `EC2_HOST` | Server IP (`178.156.251.179`) |
| `EC2_SSH_KEY` | Private SSH key for the `ubuntu` user |

**Deploy flow:**

1. A change merges to `main` (Craig self-edits via PR, or a human pushes directly)
2. GitHub Actions triggers (`.github/workflows/deploy.yml`)
3. SSHes into the server via `appleboy/ssh-action`
4. Runs `git pull origin main` to update the workspace
5. Runs bundle patches (see below)
6. Runs `systemctl --user restart openclaw-gateway` to reload Craig
7. Craig's next session uses the updated files

**Bundle patches** (applied automatically during deploy):

| Script | What it does |
|--------|-------------|
| `deploy/patch-openclaw.sh` | Disables `isBillingErrorMessage()` — prevents false billing-error warnings triggered by x402 HTTP 402 responses |
| `deploy/patch-compaction-notify.sh` | Injects a Discord notification before memory compaction so users know Craig is still alive during the 30-60s pause |

Patches are idempotent and safe to re-run. See `.claude/patches.md` for full details.

## Operational Runbook

```bash
# SSH in
ssh -i ~/.ssh/hetzner-craig ubuntu@178.156.251.179

# Check status
openclaw status --deep
systemctl --user status openclaw-gateway

# View logs
journalctl --user -u openclaw-gateway -f

# Restart
systemctl --user restart openclaw-gateway

# Manual workspace update (if auto-deploy isn't working)
cd ~/Code/merit-systems/CraigClaw && git pull origin main
systemctl --user restart openclaw-gateway

# Craig is stuck or misbehaving
systemctl --user stop openclaw-gateway
rm -rf /tmp/openclaw-*
systemctl --user start openclaw-gateway

# Check x402 wallet balance
mcporter call x402 get_wallet_info

# Generate a GitHub token manually
~/.config/craig/get-github-token.sh
```

## Security

- **GitHub App** has minimal permissions (contents + PRs + issues, read-only metadata)
- **Branch protection** prevents merging without review -- Craig cannot ship unreviewed code
- **Org-wide rulesets** enforce this across all repos automatically
- **Secrets** (API keys, tokens, private keys) live on the server only, never in this repo
- **GitHub App tokens** are short-lived (1 hour), generated on demand
- **x402 wallet** uses limited funds -- Craig can't overspend

## Cost

| Resource | Monthly Cost |
|----------|-------------|
| Hetzner CCX33 (8 vCPU, 32 GB RAM, 240 GB NVMe) | ~$54 |
| Anthropic API (Claude Opus 4.6) | Pay-per-use |
| x402 API calls | Pay-per-call (USDC on Base) |
| GitHub App | Free |
| Discord bot | Free |
| **Infrastructure total** | **~$54/month** |

## Related Repos

- [Merit-Systems/OpenClawX402](https://github.com/Merit-Systems/OpenClawX402) -- OpenClaw + x402 base setup guide
- [Merit-Systems/discord-claude-agent](https://github.com/Merit-Systems/discord-claude-agent) -- Legacy bot (replaced by CraigClaw)
- [openclaw/openclaw](https://github.com/openclaw/openclaw) -- OpenClaw core
