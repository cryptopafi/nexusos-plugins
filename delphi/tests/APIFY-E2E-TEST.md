# Apify E2E Test Report — DELPHI PRO Actors

**Date:** 2026-03-20
**Account:** vigorous_yolk (FREE plan, $5/mo credits)
**Total test cost:** $0.41 of $1.00 budget

---

## Test Results Summary

| # | Actor | Run Status | Duration | Cost | Results | Data Quality | Verdict |
|---|-------|-----------|----------|------|---------|--------------|---------|
| 1 | `apify/hello-world` | SUCCEEDED | 1.8s | $0.0001 | 0 items (expected) | N/A — smoke test | **PASS** |
| 2 | `apify/instagram-scraper` | SUCCEEDED | 4.9s | $0.0027 | 0 items | Empty — uses Google to find IG tags, returns "no_items" error | **FAIL** |
| 3 | `quacker/twitter-scraper` | SUCCEEDED | 2.2s | $0.0000 | 0 items | Dead — Twitter blocked public scraping June 2023 | **FAIL** |
| 4 | `apidojo/tweet-scraper` | SUCCEEDED | ~3s | **$0.4000** | 0 items (noResults) | REQUIRES PAID PLAN — free tier cannot use X/Twitter API | **FAIL** |
| 5 | `apify/google-search-scraper` | SUCCEEDED | 5.6s | $0.0055 | 8 organic results | Excellent — titles, URLs, descriptions, related queries | **PASS** |

---

## Detailed Results

### 1. apify/hello-world (Smoke Test)
- **Purpose:** Verify API key works
- **Result:** SUCCEEDED, $0.0001 cost
- **Verdict:** PASS — API key is valid, free tier is active

### 2. apify/instagram-scraper (scout-visual)
- **Input:** `{"search": "AI marketing", "resultsLimit": 3, "searchType": "hashtag"}`
- **Result:** 0 useful items. Returns `{"error": "no_items", "errorDescription": "Empty or private data for provided input"}`
- **Root cause:** Actor uses Google search (`site:instagram.com/explore/tags/*`) as a proxy — found 0 results
- **Verdict:** FAIL — unreliable for hashtag search. Does NOT actually scrape Instagram directly. Requires login/cookies for real scraping.
- **Recommendation:** DROP from DELPHI PRO or provide Instagram session cookies

### 3. quacker/twitter-scraper (scout-social fallback)
- **Input:** `{"searchTerms": ["AI agents 2026"], "maxTweets": 3}`
- **Result:** 0 items, 0 requests processed
- **Root cause:** Twitter/X put all content behind login on June 30, 2023. Public scraping is impossible.
- **Log message:** "On 30 June 2023, Twitter put all content behind login... scraping publicly available Twitter content is no longer possible"
- **Verdict:** FAIL — completely dead actor
- **Recommendation:** DROP immediately

### 4. apidojo/tweet-scraper V2 (scout-social)
- **Input:** `{"searchTerms": ["AI agents 2026"], "maxItems": 3}`
- **Result:** `{"noResults": true}` x5 items
- **Root cause:** Requires paid Apify plan to access X/Twitter API
- **Log:** "You cannot use the API with the Free Plan. Please subscribe to a paid plan on Apify."
- **Cost:** $0.40 for ZERO useful data — this is a pay-per-result actor with a $0.40 minimum
- **Verdict:** FAIL — too expensive, doesn't work on free tier
- **Recommendation:** DROP — $0.40/run with 3 tweets is absurdly expensive

### 5. apify/google-search-scraper (scout-web fallback)
- **Input:** `{"queries": "AI marketing automation tools 2026", "maxPagesPerQuery": 1, "resultsPerPage": 5}`
- **Result:** 8 organic results with full metadata
- **Data quality:** Excellent
  - Titles, URLs, descriptions for all 8 results
  - 16 related queries included
  - Proper search result structure
- **Cost:** $0.0055 per query — very reasonable
- **Verdict:** PASS — reliable, cheap, high quality
- **Recommendation:** KEEP as primary web search fallback

---

## Actor Not Found

| Actor ID | Status |
|----------|--------|
| `apify/twitter-scraper` | **NOT FOUND** — does not exist on Apify |
| `apify/x-scraper` | **NOT FOUND** |
| `nfp/google-search-scraper` | **NOT FOUND** |

---

## Budget Summary

| Item | Cost |
|------|------|
| hello-world smoke test | $0.0001 |
| instagram-scraper | $0.0027 |
| quacker/twitter-scraper | $0.0000 |
| apidojo/tweet-scraper | $0.4000 |
| apify/google-search-scraper | $0.0055 |
| **Total this session** | **$0.41** |
| **Remaining credits (approx)** | **$4.59 / $5.00** |

---

## Recommendations for DELPHI PRO

### KEEP
- **`apify/google-search-scraper`** — $0.005/query, excellent results, reliable. Use as `scout-web` fallback.

### DROP
- **`apify/instagram-scraper`** — Returns nothing without login cookies. Useless for hashtag discovery.
- **`quacker/twitter-scraper`** — Dead since June 2023. Twitter blocks all public scraping.
- **`apidojo/tweet-scraper`** — $0.40 minimum, requires paid plan, returns nothing on free tier.
- **`apify/twitter-scraper`** — Actor does not exist.

### Alternatives to Investigate
- For Twitter/X: Use Tavily search with `site:x.com` filter, or Exa search with Twitter category
- For Instagram: Use direct web scraping with cookies, or switch to TikTok (`clockworks/tiktok-scraper` — very popular on Apify)
- For social signals: Consider `web.harvester/easy-twitter-search-scraper` (mentioned in quacker logs as alternative)

### Cost Projections (Google Search Scraper only)
| Usage | Monthly Cost |
|-------|-------------|
| 10 queries/day | ~$1.65/mo |
| 50 queries/day | ~$8.25/mo (exceeds free tier) |
| 5 queries/day | ~$0.83/mo (safe for free tier) |

---

## Configuration Notes

- **API Key:** Stored in `~/.nexus/.env` as `APIFY_API_KEY`
- **Account:** FREE plan ($5/mo credits)
- **Rate limits:** Free plan has concurrent run limits
- **Proxy:** BUYPROXIES94952 group available (5 proxies)
