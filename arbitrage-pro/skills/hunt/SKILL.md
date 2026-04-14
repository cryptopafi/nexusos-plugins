---
name: hunt
description: |
  Hunt for profitable reselling deals at European auctions. Use when user says '/hunt', 'hunt deals', 'find bargains', 'search auctions', or wants to find items to resell. Do NOT use for market intelligence scans (use /market-scan) or when user just wants price info without deal analysis.
model: claude-sonnet-4-6
tools: [Read, Write, Bash, Agent, Glob, Grep, mcp__cortex__cortex_search, mcp__cortex__cortex_store, mcp__brave-search__brave_web_search]
---

# /hunt — Deal Hunter Entry Skill

## What You Do

Entry point for the Arbitrage Pro deal hunting pipeline. Parse user intent, then delegate to the orchestrator (`agents/arbitrage.md`) which coordinates the 10-step pipeline + Karpathy Loop: scout-source → scout-dest → scout-logistics → merge → analyzer → quality gate → reporter → distribute → karpathy logging.

## What You Do NOT Do

- Execute scouts directly (the orchestrator dispatches them)
- Market intelligence analysis (use /market-scan)
- Manual price lookups without full profitability analysis

## CRITICAL — Data Integrity (NEVER violate)
- As orchestrator: ensure ALL downstream skills follow their Data Integrity rules. If any skill returns UNKNOWN or null prices, propagate that — do NOT fill in values.
- Final report MUST show confidence level per deal. If data quality is degraded, say so explicitly.
- Apply sell_price_discount (0.15) at analyzer level. NEVER present listed prices as expected revenue.

## Operating Modes

### Mode A: ASSISTED (MVP default)
Most auction platforms require login to see bid prices. In this mode:
1. scout-source discovers lots + lot-verifier confirms existence
2. Pipeline PAUSES and presents verified lots to user
3. User provides buy prices (what they see on the platform after login)
4. Pipeline resumes: scout-dest → analyzer → reporter

### Mode B: AUTONOMOUS (default — GraphQL API + agent-browser)
Uses GraphQL API (`storefront.tbauctions.com/storefront/graphql`) for TBAuctions lots and `agent-browser` for other platforms. Zero cost, instant.
1. Full pipeline runs without user intervention
2. GraphQL extracts: real bid price, bid count, premium %, status, closing time
3. agent-browser fallback for non-TBAuctions platforms (Catawiki, Euro Auctions)
4. Does NOT require API keys or platform credentials

### Mode C: MANUAL INPUT
User provides lots directly:
`/hunt --lots "La Cimbali M34, €500, NL" "Franke Spectra, €400, NL"`
Pipeline skips scout-source, goes directly to scout-dest.

## Input

From user command: `/hunt [category] [--region XX,YY] [--min-margin N] [--limit N]`
Alternative: `/hunt --lots "title, €price, country" [...]` (Mode C)

## Input Validation

- `category`: any string, case-insensitive. Map common terms to standard categories:
  - "espresoare", "coffee machines" → "restaurant-equipment"
  - "mobilier", "furniture", "desks" → "office-furniture"
  - "laptopuri", "electronics" → "electronics"
  - "mașini", "cars", "vehicles" → "vehicles"
  - If unrecognized, pass as-is (scouts will search with the raw term)
- `--region`: validate as ISO 3166-1 alpha-2 country codes. Default: all regions.
- `--min-margin`: integer 0-100. Default: 30.
- `--limit`: integer 1-50. Default: 10.

## Execution

1. Parse and validate user input
1b. **Read `state/category-intelligence.yaml`** — check if requested category has prior data:
   - If category is `tier_4_unprofitable` → WARN user: "⚠️ [category] has been tested and showed [avg_roi]% ROI. Reason: [reason]. Continue anyway? (y/n)"
   - If category is `tier_1_profitable` → inform: "✅ [category] is a proven winner (avg [roi]% ROI across [runs] runs)"
   - If category has `key_rule` (e.g., espresso: "BUY only at closure auctions") → display the rule
   - If category is `untested` → proceed normally, note "first run — no prior data"
1c. **If no category specified** → auto-select from tier_1 priority order: compressors-industrial → welding-branded → generators → espresso-closure (I4: pallet categories first)
1d. **Add closure/insolvency filter** (I7): append to search query: prefer lots from auctions containing "faillissement", "sluiting", "closure", "insolvency", "liquidation"
1e. **Apply sub-segment filters from category-intelligence** (I11):
   - `compressors` → search "screw compressor", "Atlas Copco", "Kaeser", "CompAir", "Boge", "schroefcompressor". SKIP results matching consumer patterns (24L, 50L, 100L portable).
   - `welding` → search "Kemppi", "Fronius", "ESAB", "Lincoln", "Miller", "Cloos". SKIP results matching generic patterns (RTE, Stahlfest, F Tools, HyperWelding).
   - If `key_rule` exists for the category → apply it as a pre-filter before scout-source.
2. Determine operating mode:
   - If `--lots` flag present → Mode C (skip to step 5)
   - GraphQL API available (default) → Mode B (autonomous) — uses GraphQL for TBAuctions + agent-browser for others
   - If ATLAS_API_KEY available → Mode B (premium) — uses TBAuctions ATLAS API
   - Otherwise → Mode A (assisted, user provides buy prices)
3. Read `resources/model-config.yaml` for model routing
4. Delegate to orchestrator:
   ```
   { command: "hunt", mode: "assisted|autonomous|manual", category, region, min_margin, limit, lots_override: [...] }
   ```
5. **Mode A flow:**
   - Orchestrator runs scout-source → lot-verifier
   - Returns verified lots to user with details (title, platform, location, URL)
   - ASKS user for buy prices: "I found these lots. What are the current bid prices?"
   - User provides prices → orchestrator resumes with scout-dest → analyzer → reporter
6. **Mode B/C flow:** Full pipeline runs, returns results directly
7. Present the VPS report link to user
8. **Karpathy Loop**: Orchestrator runs Step 10.5 (MANDATORY — never skip). Logs run metrics to state files.

## Output

Clickable VPS URL to the HTML deal report + brief summary in chat:
- Number of lots scanned
- Number of deals found above threshold
- Top deal highlight (title, ROI%, verdict)

Schema references: LOT, COMPARABLE, DEAL — see `resources/contracts.md` for all field definitions.

## Common Mistakes (NEVER do this)
- WRONG: Running the full pipeline without checking operating mode first. Always determine A/B/C before dispatching.
- WRONG: Presenting deals without confidence level. Every deal MUST show HIGH/MEDIUM/LOW confidence.

## Error Handling

- No lots found → suggest broader category or different region
- API failures → report which sources were unavailable, proceed with available data
- All scouts fail → report error, suggest retry later
