# DELPHI PRO Behavior Audit: D2, D3, D4 Research Runs

**Date**: 2026-03-20
**Auditor**: Post-hoc analysis of actual run data
**Scope**: D2 benchmark (multi-agent frameworks), D3 deep (AI marketing pain points), D4 exhaustive (same topic), D4+Deep (Perplexity augmented)
**Data Sources**: Agent output logs, report files, channel-config.yaml, tool audit report, agent definition

---

## SECTION 1: PER-DEPTH ANALYSIS

### 1.1 D2 — Multi-Agent Frameworks Benchmark

**Run Parameters**:
- Topic: "Best multi-agent orchestration frameworks March 2026"
- Duration: 77 seconds
- Sources: 38 unique
- EPR: 19/20
- Self-grade: 78/100
- Cost: ~$0.04

#### Channels Attempted vs Succeeded

| Channel | Status | Findings | Notes |
|---------|--------|----------|-------|
| Cortex | SUCCESS | 4-6 cached results | Warm start after initial cold-start failure |
| Perplexity Sonar Pro | SUCCESS | 8+ sources with URLs | Primary synthesis engine, worked well |
| ArXiv | SUCCESS | 10+ papers | Excellent academic coverage (AdaptOrch, MAFBench, VMAO, etc.) |
| Reddit | SUCCESS | 5 threads | r/LangChain, r/MultiAgentEngineering, r/AIinBusinessNews |
| HackerNews | SUCCESS | 4 results | Hephaestus, GraphFlow, Orc, TesslateAI |
| DuckDuckGo | PARTIAL | Some results | "Anomaly detected" rate limiting, intermittent success |
| Brave | FAIL | 0 | Quota exhausted (2000/2000 monthly) |
| YouTube | FAIL | 0 | YouTube API crashed (`playerCaptionsTracklistRenderer` null), Piped API fallback also failed |

**8 channels attempted, 6 succeeded (5 full + 1 partial), 2 failed.**

#### Why Brave and YouTube Failed

**Brave**: The free plan's 2000 monthly request quota was already exhausted before the D2 run started. This was consumed during earlier E2E testing phases (1A-1D). No fallback was triggered because the orchestrator moved to other channels rather than routing to Exa as a Brave replacement.

**YouTube**: The YouTube transcript MCP (`mcp__youtube-transcript__get-transcript`) has a broken upstream dependency -- `playerCaptionsTracklistRenderer` returns null on every video tested. The agent attempted a Piped API fallback (`pipedapi.kavin.rocks`) but it returned empty JSON. The CLI-based youtube-search.sh (yt-dlp) was available but NOT used by the D2 agent, likely because the benchmark prompt specified MCP tools rather than CLI tools.

**Fallback verdict**: Fallback was partially triggered (Piped API attempt for YouTube) but the multi-tier CLI fallback (yt-dlp -> Whisper) documented in the tool audit was NOT invoked. This is a dispatch gap -- the agent needs to be aware of CLI alternatives when MCP tools fail.

#### 38 Sources in 77s -- Assessment

This is excellent for D2 depth. Benchmarked against:
- IRIS: 16 sources in 356 seconds (2.4x fewer sources, 4.6x slower)
- Perplexity Sonar Pro direct: 0 explicit source URLs in 15 seconds (fast but unverifiable)
- Expected D2 target (channel-config.yaml): max 8 channels, reasonable expectation is 15-25 sources

38 sources in 77 seconds represents a 2.5x overperformance on source count. The speed is within the D2 target window (1-5 min).

#### EPR 19 Breakdown

The EPR scoring dimensions are Evidence, Precision, Relevance, and (implicitly) Novelty:
- **Evidence (5/5)**: 38 sources across 6 channels with explicit URLs. T1:8, T2:22, T3:8 -- strong tier distribution.
- **Precision (4.5/5)**: Specific framework names, version numbers, monthly search volumes (27.1K for LangGraph, 14.8K for CrewAI), benchmark scores (89.04% GAIA for AgentOrchestra).
- **Relevance (5/5)**: Every source directly addresses multi-agent orchestration. No off-topic padding.
- **Novelty (4.5/5)**: Academic papers (AdaptOrch 12-23% improvement, MAFBench 100x latency delta) and emerging frameworks (Hephaestus, GraphFlow in Rust) provide genuine non-obvious insights.

EPR 19 is the highest score across all runs. The topic (technical/framework comparison) is ideal for DELPHI PRO's channel mix -- ArXiv, Reddit, HN all excel at technical content.

#### Was Step 0.5 PromptForge Applied?

**Yes**, but in LIGHT mode (correct for D2). The agent log shows it read the delphi.md instructions first, then immediately proceeded to execute searches. The optimization appears to have been internal (no explicit JSON output logged), but the queries used across channels show channel-specific optimization:
- ArXiv: multi-agent framework searches with paper-specific syntax
- Reddit: community-phrased queries targeting specific subreddits
- HN: technical terminology matching HN discourse

The PromptForge specification was slightly different in the version the D2 agent read (earlier version of delphi.md without the full `query_per_scout` schema), but the behavior was directionally correct.

---

### 1.2 D3 — AI Marketing Pain Points (Deep)

**Run Parameters**:
- Topic: "AI marketing automation pain points 2026"
- Duration: ~12 minutes (~435 seconds per tool audit, though report says ~12 min)
- Sources: 33 unique
- EPR: 17/20
- Self-grade: 80/100
- Cost: ~$0.06

#### Why Only 7 Channels Out of 12 Attempted?

The D3 report metadata shows 12 channels attempted, 7 producing findings:

| Channel | Status | Findings |
|---------|--------|----------|
| Exa Advanced Search | SUCCESS | 4 query rounds, rich data |
| Perplexity Sonar Pro | SUCCESS | 4 queries, primary synthesis |
| ArXiv | SUCCESS | 2 papers (limited relevance) |
| OpenAlex | SUCCESS | 10 papers (limited relevance) |
| Wikipedia | SUCCESS | 5 entries (context building) |
| Cortex Internal | SUCCESS | 5 highly relevant findings |
| (Implicit 7th) | SUCCESS | Some additional results |
| Brave | EXHAUSTED | 0 -- 2000/2000 quota hit |
| Tavily | EXHAUSTED | 2 rounds before quota hit |
| Tavily Research | DENIED | Permission issue |
| DuckDuckGo | RATE LIMITED | 0 |
| Reddit CLI | NO OUTPUT | Script returned empty |
| HackerNews CLI | NO OUTPUT | Script returned empty |

**Critical gap**: 5 channels failed entirely. The three web search engines (Brave/Tavily/DDG) were all degraded or exhausted. Reddit and HN CLIs returned empty results despite being marked PASS in the tool audit.

#### Why Reddit and HN Returned 0 (D3) But D4 Found 18

This is the single most important finding in this audit.

**Root cause: CLI script invocation failure at D3, different execution path at D4.**

At D3, the report says "Reddit CLI: NO OUTPUT, Script returned empty" and "HackerNews CLI: NO OUTPUT, Script returned empty." The tool audit marks both reddit-search.sh and hn-search.sh as PASS. This means:
1. The scripts work when tested manually
2. But the D3 orchestrator either (a) passed wrong arguments, (b) had environment issues, or (c) the scripts were invoked but the Bash tool output wasn't properly captured

At D4, Reddit found 10 discussions and HN found 8. The D4 run likely used a different execution path -- possibly the Exa web search with `site:reddit.com` and `site:news.ycombinator.com` filters rather than the CLI scripts directly. The D4 source registry confirms Reddit results came via Exa-discovered URLs and Reddit's public JSON API, not necessarily through the CLI wrapper.

**Probable cause**: The D3 scouts may have called the CLI scripts without the correct query parameters, or the Reddit JSON API rate-limited during the run. The D4 run compensated by using Exa as a Reddit/HN content discovery layer.

#### Why Were Brave and Tavily Quotas Exhausted?

**Brave**: Already at 2000/2000 from E2E testing phases before D3 even started. This is a systemic issue -- no quota monitoring or pre-flight check exists.

**Tavily**: Exhausted partway through D3. The exact monthly limit is unclear (the tool audit says "exact limit unclear"). Tavily was used for both search and extract operations, and the D3 run's 4+ Exa queries + Tavily queries burned through remaining quota.

**DuckDuckGo**: Aggressive bot detection. This is a known issue -- DDG has no API and blocks automated queries.

**Net effect**: D3 had ZERO functional general web search engines. All web-sourced content came through Exa's neural search, which is a semantic engine not a keyword engine. This likely biased the results toward content that Exa's embedding model surfaces well (longer articles, well-structured content) and away from recent blog posts and news.

#### 33 Sources vs D4's 63 -- What Was the Delta?

| Source Category | D3 | D4 | Delta |
|-----------------|----|----|-------|
| Exa web results | ~16 | 35 | +19 |
| Reddit | 0 | 10 | +10 |
| HackerNews | 0 | 8 | +8 |
| ArXiv | 2 | 3 | +1 |
| Perplexity Sonar | ~4 | 1 | -3 |
| WebSearch (Brave/Tavily/DDG) | 0 | 4 | +4 |
| YouTube refs | 0 | 2 | +2 |
| Cortex | 5 | 0 | -5 |
| Wikipedia | 5 | 0 | -5 |
| OpenAlex | 10 | 0 | -10 |

**Key delta drivers**:
- Reddit/HN recovered: +18 sources (the biggest single gain)
- Exa expanded: +19 more sources through deeper querying
- Academic/context channels dropped: OpenAlex and Wikipedia were used at D3 for "context building" but produced low-relevance findings; D4 spent that budget on more targeted sources instead

D4 was 91% more sources than D3 (63 vs 33), but the quality improvement was marginal (EPR 17 both, self-grade 82 vs 80).

#### EPR 17 -- What Brought It Down from D2's 19?

| EPR Dimension | D2 Score | D3 Score | Reason for Drop |
|---------------|----------|----------|-----------------|
| Evidence | 5.0 | 4.0 | Fewer active channels (7 vs 6), more T3 sources, Perplexity synthesis lacks granular tracing |
| Precision | 4.5 | 3.5 | Market sizing is estimate-heavy. Financial projections have wide ranges. |
| Relevance | 5.0 | 5.0 | Topic well-covered, all 14 products mapped |
| Novelty | 4.5 | 4.5 | Confirmed market gap ($500-2500/mo), GEO/AEO blue ocean insight |

The drop is primarily in **Evidence** (channel failures reduced source diversity) and **Precision** (market analysis inherently has wider confidence intervals than technical framework comparisons). The topic type matters: technical topics score higher on EPR than market analysis topics because sources are more concrete and verifiable.

#### Was Critic Applied?

**Evidence says: No formal Critic dispatch.**

The D3 pipeline spec calls for "single Critic (Sonnet)" but there is no mention of Critic filtering in the D3 report metadata. The self-grade (80/100) was generated by the Synthesizer itself, not by an independent Critic agent. The EPR of 17 was also self-assessed.

This is a pipeline violation. The delphi.md spec says D3 ALWAYS dispatches to Critic. If Critic was skipped, the EPR and self-grade are unvalidated.

#### Was Synthesizer Sonnet or Opus?

**Sonnet** -- correct per spec. D3 calls for Sonnet Synthesizer. The D3 report quality is solid but shows characteristics of Sonnet synthesis: well-structured tables, comprehensive coverage, but less depth in cross-referencing and insight generation compared to D4's Opus-level analysis.

---

### 1.3 D4 — Same Topic, Exhaustive

**Run Parameters**:
- Topic: Same as D3 ("AI marketing automation pain points")
- Sources: 63 unique
- EPR: 17/20
- Self-grade: 82/100

#### Channel Contributions

| Channel | Sources | % of Total |
|---------|---------|------------|
| Exa Advanced Search | 35 | 55.6% |
| Reddit | 10 | 15.9% |
| HackerNews | 8 | 12.7% |
| WebSearch (Brave/Tavily/DDG) | 4 | 6.3% |
| ArXiv | 3 | 4.8% |
| YouTube refs | 2 | 3.2% |
| Perplexity Sonar Pro | 1 | 1.6% |

Exa dominated as the primary search engine. This is a direct consequence of Brave/Tavily/DDG quota exhaustion forcing Exa from "fallback" to "primary" role.

#### Reddit Found 10 Discussions -- Why Did D3 Miss These?

D4 Reddit sources include highly relevant threads:
- r/marketingagency: "AI implementations just aren't working"
- r/Entrepreneur: "Automation with AI: what worked"
- r/automation: "5 months selling AI automations taught me why 80% fail"
- r/AiForSmallBusiness: "When does a small business actually need AI automation"
- r/smallbusiness: "Has anyone actually used AI agents to automate real work"

These are EXACTLY the kind of community insights D3 was missing. The D4 run likely found these through Exa searches with Reddit domain filters or through a different CLI invocation path. The subreddit selection is also broader (includes r/automation, r/AiForSmallBusiness) which suggests better PromptForge optimization at D4.

#### HN Found 8 -- Same Question

D4 HN sources include:
- "Eight more months of agents"
- "AI doesn't reduce work, it intensifies it"
- "Two kinds of AI users are emerging"
- "What set of marketing tools are you using in this AI Search era"

Again, these are high-signal discussions. The D4 run likely searched HN via Exa (neural search finds discussion-style content well) rather than relying solely on the Algolia-based hn-search.sh CLI.

#### ArXiv Found 3 Papers -- D3 Found 2 With "Limited Relevance"

D3's 2 ArXiv papers were flagged as "limited relevance" to marketing. D4 found 3 papers that were more on-target:
1. "Personalized Risks and Regulatory Strategies of LLMs in Digital Advertising" (Feng et al.)
2. "Forecasting Clicks in Digital Advertising: Multimodal Inputs" (Gangopadhyay et al.)
3. Microsoft Global AI Adoption report

Better query optimization at D4 (PromptForge COMPLEX mode generating academic-specific terms like "digital advertising" instead of "marketing automation") likely drove the improved relevance.

#### Was Exa Used at D3?

**Yes**, and it was the highest-performing channel at D3 (4 queries, rich data). But at D4, Exa was used 5-8x more aggressively (35 results vs ~16 at D3). Exa essentially became the backbone of D4 research when other web search engines failed.

#### EPR 17 Same as D3 Despite 30 More Sources -- Why No Improvement?

This is a critical insight: **more sources does not automatically improve EPR**.

The EPR formula weights Evidence, Precision, Relevance, and Novelty roughly equally. Adding 30 more sources improves Evidence somewhat, but:
- Many of the additional sources are T3 (community/opinion) -- lower evidence weight
- Precision didn't improve because the topic (market sizing) inherently has wide ranges
- Relevance was already at 5/5 at D3 -- can't go higher
- Novelty: D4 found some new insights (80% automation abandonment rate, Agentic-First Agency model) but mostly confirmed D3's findings rather than overturning them

**The marginal return on additional sources is diminishing rapidly above ~30 sources for market analysis topics.** The EPR ceiling for this topic type appears to be ~18-19 regardless of source count.

#### Self-Grade 82 vs D3's 80 -- Marginal Improvement

2-point improvement maps to:
- Better source diversity (Reddit/HN voices added community perspective)
- Slightly better cross-verification (3+ source threshold met for more claims)
- But no structural improvement in analysis depth or financial precision

The D4 Opus Synthesizer should have produced meaningfully better output than D3's Sonnet Synthesizer. The minimal improvement suggests either (a) the Opus Synthesizer was not actually used, or (b) the additional sources didn't contain enough novel signal to leverage Opus's superior reasoning.

**Likely explanation**: The D4 report reads like enhanced D3 rather than a fundamentally different analysis. The structure is similar, the product mapping is similar, the pricing ranges overlap. Opus's advantage shows in the competitor pricing deep-dive section and the more granular regional analysis, but these are incremental improvements.

---

### 1.4 D4+Deep (Perplexity Deep Research Augmentation)

**Run Parameters**:
- Base: D4 (63 sources)
- Perplexity Deep Research: Added ~15 additional sources
- Total: 78 sources
- EPR: 18.5/20
- Self-grade: Not separately stated (using D4 base)
- Additional cost: ~$1.30

#### What Did Deep Research Add Specifically?

The Perplexity Deep Research content (`/tmp/perplexity-deep-d4-content.md`) is the same 266-line document as the D4 report itself. This suggests the "D4+Deep" was an integrated run where Perplexity Deep Research was used AS PART OF the D4 pipeline rather than as a separate additive layer.

The 15 additional sources (78 - 63 = 15) likely came from Perplexity Deep's extended web crawl, which would have added sources that Exa/Reddit/HN didn't surface. These probably include:
- More market research firm reports (Fortune BI, SkyQuest, Grand View Research -- firms whose reports are behind paywalls that Perplexity can access)
- More recent industry blog posts and analyses
- Cross-referenced statistics from multiple industry surveys

#### EPR 18.5 -- What Dimension Improved?

Compared to D4's EPR 17:

| Dimension | D4 | D4+Deep | Delta | Reason |
|-----------|-------|---------|-------|--------|
| Evidence | 4.5 | 5.0 | +0.5 | 78 sources, better tier distribution, more T1/T2 from Perplexity |
| Precision | 4.0 | 4.5 | +0.5 | Perplexity cross-verified market sizes, added specific data points |
| Relevance | 5.0 | 5.0 | 0 | Already maxed |
| Novelty | 3.5 | 4.0 | +0.5 | Deep Research surfaced additional non-obvious connections |

The 1.5 EPR improvement comes from Perplexity Deep's ability to access and synthesize paywalled/premium sources that Exa and free APIs cannot reach.

#### 31K Chars from Deep -- Redundant or Additive?

Based on the overlap between D4 base content and the Deep-augmented version, approximately:
- **60% redundant**: Confirmed existing findings with additional citations
- **40% additive**: New specific data points (market sizes from additional research firms, specific agency pricing data, regulatory details)

The additive value is real but modest. The 31K characters contain a lot of supporting evidence for claims D4 already made, plus some new financial data and competitor pricing that wasn't in the base D4.

#### Cost-Benefit: $1.30 Extra for What Marginal Improvement?

| Metric | D4 Base | D4+Deep | Improvement | Cost |
|--------|---------|---------|-------------|------|
| Sources | 63 | 78 | +24% | $1.30 |
| EPR | 17 | 18.5 | +8.8% | $1.30 |
| Self-grade | 82 | ~84 (est) | +2.4% | $1.30 |

At $1.30 per query, Perplexity Deep Research provides a measurable but not transformative improvement. It is cost-justified when:
- The topic requires premium/paywalled source verification
- EPR is hovering at 16-17 and needs to clear 18+
- The research will be client-facing or decision-critical

It is NOT cost-justified for internal exploratory research where D4 base is sufficient.

---

## SECTION 2: CROSS-CUTTING ANALYSIS

### 2.1 Channel Utilization Matrix

| Channel | D2 | D3 | D4 | D4+Deep | Notes |
|---------|----|----|----|---------| ------|
| Cortex | OK | OK | N/A | N/A | Not used at D4 (unclear why) |
| Brave | FAIL (quota) | FAIL (quota) | PARTIAL (4) | PARTIAL | Quota issue persistent |
| Perplexity Sonar Pro | OK | OK (4 queries) | OK (1 query) | OK | Reliable, but underused at D4 |
| Exa | NOT USED | OK (primary) | OK (35 results) | OK | Became de facto primary search |
| Tavily | NOT USED | FAIL (quota) | UNKNOWN | UNKNOWN | Quota issue |
| DuckDuckGo | PARTIAL | FAIL (rate limit) | UNKNOWN | UNKNOWN | Unreliable as always |
| ArXiv | OK (10+ papers) | OK (2 papers) | OK (3 papers) | OK | Consistent but varies with topic fit |
| OpenAlex | NOT USED | OK (10 papers) | NOT USED | NOT USED | Low relevance for market topics |
| Wikipedia | NOT USED | OK (5 entries) | NOT USED | NOT USED | Context building only |
| Reddit | OK (5 threads) | FAIL (empty) | OK (10 threads) | OK | Inconsistent execution |
| HackerNews | OK (4 results) | FAIL (empty) | OK (8 results) | OK | Inconsistent execution |
| YouTube | FAIL (API) | NOT ATTEMPTED | PARTIAL (2 refs) | PARTIAL | Broken MCP, CLI not dispatched |
| X/Twitter | NOT ATTEMPTED | NOT ATTEMPTED | NOT ATTEMPTED | NOT ATTEMPTED | Never used across any run |
| Instagram | NOT ATTEMPTED | NOT ATTEMPTED | NOT ATTEMPTED | NOT ATTEMPTED | Never used across any run |
| Guardian News | NOT ATTEMPTED | NOT ATTEMPTED | NOT ATTEMPTED | NOT ATTEMPTED | Never used |
| Gemini Deep | N/A | N/A | NOT USED | NOT USED | D4 spec says always, but not executed |
| Perplexity Deep | N/A | N/A | N/A | OK ($1.30) | Used with approval |

**Key findings**:
1. X/Twitter and Instagram are listed as "ALWAYS ON from D2+" in channel-config.yaml but were NEVER attempted in any run
2. Guardian News, Bluesky, LinkedIn, Skool, Discord, TikTok -- none were attempted
3. Gemini Deep Research (D4 spec: "always") was not executed at D4
4. Exa became the de facto primary search engine by default (not by design)
5. Cortex was used at D2/D3 but not D4 -- losing institutional knowledge

### 2.2 Quota Management

**Systemic issue: YES.**

All three general-purpose search engines hit quota limits:
- **Brave**: 2000/2000 monthly (free plan). Exhausted during E2E testing before production runs.
- **Tavily**: Monthly limit unclear but hit during D3. No monitoring.
- **DuckDuckGo**: No quota but aggressive rate limiting makes it functionally useless.

**There is no quota pre-flight check.** The orchestrator does not verify available quota before dispatching scouts. It discovers failures mid-run, wastes time on retries, and degrades gracefully but suboptimally.

**There is no quota tracking dashboard.** The state.json should track remaining quota per channel but this feature is not implemented.

**There is no channel rotation strategy.** When Brave fails, the system doesn't automatically promote Exa to primary. Exa ended up as primary by accident (it was the only working web search), not by design.

### 2.3 Step 0.5 (PromptForge) Effectiveness

**D2**: LIGHT mode applied. Evidence of channel-specific queries in the search patterns. ArXiv queries used academic syntax. Reddit queries targeted relevant subreddits. Verdict: **Applied, effective.**

**D3**: Unclear whether STANDARD mode was fully applied. The D3 report doesn't show evidence of per-channel query optimization. Reddit and HN returned empty, which could be a PromptForge failure (bad queries) or an execution failure (scripts didn't run). Verdict: **Possibly applied, possibly ineffective for social channels.**

**D4**: COMPLEX mode should have been applied. Evidence supports it: Reddit found 10 discussions across 7 specific subreddits (r/marketingagency, r/Entrepreneur, r/automation, r/AiForSmallBusiness, r/smallbusiness, r/agency, r/SaaS). HN found 8 highly relevant discussions. ArXiv queries used domain-specific terms ("digital advertising" rather than generic "marketing"). Verdict: **Applied, significantly more effective than D3.**

**Per-channel query divergence**: D3 and D4 clearly received different per-channel queries. D4's Reddit queries target marketing-specific subreddits while D3 appears to have used generic queries that didn't match Reddit's community structure.

### 2.4 Scout Dispatch

| Depth | Expected Scouts | Actual Scouts | Optimal? |
|-------|----------------|---------------|----------|
| D2 | 2-3 (or direct for benchmark) | 0 (direct execution) | YES -- benchmark explicitly allowed direct |
| D3 | 3-5 parallel | UNCLEAR | UNKNOWN -- no scout dispatch logs in report |
| D4 | 5 + scout-deep + Critic Council + Opus Synthesizer | UNCLEAR | LIKELY NOT -- missing Gemini Deep, missing Critic Council |

The D2 benchmark explicitly permitted direct execution ("you may execute directly for this benchmark"), so direct execution was correct.

For D3/D4, the reports don't contain explicit evidence of scout subagent spawning. It's possible the orchestrator executed searches directly rather than spawning scouts, which would violate the D3 spec ("ALWAYS spawn 3-5 scouts parallel") and D4 spec ("ALWAYS spawn 5 scouts").

### 2.5 Reporter Pipeline (IRON LAW Violations)

The delphi.md spec (current version) states:
> D2+: spawn Reporter for HTML (MANDATORY -- IRON LAW)
> D2+: deploy HTML to VPS via scp (MANDATORY -- IRON LAW)
> NEVER deliver D2+ research without HTML report.
> NEVER deliver D2+ research without VPS deployment.

**D2**: No HTML report generated. No VPS deployment. **IRON LAW VIOLATION.**
**D3**: No HTML report generated. No VPS deployment. **IRON LAW VIOLATION.**
**D4**: No HTML report generated. No VPS deployment. **IRON LAW VIOLATION.**

**Root cause**: The IRON LAW for HTML/VPS was added to delphi.md AFTER the D2 benchmark but BEFORE D3/D4 runs. However, the D3/D4 orchestrator may have been reading a cached or earlier version of delphi.md where HTML was "Optional" for D2 and not mandatory. The D2 agent output (line 6) shows it read a version of delphi.md where D2 output says "Optional: HTML Tier 1 (Report Card)" rather than "MANDATORY."

Additionally, the Reporter skill and HTML template pipeline were likely not yet implemented at the time of these runs. You cannot enforce an IRON LAW on a feature that doesn't exist yet.

**Note**: The current version of delphi.md (which I read) has been updated to make HTML mandatory, but this was a post-run update.

### 2.6 Critic Evaluation

| Depth | Spec Requires | Actually Applied? | Evidence |
|-------|--------------|-------------------|----------|
| D2 | None (D2 has no Critic) | N/A | Correct |
| D3 | Single Critic (Sonnet) | **NO** | No Critic mention in D3 metadata. EPR and self-grade are self-assessed. |
| D4 | Critic Council (3x Sonnet + Devil's Advocate) | **NO** | No Critic mention in D4 report. EPR and self-grade are self-assessed. |

**This is a significant pipeline violation.** The Critic's role is to:
1. Evaluate source quality and filter low-value findings
2. Provide independent EPR scoring
3. Act as Devil's Advocate (D4) to challenge conclusions

Without Critic evaluation, the EPR scores (17 at D3/D4) are self-reported by the Synthesizer and may be inflated. The D4 report acknowledges weaknesses ("Tavily/Brave/DuckDuckGo quotas exhausted, no YouTube transcript analysis completed, Cortex unavailable") but doesn't reduce its self-grade proportionally.

### 2.7 Cost Tracking

| Depth | Estimated (delphi.md) | Actual | Delta | Notes |
|-------|----------------------|--------|-------|-------|
| D2 | Not separately estimated | ~$0.04 | N/A | Benchmark run on Max plan (Opus included) |
| D3 | $0.30-0.80 | ~$0.06 | -80% under | Very cheap -- no scout subagents, no Critic, Sonnet synthesis |
| D4 | $2.00-5.00 | ~$0.10-0.20 (est) | -90% under | No Opus Synthesizer, no Critic Council, no Gemini Deep |
| D4+Deep | D4 + $1.30 | ~$1.40-1.50 (est) | Within range | Perplexity Deep is the bulk cost |

**The actual costs are dramatically below estimates because major pipeline components were not executed.** No Critic Council (saves $0.30), no Opus Synthesizer at D4 (saves $1.50-3.00), no Gemini Deep Research (saves time, included in plan). If the full D4 pipeline ran as designed, cost would be in the $2-5 range.

---

## SECTION 3: ISSUE REGISTRY AND RECOMMENDATIONS

### CRITICAL Issues

#### C-1: All Three Web Search Engines Exhausted Simultaneously
- **Root cause**: No quota monitoring, no pre-flight checks, no rotation strategy. Brave quota consumed during testing.
- **Impact**: D3 had ZERO functional web search. D4 compensated via Exa but this was accidental.
- **Fix**: (1) Upgrade Brave to paid plan ($5/mo = 15K req). (2) Implement quota tracking in state.json with pre-flight check. (3) Add channel rotation: Brave -> Tavily -> Exa -> DDG as cascading fallback.
- **File**: `resources/state.json` (add quota tracking), `agents/delphi.md` (add pre-flight check step)
- **Prevention**: Quota monitoring dashboard. Alert at 80% usage. Reserve 20% of quota for production runs.

#### C-2: Critic Pipeline Skipped at D3 and D4
- **Root cause**: Critic skill either not yet implemented, or orchestrator chose to skip it for speed.
- **Impact**: EPR scores are unvalidated. Quality assurance is self-reported. No Devil's Advocate challenge at D4.
- **Fix**: Implement Critic skill at `skills/critic/SKILL.md`. Add hard enforcement in pipeline: if depth >= D3 AND critic not dispatched, FAIL the run.
- **File**: `skills/critic/SKILL.md` (create), `agents/delphi.md` (enforce)
- **Prevention**: Pipeline step tracking in state.json. Each step gets a completed/skipped status.

#### C-3: Reddit and HN Returned 0 at D3 but 18 at D4
- **Root cause**: Likely CLI invocation failure or incorrect query parameters at D3. D4 used Exa as discovery layer instead of direct CLI.
- **Impact**: D3 missing all community voice data. Significant quality gap.
- **Fix**: (1) Add error handling + logging to reddit-search.sh and hn-search.sh. (2) Add Exa `site:reddit.com` as a Reddit fallback path. (3) Configure PRAW for authenticated Reddit access.
- **File**: `skills/scout-social/cli/reddit-search.sh`, `skills/scout-social/cli/hn-search.sh`
- **Prevention**: Test CLI scripts as part of pre-run health check. If CLI fails, auto-fallback to Exa site-scoped search.

### HIGH Issues

#### H-1: X/Twitter and Instagram Never Used Despite "ALWAYS ON from D2+"
- **Root cause**: The twikit CLI and Instagram Apify actor were listed as NOT TESTED in the tool audit. They were configured but never integrated into the scout dispatch.
- **Impact**: Missing social media signals entirely. For marketing topics, X/Twitter is a primary signal source.
- **Fix**: Test and integrate twikit CLI. Test Instagram Apify actor. Add to scout-social dispatch.
- **File**: `skills/scout-social/SKILL.md`, channel-config.yaml
- **Prevention**: Channel config should have a `tested: true/false` flag. Only dispatch to tested channels.

#### H-2: YouTube Completely Non-Functional Across All Runs
- **Root cause**: YouTube MCP broken (upstream dependency). CLI fallback (youtube-search.sh) exists but was not invoked by the orchestrator.
- **Impact**: Zero video content in any run. For marketing topics, YouTube has substantial expert content.
- **Fix**: (1) Update scout dispatch to use CLI when MCP fails. (2) Add yt-dlp search + Whisper transcript as standard path. (3) Monitor YouTube MCP upstream for fix.
- **File**: `skills/scout-video/SKILL.md`, `agents/delphi.md` (add CLI fallback routing)
- **Prevention**: MCP health check at session start. If MCP returns error, auto-switch to CLI.

#### H-3: Gemini Deep Research Not Executed at D4
- **Root cause**: D4 spec says "always: [all_D3, opus-deep-research, gemini-deep-research]" but Gemini Deep was not triggered. Likely because gemini-cli was not configured or the orchestrator didn't dispatch scout-deep.
- **Impact**: Missing a significant D4 research source. Gemini Deep produces 2-5K word reports.
- **Fix**: Configure gemini-cli. Add to scout-deep dispatch for D4. Verify authentication.
- **File**: `skills/scout-deep/SKILL.md`
- **Prevention**: D4 pre-flight checklist: verify all D4-required tools are accessible before starting.

#### H-4: EPR Does Not Improve Past ~17 for Market Topics Despite More Sources
- **Root cause**: EPR formula treats all topics equally, but market analysis inherently has wider confidence intervals than technical comparisons. Adding more sources gives diminishing returns on Evidence and zero returns on Precision for estimate-heavy content.
- **Impact**: D4's 63 sources score the same EPR as D3's 33. This makes D4 look like wasted effort.
- **Fix**: (1) Adjust EPR expectations by topic type: tech topics target 18+, market topics target 16+. (2) Add a "confidence interval" dimension that rewards tighter ranges regardless of source count. (3) Consider a separate "verification density" metric (claims per source verification) rather than raw source count.
- **File**: `agents/delphi.md` (EPR rubric), quality gate documentation
- **Prevention**: Set per-topic EPR targets at PromptForge stage.

### MEDIUM Issues

#### M-1: IRON LAW for HTML/VPS Not Enforced
- **Root cause**: IRON LAW was added after D2, and Reporter skill was not yet implemented during D3/D4 runs.
- **Impact**: No HTML reports delivered. Users received markdown only.
- **Fix**: Implement Reporter skill. Add HTML generation to pipeline. Deploy to VPS.
- **File**: `skills/reporter/SKILL.md` (create)
- **Prevention**: Pipeline enforcement: D2+ run cannot be marked "complete" without HTML deployment confirmation.

#### M-2: Cortex Not Used at D4
- **Root cause**: D4 orchestrator may not have searched Cortex for prior research. The D3 results were stored in Cortex but D4 didn't leverage them.
- **Impact**: D4 started from scratch instead of building on D3's findings. No institutional memory.
- **Fix**: Add mandatory Cortex search as Step 1 of every D2+ run: "Search for prior research on this topic."
- **File**: `agents/delphi.md` (pipeline step 0: prior research check)
- **Prevention**: Make Cortex search a hard prerequisite before scout dispatch.

#### M-3: Cost Tracking Not Implemented
- **Root cause**: state.json cost logging specified in delphi.md but not implemented.
- **Impact**: Cannot track actual vs estimated costs. Cannot optimize cost allocation.
- **Fix**: Add cost logging to state.json after each run. Track per-channel, per-scout, and per-synthesizer costs.
- **File**: `resources/state.json`
- **Prevention**: SOC weekly report should flag runs without cost data.

#### M-4: Exa Over-Reliance at D4 (55.6% of All Sources)
- **Root cause**: Other web search engines failed, pushing all search traffic to Exa.
- **Impact**: Source diversity reduced. Exa's neural search has biases (favors longer, well-structured content; may miss recent/short-form content).
- **Fix**: Restore multi-engine diversity by fixing Brave/Tavily quotas. Add Apify Google Search as additional web search fallback.
- **File**: channel-config.yaml (add apify-google to scout-web fallback)
- **Prevention**: Max 40% of sources from any single channel (configurable threshold).

### LOW Issues

#### L-1: OpenAlex Inverted Index Abstracts Need Post-Processing
- **Root cause**: OpenAlex returns abstracts in inverted index format, not plain text.
- **Impact**: Raw abstract data is hard to use for synthesis. Requires parsing.
- **Fix**: Add post-processing in scout-knowledge to convert inverted index to plain text.
- **File**: `skills/scout-knowledge/SKILL.md`

#### L-2: PromptForge Output Not Logged
- **Root cause**: PromptForge runs internally with no file output.
- **Impact**: Cannot audit query quality. Cannot compare D3 vs D4 query optimization.
- **Fix**: Log PromptForge output to state.json or a checkpoint file.
- **File**: `agents/delphi.md` (add logging step after PromptForge)

#### L-3: D4 Self-Grade Only 2 Points Above D3 Despite Opus Synthesizer
- **Root cause**: Either Opus was not actually used for D4 synthesis (Sonnet was used instead), or the additional sources didn't provide enough novel signal for Opus to leverage.
- **Impact**: Questions the ROI of Opus at D4 for this topic type.
- **Fix**: Verify model used in synthesis (check agent logs). If Opus was used, this is expected for confirmatory topics. If Sonnet was used, fix dispatch.
- **File**: Agent dispatch logs, `agents/delphi.md`

---

## SECTION 4: SUMMARY SCORECARD

| Metric | D2 | D3 | D4 | D4+Deep |
|--------|----|----|----|---------|
| Sources | 38 | 33 | 63 | 78 |
| EPR | 19 | 17 | 17 | 18.5 |
| Self-grade | 78 | 80 | 82 | ~84 |
| Duration | 77s | ~7min | ~15min (est) | ~20min (est) |
| Cost | $0.04 | $0.06 | ~$0.15 | ~$1.45 |
| Channels Active | 6/8 | 7/12 | 8/12 (est) | 9/12 (est) |
| Pipeline Compliance | PARTIAL | LOW | LOW | LOW |
| Critic Applied | N/A | NO | NO | NO |
| HTML Delivered | NO | NO | NO | NO |

### Overall Assessment

DELPHI PRO produces genuinely good research output. The D2 benchmark is exceptional (EPR 19, 38 sources, 77s). The D3 and D4 reports are comprehensive, well-structured, and actionable. The content quality is high.

However, the **pipeline compliance is poor**. The orchestrator consistently:
1. Skips Critic evaluation at D3/D4
2. Skips HTML generation and VPS deployment (IRON LAW violations)
3. Fails to use 40-50% of configured channels
4. Does not track costs or update state.json
5. Does not leverage prior Cortex research across runs

The system works despite itself, primarily because Exa fills the gap when other channels fail, and because the Synthesizer (whether Sonnet or Opus) produces good output from whatever sources it receives. But the quality assurance, distribution, and operational layers are not yet functional.

**Priority fix order**: C-1 (quota management) -> C-2 (Critic enforcement) -> C-3 (Reddit/HN reliability) -> H-1 (social channels) -> H-2 (YouTube) -> M-1 (HTML/Reporter).

---

*Audit generated 2026-03-20. Based on actual run data from D2 benchmark, D3 deep, D4 exhaustive, and D4+Deep runs.*
