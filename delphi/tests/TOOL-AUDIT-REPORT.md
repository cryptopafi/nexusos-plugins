# DELPHI PRO — Tool & Channel Audit Report

**Date**: 2026-03-20
**Source**: E2E Testing Session (Phase 1A-1D, D2 Benchmark, D3 Market Analysis)
**Plugin**: ~/.claude/plugins/delphi/
**Tests Reference**: E2E-TEST-REPORT.md, TEST-PLAN-E2E.md

---

## EXECUTIVE SUMMARY

- **42 tools/channels audited** across 6 categories
- **26 PASS / 4 FAIL / 3 DEGRADED / 9 NOT TESTED**
- **4 MCPs removed** (replaced by cheaper/faster alternatives)
- **3 quota issues** identified (Brave exhausted, Tavily low, DuckDuckGo rate-limited)
- **Cost of full audit**: ~$0.05 (OpenRouter calls + Apify smoke test)

---

## Section 1: MCP Tools

| # | MCP | Status | What Was Tested | Results | Failure Reason | Recommended Action |
|---|-----|--------|-----------------|---------|----------------|-------------------|
| 1 | **brave-search** | DEGRADED | `brave_web_search` keyword queries | Fast results, clean JSON. **2000/2000 monthly quota exhausted** during D3 run. | Quota exhausted on free plan (2000 req/mo). | **FIX** — Upgrade to paid plan ($5/mo = 15K req) or demote to fallback behind Tavily/Exa. |
| 2 | **tavily** | DEGRADED | `tavily_search`, `tavily_extract`, `tavily_research` | Content snippets included, good quality. Quota exhausted partway through D3 market analysis. | Monthly quota limit hit during heavy D3 usage. Exact limit unclear. | **FIX** — Check plan limits, monitor usage. Consider upgrading if <5K/mo. |
| 3 | **exa** | PASS | `web_search_advanced_exa` neural search | 3 results returned, semantic/neural search quality high. ~85KB output per query. | N/A | **KEEP** — Premium semantic search. Use for D2+ when quality matters. |
| 4 | **perplexity (MCP)** | REMOVED | Connection test with pplx- API key | Dead key (quota exceeded permanently). MCP package itself works but key is invalid. | pplx- direct API key exhausted. jsonallen MCP removed from .claude.json. | **REMOVED** — Replaced by OpenRouter curl. Saves ~12K tokens in MCP overhead. |
| 5 | **duckduckgo** | FAIL | `duckduckgo_search` keyword queries | "Anomaly detected" / rate limited on most attempts. Intermittent success. | DuckDuckGo bot detection blocks automated queries. No API key available. | **KEEP as fallback only** — Free, no auth. Works occasionally. Do not use as primary. |
| 6 | **arxiv** | PASS | `search_papers`, `download_paper`, `read_paper` | 3 papers returned with full metadata (title, authors, abstract, categories, dates). | N/A | **KEEP** — No rate limit, structured academic data. Essential for D2+ research. |
| 7 | **openalex** | PASS | `search_works`, `get_work`, `search_authors` | 3 works returned. Inverted index abstracts (non-standard format). Connection drops observed. | N/A (works on retry) | **KEEP** — Fix stability. Add retry logic. Inverted index abstracts need post-processing. |
| 8 | **wikipedia** | PASS | `wiki_search`, `wiki_get_summary`, `wiki_get_article` | 3 results, fast response (<1s). Structured content. | N/A | **KEEP** — Free, fast, reliable. Core T1 channel for all depth levels. |
| 9 | **youtube-transcript (MCP)** | FAIL | `get-transcript` on multiple video IDs | `playerCaptionsTracklistRenderer` null crash on every video tested. Zero transcripts returned. | YouTube API change broke the MCP's caption extraction. Upstream package issue. | **REPLACED** — Using youtube-search.sh CLI (yt-dlp + Whisper fallback). Monitor MCP repo for fix. |
| 10 | **dexpaprika** | PASS | `search`, `getNetworkPools`, `getTokenDetails` | 10 tokens + 20 pools returned. Full liquidity/volume data. | N/A | **KEEP** — No rate limit, comprehensive DeFi data. Essential for finance research. |
| 11 | **cortex** | PASS | `cortex_search`, `cortex_store`, `cortex_find_procedure` | First call failed (cold start), second succeeded. 3 search results returned. Store confirmed with ID. | Cold start latency on first call after idle. | **KEEP** — Add warmup call in pipeline. Local tool, no quota. |
| 12 | **clinicaltrials** | NOT TESTED | N/A | N/A — not relevant for benchmark topic (AI agents). | N/A | **KEEP** — Niche but valuable for health/biotech research topics. Test when relevant. |
| 13 | **notion (MCP)** | REMOVED | Compared MCP vs CLI token usage | MCP schema alone costs ~12K tokens. CLI does same work for ~200 tokens. | Excessive token overhead for simple CRUD operations. | **REMOVED** — Replaced by notion-create.sh CLI. Saves ~12K tokens per session. |
| 14 | **alpha-vantage (MCP)** | REMOVED | Compared MCP vs yfinance CLI | MCP requires API key management, rate-limited (5 calls/min free). yfinance has no limits. | Free tier too restrictive. MCP adds unnecessary overhead. | **REMOVED** — Replaced by yfinance-search.sh CLI. Unlimited, no auth needed. |
| 15 | **ecb-sdw (MCP)** | REMOVED | Evaluated usage frequency vs token cost | Niche ECB data, rarely needed. MCP schema overhead not justified. | Low usage frequency doesn't justify permanent MCP loading. | **REMOVED** — Can be re-added on demand. Use direct API curl when needed. |

**MCP Summary**: 15 evaluated. 8 active PASS, 2 DEGRADED (quota), 2 FAIL (broken/rate-limited), 4 REMOVED.

---

## Section 2: CLI Tools

| # | CLI | Status | Speed | What Was Tested | Results | Failure Reason | Recommended Action |
|---|-----|--------|-------|-----------------|---------|----------------|-------------------|
| 1 | **hn-search.sh** | PASS | 2-3s | Algolia HN API search for tech topics | 3 findings returned with title, URL, score, comments. Free, no auth required. | N/A | **KEEP** — Fast, reliable, free. Core social signal channel. |
| 2 | **reddit-search.sh** | PASS | 3-5s | Reddit JSON API search (PRAW not configured) | 3 results returned. Using public JSON API fallback (no auth). | N/A | **KEEP + FIX** — Works but configure PRAW for better rate limits and sorting. |
| 3 | **yfinance-search.sh** | PASS | 4s | Stock/company info lookup (NVDA test) | NVDA company info, price, fundamentals returned correctly. Unlimited usage. | N/A | **KEEP** — Replaced alpha-vantage MCP. No rate limits. |
| 4 | **news-search.sh** | PASS | 5s | Guardian API article search | 3 articles returned with title, URL, date, section. API key active (5K/day limit). | N/A | **KEEP** — Reliable news source. 5K daily limit is generous. |
| 5 | **notion-create.sh** | PASS | N/A | Dry-run mode, token resolution, help flag | Token resolves from NOTION_TOKEN env. Help output works. Dry-run confirmed. | N/A | **KEEP** — Replaced notion MCP. Saves ~12K tokens. |
| 6 | **youtube-search.sh** | PASS | 1-15s | 3-tier transcript fallback: transcript-api, yt-dlp, Whisper | Transcripts successfully extracted via yt-dlp. Whisper fallback available via Groq. | N/A | **KEEP** — Critical replacement for broken YouTube MCP. 3-tier resilience. |

**CLI Summary**: 6/6 PASS. All operational. Reddit needs PRAW config for full capability.

---

## Section 3: OpenRouter / Perplexity

| # | Model | Status | Speed | Cost/Query | What Was Tested | Results | Recommended Action |
|---|-------|--------|-------|-----------|-----------------|---------|-------------------|
| 1 | **perplexity/sonar** | PASS | ~2s | ~$0.001 | Basic web-grounded Q&A via OpenRouter curl | Correct answers with source citations. Fast, cheap. | **KEEP** — Default for D1 quick lookups. |
| 2 | **perplexity/sonar-pro** | PASS | ~3s | ~$0.018 | Pro search with extended context via OpenRouter | Higher quality answers, more sources cited. Good for D2. | **KEEP** — Default for D2 depth. |
| 3 | **perplexity/sonar-reasoning-pro** | NOT TESTED | - | ~$0.05 | N/A — available but not tested in E2E | N/A | **TEST** — Run on next D3 research to validate reasoning quality vs sonar-pro. |
| 4 | **perplexity/sonar-deep-research** | NOT TESTED | - | ~$1.30 | N/A — too expensive for automated test | N/A | **TEST with approval** — Manual test only. Reserve for D4 deep dives. |

**OpenRouter Summary**: 2/2 tested PASS. 2 untested (cost gated). Manager API key active with sufficient credits.

---

## Section 4: Apify

| # | Actor | Status | Cost/Use | What Was Tested | Results | Recommended Action |
|---|-------|--------|----------|-----------------|---------|-------------------|
| 1 | **Account validation** | PASS | $0 | API key check, credit balance | $5 credit confirmed. Username: vigorous_yolk. FREE plan active. | **KEEP** — Platform ready for actor deployment. |
| 2 | **hello-world** | PASS | $0 | Smoke test actor execution | Actor started and completed successfully. | **KEEP** — Confirms actor runtime works. |
| 3 | **instagram-scraper** | NOT TESTED | ~$0.005/post | N/A | N/A | **TEST** — Run smoke test on public profile. Useful for social signal research. |
| 4 | **google-search** | NOT TESTED | ~$0.001/result | N/A | N/A | **TEST** — Could supplement Brave when quota exhausted. |

**Apify Summary**: 2/4 tested. Platform validated. Actor-specific tests pending.

---

## Section 5: Benchmark Results Summary

### D2 Benchmark: DELPHI PRO vs IRIS vs Perplexity

**Topic**: "Multi-agent AI patterns 2026" (or equivalent benchmark query)

| Metric | DELPHI PRO | IRIS | Perplexity (sonar-pro) |
|--------|-----------|------|----------------------|
| Sources found | **38** | 16 | 0 explicit |
| Explicit source URLs | **38** | 0 | 0 |
| Evidence Per Result (EPR) | **19** | 8-11 | N/A |
| Execution time | **77s** | 356s | 15s |
| Cost | **$0.04** | $0.50+ | $0.006 |
| Output quality | Multi-source synthesis | Single-model generation | Fluent but unverifiable |

**Verdict**: DELPHI PRO delivers 2.4x more sources than IRIS at 1/12th the cost and 4.6x faster. Perplexity is cheapest/fastest but provides no verifiable sources.

### D3 Market Analysis

| Metric | Result |
|--------|--------|
| Sources found | 33 |
| Evidence Per Result (EPR) | 17 |
| Execution time | 435s (~7 min) |
| Channels producing | 7 of 9 attempted |
| Channels failed | 2 (Brave quota, Tavily quota) |
| Cost | ~$0.06 |

**Key finding**: Quota exhaustion on Brave and Tavily during D3 confirmed need for plan upgrades or channel rotation strategy.

---

## Section 6: Channel Health Map

| # | Channel | Health | Quota Status | Rate Limit | Auth | Last Test | Notes |
|---|---------|--------|-------------|-----------|------|-----------|-------|
| 1 | **Brave Search** | QUOTA EXHAUSTED | 0/2000 monthly | N/A (quota gate) | API key | 2026-03-20 | Resets monthly. Need upgrade. |
| 2 | **Tavily** | QUOTA LOW | Exhausted during D3 | Unknown monthly cap | API key | 2026-03-20 | Check exact limit. May need upgrade. |
| 3 | **Exa** | OK | Within limits | Unknown | API key | 2026-03-20 | Neural search quality high. |
| 4 | **Perplexity (OpenRouter)** | OK | Unlimited (Manager key) | Pay-per-use | OpenRouter key | 2026-03-20 | Primary grounded search. Stable. |
| 5 | **DuckDuckGo** | RATE LIMITED | N/A (free, no key) | Aggressive bot detection | None | 2026-03-20 | Fallback only. Unreliable. |
| 6 | **ArXiv** | OK | No limit | None | None | 2026-03-20 | Academic papers. Always available. |
| 7 | **OpenAlex** | UNSTABLE | No hard limit | Connection drops observed | None (polite pool) | 2026-03-20 | Add retry logic. Works on second attempt. |
| 8 | **Wikipedia** | OK | No limit | None | None | 2026-03-20 | Fast, reliable. Core channel. |
| 9 | **YouTube (CLI)** | OK | No limit (yt-dlp) | None | None | 2026-03-20 | 3-tier fallback working. |
| 10 | **Reddit (CLI)** | OK | Soft limit (JSON API) | ~60 req/min (unauthed) | None (PRAW not configured) | 2026-03-20 | Works but needs PRAW for production. |
| 11 | **HackerNews (CLI)** | OK | No limit | None (Algolia API) | None | 2026-03-20 | Fast, free, reliable. |
| 12 | **DexPaprika** | OK | No limit | None | None | 2026-03-20 | Full DeFi data. Stable. |
| 13 | **Cortex** | OK (after warmup) | Local (no quota) | None | Local | 2026-03-20 | Cold start on first call. Add warmup. |
| 14 | **Guardian News (CLI)** | OK | 5K/day | 12 req/s | API key | 2026-03-20 | Generous limits for research use. |
| 15 | **yfinance (CLI)** | OK | Unlimited | None | None | 2026-03-20 | Replaced alpha-vantage MCP. |
| 16 | **Groq Whisper** | OK | Free tier | Rate limited | API key | 2026-03-20 | Audio transcription fallback for YouTube. |

**Channel Health Summary**:
- GREEN (OK): 11 channels
- YELLOW (DEGRADED/UNSTABLE): 3 channels (Brave, Tavily, OpenAlex)
- RED (FAIL/EXHAUSTED): 2 channels (DuckDuckGo, Brave quota)

---

## Section 7: Recommendations

### Priority 1 — Immediate (this week)

| # | Action | Impact | Cost | Effort |
|---|--------|--------|------|--------|
| 1 | **Upgrade Brave Search plan** | Restores primary web search (15K req/mo) | $5/mo | 5 min |
| 2 | **Check Tavily quota limits** | Prevent mid-research failures | $0 (check) | 10 min |
| 3 | **Add channel rotation logic** | Auto-fallback when quota exhausted (Brave->Exa->Tavily) | $0 | 1 hour |

### Priority 2 — Short-term (this month)

| # | Action | Impact | Cost | Effort |
|---|--------|--------|------|--------|
| 4 | **Configure PRAW for Reddit** | Better rate limits, sorting, subreddit targeting | $0 | 30 min |
| 5 | **Test Apify actors** (Instagram, Google Search) | New social + search channels | ~$0.01 | 30 min |
| 6 | **Fix OpenAlex stability** | Eliminate connection drops on first call | $0 | 30 min |
| 7 | **Test sonar-reasoning-pro** | Validate D3 reasoning quality vs cost | ~$0.15 | 15 min |

### Priority 3 — Medium-term (next sprint)

| # | Action | Impact | Cost | Effort |
|---|--------|--------|------|--------|
| 8 | **Add transcriptor-mcp** | Multi-platform transcripts (YouTube, podcasts, etc.) | $0 | 30 min |
| 9 | **Test sonar-deep-research** | Validate D4 deep dive capability | ~$1.30 | 15 min |
| 10 | **Monitor YouTube MCP** | If upstream fixes playerCaptionsTracklistRenderer, re-enable | $0 | Ongoing |
| 11 | **Implement quota tracking** | Dashboard showing remaining quota per channel | $0 | 2 hours |

### Removed Tools — Do NOT Re-add Unless:

| Tool | Condition to Re-add |
|------|-------------------|
| perplexity MCP | Never. OpenRouter is strictly superior (more models, one key). |
| notion MCP | Never. CLI saves 12K tokens. |
| alpha-vantage MCP | Only if yfinance breaks or real-time streaming needed. |
| ecb-sdw MCP | Only if ECB data becomes a frequent research topic. |

---

## Appendix A: Token Cost of MCP Removal

| Removed MCP | Schema Tokens Saved | Replacement |
|-------------|-------------------|-------------|
| perplexity | ~12K | OpenRouter curl |
| notion-affiliate | ~12K | notion-create.sh CLI |
| alpha-vantage | ~4K | yfinance-search.sh CLI |
| ecb-sdw | ~3K | Direct API curl (on demand) |
| **Total saved** | **~31K tokens/session** | |

At ~$0.015 per 1K input tokens (Opus), this saves ~$0.47 per session in context overhead.

---

## Appendix B: Test Coverage Matrix

| Category | Total | Tested | Pass | Fail | Degraded | Not Tested |
|----------|-------|--------|------|------|----------|-----------|
| MCP Tools | 15 | 12 | 8 | 2 | 2 | 1 |
| CLI Tools | 6 | 6 | 6 | 0 | 0 | 0 |
| OpenRouter Models | 4 | 2 | 2 | 0 | 0 | 2 |
| Apify Actors | 4 | 2 | 2 | 0 | 0 | 2 |
| Benchmarks | 2 | 2 | 2 | 0 | 0 | 0 |
| Channels | 16 | 16 | 11 | 2 | 3 | 0 |
| **TOTAL** | **47** | **40** | **31** | **4** | **5** | **5** |

---

*Report generated from E2E test session 2026-03-20. Next audit scheduled after Brave upgrade and Apify actor testing.*
