#!/usr/bin/env bash
set -euo pipefail

# on-error.sh — Error handler for Arbitrage Pro pipeline

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ROOT="$(dirname "$SCRIPT_DIR")"

ERROR_MSG="${1:-unknown error}"
STEP="${2:-unknown step}"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

echo "[ARBITRAGE-ERROR] $TIMESTAMP | step: $STEP | error: $ERROR_MSG" >&2

# Log to state file — pass values via env vars to avoid injection
STATE_FILE="$PLUGIN_ROOT/resources/state.json"
if [[ -f "$STATE_FILE" ]]; then
  ARB_TIMESTAMP="$TIMESTAMP" ARB_STEP="$STEP" ARB_ERROR="$ERROR_MSG" \
  python3 <<'PYEOF' "$STATE_FILE" 2>/dev/null || true
import json, sys, os
state_file = sys.argv[1]
with open(state_file, 'r') as f:
    state = json.load(f)
errors = state.get('errors', [])
errors.append({
    'timestamp': os.environ['ARB_TIMESTAMP'],
    'step': os.environ['ARB_STEP'],
    'error': os.environ['ARB_ERROR']
})
state['errors'] = errors[-20:]
with open(state_file, 'w') as f:
    json.dump(state, f, indent=2)
PYEOF
fi

exit 0
