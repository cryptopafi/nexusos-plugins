# D1 — Single Skill Integration Test

## Objective
Verify that each scout skill can be invoked independently and returns valid output conforming to contracts.md.

## Test Cases

### T1: scout-source standalone
1. Invoke scout-source with `{ "category": "restaurant-equipment", "region": "NL" }`
2. Verify output has `lots` array, `channels_searched` > 0
3. Each LOT has: id, platform, title, price > 0, url, location
4. No duplicate lot IDs in response

### T2: scout-dest standalone
1. Create mock LOT: `{ "id": "test-1", "title": "Espressor La Marzocco Linea Mini", "category": "restaurant-equipment" }`
2. Invoke scout-dest with `{ "lots": [mock_lot] }`
3. Verify output has `comparables` array
4. Each COMPARABLE has: platform, title, price > 0, similarity_score 0-1

### T3: scout-logistics standalone
1. Invoke scout-logistics with `{ "from": "NL", "to": "RO", "category": "restaurant-equipment" }`
2. Verify output has `routes` array with 1 ROUTE
3. ROUTE has: distance_km > 0, cost_eur > 0, vehicle_type, estimated_days > 0

### T4: analyzer standalone
1. Create mock merged record with LOT + 2 COMPARABLEs + ROUTE
2. Invoke analyzer with `{ "records": [mock], "min_margin": 30 }`
3. Verify output has `deals` array
4. Each DEAL has: landed_cost.total > 0, roi_pct (number), risk_score 0-10, verdict

## Pass Criteria
All 4 test cases return valid JSON conforming to contracts.md schemas.
