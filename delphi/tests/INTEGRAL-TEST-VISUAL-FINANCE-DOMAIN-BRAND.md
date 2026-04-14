# DELPHI PRO Integral E2E Test Report
**Date:** 2026-03-20
**Scouts tested:** scout-visual, scout-finance, scout-domain, scout-brand

---

## 1. scout-visual

### 1.1 Instagram via Brave proxy
- **Command:** `mcp__brave-search__brave_web_search` with `site:instagram.com AI marketing` count:3
- **Result:** FAIL -- Brave API 429 (quota exceeded: 2001/2000)
- **Fallback:** Tavily search attempted with same query
- **Fallback Result:** FAIL -- Tavily API quota exceeded
- **Error:** Both search providers hit plan usage limits simultaneously
- **Verdict:** **FAIL (EXTERNAL)** -- not a code defect, both external APIs exhausted

### 1.2 Skool (ECHELON)
- **Status:** REFERENCE ONLY -- custom ECHELON procedure, not directly testable via MCP tools
- **Verdict:** **SKIP**

---

## 2. scout-finance

### 2.1 yfinance CLI (NVDA)
- **Command:** `yfinance-search.sh --symbol NVDA --info`
- **Output:** `/tmp/yf-integral.json`
- **Result:** PASS
- **Summary:** Returned NVDA info: NVIDIA Corporation, Technology/Semiconductors, marketCap $4.27T, previousClose $178.56, PE 35.94, beta 2.375, 52wk range $86.62-$212.19
- **Source tier:** T1
- **Verdict:** **PASS**

### 2.2 DexPaprika (Ethereum search)
- **Command:** `~/.nexus/cli-tools/dexpaprika search -o json` query "ethereum"
- **Result:** PASS
- **Summary:** Returned 10 tokens (ETH on BSC at $2,129.96, ETH on Solana, etc.) and 20 pools (PancakeSwap V3, Uniswap V3/V4 across BSC, Base, Ethereum). Top pool volume: $13.4M on PancakeSwap V3 BSC.
- **Verdict:** **PASS**

### 2.3 News finance (NVIDIA AI / Guardian)
- **Command:** `news-search.sh --topic "NVIDIA AI" --max 3 --source guardian`
- **Output:** `/tmp/news-finance.json`
- **Result:** PASS
- **Summary:** 3 articles returned from Guardian:
  1. "Nvidia CEO reveals new 'reasoning' AI tech for self-driving cars" (2026-01-06)
  2. "China blocks Nvidia H200 AI chips..." (2026-01-17)
  3. "Nvidia insists it isn't Enron..." (2025-12-28)
- **Source tier:** T1
- **Verdict:** **PASS**

---

## 3. scout-domain

### 3.1 Full analysis (anthropic.com)
- **Command:** `domain-search.sh --domain anthropic.com`
- **Output:** `/tmp/domain-integral.json`
- **Result:** PASS
- **Summary:** 6 channels queried (whois, dns, headers, ssl, sitemap, tech) in 10.7s. Key findings:
  - Registrar: MarkMonitor Inc., registered 2001, expires 2033
  - Registrant: Anthropic PBC (US)
  - CDN: Cloudflare, Email: Google Workspace
  - SSL: Let's Encrypt, valid until 2026-05-06
  - Security grade: C (HSTS present, CSP present)
  - Sitemap: 373 pages, sections: events, research, claude, news, legal
  - Tech: GTM, GA, Facebook Pixel, HubSpot, Webflow, Sanity CMS, Angular, jQuery
- **Verdict:** **PASS**

### 3.2 Tech mode (stripe.com)
- **Command:** `domain-search.sh --domain stripe.com --mode tech`
- **Output:** `/tmp/domain-tech.json`
- **Result:** PASS
- **Summary:** Tech-only mode returned 1 finding in 4.1s. Detected: Stripe, Contentful, React, Next.js, Angular, Shopify. Detection via CSP analysis + HTML inspection.
- **Verdict:** **PASS**

---

## 4. scout-brand

### 4.1 Availability (anthropic.com -- expect TAKEN)
- **Command:** `brand-search.sh --mode availability --domain anthropic.com`
- **Output:** `/tmp/brand-avail.json`
- **Result:** PARTIAL FAIL
- **Summary:** RDAP returned `available: null` with note `http_302`. The domain is registered (WHOIS confirms), but the availability check did not produce a definitive `false` result. The RDAP redirect was not followed properly.
- **Bug:** RDAP 302 redirect not handled -- should resolve to TAKEN for known registered domains
- **Verdict:** **FAIL (BUG)** -- availability should return `false` for anthropic.com

### 4.2 Availability (xyztest99887abc.com -- expect AVAILABLE)
- **Command:** `brand-search.sh --mode availability --domain xyztest99887abc.com`
- **Output:** (crashed, no JSON written)
- **Result:** FAIL
- **Error:** `AttributeError: 'dict' object has no attribute 'lower'` in `parse_available_section` at line 76
- **Bug:** NameSilo API response parsing fails when the `available` section returns a dict instead of a string. Type-check missing.
- **Verdict:** **FAIL (BUG)** -- crash on unregistered domain lookup

### 4.3 Suggest (TestBrandXYZ)
- **Command:** `brand-search.sh --mode suggest --brand "TestBrandXYZ" --tlds "com,io,ai"`
- **Output:** `/tmp/brand-suggest.json`
- **Result:** PASS
- **Summary:** 13 variants checked, 10 available, 3 taken (tbx.com/io/ai). Prices: .com $17.29, .io $34.99, .ai $99.99. Trademark risk: low, no conflicts found.
- **Verdict:** **PASS**

---

## Summary Table

| Scout          | Test                      | Verdict            | Notes                                    |
|----------------|---------------------------|--------------------|------------------------------------------|
| scout-visual   | Instagram/Brave           | FAIL (EXTERNAL)    | Brave + Tavily quota exhausted           |
| scout-visual   | Skool/ECHELON             | SKIP               | Reference only                           |
| scout-finance  | yfinance NVDA             | **PASS**           | Full info returned, T1                   |
| scout-finance  | DexPaprika ethereum       | **PASS**           | 10 tokens, 20 pools returned             |
| scout-finance  | News NVIDIA/Guardian      | **PASS**           | 3 articles, T1                           |
| scout-domain   | Full analysis anthropic   | **PASS**           | 6 channels, 10.7s                        |
| scout-domain   | Tech mode stripe          | **PASS**           | 6 techs detected, 4.1s                   |
| scout-brand    | Avail anthropic.com       | **FAIL (BUG)**     | RDAP 302 not handled, returns null       |
| scout-brand    | Avail xyztest99887abc.com | **FAIL (BUG)**     | Crash: dict.lower() in parse_available   |
| scout-brand    | Suggest TestBrandXYZ      | **PASS**           | 10/13 available, trademark low risk      |

## Overall: 6 PASS, 2 FAIL (BUG), 1 FAIL (EXTERNAL), 1 SKIP

### Bugs to Fix
1. **scout-brand/availability RDAP 302**: When RDAP returns HTTP 302, the script should follow the redirect or fall back to WHOIS/NameSilo to determine availability. Currently returns `null`.
2. **scout-brand/availability NameSilo parse crash**: `parse_available_section` at line 76 calls `.lower()` on a dict object. Needs type-checking: `if isinstance(val, dict): ...` before string operations.
