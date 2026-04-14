# Arbitrage Pro — Stress Test Plan v1.0

## Obiectiv
Validare end-to-end a MVP-ului Arbitrage Pro prin 10 test cases care acoperă:
- Toate categoriile de produse
- Toate regiunile sursă
- Happy path + edge cases + error handling
- Pipeline complet (signal → opportunity → hunt → deal → report)

## Metrici Baseline (colectate per test)

| Metric | Descriere |
|--------|-----------|
| `lots_found` | Loturi găsite de scout-source |
| `comparables_found` | Comparabile găsite de scout-dest |
| `routes_calculated` | Rute calculate de scout-logistics |
| `deals_above_threshold` | Deals cu ROI > min_margin |
| `avg_deal_score` | Media deal_score pe deals valide |
| `avg_roi_pct` | Media ROI% pe deals valide |
| `max_roi_pct` | ROI maxim găsit |
| `errors` | Erori întâlnite |
| `warnings` | Warnings (degraded sources, fallbacks) |
| `execution_time_s` | Timp total execuție |

---

## Test Matrix (10 Cases)

### T1: Espresso Machine Hunt (Leo's Use Case)
- **Type**: Happy path
- **Command**: `/hunt espresoare --region NL,DE --min-margin 30`
- **Category**: restaurant-equipment
- **Source**: Troostwijk (NL)
- **Dest**: OLX.ro, eBay.de
- **Transport**: NL→RO (van-3.5t, 2100km, €2310 est.)
- **Expected**: Espresso machines bought at €200-600 → sell at €800-2000 pe OLX
- **Validates**: Full pipeline, Romanian characters in search, category mapping
- **Pass criteria**: ≥1 deal with ROI >30%, correct landed cost calc

### T2: CNC Lathe Industrial
- **Type**: Happy path
- **Command**: `/hunt CNC lathe --region DE --min-margin 40`
- **Category**: industrial
- **Source**: Troostwijk, Surplex (DE)
- **Dest**: OLX.ro, eBay.de
- **Transport**: DE→RO (truck-24t, 1600km, €2240 est.)
- **Expected**: High-value machinery, fewer results, higher margins
- **Validates**: truck-24t rate, high capital risk scoring, industrial category
- **Pass criteria**: Correct vehicle type selection (truck-24t), risk_score reflects high capital

### T3: Office Chair Bulk — Multi-Destination
- **Type**: Happy path + multi-dest
- **Command**: `/hunt office chairs --region BE --min-margin 25`
- **Category**: office-furniture
- **Dest markets**: RO + PL (two destinations)
- **Transport**: BE→RO (van, 2200km, €2860), BE→PL (van, ~1000km est.)
- **Expected**: Herman Miller/Steelcase chairs at 10-20% of retail
- **Validates**: Multi-destination routing, comparison between RO and PL markets
- **Pass criteria**: Routes for both destinations, correct rate differentiation

### T4: Laptop Lot Electronics
- **Type**: Category coverage
- **Command**: `/hunt laptopuri --region FR --min-margin 20`
- **Category**: electronics
- **Source**: Catawiki (FR)
- **Dest**: OLX.ro
- **Transport**: FR→RO (express-courier, €15/parcel)
- **Expected**: Electronics use courier, not van/truck
- **Validates**: express-courier vehicle selection, electronics risk_score (7/10)
- **Pass criteria**: Vehicle=express-courier, risk reflects category volatility

### T5: Vehicle Hunt (B2B Gate Test)
- **Type**: Category coverage + partial failure
- **Command**: `/hunt vehicles --region NL --min-margin 15`
- **Category**: vehicles
- **Source**: Troostwijk (NL), OpenLane blocked (B2B gate)
- **Dest**: Autovit.ro, OLX.ro
- **Transport**: NL→RO (truck-24t, 2100km, €2940 est.)
- **Expected**: OpenLane unavailable → graceful degradation
- **Validates**: Error handling when channel unavailable, high handling cost (€100)
- **Pass criteria**: Pipeline completes without OpenLane, correct vehicle/handling

### T6: Market Scan Broad
- **Type**: Market scan — no filter
- **Command**: `/market-scan`
- **Expected behavior**:
  - scout-signals → empty (Wave 2, returns [])
  - scout-source → scans ALL enabled channels (Troostwijk + Catawiki)
  - Opportunity engine → scores all new lots
  - Top opportunities trigger lightweight price checks
- **Validates**: Full market-scan pipeline, all-category scan
- **Pass criteria**: Pipeline completes, returns opportunity list, no crashes

### T7: Market Scan Filtered — Fuel Signal
- **Type**: Market scan — filtered
- **Command**: `/market-scan fuel`
- **Expected behavior**:
  - scout-signals → empty at MVP (Wave 2)
  - Since no real signal: opportunity engine should explain "no fuel signals detected at MVP"
  - Graceful degradation message
- **Validates**: Filtered scan with unavailable data source, Wave 2 skill stub
- **Pass criteria**: Clear message about Wave 2 limitation, no error

### T8: Edge — No Results Category
- **Type**: Edge case
- **Command**: `/hunt submarine periscopes --region XX --min-margin 90`
- **Category**: unrecognized → passed as-is
- **Region**: XX → invalid ISO code
- **Expected**: 0 lots found, friendly "no deals found" message
- **Validates**: Input validation (bad region), empty result handling, reporter zero-deal mode
- **Pass criteria**: No crash, proper error messages, report shows "no deals"

### T9: Edge — Malformed Input
- **Type**: Edge case + error handling
- **Tests** (3 sub-tests):
  - `T9a`: `/hunt` (no category) → should scan all categories
  - `T9b`: `/hunt --min-margin -5` → should clamp to 0 or reject
  - `T9c`: `/hunt espresoare --limit 999` → should clamp to max 50
- **Validates**: Input validation, default values, boundary conditions
- **Pass criteria**: All sub-tests handle gracefully, no undefined behavior

### T10: Full Pipeline E2E — Signal → Opportunity → Hunt → Deal
- **Type**: End-to-end integration
- **Simulated flow**:
  1. Inject synthetic SIGNAL: `{type: "commodity", name: "copper", change_pct: +15, affected_categories: ["electronics"]}`
  2. Opportunity engine evaluates → should produce OPPORTUNITY for electronics
  3. Auto-trigger: `/hunt electronics --from-signals`
  4. Full pipeline: scout-source → scout-dest → scout-logistics → analyzer → reporter
  5. HTML report generated with signal context
- **Validates**: Signal-driven hunting, opportunity scoring, full pipeline
- **Pass criteria**: Opportunity generated from signal, hunt triggered, report includes signal context

---

## Execution Strategy

### Phase 1: Offline Validation (T2 partial, T3 partial, T8, T9)
Test analyzer math, transport calculations, input validation — no external API calls needed.
Use synthetic LOT/COMPARABLE/ROUTE data.

### Phase 2: Script Dry-Run
Test scout-source.sh and scout-dest-olx.sh error handling (missing API key, bad platform, timeout).

### Phase 3: Live Tests (T1, T4, T6)
If APIFY_API_KEY available: run real searches against Troostwijk/Catawiki/OLX.
If not: use Brave Search fallback for all source/dest lookups.

### Phase 4: Integration (T10)
Full pipeline with real or simulated data.

---

## Benchmark Output Format

```json
{
  "version": "1.0.0",
  "timestamp": "2026-03-21T...",
  "test_results": [
    {
      "id": "T1",
      "name": "Espresso Machine Hunt",
      "status": "PASS | FAIL | PARTIAL",
      "metrics": { ... },
      "errors": [],
      "warnings": [],
      "duration_ms": 0,
      "notes": ""
    }
  ],
  "summary": {
    "total": 10,
    "passed": 0,
    "failed": 0,
    "partial": 0,
    "avg_execution_time_ms": 0
  }
}
```
