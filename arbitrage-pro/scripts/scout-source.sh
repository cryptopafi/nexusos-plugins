#!/usr/bin/env bash
set -euo pipefail

# scout-source.sh — Discover auction lots via agent-browser category browse
# Usage: ./scout-source.sh [category] [platform] [max_lots]
# Output: JSON array of lot URLs + titles to stdout
# NOTE: This is the FALLBACK discovery method. Primary discovery is Sonar Pro (called from SKILL.md).
#       This script handles Phase 1b: direct category browsing when Sonar fails.

CATEGORY="${1:-}"
PLATFORM="${2:-troostwijk}"
MAX_LOTS="${3:-20}"

# Verify agent-browser is available
if ! command -v agent-browser &>/dev/null; then
  echo '{"error": "agent-browser not installed", "lots": []}' >&2
  exit 1
fi

# Verify jq is available
if ! command -v jq &>/dev/null; then
  echo '{"error": "jq not installed — run: brew install jq", "lots": []}' >&2
  exit 1
fi

case "$PLATFORM" in
  troostwijk)
    # Browse active auctions page
    AUCTIONS_URL="https://www.troostwijkauctions.com/en/auctions?auctionBiddingStatuses=BIDDING_OPEN&sorting=START_DATE_ASC"
    ;;
  catawiki)
    AUCTIONS_URL="https://www.catawiki.com/en/l/all"
    ;;
  *)
    echo '{"error": "Unknown platform — use troostwijk or catawiki", "lots": []}' >&2
    exit 1
    ;;
esac

# Open auctions page
agent-browser open "$AUCTIONS_URL" >/dev/null 2>&1 || {
  echo '{"error": "Failed to open auctions page", "lots": []}' >&2
  exit 1
}

# Wait for page load (explicit wait, NOT networkidle — E10 fix)
agent-browser wait 5000 >/dev/null 2>&1

# Accept cookie banner if present (E5 fix)
agent-browser eval 'document.querySelectorAll("button").forEach(b => { if (b.textContent.includes("Accept")) b.click(); })' >/dev/null 2>&1 || true
sleep 1

# Extract auction lot links via JS eval
LOTS_JSON=$(agent-browser eval --stdin <<'EVALEOF'
JSON.stringify({
  lots: Array.from(document.querySelectorAll('a[href*="/en/l/"]')).map(a => {
    var parent = a.closest('[class*="card"], [class*="lot"], [class*="item"], li, article, div') || a.parentElement?.parentElement;
    var text = parent ? parent.textContent : '';
    var priceMatch = text.match(/€\s*[\d,.]+/);
    return {
      title: a.textContent.trim().substring(0, 100),
      url: a.href.split('?')[0],
      price_hint: priceMatch ? priceMatch[0] : null
    };
  }).filter(l => l.title.length > 5)
});
EVALEOF
) || {
  echo '{"error": "Failed to extract lots from page", "lots": []}' >&2
  exit 1
}

echo "$LOTS_JSON"
