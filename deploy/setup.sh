#!/bin/bash
set -euo pipefail

# CraigClaw EC2 Setup Script
# Run this on a fresh Ubuntu 24.04 EC2 instance after SSH'ing in.
#
# Prerequisites:
#   - EC2 instance running (see Merit-Systems/OpenClawX402/EC2.md)
#   - SSH access configured
#
# Usage:
#   ssh ubuntu@<ip> 'bash -s' < deploy/setup.sh
#
# After running this script, you still need to:
#   1. Run OpenClaw onboard (see Next Steps output)
#   2. Create ~/.openclaw/secrets.json (see deploy/secrets.json.example)
#   3. Place GitHub App private key at ~/.config/craig/github-app-key.pem
#   4. Install x402 (see Merit-Systems/OpenClawX402/x402.md)

echo "=== CraigClaw EC2 Setup ==="

# 1. Install Node.js 22
echo "Installing Node.js 22..."
curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
sudo apt-get install -y nodejs

# 2. Install pnpm (needed to build OpenClaw from fork source)
echo "Installing pnpm..."
npm install -g pnpm

# 3. Install GitHub CLI
echo "Installing GitHub CLI..."
(type -p wget >/dev/null || (sudo apt update && sudo apt-get install wget -y)) \
  && sudo mkdir -p -m 755 /etc/apt/keyrings \
  && out=$(mktemp) && wget -nv -O"$out" https://cli.github.com/packages/githubcli-archive-keyring.gpg \
  && cat "$out" | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null \
  && sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
  && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
  && sudo apt update \
  && sudo apt install gh -y

# 4. Create directory structure
echo "Creating directory structure..."
mkdir -p ~/Code/merit-systems ~/Code/openclaw ~/.config/craig

# 5. Clone CraigClaw workspace
echo "Cloning CraigClaw workspace..."
git clone https://github.com/Merit-Systems/CraigClaw.git ~/Code/merit-systems/CraigClaw

# 6. Clone OpenClaw fork
echo "Cloning OpenClaw fork..."
git clone https://github.com/Merit-Systems/openclaw.git ~/Code/openclaw/openclaw

# 7. Configure git
echo "Configuring git..."
git config --global user.name "craig2-bot"
git config --global user.email "craig2@merit-systems.dev"
git config --global init.defaultBranch main

# 8. Copy credential scripts from repo
echo "Setting up credential scripts..."
cp ~/Code/merit-systems/CraigClaw/deploy/craig/get-github-token.sh ~/.config/craig/
cp ~/Code/merit-systems/CraigClaw/deploy/craig/git-credential-helper.sh ~/.config/craig/
chmod +x ~/.config/craig/*.sh
git config --global credential.helper /home/ubuntu/.config/craig/git-credential-helper.sh

echo ""
echo "=== Next Steps ==="
echo "1. Set your Anthropic API key and run OpenClaw onboard:"
echo "   export ANTHROPIC_API_KEY='your-key'"
echo "   openclaw onboard --non-interactive --accept-risk \\"
echo "     --mode local \\"
echo "     --auth-choice apiKey \\"
echo "     --anthropic-api-key \"\$ANTHROPIC_API_KEY\" \\"
echo "     --gateway-port 18789 \\"
echo "     --gateway-bind loopback \\"
echo "     --install-daemon \\"
echo "     --daemon-runtime node"
echo ""
echo "2. Create ~/.openclaw/secrets.json with Discord + gateway tokens:"
echo "   See deploy/secrets.json.example for the format."
echo ""
echo "3. Place the GitHub App private key:"
echo "   scp github-app-key.pem ubuntu@<ip>:~/.config/craig/github-app-key.pem"
echo ""
echo "4. Set up the systemd override:"
echo "   mkdir -p ~/.config/systemd/user/openclaw-gateway.service.d"
echo "   cp ~/Code/merit-systems/CraigClaw/deploy/craig/github.conf \\"
echo "     ~/.config/systemd/user/openclaw-gateway.service.d/"
echo "   systemctl --user daemon-reload"
echo ""
echo "5. Render config and start:"
echo "   jq -s '.[0] * .[1]' ~/Code/merit-systems/CraigClaw/deploy/openclaw.json \\"
echo "     ~/.openclaw/secrets.json > ~/.openclaw/openclaw.json"
echo "   systemctl --user restart openclaw-gateway"
echo ""
echo "6. Install x402 (see Merit-Systems/OpenClawX402/x402.md)"
echo ""
echo "=== Setup complete ==="
