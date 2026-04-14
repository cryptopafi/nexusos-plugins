#!/bin/bash
# CCP-004 mapping: Custom pre-research hook (fires before research pipeline, not a standard Claude Code hook event)
# pre-research.sh — DELPHI PRO pre-research hook
# Runs before each research session. Checks API health + Cortex pre-search.
set -euo pipefail

PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"

TOPIC="${1:-}"
DEPTH="${2:-auto}"

# 1. Log start
echo "[DELPHI-PRO] Research starting: topic='${TOPIC}', depth=${DEPTH}" >> ~/.nexus/logs/delphi.log 2>/dev/null || true

# 2. Check Cortex availability
CORTEX_OK=$(curl -s --connect-timeout 3 http://localhost:6400/api/health 2>/dev/null | python3 -c "import sys,json; print(json.load(sys.stdin).get('status','down'))" 2>/dev/null || echo "down")
if [[ "$CORTEX_OK" != "ok" ]]; then
  echo "[DELPHI-PRO] WARNING: Cortex unavailable. Pre-search skipped." >> ~/.nexus/logs/delphi.log 2>/dev/null || true
fi

# Note: last_run timestamp is updated by post-research.sh on completion (not here)

echo "pre-research OK"
