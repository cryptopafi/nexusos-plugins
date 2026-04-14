# D3 — Error Flow Integration Test

## Objective
Verify graceful degradation when scouts fail, APIs are unavailable, or data is incomplete.

## Test Cases

### T1: Scout-source Apify failure
1. Set APIFY_API_KEY to invalid value
2. Run `/hunt electronics`
3. Verify: scout-source falls back to Brave search
4. Verify: pipeline continues with Brave results (or empty with warning)
5. Verify: on-error.sh logs the failure to state.json errors array

### T2: VPS unreachable
1. Block VPS connectivity (or test with wrong IP)
2. Run `/hunt office-furniture`
3. Verify: reporter saves HTML locally at /tmp/
4. Verify: user sees local path instead of VPS URL
5. Verify: warning message about VPS unreachable

### T3: Zero comparables
1. Search for obscure category with no OLX/eBay matches
2. Run `/hunt [obscure-item]`
3. Verify: analyzer flags low confidence (dest_price_confidence=0.3)
4. Verify: deals get SKIP verdict (insufficient comparable data)
5. Verify: report says "no profitable deals found" with methodology note

### T4: Invalid input
1. Run `/hunt --min-margin 200` (impossible margin)
2. Verify: graceful error message, not a crash
3. Run `/hunt --region ZZZZZ` (invalid country code)
4. Verify: graceful error message suggesting valid regions

### T5: State file corruption
1. Write invalid JSON to state/lots-seen.json
2. Run `/hunt`
3. Verify: store-cache detects corruption, backs up .bak, starts fresh
4. Verify: pipeline completes normally

## Pass Criteria
- No unhandled crashes in any test case
- Error messages are clear and actionable
- Pipeline degrades gracefully (partial results > no results > clear error)
- on-error.sh logs all failures
