# REFERENCE: DELPHI PRO Operational Details

> Extracted from `delphi.md`. This file contains quota management, scout failure detection,
> mid-pipeline checkpointing, memory protection workflow, and cost guardrails.
> Core delphi.md contains compact summaries with pointers here.

## Quota Management (MANDATORY pre-flight)

Before dispatching scouts, run `hooks/pre-research-quota.sh` and check `channel_quotas` in `resources/state.json`.

### Pre-flight Rules

1. If `brave.used_this_month >= brave.monthly_limit * 0.8` --> switch to Exa as primary web search
2. If `tavily.used_this_month >= tavily.monthly_limit * 0.8` --> switch to Perplexity Sonar Pro as primary
3. If ALL web search channels (Brave + Tavily + Exa) exhausted --> use ONLY Perplexity via OpenRouter + DuckDuckGo (free, rate-limited)
4. After each scout run, increment the relevant `used_this_month` counter in state.json

### Rotation Priority (when quotas are low)

| Priority | Channel | Notes |
|:---:|:---:|:---:|
| 1 | Exa (semantic search, 1000/mo) | PRIMARY when Brave exhausted |
| 2 | Perplexity Sonar Pro via OpenRouter | ALWAYS AVAILABLE (pay-per-use) |
| 3 | DuckDuckGo | Free but rate-limited — LAST RESORT |

### Hard Block

NEVER start a D3/D4 research if zero web search channels are available.
Instead: warn user -- "Web search quotas exhausted. Available: Perplexity via OpenRouter only. Proceed?"
Wait for explicit approval before continuing with degraded channel set.

### Quota Counter Update

After each research run completes (step 12 in pipeline), update `channel_quotas` in state.json:
- Count Brave API calls made during this run --> add to `brave.used_this_month`
- Count Tavily API calls --> add to `tavily.used_this_month`
- Count Exa API calls --> add to `exa.used_this_month`
- Check `reset_date` -- if current date >= reset_date, reset all counters to 0 and set next reset_date to first of next month

---

## Scout Failure Detection (MANDATORY)

After receiving results from each scout, ALWAYS check:
1. `status == "error"` -> log error, try fallback channel
2. `status == "partial"` -> check which channels failed, note in report methodology
3. `status == "complete"` but `findings count == 0` -> channel returned nothing, try alternative query
4. `status == "empty"` -> channel has no results for this topic, move on

### Scout Failure Fallback Chain

- scout-social Reddit fails -> Brave search `"site:reddit.com [topic]"`
- scout-social HN fails -> Brave search `"site:news.ycombinator.com [topic]"`
- scout-social X fails -> Brave search `"site:twitter.com [topic]"` OR Perplexity `"what are people saying on X about [topic]"`
- scout-video YouTube fails -> Brave search `"site:youtube.com [topic]"` + Perplexity `"youtube videos about [topic]"`
- Any scout fails completely -> Perplexity Sonar Pro as universal fallback

NEVER silently drop a failed channel. ALWAYS either:
a) Try the fallback chain, OR
b) Log the failure in report methodology section

---

## Mid-Pipeline Checkpointing (D3/D4 only)

For D3/D4 research runs that take 10-60 minutes, checkpoint intermediate results so work is not lost on crash:

```
After step 2 (MERGE):
  -> Save merged findings to Cortex: cortex_store(collection="research",
    metadata={type: "checkpoint", stage: "merged", topic: X, correlation_id: Y})

After step 4 (CRITIC):
  -> Save curated findings to Cortex: cortex_store(collection="research",
    metadata={type: "checkpoint", stage: "curated", topic: X, epr: N})

On crash/resume:
  -> Search Cortex for checkpoints: cortex_search(query="checkpoint {topic}")
  -> If curated checkpoint exists -> skip to step 6 (Synthesizer)
  -> If merged checkpoint exists -> skip to step 3 (Critic)
  -> If no checkpoint -> restart from step 1

Checkpoint cleanup:
  -> After successful delivery (step 11), delete checkpoints for this correlation_id
  -> Stale checkpoints (>24h) cleaned by DELPHI-SOC
```

---

## Memory Protection — Detailed Workflow

### Protected files (NEVER modify directly):
- `human-program.md` — ONLY Pafi writes this. Propose changes via optimization-buffer.md.
- Any `SKILL.md` — ONLY through SOC with audit approval. Propose via optimization-buffer.md.
- `state.json` -> `optimization_history` — ONLY through approved buffer entries.
- Any memory files (`~/.claude/projects/*/memory/*.md`) — ONLY Pafi or approved SOC changes.
- `channel-config.yaml` — structural changes require approval. Channel health updates are OK.
- `delphi.md` (your own SOUL) — you NEVER modify yourself. Period.

### Auto-writable fields (no approval needed):
- `state.json` -> run counters (`last_run`, `total_runs`, `runs_by_depth`) — auto-update after each run
- `state.json` -> `channel_health` — auto-update based on channel responses
- `state.json` -> `channel_quotas` — auto-increment after each API call
- `state.json` -> `critic_stats` — auto-update after each critic run
- `optimization-buffer.md` — your ONLY writable scratchpad for proposals

### Proposal Workflow

When you want to suggest an optimization:
1. Write the proposal to `optimization-buffer.md` with date, type, target, and description
2. Do NOT apply it
3. Wait for weekly DELPHI-SOC Faza 5.5 review
4. Pafi approves/rejects each proposal
5. Only approved proposals get applied (by the SOC procedure, not by you)

Proposal types:
- [SKILL-UPDATE] — change to a SKILL.md prompt or structure
- [CONFIG-UPDATE] — change to channel-config.yaml priorities
- [TOOL-ADD] — new tool/channel to add
- [TOOL-REMOVE] — tool/channel to deprecate
- [PERFORMANCE] — optimization based on run data

---

## Cost Guardrails

Before dispatching D3/D4 pipeline, estimate cost:

```
D3 estimate: ~$0.30-0.80
  = Sonnet orchestration (~$0.05)
  + 3-5 Haiku scouts (~$0.05 total)
  + scout-deep Opus CLI (included in Max plan)
  + Sonnet Critic (~$0.10)
  + Sonnet Synthesizer (~$0.15)
  + Reporter (~$0.05)

D4 estimate: ~$2.00-5.00
  = Sonnet orchestration (~$0.05)
  + 5 Haiku scouts (~$0.08 total)
  + scout-deep Opus CLI (included in Max plan)
  + 3x Sonnet Critic Council (~$0.30)
  + Opus Synthesizer (~$1.50-3.00)
  + Reporter (~$0.05)
  + Gemini Deep Research (included in plan)

D4 + Perplexity Deep: +$1.30 (requires approval)

Max cost per run: $8.00 (abort and flag if estimated > $8)
```

Log actual cost to state.json after each run for SOC tracking.
