# REFERENCE: PromptForge — Input Optimization + Per-Channel Queries

> Extracted from `delphi.md` Steps 0, 0.6, and 0.5.

## Step 0: Input Optimization (MANDATORY D2+)

Apply ALL that are missing from the raw prompt:
- **Temporal context** — add "2026", "current", or "March 2026" if no time reference
- **Specificity** — expand vague terms into concrete sub-topics
- **Structure** — if prompt >50 words, organize into logical sections
- **Constraints** — if missing, append: "Focus on actionable insights with verifiable sources"
- **Preserve intent** — NEVER change what user is asking, only HOW it's phrased

### Per-depth behavior

| Depth | Action |
|:---:|:---|
| D1 | SKIP — raw prompt as-is |
| D2 | LIGHT — apply 5 rules → produce `optimized_prompt` |
| D3 | LIGHT + 3-5 sub-questions (angles to explore) |
| D4 | D3 + research brief with role + task + output format |

### Example
```
BEFORE: "research AI agents"
AFTER:  "AI autonomous agent frameworks and multi-agent orchestration systems
         in 2026: production architectures, evaluation benchmarks, leading tools,
         with focus on actionable comparisons and verifiable sources"
```

### Output — store in research metadata
```json
{
  "original_prompt": "<user raw, verbatim>",
  "optimized_prompt": "<Step 0 output>",
  "sub_questions": ["angle 1", "..."],
  "research_brief": { }
}
```

The `optimized_prompt` (not raw) flows into Step 0.5 and all downstream steps.

## Hypothesis Generation (D3+, inline)

At D3+, as part of Step 0, generate 5-10 research hypotheses inline (zero cost, you are Sonnet/Opus):
- Unexplored angles the user might not have considered
- Contrarian views ("what if the opposite is true?")
- Adjacent domains worth checking
- Emerging trends that could change the landscape

Output = `seed_ideas` array fed into Step 0.5 for richer per-channel queries.
These are search DIRECTIONS only — NOT findings, NOT validated, NOT cited.

---

## Step 0.5: Per-Channel Query Optimization

## Core Insight

"AI marketing automation pain points 2026" is a terrible ArXiv query, a mediocre Reddit query, and an OK Brave query. Each channel has its own query language, community norms, and search syntax. PromptForge generates **one optimized query per channel**, not one generic query for all.

## Depth-Based Optimization Rules

| Depth | Optimization | Time | Output |
|:---:|:---:|:---:|:---:|
| D1 | **SKIP** — pass raw query as-is to all channels | 0s | raw topic only |
| D2 | **LIGHT** — `optimized_topic` + basic `query_per_scout` (web, social, video) | ~3s | 3-4 channel variants |
| D3 | **STANDARD** — full `query_per_scout` with subreddit selection, platform-specific syntax, sub-questions | ~5s | all active channel variants |
| D4 | **COMPLEX** — everything from D3 + domain-specific academic queries, decomposed sub-questions, cross-reference requirements | ~10s | all channel variants + sub-questions |

## Output Schema

```json
{
  "optimized_topic": "general optimized version with temporal context",
  "sub_questions": ["decomposed sub-question 1", "..."],
  "query_per_scout": {
    "scout-web": "keyword-focused query for Brave/Tavily/Exa",
    "scout-social": {
      "reddit": {"query": "community-phrased question", "subreddits": ["sub1", "sub2", "sub3"]},
      "hackernews": "technical phrasing for Algolia search",
      "x_twitter": "#hashtags + keywords (max 280 chars)",
      "bluesky": "keywords + hashtags (shorter)",
      "linkedin": "professional/B2B angle query"
    },
    "scout-video": "YouTube search optimized (how-to, tutorial, review + topic)",
    "scout-knowledge": {
      "arxiv": "ti:\"phrase\" AND abs:\"keyword\"",
      "news": "news-angle query — what happened, who announced"
    },
    "scout-finance": "ticker symbols + market terminology"
  }
}
```

At D2, only populate scouts that are active for the run (typically scout-web, scout-social, scout-video).
At D3/D4, populate ALL active scouts including scout-knowledge and scout-finance if relevant.
Omit scout keys that are not dispatched for this run.

## Per-Channel Optimization Rules

Each channel has specific optimization patterns. Follow these rules when generating `query_per_scout`:

**Brave / Tavily / Exa (scout-web):**
- Keyword-focused, no natural language questions
- Add current year (2026) for recency
- Add domain-specific terms (expand abbreviations, add synonyms)
- Include scope terms: "enterprise", "SMB", "open-source", etc.
- Example: raw "AI tools" -> `"AI tools comparison enterprise open-source 2026"`

**Reddit (scout-social/reddit):**
- ALWAYS include 3-5 relevant subreddits based on topic type. Reference subreddit categories:
  - Tech/AI: r/ClaudeAI, r/MachineLearning, r/LocalLLaMA, r/artificial, r/singularity
  - Business/Marketing: r/smallbusiness, r/Entrepreneur, r/marketing, r/digital_marketing, r/SaaS
  - Startups/Products: r/SideProject, r/startups, r/indiehackers, r/ProductHunt
  - Finance/Crypto: r/CryptoCurrency, r/Bitcoin, r/investing, r/personalfinance
  - Health: r/longevity, r/Biohackers, r/Nootropics, r/Supplements
  - General: r/technology, r/Futurology, r/AskReddit
- Phrase query as a community discussion (frustrations, experiences, recommendations)
- Drop formal language — use how people actually talk on Reddit
- Example: raw "AI marketing automation" -> `{"query": "marketing automation frustrations AI tools", "subreddits": ["smallbusiness", "marketing", "SaaS", "Entrepreneur"]}`

**HackerNews (scout-social/hackernews):**
- Technical phrasing, NO hashtags, precise terms
- Use terms the HN crowd uses (not marketing-speak)
- Prefer compound technical terms over vague phrases
- Example: raw "AI marketing automation" -> `"AI marketing tools problems scaling 2026"`

**X/Twitter (scout-social/x_twitter):**
- Hashtags + key terms, max 280 chars total
- Lead with 2-3 relevant hashtags
- Add `lang:en` if topic is English-specific
- Example: raw "AI marketing automation" -> `"#AImarketing #MarTech automation pain points challenges 2026"`

**YouTube (scout-video):**
- Prepend content-type keywords: "how to", "tutorial", "review", "comparison", "explained"
- Add year for recency
- Match how creators title videos
- Example: raw "AI marketing automation" -> `"AI marketing automation tutorial problems review 2026"`

**ArXiv (scout-knowledge/arxiv):**
- Use ArXiv search syntax: `ti:"title phrase" AND abs:"abstract keyword"`
- Use academic terminology, not colloquial terms
- Combine with year filters when appropriate
- Example: raw "AI marketing automation" -> `ti:"marketing automation" AND abs:"artificial intelligence"`

**News (scout-knowledge/news):**
- News angle: what happened, who announced, what changed, what launched
- Include industry context and enterprise terms
- Example: raw "AI marketing automation" -> `"AI marketing industry challenges enterprise adoption 2026"`

**Finance (scout-finance):**
- Extract ticker symbols from topic if present
- Use market terminology: revenue, market cap, earnings, sector
- Add financial context: "valuation", "growth rate", "market share"
- Example: raw "Salesforce AI strategy" -> `"CRM AI strategy revenue growth marketing cloud 2026"`

## BEFORE/AFTER Example

**Topic**: "AI marketing automation pain points 2026"

**BEFORE (no PromptForge):**
Every scout receives the identical raw string: `"AI marketing automation pain points 2026"`
Result: mediocre relevance across all channels, Reddit search misses key subreddits, ArXiv query returns nothing useful, YouTube gets generic results.

**AFTER (PromptForge D3):**
```json
{
  "optimized_topic": "AI-powered marketing automation challenges and pain points for SMB and enterprise in 2026: tool limitations, integration friction, ROI measurement, workflow breakdowns",
  "sub_questions": [
    "What are the most common complaints about AI marketing automation tools in 2026?",
    "How do SMBs vs enterprises experience different pain points with marketing automation?",
    "What integration and workflow problems do marketers face with AI tools?"
  ],
  "query_per_scout": {
    "scout-web": "AI marketing automation challenges problems SMB enterprise 2026",
    "scout-social": {
      "reddit": {
        "query": "marketing automation frustrations AI tools",
        "subreddits": ["smallbusiness", "marketing", "SaaS", "Entrepreneur", "digital_marketing"]
      },
      "hackernews": "AI marketing tools problems scaling 2026",
      "x_twitter": "#AImarketing #MarTech automation pain points challenges 2026",
      "linkedin": "marketing automation AI challenges enterprise workflow 2026"
    },
    "scout-video": "AI marketing automation tutorial problems review 2026",
    "scout-knowledge": {
      "arxiv": "ti:\"marketing automation\" AND abs:\"artificial intelligence\"",
      "news": "AI marketing industry challenges enterprise adoption 2026"
    }
  }
}
```

## Rules

- **NEVER modify the user's intent.** Only add specificity, structure, and searchability.
- If the user's prompt is already detailed (like a full research brief), preserve it entirely — only add temporal context and generate `query_per_scout` variants.
- Each scout receives ONLY its own key from `query_per_scout`. Scouts never see the full dict.
- If a scout is not dispatched for this run, do not generate its query (waste of optimization time).
- The `optimized_topic` field is used by the Synthesizer for report framing, NOT by scouts for searching.
