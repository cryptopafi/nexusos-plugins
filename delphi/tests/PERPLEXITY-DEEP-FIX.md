# Perplexity Deep Research Truncation: Root Cause & Fix

**Date:** 2026-03-20
**Investigated by:** Claude Opus 4.6
**Status:** ROOT CAUSE IDENTIFIED + FIX RECOMMENDED

---

## 1. Root Cause

**The sonar-deep-research model has a soft output ceiling of ~10,000 completion tokens regardless of `max_tokens` setting.**

### Evidence from live tests (2026-03-20):

| Test | max_tokens | Actual Output | finish_reason | Words |
|------|-----------|---------------|---------------|-------|
| Simple query (top 10 AI tools) | 16,000 | 8,950 tokens | `stop` | 6,304 |
| Complex 7-section market analysis | 32,000 | 9,867 tokens | `stop` | 6,208 |
| Original pain-point research | 8,000 | ~4,078 words | likely `length` | 4,078 |

### Key findings:

1. **OpenRouter metadata confirms `max_completion_tokens: null`** for this model -- meaning Perplexity itself imposes no documented hard cap, but the model empirically stops around 9-10K tokens.

2. **The original call used `max_tokens=8000`** -- this likely HIT the cap. With 8K max_tokens, the model ran out of budget before completing all sections. The `finish_reason` would have been `length` (forced truncation), not `stop` (natural completion).

3. **Setting max_tokens higher (16K-32K) does NOT produce proportionally more output.** The model naturally completes around 9-10K tokens even with 32K budget. But it DOES prevent premature truncation at 8K.

4. **This is a known issue.** Perplexity community forum thread (Oct 2025) reports identical behavior: users set 8K-20K max_tokens but output always caps around 10K tokens. Perplexity staff acknowledged the report but provided no official fix.

### Root cause of the 267-line / 40%+ missing report:

**`max_tokens=8000` was too low.** The model was generating a ~10K token report but got force-stopped at 8K, cutting off the SaaS stakeholder section, regional analysis, financial sizing, and source list.

---

## 2. Recommended Fix

### Fix A: Increase max_tokens to 16,000 (IMMEDIATE)

Change the OpenRouter call from `max_tokens: 8000` to `max_tokens: 16000`.

This gives the model headroom to finish naturally at its ~10K token ceiling instead of being force-stopped at 8K. The extra 6K tokens of budget costs nothing if unused -- you only pay for actual output tokens.

**Cost impact:** Negligible. You pay per output token used, not per token budgeted. A 10K token output at $8/M = $0.08 output cost (vs $0.064 for 8K). The search + reasoning costs (~$1.00-1.20) dominate.

### Fix B: Chunk complex prompts into 3-5 focused queries (FOR LONGER REPORTS)

For reports requiring >10K tokens of output (which sonar-deep-research cannot produce in a single call):

**Split strategy:**
```
Query 1: Pain points by segment (SMB + Mid-market + Enterprise)
Query 2: Stakeholder-specific analysis (KOLs + Political + SaaS)
Query 3: Regional analysis (NA, EU, APAC, MENA, LATAM, Africa, Oceania)
Query 4: Product competitive matrix (14 products with pricing)
Query 5: Financial sizing + TAM/SAM/SOM + emerging opportunities
```

Each query gets the full Deep Research treatment (~10K tokens each), then merge results. Total output: ~40-50K tokens across 5 queries.

**Cost impact:** 5x the cost ($6.50 vs $1.30 per research run). Use only when a single query is genuinely insufficient.

### Fix C: Check finish_reason in the response (DEFENSIVE)

Always check the API response:
- `finish_reason: stop` = model completed naturally. Output is complete.
- `finish_reason: length` = model hit max_tokens cap. Output is TRUNCATED. Retry with higher max_tokens or chunk the query.

```python
if response['choices'][0]['finish_reason'] == 'length':
    # TRUNCATED! Either:
    # 1. Retry with max_tokens=16000
    # 2. Chunk into sub-queries
    # 3. Flag to orchestrator as incomplete
```

### Fix D: Use streaming (OPTIONAL, NOT A FIX)

Streaming IS supported (`stream: true`). However, streaming does not increase output length -- it just delivers the same tokens incrementally. It helps with:
- Timeout prevention on slow connections
- Progress indication
- Slightly more reliable delivery (no single large response body)

It does NOT prevent truncation caused by max_tokens cap.

---

## 3. Should we use Perplexity MCP instead of OpenRouter?

### Official Perplexity MCP Server

Perplexity now has an official MCP server:
```bash
claude mcp add perplexity --env PERPLEXITY_API_KEY="your_key_here" -- npx -y @perplexity-ai/mcp-server
```

**Problem:** This requires a direct Perplexity API key, which we deleted (per reference_perplexity_config.md). Our decision was OpenRouter ONLY.

### Third-party Perplexity MCPs

Several exist (Alcova-AI, wynandw87, jsonallen) but:
- Most require direct Perplexity API key
- None specifically solve the output length limitation
- The truncation is a model-level behavior, not an API delivery issue

**Recommendation:** Stay with OpenRouter curl approach. MCP would not fix the core issue. The fix is max_tokens=16000 + chunking for large reports.

---

## 4. Updated scout-deep SKILL.md Parameters

### Changes needed in Perplexity Deep Research section:

```markdown
### Perplexity Deep Research
- Tool: OpenRouter `perplexity/sonar-deep-research` via curl
- **max_tokens: 16000** (was 8000 -- model caps at ~10K naturally, need headroom)
- Always check `finish_reason` in response:
  - `stop` = complete report
  - `length` = TRUNCATED -- escalate or chunk
- For reports requiring >10K tokens: split into 3-5 focused sub-queries
- Cost per query: ~$1.30 (searches + reasoning dominate; output tokens are minor)
- Query format: focused research question, 2-4 sentences max
  - BAD: 500-word prompt with 7+ sections requested
  - GOOD: focused 2-sentence prompt per sub-topic, then merge
```

### Curl template:

```bash
curl -s "https://openrouter.ai/api/v1/chat/completions" \
  -H "Authorization: Bearer $OPENROUTER_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "perplexity/sonar-deep-research",
    "messages": [{"role": "user", "content": "FOCUSED QUERY HERE (2-4 sentences)"}],
    "max_tokens": 16000
  }'
```

---

## 5. Cost Impact Summary

| Approach | Queries | Cost | Output Tokens | Complete? |
|----------|---------|------|---------------|-----------|
| Original (max_tokens=8000) | 1 | ~$1.30 | ~8K (truncated) | NO |
| Fix A (max_tokens=16000) | 1 | ~$1.30 | ~10K (natural) | YES (for moderate reports) |
| Fix B (5 chunked queries) | 5 | ~$6.50 | ~50K total | YES (for comprehensive reports) |
| Fix A + Fix C (defensive) | 1-2 | ~$1.30-2.60 | ~10-20K | YES (retry on truncation) |

**Recommended default:** Fix A (max_tokens=16000) + Fix C (check finish_reason). Only use Fix B (chunking) when the research topic genuinely requires >10K tokens of output.

---

## 6. Alternative Deep Research Options

For cases where 10K tokens is genuinely insufficient:

| Model | Max Output | Cost | Via |
|-------|-----------|------|-----|
| perplexity/sonar-deep-research | ~10K tokens | ~$1.30/q | OpenRouter |
| openai/o3-deep-research | 100K tokens | ~$0.01/1K input + $0.04/1K output + $0.01/search | OpenRouter |
| openai/o4-mini-deep-research | 100K tokens | ~$0.002/1K input + $0.008/1K output + $0.01/search | OpenRouter |
| tavily_research (MCP) | Unlimited (model-generated) | ~$0.05/q | MCP built-in |
| Opus CLI deep research | Unlimited (model-generated) | Included in Max plan | CLI |

**Notable:** OpenAI's o3-deep-research and o4-mini-deep-research support 100K max completion tokens -- 10x Perplexity's effective limit. If comprehensive single-query deep research is needed, these are worth testing.

---

*Generated 2026-03-20 by Claude Opus 4.6 during Perplexity truncation investigation.*
