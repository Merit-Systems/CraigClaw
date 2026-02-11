#!/bin/bash
# Patch OpenClaw's false-positive billing error detection for x402.
#
# OpenClaw's isBillingErrorMessage() matches /\b402\b/ in error text,
# which triggers false "billing error" warnings whenever x402 MCP tools
# return HTTP 402 responses (the normal x402 payment protocol).
#
# This removes the overly-broad 402 pattern while keeping all other
# billing error checks (insufficient credits, payment required, etc.).
#
# Safe to run multiple times (idempotent).

set -euo pipefail

OPENCLAW_DIR="${npm_config_prefix:-$HOME/.npm-global}/lib/node_modules/openclaw/dist"

if [ ! -d "$OPENCLAW_DIR" ]; then
  echo "[patch-openclaw] OpenClaw dist not found at $OPENCLAW_DIR, skipping"
  exit 0
fi

patched=0
for f in "$OPENCLAW_DIR"/pi-embedded-helpers-*.js; do
  if grep -q '/\\b402\\b/' "$f" 2>/dev/null; then
    sed -i 's|/\\b402\\b/,||g' "$f"
    patched=$((patched + 1))
  fi
done

if [ "$patched" -gt 0 ]; then
  echo "[patch-openclaw] Patched $patched file(s) — removed /\b402\b/ from billing error patterns"
else
  echo "[patch-openclaw] Already patched (no changes needed)"
fi
