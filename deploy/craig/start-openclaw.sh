#!/bin/bash
# Startup wrapper for OpenClaw gateway.
# Mints a fresh GitHub App token and execs the gateway process.
# Note: largely redundant with github.conf systemd override, but kept
# for manual restarts outside of systemd.
export GH_TOKEN=$(/home/ubuntu/.config/craig/get-github-token.sh 2>/dev/null)
export PATH="/home/ubuntu/.local/bin:/home/ubuntu/.npm-global/bin:/home/ubuntu/bin:/usr/local/bin:/usr/bin:/bin"
exec /usr/bin/node /home/ubuntu/.npm-global/lib/node_modules/openclaw/dist/index.js gateway --port 18789
