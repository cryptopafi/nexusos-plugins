# Arbitrage Pro — MVP Lessons Learned
# Errors encountered during E2E testing (2026-03-21)
# Each error includes: what happened, root cause, and preventive fix

## E1: Apify Credits Exhausted Mid-Test
- **What**: `Monthly usage hard limit exceeded` — all Apify calls failed
- **Root cause**: Used cloud Playwright (Apify) when local Playwright (agent-browser) was available and FREE
- **Prevention**: agent-browser is PRIMARY extraction tool. Apify removed from W1 pipeline. Scripts should check agent-browser availability first, never depend on cloud credits.
- **Fix applied**: channel-config.yaml updated — `extraction_method: agent-browser`

## E2: Playwright CSS Selectors Miss Troostwijk Prices
- **What**: `playwright-scrape-lot.sh` returned `current_bid: null` on all lots
- **Root cause**: Generic selectors (`[data-bid-amount]`, `.bid-amount`, `[class*="current-bid"]`) don't match Troostwijk's actual DOM. Troostwijk renders prices as plain text inside generic divs.
- **Prevention**: Use JS text extraction (regex on `document.body.innerText`) instead of CSS selectors. Tested pattern: `€\s*[\d.,]+` captures all price elements reliably.
- **Fix applied**: scout-source/SKILL.md updated with working `agent-browser eval` JS pattern

## E3: Sonar Pro Cannot Extract JS-Rendered Prices
- **What**: Sonar Pro returned lot URLs but `"current_bid_price": "Not visible"` for all lots
- **Root cause**: Sonar Pro queries a search index, not live pages. Troostwijk renders bid prices client-side via JavaScript — invisible to any search-based tool.
- **Prevention**: NEVER rely on Sonar Pro for bid prices. Sonar = discovery only (URLs + titles). agent-browser = price extraction. This is documented in scout-source/SKILL.md Phase 1 vs Phase 2.

## E4: Troostwijk Category Page Returns 500 Error
- **What**: `https://www.troostwijkauctions.com/en/c/catering/espresso-machines/41` → 500 error page
- **Root cause**: Troostwijk category URLs are unstable — IDs change, pages go offline
- **Prevention**: Use search (`/en/auctions` + search bar) instead of direct category URLs. Search is always available and returns 81+ results. Add retry logic: if page returns 500/error, try search fallback.

## E5: Cookie Banners Block Page Content
- **What**: Troostwijk and eBay.de show consent banners that overlay content, making extraction return empty/incomplete
- **Root cause**: GDPR consent banners must be dismissed before DOM is fully accessible
- **Prevention**: First visit to any domain must include cookie acceptance step:
  1. `agent-browser snapshot -i | grep -i "accept.*cookie"`
  2. Click accept button
  3. Cookie persists for session — subsequent lots skip this step
- **Fix applied**: channel-config.yaml includes `cookie_accept` button text per platform

## E6: OLX Search for Niche Brands Returns No Results
- **What**: Searching "espressor profesional Spinel" on OLX → zero relevant results (returned apartments, helmets, goats)
- **Root cause**: Spinel is too niche for Romanian market. OLX search defaults to "latest listings" when no matches found.
- **Prevention**: Implement BROADER SEARCH strategy:
  1. First try: exact brand + model ("Spinel Tre Lux")
  2. If <3 results: category + type ("espressor profesional 3 grupuri")
  3. If <3 results: generic category ("espressor profesional")
  4. Score results by similarity to lot title (word overlap)

## E7: eBay.de Sold Returns Parts, Not Complete Machines
- **What**: eBay.de "Faema Smart espresso machine" sold → returned boilers, gaskets, gauges, not machines
- **Root cause**: eBay.de has smaller inventory for commercial espresso machines. Many listings are spare parts with brand name in title.
- **Prevention**: Use eBay.com (via Exa) for broader international inventory. Filter results: exclude items with "parts", "gasket", "pump", "motor", "Ersatzteil" in title. Or add `LH_ItemCondition=3000` (used) to URL.

## E8: Sell Price Estimation Without Comps Is Wrong
- **What**: Used `buy_price * 3 * 0.85` as estimate when no comps found → €255 sell price for a 3-group commercial espresso machine worth €1,500+
- **Root cause**: Arbitrary multiplier doesn't account for item category or market value
- **Prevention**: When no direct comps found:
  1. Do NOT estimate from buy price — they're unrelated
  2. Search broader (see E6)
  3. If still no comps: mark sell_price as NULL, confidence as NONE
  4. Analyzer should flag as "UNVERIFIED — manual price check required"

## E9: Zsh Array Syntax Breaks Bash Heredocs
- **What**: `LOTS=( ... ); for i in "${!LOTS[@]}"` → `bad substitution` error
- **Root cause**: MacOS zsh doesn't support `${!array[@]}` (bash-only indirect expansion)
- **Prevention**: Use simple sequential commands or Python scripts for multi-lot processing. Avoid bash arrays in pipeline scripts. All scripts should use `#!/usr/bin/env bash` with explicit `set -euo pipefail`.

## E10: page.waitForLoadState Timeout on Troostwijk
- **What**: `page.waitForLoadState: Timeout 25000ms exceeded` on Spinel lot page
- **Root cause**: Troostwijk pages load slowly (multiple API calls, analytics, images). Default 25s timeout is sometimes insufficient.
- **Prevention**: Don't rely on `networkidle`. Use explicit wait: `agent-browser wait 5000` after open. If eval fails, retry once after additional 3s wait. Working pattern:
  ```
  agent-browser open URL
  agent-browser wait 5000
  agent-browser eval ...
  ```

## E11: Exa Output Too Large (81KB)
- **What**: Exa eBay search returned 81,947 characters → saved to file instead of inline
- **Root cause**: `numResults: 5` with full text content + highlights = very large response
- **Prevention**: Add `textMaxCharacters: 500` to Exa queries. Use `enableHighlights: true` with `highlightsPerUrl: 1` + `highlightsNumSentences: 2` to keep responses compact. Parse highlights for prices instead of full text.

## E12: Brave Search Quota Exhausted (2000 req/month)
- **What**: All 3 parallel Brave Search queries failed with 429 — `quota_current: 2001`
- **Root cause**: Free plan has 2000 requests/month, already consumed by other tools
- **Prevention**: Brave Search is supplementary, not primary. Track usage. Consider paid plan ($5/month for 10K requests) if usage grows. For now, Exa is primary for discovery.

---

## Summary: Error Prevention Rules for MVP Build

1. **agent-browser FIRST** — local Playwright is free, reliable, and extracts JS content. Cloud APIs are fallback only.
2. **Text regex > CSS selectors** — auction sites have unstable DOMs. `€\s*[\d.,]+` is more robust than `.bid-amount`.
3. **Cookie handling is mandatory** — first visit to any domain needs consent acceptance.
4. **Broader search before giving up** — brand → category → generic, with similarity scoring.
5. **Never estimate sell price from buy price** — they're independent. No comps = NULL, not a guess.
6. **Explicit waits > networkidle** — `wait 5000` is more reliable than `waitForLoadState`.
7. **Limit Exa output** — `textMaxCharacters: 500`, `highlightsPerUrl: 1`.
8. **Use bash, not zsh** — all scripts must have `#!/usr/bin/env bash`.
9. **Search URL > category URL** — search is always available, categories may 500.
10. **eBay.com > eBay.de** — for sold commercial equipment, .com has 10x inventory.
