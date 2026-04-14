#!/usr/bin/env bash
set -euo pipefail

# playwright-scrape-lot.sh — Extract exact lot data from auction page via agent-browser
# Uses LOCAL Playwright (agent-browser) — FREE, no API credits needed
# Usage: ./playwright-scrape-lot.sh <lot_url> [platform]
# Output: JSON with price, deadline, status, title to stdout

LOT_URL="${1:-}"
PLATFORM="${2:-troostwijk}"

if [[ -z "$LOT_URL" ]]; then
  echo '{"error": "lot_url required", "lot": null}' >&2
  exit 1
fi

# Verify agent-browser is available
if ! command -v agent-browser &>/dev/null; then
  echo '{"error": "agent-browser not installed", "lot": null}' >&2
  exit 1
fi

# Sanitize URL — must start with https://
if [[ ! "$LOT_URL" =~ ^https:// ]]; then
  echo '{"error": "Invalid URL — must start with https://", "lot": null}' >&2
  exit 1
fi

# Open lot page with explicit wait (E10 fix: don't use networkidle)
agent-browser open "$LOT_URL" >/dev/null 2>&1 || {
  echo '{"error": "Failed to open lot URL", "lot": null}' >&2
  exit 1
}
agent-browser wait 5000 >/dev/null 2>&1

# Accept cookie banner on first visit (E5 fix)
agent-browser eval 'document.querySelectorAll("button").forEach(b => { if (b.textContent.includes("Accept")) b.click(); })' >/dev/null 2>&1 || true
sleep 1

# Extract lot data via JS eval — text regex, NOT CSS selectors (E2 fix)
LOT_DATA=$(agent-browser eval --stdin <<'EVALEOF'
JSON.stringify({
  title: document.querySelector('h1')?.textContent?.trim(),
  all_prices: (() => {
    const els = document.querySelectorAll('*');
    const prices = [];
    for (const el of els) {
      const t = el.textContent?.trim();
      if (t && t.match(/^€\s*[\d.,]+$/) && t.length < 20) prices.push(t);
    }
    return [...new Set(prices)];
  })(),
  is_sold: document.body.innerText.includes('auction has ended') || document.body.innerText.includes('Sold by'),
  is_active: document.body.innerText.includes('Sign in to bid'),
  reserve_not_met: document.body.innerText.includes('Reserve Price not met') || document.body.innerText.includes('Reserve price not met'),
  bid_count: (() => {
    const m = document.body.innerText.match(/(\d+)\s*[Bb]ids?/);
    return m ? parseInt(m[1]) : null;
  })(),
  deadline: (() => {
    const m = document.body.innerText.match(/(\d{1,2}\s+\w+\s+\d{4}\s+\d{1,2}:\d{2})/);
    return m ? m[1] : null;
  })(),
  location: (() => {
    const m = document.body.innerText.match(/Online,\s*([A-Z]{2})/);
    return m ? m[1] : null;
  })(),
  url: window.location.href,
  platform: (() => {
    const h = window.location.hostname;
    if (h.includes('troostwijk')) return 'troostwijk';
    if (h.includes('catawiki')) return 'catawiki';
    if (h.includes('surplex')) return 'surplex';
    return 'unknown';
  })(),
  extracted_at: new Date().toISOString()
});
EVALEOF
) || {
  echo '{"error": "Failed to extract lot data", "lot": null}' >&2
  exit 1
}

echo "{\"lot\": $LOT_DATA}"
