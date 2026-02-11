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
#   1. Set environment variables (ANTHROPIC_API_KEY, DISCORD_BOT_TOKEN)
#   2. Configure openclaw.json from the template
#   3. Set up the GitHub App credentials
#   4. Install x402 (see Merit-Systems/OpenClawX402/x402.md)

echo "=== CraigClaw EC2 Setup ==="

# 1. Install Node.js 22
echo "Installing Node.js 22..."
curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
sudo apt-get install -y nodejs

# 2. Install OpenClaw
echo "Installing OpenClaw..."
curl -fsSL https://openclaw.ai/install.sh | bash

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
mkdir -p ~/Code/merit-systems

# 5. Clone CraigClaw workspace
echo "Cloning CraigClaw workspace..."
git clone https://github.com/Merit-Systems/CraigClaw.git ~/Code/merit-systems/CraigClaw

# 6. Configure git
echo "Configuring git..."
git config --global user.name "craig2-bot"
git config --global user.email "craig2@merit-systems.dev"
git config --global init.defaultBranch main

# 7. Run OpenClaw onboard
echo ""
echo "=== Next Steps ==="
echo "1. Set your environment variables:"
echo "   export ANTHROPIC_API_KEY='your-key'"
echo "   export DISCORD_BOT_TOKEN='your-token'"
echo ""
echo "2. Run OpenClaw onboard:"
echo "   openclaw onboard --non-interactive --accept-risk \\"
echo "     --mode local \\"
echo "     --auth-choice apiKey \\"
echo "     --anthropic-api-key \"\$ANTHROPIC_API_KEY\" \\"
echo "     --gateway-port 18789 \\"
echo "     --gateway-bind loopback \\"
echo "     --install-daemon \\"
echo "     --daemon-runtime node"
echo ""
echo "3. Configure the workspace path in openclaw.json:"
echo "   openclaw config set agents.defaults.workspace ~/Code/merit-systems/CraigClaw"
echo ""
echo "4. Add Discord channel:"
echo "   openclaw channels add --channel discord --token \"\$DISCORD_BOT_TOKEN\""
echo ""
echo "5. Install x402 (see Merit-Systems/OpenClawX402/x402.md)"
echo ""
echo "6. Restart the gateway:"
echo "   systemctl --user restart openclaw-gateway"
echo ""
echo "=== Setup complete ==="
