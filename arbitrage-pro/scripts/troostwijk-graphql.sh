#!/bin/bash
# troostwijk-graphql.sh — Extract real bid prices from TBAuctions via GraphQL API
# Discovered: 2026-03-22 via agent-browser reverse engineering
# Schema updated: 2026-03-22 (lotDetails query, Money uses cents, Platform enum)
# Endpoint: storefront.tbauctions.com/storefront/graphql
# No authentication required — public API (bid data is public after all)
#
# Usage: ./troostwijk-graphql.sh <lot_display_id> [platform]
# Example: ./troostwijk-graphql.sh A1-44017-27
# Example: ./troostwijk-graphql.sh A7-36729-1 SPX
#
# Platforms: TWK (Troostwijk), SPX (Surplex), BVA, VAVATO, AUK, EPIC, HT, BMA, DAB, PS
#            KVK_FI, KVK_DK, KVK_SE
#
# Output: JSON with bid price (EUR), bid count, premium %, condition, closing date
#
# Search mode: ./troostwijk-graphql.sh --search "compressor" [platform] [limit]
# List mode:   ./troostwijk-graphql.sh --list [platform] [page] [size]

set -euo pipefail

GRAPHQL_URL="https://storefront.tbauctions.com/storefront/graphql"

# --- SEARCH MODE ---
if [ "${1:-}" = "--search" ]; then
  SEARCH_TERM="${2:?Usage: $0 --search <term> [platform] [pages]}"
  PLATFORM="${3:-TWK}"
  PAGES="${4:-3}"

  # Paginate through multiple pages (max 100 per page) and filter by title
  ALL_RESULTS="[]"
  for page in $(seq 1 "$PAGES"); do
    RAW_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$GRAPHQL_URL" \
      -H "Content-Type: application/json" \
      -d '{"query": "query { allLots(request: {pageNumber: '"$page"', pageSize: 100, locale: \"en\", lotBiddingStatuses: [BIDDING_OPEN], sortBy: END_DATE_ASC}, platform: '"$PLATFORM"') { results { displayId title currentBidAmount { cents currency } bidsCount endDate location { city countryCode } saleTerm } } }"}' \
      --connect-timeout 10 --max-time 30 2>/dev/null || echo -e "\n000")
    HTTP_CODE=$(echo "$RAW_RESPONSE" | tail -1)
    PAGE_RESPONSE=$(echo "$RAW_RESPONSE" | sed '$d')

    if [ "$HTTP_CODE" != "200" ]; then
      echo '{"error": "Search page '"$page"' failed", "http_code": "'"$HTTP_CODE"'", "platform": "'"$PLATFORM"'"}' >&2
      continue
    fi

    MATCHES=$(echo "$PAGE_RESPONSE" | jq --arg term "$SEARCH_TERM" '[.data.allLots.results // [] | .[] | select(.title | test($term; "i"))]' 2>/dev/null || echo "[]")
    ALL_RESULTS=$(echo "$ALL_RESULTS" "$MATCHES" | jq -s '.[0] + .[1]')
  done

  echo "$ALL_RESULTS" | jq 'map({
    id: .displayId,
    title: (.title | gsub("\\r"; "")),
    price: (if .currentBidAmount then (.currentBidAmount.cents / 100) else null end),
    currency: (.currentBidAmount.currency // "EUR"),
    bid_count: (.bidsCount // 0),
    deadline: .endDate,
    location: .location.countryCode,
    location_city: .location.city,
    sale_term: .saleTerm,
    price_source: "PLATFORM_LIVE"
  })'
  exit 0
fi

# --- LIST MODE ---
if [ "${1:-}" = "--list" ]; then
  PLATFORM="${2:-TWK}"
  PAGE="${3:-1}"
  SIZE="${4:-20}"

  RAW_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$GRAPHQL_URL" \
    -H "Content-Type: application/json" \
    -d '{"query": "query { allLots(request: {pageNumber: '"$PAGE"', pageSize: '"$SIZE"', locale: \"en\", lotBiddingStatuses: [BIDDING_OPEN], sortBy: BIDS_COUNT_DESC}, platform: '"$PLATFORM"') { totalSize hasNext results { displayId title currentBidAmount { cents currency } bidsCount endDate location { city countryCode } saleTerm } } }"}' \
    --connect-timeout 10 --max-time 30 2>/dev/null || echo -e "\n000")
  HTTP_CODE=$(echo "$RAW_RESPONSE" | tail -1)
  BODY=$(echo "$RAW_RESPONSE" | sed '$d')

  if [ "$HTTP_CODE" != "200" ]; then
    echo '{"error": "List request failed", "http_code": "'"$HTTP_CODE"'", "platform": "'"$PLATFORM"'"}' >&2
    exit 1
  fi

  echo "$BODY" | jq '{
      total: .data.allLots.totalSize,
      has_next: .data.allLots.hasNext,
      lots: [.data.allLots.results // [] | .[] | {
        id: .displayId,
        title: (.title | gsub("\\r"; "")),
        price: (if .currentBidAmount then (.currentBidAmount.cents / 100) else null end),
        bid_count: .bidsCount,
        location: .location.countryCode,
        sale_term: .saleTerm
      }]
    }'
  exit 0
fi

# --- SINGLE LOT MODE (default) ---
LOT_ID="${1:?Usage: $0 <lot_display_id> [platform]  OR  $0 --search <term> [platform] [limit]  OR  $0 --list [platform] [page] [size]}"
PLATFORM="${2:-TWK}"

# Exponential backoff (1s→2s→4s→8s, max 4 retries)
MAX_RETRIES=4
RETRY=0
DELAY=1

# Query lotDetails — returns full Lot type with premium, markup, condition, insolvency
while [ $RETRY -lt $MAX_RETRIES ]; do
  RESPONSE=$(curl -s -w "\n%{http_code}" \
    -X POST "$GRAPHQL_URL" \
    -H "Content-Type: application/json" \
    -H "Accept: application/json" \
    -d '{"query": "query { lotDetails(displayId: \"'"${LOT_ID}"'\", locale: \"en\", platform: '"$PLATFORM"') { lot { displayId title currentBidAmount { cents currency } bidsCount buyerPremiumPercentage markupPercentage endDate condition insolvency location { city countryCode postalCode } saleTerm minimumBidAmountMet initialAmount { cents currency } categoryInformation { categoryLevel1 categoryLevel2 categoryLevel3 } } } }"}' \
    --connect-timeout 10 \
    --max-time 30 2>/dev/null || echo -e "\n000")

  HTTP_CODE=$(echo "$RESPONSE" | tail -1)
  BODY=$(echo "$RESPONSE" | sed '$d')

  if [ "$HTTP_CODE" = "200" ]; then
    # Check if response has data
    if echo "$BODY" | jq -e '.data.lotDetails.lot' >/dev/null 2>&1; then
      # Format output — convert cents to EUR, normalize fields
      # Field names aligned to contracts.md LOT schema
      echo "$BODY" | jq '{
        id: .data.lotDetails.lot.displayId,
        title: (.data.lotDetails.lot.title | gsub("\\r"; "")),
        price: (if .data.lotDetails.lot.currentBidAmount then (.data.lotDetails.lot.currentBidAmount.cents / 100) else (.data.lotDetails.lot.initialAmount.cents / 100) end),
        currency: (.data.lotDetails.lot.currentBidAmount.currency // .data.lotDetails.lot.initialAmount.currency // "EUR"),
        bid_count: (.data.lotDetails.lot.bidsCount // 0),
        buyer_premium_pct: (.data.lotDetails.lot.buyerPremiumPercentage // "0" | tonumber),
        markup_pct: (.data.lotDetails.lot.markupPercentage // "0" | tonumber),
        condition: .data.lotDetails.lot.condition,
        insolvency: .data.lotDetails.lot.insolvency,
        sale_term: .data.lotDetails.lot.saleTerm,
        reserve_met: .data.lotDetails.lot.minimumBidAmountMet,
        deadline: .data.lotDetails.lot.endDate,
        starting_price: ((.data.lotDetails.lot.initialAmount.cents // null) / 100),
        location: .data.lotDetails.lot.location.countryCode,
        location_city: .data.lotDetails.lot.location.city,
        location_postal: .data.lotDetails.lot.location.postalCode,
        category_l1: .data.lotDetails.lot.categoryInformation.categoryLevel1,
        category_l2: .data.lotDetails.lot.categoryInformation.categoryLevel2,
        category_l3: .data.lotDetails.lot.categoryInformation.categoryLevel3,
        price_source: "PLATFORM_LIVE",
        price_captured_at: (now | strftime("%Y-%m-%dT%H:%M:%SZ")),
        platform: "'"$PLATFORM"'"
      }'
      exit 0
    else
      echo '{"error": "Lot not found", "lot_id": "'"${LOT_ID}"'", "platform": "'"$PLATFORM"'", "response": '"$BODY"'}' >&2
      exit 1
    fi
  fi

  RETRY=$((RETRY + 1))
  if [ $RETRY -lt $MAX_RETRIES ]; then
    sleep $DELAY
    DELAY=$((DELAY * 2))
  fi
done

echo '{"error": "API request failed after '"$MAX_RETRIES"' retries", "http_code": "'"$HTTP_CODE"'", "lot_id": "'"${LOT_ID}"'", "platform": "'"$PLATFORM"'"}' >&2
exit 1
