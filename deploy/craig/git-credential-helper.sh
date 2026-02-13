#!/bin/bash
# Git credential helper for GitHub App installation tokens.
# Configured via: git config --global credential.helper /path/to/this/script
if echo "$1" | grep -q "get"; then
  TOKEN=$(/home/ubuntu/.config/craig/get-github-token.sh 2>/dev/null)
  echo "protocol=https"
  echo "host=github.com"
  echo "username=x-access-token"
  echo "password=$TOKEN"
fi
