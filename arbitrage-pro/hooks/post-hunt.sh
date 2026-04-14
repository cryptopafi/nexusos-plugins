#!/usr/bin/env bash
set -euo pipefail

# post-hunt.sh — Post-hunt cleanup and state update

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ROOT="$(dirname "$SCRIPT_DIR")"

# Update state.json with run counter
STATE_FILE="$PLUGIN_ROOT/resources/state.json"
if [[ -f "$STATE_FILE" ]]; then
  # Increment run count using python (available on macOS)
  python3 <<'PYEOF' "$STATE_FILE" 2>/dev/null || echo "[POST-HUNT] WARNING: Could not update state.json" >&2
import json, sys
state_file = sys.argv[1]
with open(state_file, 'r') as f:
    state = json.load(f)
state['hunt_runs'] = state.get('hunt_runs', 0) + 1
with open(state_file, 'w') as f:
    json.dump(state, f, indent=2)
PYEOF
fi

# Clean up temp files older than 24h
find /tmp -maxdepth 1 -name "arbitrage-*.html" -mmin +1440 -delete 2>/dev/null || true

echo "[POST-HUNT] Cleanup complete" >&2
exit 0
