#!/usr/bin/env bash
# Send Arbitrage Pro deal alert via Telegram
# Usage: telegram-alert.sh "category" "lot_id" "title" "roi_pct" "max_bid" "verdict" "current_bid"
# Sends to Pafi via @claudemacm4_bot (Lis notification bot)

set -euo pipefail

CATEGORY="${1:-unknown}"
LOT_ID="${2:-}"
TITLE="${3:-}"
ROI="${4:-0}"
MAX_BID="${5:-}"
VERDICT="${6:-BUY}"
CURRENT_BID="${7:-}"

# Get token from env or Keychain (macOS)
BOT_TOKEN="${TELEGRAM_BOT_TOKEN:-}"
if [[ -z "$BOT_TOKEN" ]] && command -v security &>/dev/null; then
  BOT_TOKEN="$(security find-generic-password -s "telegram-bot-token-claudemacm4" -w 2>/dev/null)" || true
fi
CHAT_ID="${TELEGRAM_CHAT_ID:-}"
if [[ -z "$CHAT_ID" ]] && command -v security &>/dev/null; then
  CHAT_ID="$(security find-generic-password -s "PAFI_TELEGRAM_CHAT_ID" -w 2>/dev/null)" || true
fi

if [[ -z "$BOT_TOKEN" || -z "$CHAT_ID" ]]; then
  echo "ERROR: Missing TELEGRAM_BOT_TOKEN or CHAT_ID" >&2
  exit 1
fi

# Format emoji based on verdict
case "$VERDICT" in
  BUY)  EMOJI="🟢" ;;
  WATCH) EMOJI="🟡" ;;
  *)     EMOJI="⚪" ;;
esac

# Build message
MSG="${EMOJI} <b>Arbitrage Pro Alert</b>

<b>Category:</b> ${CATEGORY}
<b>Verdict:</b> ${VERDICT}
<b>ROI:</b> ${ROI}%"

[[ -n "$TITLE" ]] && MSG="${MSG}
<b>Item:</b> ${TITLE}"

[[ -n "$LOT_ID" ]] && MSG="${MSG}
<b>Lot:</b> <code>${LOT_ID}</code>"

[[ -n "$CURRENT_BID" ]] && MSG="${MSG}
<b>Current Bid:</b> €${CURRENT_BID}"

[[ -n "$MAX_BID" ]] && MSG="${MSG}
<b>Max Bid (30% ROI):</b> €${MAX_BID}"

[[ -n "$LOT_ID" ]] && MSG="${MSG}

<a href=\"http://89.116.229.189:8080/go/${LOT_ID}\">Open Auction</a> | <a href=\"http://89.116.229.189:8080/\">Dashboard</a>"

# Send via Telegram Bot API with exponential backoff
for attempt in 1 2 3 4; do
  RESPONSE=$(curl -s -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" \
    -d chat_id="$CHAT_ID" \
    -d parse_mode="HTML" \
    --data-urlencode "text=${MSG}" \
    --connect-timeout 10 \
    --max-time 15 2>&1)

  if echo "$RESPONSE" | grep -q '"ok":true'; then
    echo "Alert sent successfully"
    exit 0
  fi

  WAIT=$((attempt * attempt))
  echo "Attempt $attempt failed, retrying in ${WAIT}s..." >&2
  sleep "$WAIT"
done

echo "ERROR: Failed to send alert after 4 attempts" >&2
echo "$RESPONSE" >&2
exit 1
