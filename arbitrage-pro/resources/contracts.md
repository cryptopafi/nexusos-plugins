# Contracts — Canonical JSON Schemas

All skill I/O must conform to these schemas. When adding new skills, define their contract here first.

---

## LOT (scout-source output)

A single auction lot found on a platform.

```json
{
  "id": "string — platform-specific lot ID (e.g., A1-44017-27)",
  "platform": "string — TWK | SPX | BVA | VAVATO | AUK | EPIC | catawiki | netbid | euro-auctions | bidspotter",
  "category": "string — normalized category",
  "title": "string — lot title (original language, \r stripped)",
  "price": "number|null — current bid or starting price in EUR. null if no price available.",
  "currency": "EUR | GBP | USD | SEK",
  "location": "string — ISO 3166-1 alpha-2 lowercase country code (nl, de, fr, etc.)",
  "location_city": "string|null — city name",
  "location_postal": "string|null — postal code",
  "condition": "NOT_APPLICABLE | NOT_CHECKED | GOOD | FAIR | POOR",
  "deadline": "number — Unix timestamp (integer seconds since epoch) when auction closes. From GraphQL endDate field.",
  "url": "string — direct link to lot page",
  "images": ["string — image URLs"],
  "description_raw": "string — original description text",
  "buyer_premium_pct": "number — buyer's premium percentage (8-23%, VARIABLE per lot from GraphQL)",
  "markup_pct": "number|null — markup percentage from GraphQL (often same as buyer_premium_pct)",
  "bid_count": "number|null — number of bids (from GraphQL, low = less competition)",
  "insolvency": "boolean — true if closure/insolvency auction (best deals, low competition)",
  "sale_term": "string|null — GUARANTEED_SALE | OPEN_RESERVE_PRICE_NOT_ACHIEVED | OPEN_RESERVE_PRICE_ACHIEVED | OPEN_ALLOCATION_SET",
  "reserve_met": "string|null — NO_MINIMUM_BID_AMOUNT | MINIMUM_BID_AMOUNT_NOT_MET | MINIMUM_BID_AMOUNT_MET",
  "auction_type": "string|null — closure | insolvency | regular | unknown (derived from insolvency boolean + sale_term)",
  "starting_price": "number|null — initial/starting price in EUR (before any bids)",
  "category_l1": "string|null — TBAuctions category UUID level 1",
  "category_l2": "string|null — TBAuctions category UUID level 2",
  "category_l3": "string|null — TBAuctions category UUID level 3",
  "price_source": "string — PLATFORM_LIVE | ESTIMATED | UNKNOWN",
  "price_captured_at": "string — ISO 8601 timestamp when price was extracted",
  "price_stale": "boolean — true if price_captured_at > 24h ago (set by analyzer)"
}
```

### LOT_WITH_LCS (lot-verifier output)

Extends LOT with verification data.

```json
{
  "...LOT fields...": "...",
  "lcs": "number 0.0–1.0 — Lot Confidence Score composite",
  "url_status": "LIVE | REDIRECT | NOT_FOUND | BLOCKED | TIMEOUT | NO_URL",
  "completeness_score": "number 0.0–1.0 — data field completeness",
  "freshness": "ACTIVE | FAR_FUTURE | UNKNOWN | EXPIRED",
  "price_source": "PLATFORM_LIVE | SONAR_ESTIMATE | USER_INPUT | UNKNOWN",
  "confidence": "VERIFIED | PARTIAL — maps from LCS threshold (>=0.7 / 0.4-0.69)"
}
```

**Standard categories**: restaurant-equipment, office-furniture, electronics, industrial, vehicles, collectibles, construction, medical, agricultural, woodworking, metalworking

---

## COMPARABLE (scout-dest output)

A matching or similar item found on a resale marketplace.

```json
{
  "platform": "olx | ebay | marktplaats | kleinanzeigen | vinted | facebook",
  "title": "string",
  "price": "number",
  "currency": "EUR | RON | GBP | PLN",
  "status": "active | sold",
  "url": "string",
  "similarity_score": "number 0.0–1.0 — how closely this matches the lot",
  "days_listed": "number | null — days since listing (if available)",
  "location": "string — country or city"
}
```

---

## ROUTE (scout-logistics output)

Transport cost estimate for a specific route.

```json
{
  "from": "string — ISO country code",
  "to": "string — ISO country code",
  "distance_km": "number",
  "cost_eur": "number — total estimated transport cost",
  "vehicle_type": "pallet_groupage | courier_light | courier_heavy | bulk",
  "estimated_days": "number — business days",
  "source": "static-table | trans-eu | timocom | cargopedia"
}
```

---

## SIGNAL (scout-signals output)

A market intelligence signal indicating a potential opportunity.

```json
{
  "type": "fuel-price | fx-rate | commodity | trend | news | economic-indicator",
  "name": "string — e.g., 'EUR/RON', 'Brent crude', 'espresso machine'",
  "value": "number — current value",
  "change_pct": "number — percentage change vs previous period",
  "direction": "up | down | stable",
  "period": "string — comparison period, e.g., '7d', '30d'",
  "affected_categories": ["string — product categories impacted"],
  "confidence": "number 0.0–1.0",
  "source": "string — data source name",
  "timestamp": "string — ISO 8601"
}
```

---

## DEMAND (scout-demand output)

A buyer purchase request found on a WTB platform.

```json
{
  "platform": "kros | publi24 | alibaba-rfq | facebook-groups",
  "title": "string — what the buyer wants",
  "category": "string — normalized category",
  "budget_max": "number | null — maximum budget in currency",
  "currency": "EUR | RON",
  "location": "string — buyer location",
  "url": "string — link to the request",
  "posted_date": "string — ISO 8601",
  "description": "string — full request text"
}
```

---

## OPPORTUNITY (opportunity-engine output)

An identified arbitrage opportunity based on signals, lots, or demands.

```json
{
  "category": "string — product category to target",
  "trigger_type": "signal | new-lot | demand-match",
  "trigger_ref": "string — reference ID (signal name, lot ID, or demand ID)",
  "confidence": "number 0.0–1.0",
  "priority": "HIGH | MEDIUM | LOW",
  "action": "HUNT | WATCH | SKIP",
  "reasoning": "string — why this is an opportunity"
}
```

---

## DEAL (analyzer output)

Complete profitability analysis for a specific lot.

```json
{
  "lot": "LOT object",
  "comparables": ["COMPARABLE objects"],
  "route": "ROUTE object",
  "landed_cost": {
    "buy_price": "number",
    "buyers_premium": "number",
    "transport": "number",
    "vat": "number",
    "platform_fee": "number",
    "handling": "number",
    "total": "number"
  },
  "sell_price": "number — median of comparables (similarity-weighted)",
  "net_profit": "number — sell_price - landed_cost.total",
  "roi_pct": "number — net_profit / landed_cost.total × 100",
  "risk_score": "number 0–10",
  "deal_score": "number — roi_pct × (1 - risk_score/20) × confidence",
  "confidence": "number 0.0–1.0 — min(source_freshness, dest_confidence, logistics_confidence)",
  "dcs": "number 0–10 — Deal Confidence Score (6 dimensions × 0-2, raw 0-12, normalized 0-10)",
  "confidence_level": "HIGH_CONFIDENCE | MEDIUM_CONFIDENCE | LOW_CONFIDENCE — maps from DCS (>=7 / 4-6 / <4)",
  "price_source": "PLATFORM_LIVE | SONAR_ESTIMATE | USER_INPUT | UNKNOWN — how buy price was obtained",
  "verdict": "BUY | WATCH | SKIP",
  "reasoning": "string — why this verdict"
}
```

**Verdict thresholds**:
- deal_score > 40 → BUY
- deal_score 15–40 → WATCH
- deal_score < 15 → SKIP

**Minimum ROI filter**: deals with roi_pct < 30% are excluded from reports (configurable via --min-margin).
