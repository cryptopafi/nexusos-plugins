# DELPHI PRO — E2E Test Plan v1.0

**Date**: 2026-03-20
**Test topic**: "AI research agents 2026" (consistent across all tests)
**Apify budget**: max $1.00 for all tests combined

---

## Phase 1: INDIVIDUAL TOOL TESTS (verify each tool works)

### 1A. CLI Tools (already tested, results below)
| # | Tool | Test command | Expected | Status |
|---|------|-------------|----------|--------|
| 1.1 | hn-search.sh | `--topic "AI research agents" --max 3` | JSON with ≥1 finding | PASS |
| 1.2 | reddit-search.sh | `--topic "AI research agents" --max 3` | JSON with ≥1 finding | PASS |
| 1.3 | yfinance-search.sh | `--symbol NVDA --info` | JSON with company data | PASS |
| 1.4 | news-search.sh | `--topic "AI agents" --source guardian` | JSON with ≥1 article | PASS |
| 1.5 | notion-create.sh | `--help` (dry run) | Help text + token found | PASS |

### 1B. MCP Tools (test each MCP individually)
| # | MCP | Test query | Expected | Pass criteria |
|---|-----|-----------|----------|---------------|
| 1.6 | brave-search | "AI research agents 2026" | Search results | ≥3 results |
| 1.7 | tavily_search | "AI research agents 2026" | Search + snippets | ≥3 results |
| 1.8 | exa_search | "AI research agents best practices" | Semantic results | ≥2 results |
| 1.9 | perplexity_search | "AI research agents 2026" | Synthesized answer | Answer + sources |
| 1.10 | duckduckgo_search | "AI research agents" | Web results | ≥3 results |
| 1.11 | arxiv_search | "research agents" | Papers | ≥2 papers |
| 1.12 | openalex_search | "AI research agents" | Works | ≥2 works |
| 1.13 | wikipedia_search | "Intelligent agent" | Article matches | ≥1 match |
| 1.14 | cortex_search | "research agents" | Knowledge entries | Any result (may be empty) |
| 1.15 | youtube_transcript | Known video ID | Transcript text | Non-empty text |
| 1.16 | dexpaprika_search | "bitcoin" | Token info | Token found |

### 1C. Apify Actors (test with minimal runs)
| # | Actor | Test | Budget | Pass criteria |
|---|-------|------|--------|---------------|
| 1.17 | apify/hello-world | Smoke test | $0.00 | Actor runs successfully |
| 1.18 | apify/instagram-scraper | Search "AI agents" 3 posts | ~$0.02 | ≥1 post returned |
| 1.19 | Apify Google Search | "AI research agents" 5 results | ~$0.01 | ≥3 results |

**Phase 1 budget**: ~$0.03 Apify + $0.00 CLIs + ~$0.10 MCP API calls

---

## Phase 2: SCOUT SKILL TESTS (each scout as subagent)

Test each scout independently — spawn as subagent with a standardized prompt.

| # | Scout | Spawn prompt | Expected channels | Pass criteria |
|---|-------|-------------|-------------------|---------------|
| 2.1 | scout-web | "Search web for 'AI research agents 2026', max 5 per channel" | Brave, Perplexity, Tavily | ≥8 findings total, JSON valid |
| 2.2 | scout-social | "Search social for 'AI research agents 2026', max 3 per channel" | Reddit, HN, (X skip if no auth) | ≥4 findings, JSON valid |
| 2.3 | scout-video | "Search video for 'AI research agents', max 3" | YouTube (transcript) | ≥1 finding with transcript |
| 2.4 | scout-knowledge | "Search academic for 'AI research agents', max 3 per channel" | ArXiv, OpenAlex, Wikipedia | ≥5 findings, ≥1 T1 source |
| 2.5 | scout-news | "Search news for 'AI agents', max 3" | Guardian, RSS | ≥2 findings |
| 2.6 | scout-finance | "Search finance for 'NVIDIA AI', max 3" | yfinance, DexPaprika | ≥1 finding with market data |
| 2.7 | scout-deep | SKIP (D4 only, too expensive for test) | — | — |

### Per-scout verification checklist:
- [ ] Output JSON is valid
- [ ] `status` field is "complete" or "partial"
- [ ] `agent` field matches scout name
- [ ] `findings[]` has items with: source_url, source_tier, channel, title, content_summary, relevance_score
- [ ] `metadata` has: items_total, items_returned, duration_ms, channels_queried
- [ ] `errors[]` is array (empty if no errors)
- [ ] Each finding has valid `source_tier` (T1, T2, or T3)
- [ ] No duplicate URLs in findings
- [ ] Duration < 120s per scout

**Phase 2 budget**: ~$0.30 (Perplexity Sonar Pro + Tavily + Exa API calls)

---

## Phase 3: INFRASTRUCTURE SKILL TESTS

| # | Skill | Test | Pass criteria |
|---|-------|------|---------------|
| 3.1 | store-cortex SEARCH | Search "AI research agents" | Returns results or empty array |
| 3.2 | store-cortex STORE | Store test finding | Returns stored ID |
| 3.3 | store-cortex FIND_PROCEDURE | Find "research" procedure | Returns procedure or empty |
| 3.4 | store-vault CREATE | Create test note in research/ | File exists in vault |
| 3.5 | store-notion CREATE | Create test page (dry run check) | Token works, format correct |

**Phase 3 budget**: $0.00 (all local operations)

---

## Phase 4: DEPTH LEVEL TESTS (D1 → D2 → D3)

### 4.1 D1 Test — INSTANT (<30s)
```
Topic: "What is Claude Code?"
Expected: DELPHI direct execution, no scouts
Channels: Cortex + Brave + Wikipedia (max 3)
Pass criteria:
  - Response in <30s
  - Contains factual answer
  - No subagent spawned
  - state.json updated (D1 counter +1)
```

### 4.2 D2 Test — STANDARD (1-5 min)
```
Topic: "AI research agents 2026 best practices"
Expected: DELPHI direct OR 2-3 scouts (depends on channel count)
Channels: Cortex + Brave + Perplexity + YouTube + X + ArXiv (6 = scouts)
Pass criteria:
  - ≥3 sources in output
  - EPR ≥ 14
  - Duration 1-5 min
  - state.json updated (D2 counter +1)
  - Cortex store called (post-research)
```

### 4.3 D3 Test — DEEP (5-20 min)
```
Topic: "How do deep research agents work? Architecture, tools, evaluation methods"
Depth: D3 explicit
Expected: 3-5 scouts parallel + Critic (Sonnet) + Synthesizer (Sonnet)
Pass criteria:
  - ≥8 sources in output
  - EPR ≥ 16
  - Critic evaluation present (findings filtered)
  - Report has: executive summary, key findings, detailed analysis, sources, methodology
  - Duration 5-20 min
  - Cortex + Vault saved
  - state.json updated (D3 counter +1)
```

### 4.4 D4 Test — SKIP for now
```
Reason: Requires Opus Synthesizer ($2-5), Gemini Deep Research, full HTML on VPS.
Will test after D1-D3 are confirmed stable.
Trigger: Manual when ready — /research-pro-deep "longevity interventions" --depth=D4
```

**Phase 4 budget**: ~$0.50-1.50 (D1: $0.01, D2: $0.15, D3: $0.80)

---

## Phase 5: INTEGRATION & EDGE CASE TESTS

| # | Test | What it verifies | Pass criteria |
|---|------|-----------------|---------------|
| 5.1 | Scout standalone call | ECHELON can call scout-social directly | `bash scout-social.sh --topic "test"` returns JSON |
| 5.2 | Fallback chain | Simulate channel failure (invalid URL) | Scout returns partial results, not crash |
| 5.3 | Report Self-Audit | D3 report passes 7-point IRON LAW checklist | All 7 checks pass in methodology |
| 5.4 | State persistence | Check state.json after D1+D2+D3 runs | Counters incremented, channel health updated |
| 5.5 | Deduplication | Same topic on 2 scouts returning same URL | Merged findings have no duplicate URLs |
| 5.6 | Empty topic | Send empty string as topic | Error JSON, not crash |
| 5.7 | Cost tracking | Check estimated cost after all runs | state.json shows cost_usd per run |

**Phase 5 budget**: $0.00 (reuses previous results + edge case tests)

---

## Phase 6: REPORT GENERATION

| # | Test | Expected |
|---|------|----------|
| 6.1 | Generate Tier 1 report card (from D2 results) | Single-page HTML card, dark mode, share button |
| 6.2 | Generate Tier 2 full report (from D3 results) | Multi-section HTML, TOC, charts, dark/light toggle |
| 6.3 | Verify self-audit on HTML | 7-point checklist passes on generated report |

**Phase 6 budget**: $0.00 (HTML generation is local)

---

## TOTAL BUDGET

| Phase | Estimated cost |
|:---:|:---:|
| Phase 1 (tools) | ~$0.13 |
| Phase 2 (scouts) | ~$0.30 |
| Phase 3 (infra) | $0.00 |
| Phase 4 (depths) | ~$1.00 |
| Phase 5 (integration) | $0.00 |
| Phase 6 (reports) | $0.00 |
| **TOTAL** | **~$1.43** |

Apify: ~$0.03 of $5.00 available.
API calls: ~$1.40 (Perplexity, Tavily, Exa via paid APIs).

---

## SUCCESS CRITERIA

```
PHASE 1: ≥14 of 16 MCP tools pass (2 failures acceptable if fallback works)
PHASE 2: ≥5 of 6 scouts pass (scout-deep skipped)
PHASE 3: All 5 infrastructure tests pass
PHASE 4: D1 <30s, D2 EPR≥14, D3 EPR≥16
PHASE 5: ≥5 of 7 integration tests pass
PHASE 6: Both HTML tiers generate correctly

OVERALL: PASS if all phases meet criteria above
```

---

## EXECUTION ORDER

```
Phase 1A: CLI tools ✅ (already done)
Phase 1B: MCP tools (parallel, 5 min)
Phase 1C: Apify actors (2 min)
Phase 2: Scout skills (parallel, 5-10 min)
Phase 3: Infrastructure (2 min)
Phase 4.1: D1 test (30s)
Phase 4.2: D2 test (5 min)
Phase 4.3: D3 test (20 min)
Phase 5: Integration (5 min)
Phase 6: Reports (5 min)

Total estimated time: ~50-60 min
```
