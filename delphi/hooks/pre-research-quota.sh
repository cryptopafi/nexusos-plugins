#!/bin/bash
# CCP-004 mapping: Custom pre-research hook (fires before scout dispatch, checks search quotas)
# pre-research-quota.sh — Check search engine quotas before research
# Called by DELPHI PRO before dispatching scouts.
# Reads channel_quotas from state.json, checks external APIs where possible,
# and reports channel availability. Exits non-zero if ALL web search channels exhausted.
set -euo pipefail

PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"

# Portable key resolution (.env -> env var -> macOS Keychain)
source "${PLUGIN_ROOT}/lib/resolve-key.sh"

DEPTH="${1:-D2}"
STATE_FILE="${PLUGIN_ROOT}/resources/state.json"
LOG_FILE="$HOME/.nexus/logs/delphi.log"

log() { echo "[DELPHI-QUOTA] $(date '+%H:%M:%S') $*" >> "$LOG_FILE" 2>/dev/null || true; }

# ---------- Read quota state ----------
read_quotas() {
  python3 -c "
import json, sys, os
state_path = '$STATE_FILE'
try:
    with open(state_path) as f:
        state = json.load(f)
    quotas = state.get('channel_quotas', {})
    print(json.dumps(quotas))
except Exception as e:
    print('{}')
    sys.exit(0)
"
}

QUOTAS=$(read_quotas)

# ---------- Check each channel ----------
AVAILABLE=0
EXHAUSTED=0
CHANNELS_UP=""
CHANNELS_DOWN=""

check_local_quota() {
  local channel="$1"
  local used limit pct
  used=$(echo "$QUOTAS" | python3 -c "import sys,json; q=json.load(sys.stdin).get('$channel',{}); print(q.get('used_this_month',0))" 2>/dev/null || echo "0")
  limit=$(echo "$QUOTAS" | python3 -c "import sys,json; q=json.load(sys.stdin).get('$channel',{}); print(q.get('monthly_limit',9999))" 2>/dev/null || echo "9999")

  if [[ "$limit" -gt 0 ]]; then
    pct=$(( (used * 100) / limit ))
  else
    pct=0
  fi

  if [[ "$pct" -ge 100 ]]; then
    # Counter says exhausted — verify with live API probe before declaring dead
    local live_ok=false
    live_ok=$(live_probe "$channel" 2>/dev/null)
    if [[ "$live_ok" == "true" ]]; then
      AVAILABLE=$((AVAILABLE + 1))
      CHANNELS_UP="${CHANNELS_UP} ${channel}"
      echo "  \"$channel\": {\"status\": \"ok\", \"used\": $used, \"limit\": $limit, \"pct\": $pct, \"live_probe\": \"override_healthy\"},"
      log "$channel: counter=$pct% but LIVE PROBE OK — marking healthy (key rotated?)"
    else
      EXHAUSTED=$((EXHAUSTED + 1))
      CHANNELS_DOWN="${CHANNELS_DOWN} ${channel}(${used}/${limit})"
      echo "  \"$channel\": {\"status\": \"exhausted\", \"used\": $used, \"limit\": $limit, \"pct\": $pct, \"live_probe\": \"confirmed_dead\"},"
      log "$channel: EXHAUSTED confirmed by live probe ($used/$limit = ${pct}%)"
    fi
  elif [[ "$pct" -ge 80 ]]; then
    AVAILABLE=$((AVAILABLE + 1))
    CHANNELS_UP="${CHANNELS_UP} ${channel}(${pct}%)"
    echo "  \"$channel\": {\"status\": \"low\", \"used\": $used, \"limit\": $limit, \"pct\": $pct},"
    log "$channel: LOW ($used/$limit = ${pct}%)"
  else
    AVAILABLE=$((AVAILABLE + 1))
    CHANNELS_UP="${CHANNELS_UP} ${channel}"
    echo "  \"$channel\": {\"status\": \"ok\", \"used\": $used, \"limit\": $limit, \"pct\": $pct},"
    log "$channel: OK ($used/$limit = ${pct}%)"
  fi
}

# Live API probe — lightweight test call per channel (only called when counter says exhausted)
live_probe() {
  local channel="$1"
  case "$channel" in
    brave)
      local BRAVE_KEY
      BRAVE_KEY=$(resolve_key "BRAVE_SEARCH_API_KEY" || echo "")
      [[ -z "$BRAVE_KEY" ]] && echo "false" && return
      local http_code
      http_code=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 --max-time 10 \
        -H "X-Subscription-Token: ${BRAVE_KEY}" \
        "https://api.search.brave.com/res/v1/web/search?q=test&count=1" 2>/dev/null)
      [[ "$http_code" == "200" ]] && echo "true" || echo "false"
      ;;
    tavily)
      local TAVILY_KEY
      TAVILY_KEY=$(resolve_key "TAVILY_API_KEY" || echo "")
      [[ -z "$TAVILY_KEY" ]] && echo "false" && return
      local http_code
      http_code=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 --max-time 10 \
        -X POST "https://api.tavily.com/search" \
        -H "Content-Type: application/json" \
        -d "{\"api_key\":\"${TAVILY_KEY}\",\"query\":\"test\",\"max_results\":1}" 2>/dev/null)
      [[ "$http_code" == "200" ]] && echo "true" || echo "false"
      ;;
    exa)
      local EXA_KEY
      EXA_KEY=$(resolve_key "EXA_API_KEY" || echo "")
      [[ -z "$EXA_KEY" ]] && echo "false" && return
      local http_code
      http_code=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 --max-time 10 \
        -X POST "https://api.exa.ai/search" \
        -H "x-api-key: ${EXA_KEY}" -H "Content-Type: application/json" \
        -d "{\"query\":\"test\",\"numResults\":1}" 2>/dev/null)
      [[ "$http_code" == "200" ]] && echo "true" || echo "false"
      ;;
    *)
      echo "false"
      ;;
  esac
}

echo '{"quota_check": {'

# Brave Search (local counter)
check_local_quota "brave"

# Tavily (local counter)
check_local_quota "tavily"

# Exa (local counter)
check_local_quota "exa"

# OpenRouter (live check for balance — needed for Perplexity Sonar)
OR_KEY=$(resolve_key "OPENROUTER_API_KEY" || echo "")
if [[ -n "$OR_KEY" ]]; then
  OR_RAW=$(curl -s --connect-timeout 5 "https://openrouter.ai/api/v1/auth/key" \
    -H "Authorization: Bearer $OR_KEY" 2>/dev/null || echo "{}")
  OR_STATUS=$(echo "$OR_RAW" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin).get('data', {})
    limit = d.get('limit', None)
    limit_remaining = d.get('limit_remaining', None)
    limit_reset = d.get('limit_reset', 'unknown')
    usage_daily = d.get('usage_daily', 0)
    if limit is None:
        print(f'ok,unlimited,today=\${usage_daily:.4f}')
    elif limit_remaining is not None and limit_remaining > 0:
        print(f'ok,{limit_reset}_limit=\${limit:.2f},remaining=\${limit_remaining:.2f},today=\${usage_daily:.4f}')
    else:
        print(f'exhausted,{limit_reset}_limit=\${limit:.2f},remaining=\${limit_remaining:.2f},today=\${usage_daily:.4f}')
except:
    print('error')
" 2>/dev/null || echo "error")
  echo "  \"openrouter\": \"$OR_STATUS\","
  if [[ "$OR_STATUS" == exhausted* ]]; then
    EXHAUSTED=$((EXHAUSTED + 1))
    CHANNELS_DOWN="${CHANNELS_DOWN} openrouter"
    log "OpenRouter: EXHAUSTED"
  else
    AVAILABLE=$((AVAILABLE + 1))
    CHANNELS_UP="${CHANNELS_UP} openrouter"
    log "OpenRouter: $OR_STATUS"
  fi
else
  echo "  \"openrouter\": \"no_key\","
  log "OpenRouter: no key found"
fi

# DuckDuckGo (free, always available unless rate-limited)
AVAILABLE=$((AVAILABLE + 1))
CHANNELS_UP="${CHANNELS_UP} ddg"
echo "  \"ddg\": {\"status\": \"ok\", \"note\": \"free, rate-limited\"},"

# ---------- Verdict ----------

# WEB_AVAILABLE = web search channels only (brave+tavily+exa+ddg), excluding openrouter (LLM, not search)
WEB_AVAILABLE=0
for ch in brave tavily exa ddg; do
  [[ "$CHANNELS_UP" == *" $ch"* || "$CHANNELS_UP" == *" ${ch}("* ]] && WEB_AVAILABLE=$((WEB_AVAILABLE + 1))
done

if [[ "$WEB_AVAILABLE" -eq 0 ]]; then
  echo "  \"verdict\": \"ALL_EXHAUSTED\","
  echo "  \"recommendation\": \"ABORT — no web search channels available.\""
  log "CRITICAL: ALL web search channels exhausted!"
  echo '}}'
  exit 1
elif [[ "$WEB_AVAILABLE" -le 1 ]] && [[ "$DEPTH" == "D3" || "$DEPTH" == "D4" ]]; then
  echo "  \"verdict\": \"BLOCKED\","
  echo "  \"available\": \"${CHANNELS_UP}\","
  echo "  \"exhausted\": \"${CHANNELS_DOWN}\","
  echo "  \"recommendation\": \"BLOCKED: Only $WEB_AVAILABLE web search channel(s) for $DEPTH. Need >=2. Upgrade Brave/Tavily or wait for quota reset.\""
  log "BLOCKED: $DEPTH needs >=2 web channels, only $WEB_AVAILABLE available"
  echo '}}'
  exit 1
elif [[ "$EXHAUSTED" -gt 0 ]]; then
  echo "  \"verdict\": \"PARTIAL\","
  echo "  \"available\": \"${CHANNELS_UP}\","
  echo "  \"exhausted\": \"${CHANNELS_DOWN}\","
  if [[ "$WEB_AVAILABLE" -le 2 ]]; then
    echo "  \"recommendation\": \"WARNING: Only $WEB_AVAILABLE web search channel(s) available. Results may be limited.\""
  else
    echo "  \"recommendation\": \"Route to available channels. Priority: Exa > Perplexity Sonar Pro > DDG\""
  fi
  log "PARTIAL: available=[${CHANNELS_UP}] exhausted=[${CHANNELS_DOWN}]"
else
  echo "  \"verdict\": \"ALL_OK\","
  echo "  \"available\": \"${CHANNELS_UP}\""
  log "ALL OK: [${CHANNELS_UP}]"
fi

echo '}}'
exit 0
