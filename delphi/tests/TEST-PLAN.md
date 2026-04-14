# DELPHI PRO — Test Plan v1.0

**Status**: DRAFT → AUDIT → EXECUTE
**Date**: 2026-03-20
**Test topic**: "AI research agents 2026" (consistent pe toate testele)
**Finance topic**: "NVDA stock analysis" (pentru scout-finance)

---

## Phase 1: CLI WRAPPERS (individual, izolat)

Testează fiecare CLI wrapper independent. Output → tmpfile → validate JSON.

| # | Test | CLI Script | Expected | Pass Criteria |
|---|------|-----------|----------|---------------|
| 1.1 | HN Search | `scout-social/cli/hn-search.sh --topic "AI research agents" --max 5` | JSON cu findings[] | status=complete, items_returned >= 1, valid JSON |
| 1.2 | Reddit Search | `scout-social/cli/reddit-search.sh --topic "AI research agents" --max 5` | JSON cu findings[] | status=complete, items_returned >= 1, method field present |
| 1.3 | yfinance Price | `scout-finance/cli/yfinance-search.sh --symbol NVDA` | JSON cu history | status=complete, data_points > 0 |
| 1.4 | yfinance Info | `scout-finance/cli/yfinance-search.sh --symbol NVDA --info` | JSON cu info{} | status=complete, info.shortName present |
| 1.5 | News Guardian | `scout-knowledge/cli/news-search.sh --topic "AI agents" --max 3 --source guardian` | JSON cu findings[] | status=complete, items_returned >= 1 |
| 1.6 | News GNews | `scout-knowledge/cli/news-search.sh --topic "AI agents" --max 3 --source gnews` | JSON cu findings[] | status=complete OR partial (GNews free tier) |
| 1.7 | News RSS | `scout-knowledge/cli/news-search.sh --topic "AI" --max 3 --source rss` | JSON cu findings[] | status=complete, RSS feeds parseable |
| 1.8 | Notion dry-run | `store-notion/cli/notion-create.sh --help` | Help text + token resolved | Token found, help displays |

**Method**: `script > /tmp/delphi-test-X.json 2>&1 && python3 validate.py`
**Timeout**: 15s per test
**Fallback check**: Dacă primary fail, testează fallback automat (ex: Reddit PRAW fail → JSON API)

---

## Phase 2: MCP TOOLS (individual, via Claude Code)

Testează fiecare MCP tool direct. Verifică: funcționează, returnează date, format corect.

| # | Test | MCP Tool | Query | Pass Criteria |
|---|------|----------|-------|---------------|
| 2.1 | Brave Search | `mcp__brave-search__brave_web_search` | "AI research agents 2026" | Results returned, count > 0 |
| 2.2 | Cortex Search | `mcp__cortex__cortex_search` | "research agent" | Results returned, score > 0 |
| 2.3 | Cortex Store | `mcp__cortex__cortex_store` | Test entry | Stored successfully, ID returned |
| 2.4 | Wikipedia Search | `mcp__wikipedia__wiki_search` | "artificial intelligence" | Results returned |
| 2.5 | Wikipedia Article | `mcp__wikipedia__wiki_get_summary` | "Claude (language model)" | Summary text returned |
| 2.6 | ArXiv Search | `mcp__arxiv__search_papers` | "research agents" | Papers found, IDs returned |
| 2.7 | DuckDuckGo | `mcp__duckduckgo__search` | "AI research agents" | Results returned |
| 2.8 | Tavily Search | `mcp__tavily__tavily_search` | "AI research agents 2026" | Results with URLs |
| 2.9 | Tavily Extract | `mcp__tavily__tavily_extract` | Extract from a found URL | Content extracted |
| 2.10 | Exa Search | `mcp__exa__web_search_advanced_exa` | "AI research agent tools" | Results returned |
| 2.11 | YouTube Transcript | `mcp__youtube-transcript__get-transcript` | A known AI video ID | Transcript text returned |
| 2.12 | Perplexity Search | `mcp__perplexity__search` | "AI research agents 2026" | Answer + citations (or ERROR if key broken) |
| 2.13 | Perplexity Reason | `mcp__perplexity__reason` | "Compare Tavily vs Perplexity for research" | Reasoned answer (or ERROR) |
| 2.14 | OpenAlex Search | `mcp__openalex__search_works` | "AI agents" | Works returned |
| 2.15 | DexPaprika Search | `~/.nexus/cli-tools/dexpaprika search -o json` | "bitcoin" | Token results |
| 2.16 | Fetch URL | `mcp__fetch__fetch` | "https://arxiv.org" | Content returned |

**Perplexity note**: Dacă 2.12/2.13 fail cu auth error, se confirmă "Perplexity needs OpenRouter" → marcat KNOWN ISSUE, nu FAIL.

| 2.17 | Apify API Key | Apify Actor call | Test actor run on Apify | Key valid, actor starts, credits available |

**Apify test**: Rulează un actor mic (ex: apify/hello-world sau un search mic) pentru a verifica key-ul nou și creditele disponibile.

---

## Phase 3: SCOUT SUBAGENT SIMULATION

Testează fiecare scout ca subagent (spawnat cu Agent tool). Topic consistent.

| # | Test | Scout | Channels to test | Pass Criteria |
|---|------|-------|-----------------|---------------|
| 3.1 | Scout-Web | scout-web | Brave + Tavily + Exa | status=complete, findings >= 3, unique URLs |
| 3.2 | Scout-Social | scout-social | Reddit CLI + HN CLI | status=complete, findings >= 2, source_tier present |
| 3.3 | Scout-Video | scout-video | YouTube transcript | status=complete, at least 1 transcript extracted |
| 3.4 | Scout-Knowledge | scout-knowledge | ArXiv + Wikipedia + News CLI | status=complete, findings >= 3, T1/T2 sources |
| 3.5 | Scout-Finance | scout-finance | yfinance CLI + DexPaprika MCP | status=complete, price data present |
| 3.6 | Scout standalone | scout-social via bash CLI | `scout-social.sh --topic "Claude Code" --channels "reddit"` | Funcționează fără DELPHI |

**Method**: Spawned ca Agent subagent cu prompt specific. Returnează JSON.
**Timeout**: 120s per scout
**Model**: Haiku (conform plan)

---

## Phase 4: DEPTH LEVEL TESTS (D1-D3)

### 4.1 D1 — Instant (<30s)
```
Topic: "What is Claude Code?"
Expected depth: D1
Channels: Cortex + Brave + optional Wikipedia
Execution: DELPHI direct (no scouts)
```
**Pass criteria**:
- [ ] Duration < 30 seconds
- [ ] Result contains factual answer
- [ ] Cortex was queried (pre-search)
- [ ] Brave Search was called
- [ ] No scouts spawned
- [ ] No HTML generated (text only)

### 4.2 D2 — Standard (1-5 min)
```
Topic: "multi-agent orchestration patterns 2026"
Expected depth: D2
Channels: Cortex + Brave + Perplexity + YouTube + Reddit + ArXiv
Execution: DELPHI direct (≤5 channels) OR scouts (>5 channels)
```
**Pass criteria**:
- [ ] Duration 1-5 minutes
- [ ] Sources >= 3
- [ ] EPR >= 14
- [ ] At least 2 different channel types used
- [ ] Social media channel included (YouTube or Reddit)
- [ ] Markdown report generated
- [ ] Cortex pre-search executed

### 4.3 D3 — Deep (5-20 min)
```
Topic: "AI research agent best practices and architecture"
Expected depth: D3 (forced via /research-pro-deep)
Channels: All D2 + full social + academic + news
Execution: 3-5 scouts paralel + Critic + Synthesizer
```
**Pass criteria**:
- [ ] Duration 5-20 minutes
- [ ] Sources >= 8
- [ ] EPR >= 16
- [ ] At least 3 scouts spawned
- [ ] Critic ran (evaluations present)
- [ ] Synthesizer ran (self_grade present)
- [ ] Report Self-Audit PASSED (7 checkboxes)
- [ ] Markdown report saved
- [ ] Cortex store executed
- [ ] Quality gates enforced

**D4 NOT TESTED** — requires Gemini Deep Research + Opus Synthesizer. Costisitor. Test manual separat.

---

## Phase 5: INFRASTRUCTURE TESTS

| # | Test | Component | Pass Criteria |
|---|------|-----------|---------------|
| 5.1 | Cortex store | store-cortex skill | Save + search + find back |
| 5.2 | Vault write | store-vault CLI | Note created at expected path |
| 5.3 | Notion dry-run | store-notion CLI | Token valid, help works |
| 5.4 | State tracking | state.json | Updated after each depth test |
| 5.5 | Channel config | channel-config.yaml | Parseable, no phantom refs |

---

## Phase 6: CROSS-CUTTING VALIDATION

| # | Test | What | Pass Criteria |
|---|------|------|---------------|
| 6.1 | Error handling | Kill a scout mid-run | DELPHI continues with partial data |
| 6.2 | Deduplication | Same topic across 2 scouts | No duplicate URLs in merged findings |
| 6.3 | Tier consistency | All findings from all scouts | source_tier is T1, T2, or T3 only (no T2-high) |
| 6.4 | Metadata standard | All scout outputs | All have items_total, items_returned, duration_ms, channels_queried |
| 6.5 | JSON validity | All CLI outputs | Valid JSON, no control chars, parseable |
| 6.6 | Timeout handling | Force slow CLI | Times out gracefully, flags error |

---

## Phase 7: COST TRACKING

After all tests, calculate:

| Metric | How to measure |
|--------|---------------|
| Total MCP calls | Count from test logs |
| Total CLI calls | Count from test logs |
| Perplexity status | Working or broken (OpenRouter issue) |
| Apify credits used | Check Apify dashboard |
| Estimated cost D1 | Sum API costs |
| Estimated cost D2 | Sum API costs |
| Estimated cost D3 | Sum API costs |
| Token usage per test | Estimate from context |

---

## Execution Order

```
1. Phase 1: CLIs (paralel, 8 tests, ~2 min total)
2. Phase 2: MCPs (paralel batches, 16 tests, ~3 min total)
3. Phase 3: Scouts (paralel, 6 tests, ~5 min total)
4. Phase 4.1: D1 test (serial, ~30s)
5. Phase 4.2: D2 test (serial, ~3 min)
6. Phase 4.3: D3 test (serial, ~15 min)
7. Phase 5: Infrastructure (paralel, ~2 min)
8. Phase 6: Cross-cutting (serial, ~5 min)
9. Phase 7: Cost summary (aggregation, ~1 min)

Total estimated: ~30-35 min
```

---

## Test Report Format

```
DELPHI PRO TEST REPORT — {date}

PHASE 1: CLI WRAPPERS
  [PASS/FAIL] 1.1 HN Search — {duration}ms, {results} results
  [PASS/FAIL] 1.2 Reddit — {duration}ms, {results} results, method={method}
  ...
  Summary: {passed}/{total} PASS

PHASE 2: MCP TOOLS
  [PASS/FAIL] 2.1 Brave — {results} results
  ...
  Summary: {passed}/{total} PASS
  Known issues: {list}

PHASE 3: SCOUTS
  [PASS/FAIL] 3.1 Scout-Web — {findings} findings, {duration}s
  ...
  Summary: {passed}/{total} PASS

PHASE 4: DEPTH TESTS
  [PASS/FAIL] D1 — {duration}s, Cortex={y/n}, Brave={y/n}
  [PASS/FAIL] D2 — {duration}s, sources={n}, EPR={score}
  [PASS/FAIL] D3 — {duration}s, sources={n}, EPR={score}, scouts={n}

PHASE 5: INFRASTRUCTURE
  [PASS/FAIL] Cortex — store+search OK
  [PASS/FAIL] Vault — note created
  ...

PHASE 6: CROSS-CUTTING
  [PASS/FAIL] Dedup — no duplicates
  [PASS/FAIL] Tiers — consistent T1/T2/T3
  ...

COST SUMMARY
  MCP calls: {n}
  CLI calls: {n}
  Estimated total cost: ${x.xx}

VERDICT: {PASS / CONDITIONAL / FAIL}
  Blocking issues: {list or "none"}
  Known issues: {list}
```
