#!/usr/bin/env bash
set -euo pipefail

# scout-dest-olx.sh — OLX.ro price lookup via agent-browser (local Playwright)
# Usage: ./scout-dest-olx.sh "search query"
# Output: JSON array of listings to stdout

QUERY="${1:-}"
if [[ -z "$QUERY" ]]; then
  echo '{"error": "No search query provided", "listings": []}' >&2
  exit 1
fi

# Verify agent-browser is available
if ! command -v agent-browser &>/dev/null; then
  echo '{"error": "agent-browser not installed", "listings": []}' >&2
  exit 1
fi

# URL-encode the query
ENCODED_QUERY=$(python3 -c "import urllib.parse; print(urllib.parse.quote('$QUERY'))" 2>/dev/null || echo "${QUERY// /+}")

# Open OLX search
agent-browser open "https://www.olx.ro/oferte/q-${ENCODED_QUERY}/" >/dev/null 2>&1 || {
  echo '{"error": "Failed to open OLX search", "listings": []}' >&2
  exit 1
}
agent-browser wait 3000 >/dev/null 2>&1

# Extract listings via JS eval
LISTINGS=$(agent-browser eval --stdin <<'EVALEOF'
JSON.stringify({
  listings: Array.from(document.querySelectorAll('[data-cy="l-card"]')).slice(0, 10).map(card => ({
    title: card.querySelector('h4, h6, [class*="title"]')?.textContent?.trim(),
    price: card.querySelector('[data-testid="ad-price"], [class*="price"]')?.textContent?.trim(),
    location: card.querySelector('[class*="location"]')?.textContent?.trim(),
    url: card.querySelector('a')?.href
  })).filter(l => l.title && l.price)
});
EVALEOF
) || {
  echo '{"error": "Failed to extract OLX listings", "listings": []}' >&2
  exit 1
}

echo "$LISTINGS"
