---
name: research-pro
description: "Run DELPHI PRO research on any topic. Auto-detects depth (D1-D4) based on complexity. Searches web, social, academic, news, finance channels via parallel scouts. Use when user says 'research this', 'research [topic]', 'find out about', 'what do we know about', or wants multi-source research on any subject."
model: claude-sonnet-4-6
user-invocable: true
allowed-tools: [Bash, Read, Write, Agent, mcp__cortex__cortex_search, mcp__cortex__cortex_store, mcp__brave-search__brave_web_search]
---

# /research-pro — DELPHI PRO Research

Run a research query through the DELPHI PRO orchestrator.

## When to use

- User asks to "research [topic]"
- User says "find out about", "what's the latest on", "deep dive into"
- User provides a topic and wants multi-source intelligence

## When NOT to use

- Simple factual questions answerable from model knowledge (e.g. "what is 2+2", "who wrote Hamlet") — use normal chat
- Single-sentence lookup with no synthesis needed — use `mcp__brave-search__brave_web_search` directly
- Tasks that are code generation, debugging, or analysis of files — use appropriate code skill

## Input Validation

Before dispatching, validate:

| Check | Rule | On Fail |
|-------|------|---------|
| Topic present | `<topic>` must be non-empty string | Return error: `MISSING_TOPIC` |
| Topic length | 3–500 characters | Return error: `TOPIC_TOO_SHORT` or `TOPIC_TOO_LONG` |
| Depth flag | If provided, must be one of `D1`, `D2`, `D3`, `D4` | Return error: `INVALID_DEPTH` |
| Agent file | `~/.claude/plugins/delphi/agents/delphi.md` must be readable | Return error: `AGENT_NOT_FOUND` |
| Timeout guard | D1/D2: 3 min max; D3: 8 min max; D4: 15 min max | Abort step, return partial result with `TIMEOUT` status |

## Execution

1. Read the DELPHI PRO agent: `~/.claude/plugins/delphi/agents/delphi.md`
2. Read model config: `~/.claude/plugins/delphi/resources/model-config.yaml`
3. Dispatch the research request to DELPHI PRO agent with:

```json
{
  "topic": "<user topic>",
  "depth": "auto",
  "output_format": "markdown",
  "requester": "pafi"
}
```

4. DELPHI PRO handles everything: depth routing, channel selection, scout dispatch, critic, synthesis, quality gates, distribution.

## Checkpointing (Lobster Pattern 2)

For D3/D4 research, the pipeline has 8 checkpoint steps. If interrupted, the agent resumes from the last completed step (no restart-from-zero):

| Step | Name | What | Resume Benefit |
|------|------|------|---------------|
| 1 | `depth-route` | Classify depth D1-D4 | Trivial |
| 2 | `promptforge` | Optimize query (D2+) | Skip prompt optimization |
| 3 | `grillgate` | Clarification questions (D4) | Skip intake questions |
| 4 | `scout-dispatch` | Run parallel scouts | High: skip $1-3 in API calls |
| 5 | `critic` | EPR evaluation | Skip Opus critic council ($0.50) |
| 6 | `synthesis` | Generate report | Skip Sonnet/Opus synthesis |
| 7 | `quality-gate` | EPR >= 16, self_grade >= 70 | Skip quality check |
| 8 | `distribution` | Store + report + notify | Skip storage writes |

Checkpoint state stored in PROGRESS.md frontmatter via `~/.nexus/v2/shared-skills/checkpoint.sh`.

## Arguments

- `<topic>` (required): What to research
- `--depth D1|D2|D3|D4` (optional): Force specific depth. Default: auto-detect.
- `--html` (optional): Force HTML report output

## Output Contract

On success, this skill returns a structured result:

```json
{
  "status": "ok",
  "depth": "D2",
  "epr_score": 14,
  "self_grade": 78,
  "report_path": "~/.nexus/reports/<slug>.md",
  "html_path": "~/.nexus/reports/<slug>.html",
  "stored_in_cortex": true,
  "sources_count": 12
}
```

On failure, returns:

```json
{
  "status": "error",
  "error_code": "<ERROR_CODE>",
  "message": "<human-readable description>",
  "partial_report_path": "~/.nexus/reports/<slug>.md"
}
```

`partial_report_path` is present only if synthesis reached step 6 before failing.

## Error Contract

| Error Code | Trigger | Recovery |
|------------|---------|----------|
| `MISSING_TOPIC` | No topic provided | Prompt user to specify topic |
| `TOPIC_TOO_SHORT` | Topic < 3 characters | Ask user to elaborate |
| `TOPIC_TOO_LONG` | Topic > 500 characters | Ask user to shorten or split |
| `INVALID_DEPTH` | Depth flag not D1-D4 | Default to `auto`, warn user |
| `AGENT_NOT_FOUND` | `delphi.md` unreadable | Halt, instruct user to check plugin installation |
| `SCOUT_FAILURE` | All scouts returned empty | Return partial result, flag `epr_score=0` |
| `QUALITY_GATE_FAIL` | EPR < 16 and self_grade < 70 | Return report with `status: low_quality`, do not store |
| `TIMEOUT` | Step exceeded depth time limit | Abort, return last completed checkpoint output |
| `CORTEX_STORE_FAIL` | Cortex write fails | Warn user, still return local report path |

## Edge Cases

| Scenario | Expected Behavior |
|----------|-----------------|
| Topic is a URL only | Treat as web research topic; pass to scout-web |
| Topic contains PII (email, phone, SSN pattern) | Redact before dispatch, warn user |
| Depth auto-detects D4 but user is on a slow connection | Proceed with D4; user can override with `--depth D2` |
| Agent file exists but model-config.yaml missing | Use hardcoded defaults (D1=haiku, D2-D4=sonnet), warn user |
| Cortex search returns prior research on same topic | Surface summary of prior session, ask user if fresh run needed |
| `--html` requested but report renderer unavailable | Return markdown report, warn that HTML generation failed |
| Scout returns >50 sources | Critic truncates to top 20 by relevance score before synthesis |
| User interrupts mid-D4 run | Checkpoint saves state; next `/research-pro` on same topic resumes |

## Examples

```
/research-pro multi-agent orchestration frameworks 2026
/research-pro --depth D3 AI marketing automation pain points
/research-pro --html longevity interventions rapamycin
```