# D2 — Full Pipeline Integration Test

## Objective
Verify end-to-end `/hunt` flow: command → orchestrator → scouts → analyzer → reporter → distribute.

## Test Case: `/hunt espresoare --region NL,DE,RO`

### Steps
1. Invoke `/hunt espresoare --region NL,DE,RO --min-margin 30 --limit 5`
2. Verify orchestrator parses: category="restaurant-equipment", region=["NL","DE","RO"], min_margin=30, limit=5
3. Verify scout-source is dispatched and returns lots
4. Verify scout-dest is dispatched for each lot and returns comparables
5. Verify scout-logistics is dispatched and returns routes
6. Verify analyzer produces DEAL objects with profitability calculations
7. Verify reporter generates HTML file at /tmp/arbitrage-*.html
8. Verify HTML is deployed to VPS: `curl -s -o /dev/null -w "%{http_code}" http://89.116.229.189/nexus/arbitrage-*.html` returns 200
9. Verify Cortex entry created: `cortex_search("arbitrage espresoare")` returns results
10. Verify state/lots-seen.json updated with processed lot IDs
11. Verify state/deals.json updated with analyzed deals

### Pass Criteria
- HTML report accessible on VPS
- At least 1 deal in report (or "no deals found" message if no lots match)
- All state files updated
- Cortex entry stored
- Summary shown to user with VPS link
