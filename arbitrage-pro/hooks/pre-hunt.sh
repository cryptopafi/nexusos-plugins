#!/usr/bin/env bash
set -euo pipefail

# pre-hunt.sh — Pre-flight checks before /hunt pipeline
# Verifies API keys and required tools are available

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ROOT="$(dirname "$SCRIPT_DIR")"

source "$PLUGIN_ROOT/lib/resolve-key.sh"

ERRORS=0

# Check agent-browser CLI (required for autonomous price extraction)
if ! command -v agent-browser &>/dev/null; then
  echo "[PRE-HUNT] WARNING: agent-browser not installed — Mode B (autonomous) unavailable, falling back to Mode A (assisted)" >&2
fi

# Check OpenRouter API key (used for Sonar Pro discovery)
OPENROUTER_KEY=$(resolve_key "OPENROUTER_API_KEY")
if [[ -z "$OPENROUTER_KEY" ]]; then
  echo "[PRE-HUNT] WARNING: OPENROUTER_API_KEY not found — Sonar Pro discovery unavailable, using agent-browser browse fallback" >&2
fi

# Check that state directory exists
if [[ ! -d "$PLUGIN_ROOT/state" ]]; then
  mkdir -p "$PLUGIN_ROOT/state"
  echo "[PRE-HUNT] Created state directory" >&2
fi

# Check that resource files exist
for f in tax-tables.yaml transport-rates.yaml model-config.yaml; do
  if [[ ! -f "$PLUGIN_ROOT/resources/$f" ]]; then
    echo "[PRE-HUNT] ERROR: Missing resource: resources/$f" >&2
    ERRORS=$((ERRORS + 1))
  fi
done

# Read VPS host from channel-config.yaml (no hardcoded IPs)
VPS_HOST=$(grep 'vps_host:' "$PLUGIN_ROOT/resources/channel-config.yaml" 2>/dev/null | head -1 | sed 's/.*: *"\(.*\)"/\1/')
VPS_USER=$(grep 'vps_user:' "$PLUGIN_ROOT/resources/channel-config.yaml" 2>/dev/null | head -1 | sed 's/.*: *"\(.*\)"/\1/')
if [[ -n "$VPS_HOST" && -n "$VPS_USER" ]]; then
  if ! ssh -o ConnectTimeout=3 -o BatchMode=yes "${VPS_USER}@${VPS_HOST}" "echo ok" &>/dev/null; then
    echo "[PRE-HUNT] WARNING: VPS unreachable — reports will be saved locally only" >&2
  fi
fi

if [[ $ERRORS -gt 0 ]]; then
  echo "[PRE-HUNT] BLOCKED: $ERRORS critical errors. Fix before proceeding." >&2
  exit 1
fi

echo "[PRE-HUNT] All checks passed" >&2
exit 0
