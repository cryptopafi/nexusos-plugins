#!/bin/bash
# resolve-key.sh — Portable API key resolution for Arbitrage Pro
# Usage: source this file, then call resolve_key "KEY_NAME"
# Priority: .env file -> environment variable -> macOS Keychain -> empty

resolve_key() {
  local KEY_NAME="$1"
  local VAL=""

  # 1. Check .env file (most portable)
  if [[ -f "$HOME/.nexus/.env" ]]; then
    VAL=$(grep -E "^(export\s+)?${KEY_NAME}=" "$HOME/.nexus/.env" 2>/dev/null | head -1 | sed "s/^export[[:space:]]*//" | cut -d= -f2- | sed "s/^['\"]//;s/['\"]$//")
    if [[ -n "$VAL" ]]; then echo "$VAL"; return 0; fi
  fi

  # 2. Check environment variable (already exported)
  VAL="${!KEY_NAME:-}"
  if [[ -n "$VAL" ]]; then echo "$VAL"; return 0; fi

  # 3. Fallback: macOS Keychain (not portable but works locally)
  if command -v security &>/dev/null; then
    VAL=$(security find-generic-password -s "$KEY_NAME" -w 2>/dev/null || echo "")
    if [[ -n "$VAL" ]]; then echo "$VAL"; return 0; fi
  fi

  # 4. Not found
  echo ""
  return 1
}
