#!/bin/bash
# CCP-004 mapping: Custom error handler (fires on research pipeline failure)
# on-error.sh — DELPHI PRO error hook
# Runs when research pipeline encounters a critical error.
set -euo pipefail

PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"

ERROR_MSG="${1:-Unknown error}"
TOPIC="${2:-}"
DEPTH="${3:-}"

# 1. Log error
echo "[DELPHI-PRO] ERROR: ${ERROR_MSG} | topic='${TOPIC}', depth=${DEPTH}" >> ~/.nexus/logs/delphi.log 2>/dev/null || true

# 2. Telegram notification (D3/D4 only)
if [[ "$DEPTH" == "D3" || "$DEPTH" == "D4" ]]; then
  if command -v telegram-notify &>/dev/null; then
    telegram-notify "DELPHI PRO ERROR: ${ERROR_MSG}" 2>/dev/null || true
  fi
fi

echo "error-hook OK"
