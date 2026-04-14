# Content Gaps & KSL Analysis
## Bridging DELPHI PRO's Missing Content Types + Extending Optimization
**Date:** 2026-03-20 | **Author:** Claude Opus 4.6

---

## PART A: Missing Content Types — How to Find Them

The Content Quality Benchmark identified 5 content types missing from ALL reports (Benchmark, D3, D4, D4+Deep). This section proposes concrete changes to PromptForge, scouts, Critic, and Synthesizer to fill each gap.

---

### 1. Customer Interviews / First-Person Accounts

**Why it matters:** All 4 reports are secondary research. Zero first-hand conversations. D4 came closest with Reddit quotes ("AI felt like it wasn't for me"), proving the channel CAN surface this data — it just wasn't specifically targeted.

#### Best Channels

| Channel | Effectiveness | Why |
|---|---|---|
| Reddit (r/smallbusiness, r/Entrepreneur, r/SaaS) | HIGH | People write mini-essays about their experiences. "I tried X and here's what happened" posts are common. |
| HackerNews | MEDIUM-HIGH | "Show HN" and "Ask HN" threads contain practitioner accounts. Less emotional, more technical. |
| YouTube | MEDIUM | Founder vlogs, "I built X" videos, agency case study walkthroughs. Transcripts extractable. |
| X/Twitter | LOW-MEDIUM | Short-form, less depth. But quote threads can contain experience narratives. |
| Brave/Tavily | LOW | Blog posts sometimes contain founder stories, but hard to filter from marketing content. |

#### PromptForge Changes (Step 0.5 `query_per_scout`)

Add to `sub_questions` generation at D3/D4:
```
"What do real users/practitioners say about their first-hand experience with [topic]?"
"What failures or surprises did people encounter when implementing [topic]?"
```

Add to `query_per_scout.scout-social.reddit`:
```json
{
  "query": "[topic] experience 'I tried' OR 'my experience' OR 'switched from' OR 'we built' OR 'lessons learned'",
  "subreddits": ["smallbusiness", "Entrepreneur", "SaaS", "startups", "indiehackers"]
}
```

Add to `query_per_scout.scout-social.hackernews`:
```
"Ask HN [topic] experience" OR "Show HN [topic]" OR "[topic] lessons learned"
```

Add to `query_per_scout.scout-video`:
```
"[topic] case study my experience building review 2026"
```

#### Scout SKILL.md Changes

**scout-social/SKILL.md** — Add new query template section:

```markdown
### First-Person Account Extraction (D3+ only)
When dispatched with `extract_mode: "first_person"`:
- Reddit: Prioritize posts starting with "I", "We", "My", "Our"
- Reddit: Filter for posts with 500+ characters (substantial accounts, not drive-by comments)
- Reddit: Sort by top/month to get validated experiences (community-upvoted)
- HackerNews: Filter for "Show HN" and "Ask HN" prefixes
- HackerNews: Look for comments with "In my experience", "At my company", "We found that"
- Tag findings with `finding_type: "first_person_account"` in output
```

**scout-video/SKILL.md** — Add query template variant:

```markdown
### Case Study / Experience Videos
When topic context includes "first_person" or "experience":
- YouTube query: "[topic] case study OR vlog OR 'my experience' OR 'what I learned' {year}"
- Prioritize videos from small channels (100-50K subs) — more authentic, less polished marketing
- Extract founder/practitioner name from channel info
```

#### Critic Changes

Add evaluation dimension check (not a new score — a flag):
```
first_person_evidence_present: boolean
first_person_count: number (how many findings contain first-person accounts)
```

If `first_person_count == 0` at D3+, flag: `"WARNING: No first-person accounts found. Consider supplementary Reddit/HN search."`

#### Synthesizer Changes

Add optional report section at D3+:
```markdown
## Practitioner Perspectives
What real users and builders say about [topic] — direct quotes and experiences
from Reddit, HackerNews, and YouTube case studies.

[Quote from Reddit user] — r/smallbusiness, [date]
[Quote from HN comment] — HackerNews, [date]
```

---

### 2. Competitive Product Teardowns

**Why it matters:** Reports name competitors but nobody actually used the products. D3 found "only 4/33 agencies offer GEO" — good signal. D4 mapped pricing tiers with named competitors. But neither did feature-by-feature comparison.

#### Best Channels

| Channel | Effectiveness | Why |
|---|---|---|
| Brave/Tavily (review sites) | HIGH | G2, Capterra, TrustRadius host detailed feature comparisons. |
| YouTube | HIGH | "X vs Y" comparison videos are a content genre. Transcripts give feature-level detail. |
| HackerNews | MEDIUM | "Alternative to X" threads often contain detailed teardowns. |
| Reddit | MEDIUM | r/SaaS and r/marketing have "which tool should I use" threads with feature lists. |
| Exa (neural search) | MEDIUM | Semantic search can find comparison articles that keyword search misses. |

#### PromptForge Changes

Add to `sub_questions` at D3/D4:
```
"How does [product A] compare feature-by-feature to [product B] and [product C]?"
"What are the main alternatives to [topic] and how do they differ in features, pricing, and target market?"
```

Add to `query_per_scout.scout-web`:
```
"[product A] vs [product B] comparison features pricing review {year}"
"[topic category] comparison chart alternatives G2 Capterra {year}"
```

Add to `query_per_scout.scout-social.reddit`:
```json
{
  "query": "[product A] vs OR alternative OR 'switched from' OR comparison",
  "subreddits": ["SaaS", "marketing", "smallbusiness", "startups"]
}
```

Add to `query_per_scout.scout-video`:
```
"[product A] vs [product B] comparison review {year}"
```

#### Scout SKILL.md Changes

**scout-web/SKILL.md** — Add teardown query pattern:

```markdown
### Competitive Teardown Queries (D3+ only)
When dispatched with `extract_mode: "competitive_teardown"`:
- Brave: Add `site:g2.com OR site:capterra.com OR site:trustradius.com` to find review platform comparisons
- Brave: Use "[product] vs" pattern to find head-to-head comparison articles
- Tavily: Use `search_depth: "advanced"` to extract comparison tables from review articles
- Exa: Neural search for "comprehensive comparison of [product category] tools {year}"
- Tag findings with `finding_type: "competitive_teardown"` in output
```

**scout-social/SKILL.md** — Add HN teardown pattern:

```markdown
### Competitive Discussion Queries
- HackerNews: "[product] alternative" or "best [category] tools" — sort by points for quality
- Reddit: "which [category] tool" or "[product A] vs" in relevant subreddits
```

#### Critic Changes

Add flag:
```
competitive_context_present: boolean
competitor_count: number (how many unique competitors mentioned across findings)
```

If `competitor_count < 3` at D3+, flag: `"WARNING: Insufficient competitive context. Consider targeted 'vs' queries."`

#### Synthesizer Changes

Add optional section at D3+:
```markdown
## Competitive Landscape
### Feature Comparison Matrix
| Feature | Product A | Product B | Product C | Our Position |
|---|---|---|---|---|

### Competitor Pricing Tiers
[Table from findings]

### Key Differentiators
[Analysis of where gaps and opportunities exist]
```

---

### 3. Pricing Sensitivity Testing

**Why it matters:** All WTP (willingness-to-pay) ranges in the reports are estimates or survey-derived. No Van Westendorp, no conjoint analysis. The gap between "$500-1,500/mo WTP" and knowing the actual price-volume curve is the difference between guessing and knowing.

#### Best Channels

| Channel | Effectiveness | Why |
|---|---|---|
| Reddit | HIGH | "Too expensive", "worth the price", "switched because of pricing" discussions reveal real price sensitivity. |
| HackerNews | MEDIUM-HIGH | Technical buyers discuss pricing honestly. "I cancelled X because..." posts. |
| X/Twitter | MEDIUM | Price reaction threads. "@product raised prices and..." |
| G2/Capterra (via Brave) | MEDIUM | Review sites often have pricing complaints/praise in reviews. |
| YouTube | LOW-MEDIUM | "Is X worth it?" videos sometimes contain pricing analysis. |

#### PromptForge Changes

Add to `sub_questions` at D3/D4:
```
"What price do people actually pay for [topic/product category] and what do they consider too expensive or too cheap?"
"Why do customers switch from [competitor] — is it pricing, features, or both?"
"What pricing model (monthly, annual, usage-based, per-seat) do users prefer for [category]?"
```

Add to `query_per_scout.scout-social.reddit`:
```json
{
  "query": "[topic] pricing 'too expensive' OR 'worth the price' OR 'switched because' OR 'cancelling' OR 'free alternative'",
  "subreddits": ["SaaS", "smallbusiness", "Entrepreneur", "marketing"]
}
```

Add to `query_per_scout.scout-web`:
```
"[product category] pricing comparison {year}" OR "[product] pricing review worth it {year}"
```

#### Scout SKILL.md Changes

**scout-social/SKILL.md** — Add pricing extraction pattern:

```markdown
### Pricing Sensitivity Extraction (D3+ only)
When dispatched with `extract_mode: "pricing_sensitivity"`:
- Reddit: Search for pricing complaint/praise posts. Keywords: "pricing", "expensive", "cheap",
  "worth", "switched", "cancelled", "free alternative", "budget"
- Reddit: Prioritize posts in r/SaaS, r/smallbusiness where people discuss actual spend amounts
- HackerNews: "[product] pricing" or "why I cancelled [product]"
- Extract specific dollar amounts mentioned by users
- Tag findings with `finding_type: "pricing_signal"` and extract `mentioned_price` field
```

#### Critic Changes

Add flag:
```
pricing_data_present: boolean
pricing_data_points: number (unique price mentions across findings)
```

If `pricing_data_points < 3` at D3+ for business topics, flag: `"WARNING: Insufficient pricing data. Real WTP data needed."`

#### Synthesizer Changes

Add optional section:
```markdown
## Pricing Intelligence
### What People Actually Pay
[Extracted price points from Reddit/HN/reviews]

### Price Sensitivity Signals
- "Too expensive" threshold: $X/mo (based on N user complaints)
- "Fair price" zone: $X-$Y/mo (based on N positive mentions)
- Switching triggers: [reasons people switch, with price thresholds]

### Pricing Model Preferences
[Monthly vs annual vs usage-based, from user discussions]
```

---

### 4. GTM Playbooks (Go-to-Market Strategy)

**Why it matters:** Reports say "launch in US first" but don't specify channel, budget, expected conversion rates, or sequencing. The Benchmark had the best GTM (4-product launch sequence) but with no attribution.

#### Best Channels

| Channel | Effectiveness | Why |
|---|---|---|
| YouTube | HIGH | "How I launched X" videos, SaaS launch playbook content, agency growth tutorials. |
| Brave/Tavily | HIGH | Blog posts about launch strategies, growth playbooks, case studies with metrics. |
| Reddit (r/startups, r/SaaS) | MEDIUM-HIGH | "How we got our first 100 customers" posts. Real GTM data. |
| HackerNews | MEDIUM | "Launch HN" retrospectives and growth strategy discussions. |
| ArXiv/OpenAlex | LOW | Academic papers on go-to-market rarely — more for market sizing methodology. |

#### PromptForge Changes

Add to `sub_questions` at D3/D4:
```
"What go-to-market strategies have worked for companies launching [topic/product category]?"
"What channels (LinkedIn, cold outbound, content, partnerships) drive customer acquisition in [category]?"
"What are realistic conversion rates and CAC benchmarks for [category] launches?"
```

Add to `query_per_scout.scout-web`:
```
"[product category] go-to-market strategy playbook launch case study {year}"
"[category] customer acquisition channel strategy SaaS B2B {year}"
```

Add to `query_per_scout.scout-video`:
```
"[category] launch playbook case study growth strategy how to get first customers {year}"
```

Add to `query_per_scout.scout-social.reddit`:
```json
{
  "query": "[category] launch strategy 'first customers' OR 'how we grew' OR 'GTM' OR 'go to market'",
  "subreddits": ["startups", "SaaS", "Entrepreneur", "indiehackers", "marketing"]
}
```

#### Scout SKILL.md Changes

**scout-web/SKILL.md** — Add GTM query pattern:

```markdown
### GTM / Launch Strategy Queries (D3+ only)
When dispatched with `extract_mode: "gtm_playbook"`:
- Brave: "[category] go-to-market strategy case study" + "[category] launch playbook"
- Tavily: Focus on extracting specific metrics (CAC, conversion rates, channel breakdown)
- Exa: Neural search for "successful launch strategy [category] with metrics"
- Tag findings with `finding_type: "gtm_data"` and extract any mentioned metrics
```

**scout-video/SKILL.md** — Add GTM video pattern:

```markdown
### Launch / Growth Strategy Videos
When topic context includes "gtm" or "go-to-market":
- YouTube: "[category] launch strategy OR growth playbook OR 'how I got first customers' {year}"
- Prioritize videos with specific numbers in titles ("$0 to $100K", "first 1000 users")
- Extract transcript sections with dollar amounts, percentages, timeline references
```

#### Critic Changes

Add flag:
```
gtm_data_present: boolean
gtm_channels_mentioned: list[string] (which acquisition channels are discussed)
```

If `gtm_data_present == false` at D3+ for business/product topics, flag: `"WARNING: No GTM strategy data. Consider YouTube/Reddit supplementary search."`

#### Synthesizer Changes

Add optional section:
```markdown
## Go-to-Market Playbook
### Recommended Launch Sequence
1. [Phase 1]: [Channel] — [Expected outcome] — [Budget]
2. [Phase 2]: ...

### Customer Acquisition Channels
| Channel | CAC Estimate | Conversion Rate | Time to First Customer | Source |
|---|---|---|---|---|

### Benchmarks from Similar Launches
[Case studies and metrics from findings]
```

---

### 5. Risk Analysis (What Could Go Wrong)

**Why it matters:** No report seriously considers downside scenarios. What if GEO/AEO doesn't take off? What if a platform launches a free competitor? D4 came closest with HN contrarian evidence ("AI doesn't reduce work, it intensifies it") but this was incidental, not systematically sought.

#### Best Channels

| Channel | Effectiveness | Why |
|---|---|---|
| HackerNews | HIGH | HN is the best source for contrarian and skeptical perspectives on tech. |
| Reddit | HIGH | r/startups failure post-mortems, r/SaaS "why I shut down" posts. |
| ArXiv/News | MEDIUM | Research on AI risks, regulatory changes, market disruption patterns. |
| Brave/Tavily | MEDIUM | Blog posts about failures, "what went wrong" analyses. |
| YouTube | LOW-MEDIUM | "Why X failed" videos exist but are less common than success content. |

#### PromptForge Changes

Add to `sub_questions` at D3/D4:
```
"What are the main risks and failure modes of [topic]? What could go wrong?"
"What regulatory or competitive threats could disrupt [topic] in the next 12-24 months?"
"What are contrarian or skeptical perspectives on [topic]?"
```

Add to `query_per_scout.scout-social.hackernews`:
```
"[topic] risk OR failure OR problem OR skeptic OR overrated OR bubble"
```

Add to `query_per_scout.scout-social.reddit`:
```json
{
  "query": "[topic] failed OR shutdown OR 'what went wrong' OR risk OR 'learned the hard way'",
  "subreddits": ["startups", "SaaS", "Entrepreneur", "smallbusiness"]
}
```

Add to `query_per_scout.scout-knowledge.news`:
```
"[topic] risk regulation failure disruption {year}"
```

#### Scout SKILL.md Changes

**scout-social/SKILL.md** — Add risk/contrarian extraction:

```markdown
### Risk & Contrarian Signal Extraction (D3+ only)
When dispatched with `extract_mode: "risk_analysis"`:
- HackerNews: Prioritize critical/skeptical comments. Keywords: "overrated", "bubble",
  "won't work", "tried and failed", "regulatory risk"
- Reddit: Search for failure post-mortems. r/startups "I shut down", r/SaaS "failed"
- Both: Look for comments predicting competitive threats or regulatory action
- Tag findings with `finding_type: "risk_signal"` and `risk_type: "competitive|regulatory|technical|market"`
```

**scout-knowledge/SKILL.md** — Add risk-focused news queries:

```markdown
### Risk / Regulatory Queries
When dispatched with `extract_mode: "risk_analysis"`:
- Guardian: "[topic] risk regulation concerns {year}"
- GNews: "[topic] failure shutdown regulatory crackdown {year}"
- ArXiv: Focus on papers about limitations, failure modes, ethical concerns
- Tag findings with `finding_type: "risk_signal"`
```

#### Critic Changes

Add flag:
```
risk_coverage_present: boolean
risk_types_covered: list[string] (competitive, regulatory, technical, market, execution)
```

If `risk_coverage_present == false` at D3+, flag: `"WARNING: No risk analysis in findings. Research may be overly optimistic."`

#### Synthesizer Changes

Add MANDATORY section at D3+:
```markdown
## Risk Analysis
### Competitive Risks
- [What if a major platform launches a free version?]
- [What if an incumbent acquires a key competitor?]

### Regulatory Risks
- [EU AI Act impact, state-level regulations, data privacy]

### Market Risks
- [What if the market doesn't materialize as projected?]
- [Contrarian perspectives from HN/Reddit]

### Execution Risks
- [Team, funding, technology dependencies]

### Mitigations
[For each major risk, what can be done to reduce impact]
```

---

## Summary of All Changes

### PromptForge (Step 0.5) — Additional Sub-Questions

At D3/D4, ALWAYS generate these 5 additional sub-questions alongside existing ones:

1. **First-person:** "What do real practitioners say about their experience with [topic]?"
2. **Competitive:** "How do the top 3-5 alternatives compare feature-by-feature?"
3. **Pricing:** "What prices do people actually pay, and where is the 'too expensive' threshold?"
4. **GTM:** "What go-to-market strategies have worked for similar products/services?"
5. **Risk:** "What are the main risks, failure modes, and contrarian perspectives?"

### Scout Query Enhancement Matrix

| Content Type | Primary Scout | Query Pattern Addition | Secondary Scout |
|---|---|---|---|
| First-person accounts | scout-social (Reddit, HN) | "I tried" / "my experience" / "lessons learned" | scout-video (case study videos) |
| Competitive teardowns | scout-web (Brave, G2/Capterra) | "[A] vs [B]" / "comparison" / "alternative" | scout-social (Reddit "which tool") |
| Pricing sensitivity | scout-social (Reddit, HN) | "too expensive" / "worth the price" / "switched because" | scout-web (pricing reviews) |
| GTM playbooks | scout-video (YouTube) + scout-web | "launch strategy" / "first customers" / "growth playbook" | scout-social (r/startups) |
| Risk analysis | scout-social (HN) + scout-knowledge | "risk" / "failure" / "overrated" / "regulation" | scout-web (news) |

### Critic — New Flags (Not New Scores)

Add to Critic output at D3+:

```json
"content_completeness": {
  "first_person_evidence": {"present": true, "count": 4},
  "competitive_context": {"present": true, "competitor_count": 7},
  "pricing_data": {"present": false, "data_points": 0},
  "gtm_data": {"present": false},
  "risk_coverage": {"present": true, "risk_types": ["competitive", "regulatory"]}
}
```

If any flag is `false`, Critic adds a WARNING in output. This does NOT block the pipeline — it informs the Synthesizer and can trigger supplementary scout dispatch by DELPHI PRO.

### Synthesizer — New Optional Sections

At D3+, Synthesizer SHOULD include these sections if findings support them:
1. Practitioner Perspectives (if first_person findings exist)
2. Competitive Landscape (if competitive findings exist)
3. Pricing Intelligence (if pricing data exists)
4. Go-to-Market Playbook (if GTM findings exist, business topics only)
5. Risk Analysis (MANDATORY at D3+ — even if findings are thin, acknowledge risks)

---

## PART B: KSL Optimization Analysis

### Current Design (from DELPHI-SOC Faza 0)

```
1. Read human-program.md for focus area
2. Pick random topic from research history
3. Apply ONE modification to ONE skill prompt
4. Run D2 research with modification
5. Binary eval: EPR_new > EPR_baseline? → keep/revert
6. Log result to state.json
7. Repeat until time budget exhausted (02:00-06:00)
```

Constraints: 50-100 experiments/night, ~$0.50-2.00/night, STABLE mark after 3 cycles no improvement >= 2pts.

### What the KSL Currently Observes

| Dimension | Observable? | Source | Notes |
|---|---|---|---|
| EPR score (0-20) | YES | Critic output `epr_score` | Primary optimization metric. 4 sub-dimensions: Evidence, Precision, Relevance, Novelty. |
| Source count | YES | Synthesizer `source_count` | Total and per-tier (T1/T2/T3). |
| Source tier distribution | YES | Synthesizer `source_count.T1/T2/T3` | More T1 = higher Evidence score in EPR. |
| Channel diversity | YES | Scout metadata `channels_queried` | Countable from merged findings. |
| Duration | YES | `metadata.duration_ms` | Faster at same quality = better efficiency. |
| Self-grade | YES | Synthesizer `self_grade` (0-100) | 5 sub-dimensions: Coverage, Coherence, Attribution, Actionability, Accuracy. |
| Scout success rate | YES | Scout `status` + `items_returned` | Which scouts produced useful findings vs empty/error. |
| Critic inclusion rate | YES | Critic `summary.included / summary.total` | What percentage of findings survived Critic filtering. |

### What KSL CANNOT Currently Observe

| Dimension | Why Not | Impact |
|---|---|---|
| Content actionability for real executives | EPR "Precision" is a proxy but doesn't measure "can a CEO act on this today" | Reports may score high EPR but be academically interesting rather than practically useful |
| First-person evidence presence | No metric tracks whether findings include real user experiences | Loop can't optimize toward more first-person content |
| Competitive teardown quality | No metric for feature-by-feature comparison depth | Loop can't optimize toward better competitive analysis |
| Pricing data accuracy | No metric for real WTP data vs estimates | Loop can't distinguish "$500-1500 estimated" from "$500-1500 validated by 50 user reports" |
| GTM playbook completeness | No metric for launch strategy specificity | Loop can't optimize toward actionable GTM recommendations |
| Risk coverage depth | No metric for contrarian/risk perspectives | Loop can't optimize toward balanced (bullish + bearish) reports |
| Executive readability | EPR doesn't measure scan-ability, visual hierarchy, or 5-minute skim potential | Loop can't optimize report structure for C-level consumption |
| Report delivery quality | No metric for HTML rendering, chart accuracy, or link validity | Loop runs D2 (no HTML) so can't test delivery quality |

### The Fundamental Limitation

The KSL runs at D2 depth. D2 does NOT include:
- Critic evaluation (optional at D2, skipped for speed if < 8 sources)
- HTML report generation (D2 gets Report Card, not full report)
- Multi-scout coordination (D2 may run direct, not scout-based)

This means the loop optimizes query templates and channel selection for **D2 quality**, which may not transfer to D3/D4 behavior. A query template that works at D2 (5 channels, no critic) may underperform at D3 (18 channels, critic validated) because the dynamics are different.

### Recommendation: Content Completeness Score (CCS)

**Do NOT extend EPR.** EPR is well-defined (Evidence, Precision, Relevance, Novelty) and changing its definition would invalidate all historical baselines. Instead, create a parallel metric.

#### Content Completeness Score (CCS) — 0 to 25

| Dimension | Scale | What It Measures |
|---|---|---|
| **Actionability** | 0-5 | Can a business executive act on findings today? (0=abstract, 5=step-by-step playbook) |
| **First-Person Evidence** | 0-5 | Are there real user quotes/experiences? (0=none, 5=5+ validated accounts) |
| **Competitive Context** | 0-5 | Does it compare alternatives? (0=no competitors, 5=feature matrix + pricing tiers) |
| **Risk Coverage** | 0-5 | Are risks and failure modes addressed? (0=none, 5=multi-category with mitigations) |
| **GTM Specificity** | 0-5 | Is there a go-to-market path? (0=no GTM, 5=channel + budget + timeline + benchmarks) |

#### How CCS Integrates with KSL

```
Current flow:
  modify prompt → run D2 → EPR_new > EPR_baseline? → keep/revert

Proposed flow:
  modify prompt → run D2 → compute EPR AND CCS
  → composite_score = EPR * 0.6 + CCS * 0.4
  → composite_new > composite_baseline? → keep/revert
```

The 60/40 weighting ensures EPR remains primary (source quality, evidence rigor) while CCS pulls the loop toward content completeness.

#### Who Computes CCS?

**The Critic.** Extend Critic SKILL.md to compute CCS alongside EPR:

```json
{
  "epr_score": 17,
  "epr_breakdown": {"evidence": 4, "precision": 4, "relevance": 5, "novelty": 4},
  "ccs_score": 15,
  "ccs_breakdown": {
    "actionability": 4,
    "first_person_evidence": 2,
    "competitive_context": 4,
    "risk_coverage": 3,
    "gtm_specificity": 2
  },
  "content_completeness": {
    "first_person_evidence": {"present": true, "count": 2},
    "competitive_context": {"present": true, "competitor_count": 5},
    "pricing_data": {"present": true, "data_points": 3},
    "gtm_data": {"present": false},
    "risk_coverage": {"present": true, "risk_types": ["competitive", "regulatory"]}
  }
}
```

#### KSL at D2 — CCS Challenge

At D2, CCS will typically be low because:
- D2 has fewer sources (5-8 vs 20-60 at D4)
- D2 skips Critic (so CCS must be self-computed or computed by a lightweight check)
- D2 doesn't target first-person accounts specifically

**Solution**: For KSL D2 experiments, compute a "D2-adjusted CCS" with relaxed thresholds:
- First-person evidence: 1+ accounts = 3/5 (vs 5+ for full score at D4)
- Competitive context: 2+ competitors = 3/5
- Risk coverage: any risk mention = 2/5
- GTM: any GTM signal = 2/5

This lets the loop optimize toward these content types at D2 scale without requiring D4-level depth.

### Implementation Priority

| Change | Effort | Impact | Priority |
|---|---|---|---|
| Add 5 sub-questions to PromptForge | LOW (prompt text only) | HIGH (immediate query improvement) | P0 — Do first |
| Add `finding_type` tags to scout outputs | LOW (output schema addition) | MEDIUM (enables Critic tracking) | P1 |
| Add `content_completeness` flags to Critic | MEDIUM (Critic SKILL.md update) | HIGH (enables CCS scoring) | P1 |
| Add CCS scoring to Critic | MEDIUM (new evaluation logic) | HIGH (enables KSL optimization) | P1 |
| Add optional report sections to Synthesizer | MEDIUM (template additions) | HIGH (direct report quality improvement) | P1 |
| Update KSL to use composite score | LOW (scoring formula change) | HIGH (loop optimizes for completeness) | P2 (after CCS is validated) |
| Add new `extract_mode` variants to scouts | MEDIUM (query template work) | MEDIUM (targeted extraction) | P2 |
| Run KSL at D3 periodically | HIGH (cost increase ~3x) | HIGH (validates D3-level optimizations) | P3 (after D2 CCS stabilizes) |

### What KSL Will Optimize After These Changes

**Before (current):**
- Query template wording for better EPR (Evidence + Precision + Relevance + Novelty)
- Channel selection for higher source quality
- Implicit: source count and tier distribution

**After (with CCS):**
- Everything above PLUS:
- Query templates that surface first-person accounts (CCS: first_person_evidence)
- "vs" query patterns that find competitive comparisons (CCS: competitive_context)
- Pricing-specific queries that extract real WTP data (CCS: actionability, via pricing signals)
- Risk/contrarian query patterns (CCS: risk_coverage)
- GTM-focused queries from YouTube and Reddit (CCS: gtm_specificity)

The loop can now evolve query templates that specifically target these content types, and the binary eval (composite_new > composite_baseline) will keep improvements that produce more complete reports.

### Open Questions for Pafi

1. **Should CCS be mandatory or optional at D2?** Making it mandatory adds ~10s to each KSL experiment (Critic must run). Making it optional means the loop can't optimize for it.

2. **Should Risk Analysis be MANDATORY in Synthesizer output at D3+?** Current proposal says yes. This means every D3/D4 report gets a risk section even if risk findings are thin. Alternative: only include when risk_coverage_present == true.

3. **Should KSL occasionally run at D3?** D2 experiments cost ~$0.30 each. D3 experiments cost ~$0.50-0.80 each. Running 10% of experiments at D3 (5-10 per night) would validate that D2-optimized prompts transfer to D3. Cost increase: ~$2-4/night.

4. **Weighting of EPR vs CCS in composite score?** Proposed 60/40. More aggressive: 50/50. More conservative: 70/30. Depends on whether you want the loop to prioritize source rigor (EPR-heavy) or content completeness (CCS-heavy).

5. **Should `content_completeness` flags trigger automatic supplementary scout dispatch?** If Critic reports `pricing_data: false` for a business topic, should DELPHI PRO automatically dispatch a supplementary pricing-focused Reddit search? This adds cost but fills gaps automatically.

---

*Analysis conducted 2026-03-20 by Claude Opus 4.6 (1M context)*
*Input files: CONTENT-QUALITY-BENCHMARK.md, delphi.md, human-program.md, DELPHI-SOC.md, all scout SKILL.md files, critic SKILL.md, synthesizer SKILL.md, channel-config.yaml*
