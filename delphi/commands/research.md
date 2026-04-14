---
name: research-pro
description: "Run DELPHI PRO research on a topic. Auto-detects depth (D1-D4) or accepts explicit depth. Use: /research-pro [topic] [--depth D1|D2|D3|D4]"
argument-hint: <topic> [--depth D1|D2|D3|D4]
allowed-tools: [Bash, Read, Write, Agent, mcp__cortex__cortex_search, mcp__cortex__cortex_store]
---

# /research-pro — DELPHI PRO Research

Run a research query through the DELPHI PRO orchestrator.

## Arguments

- **topic** (required): the research topic, question, or URL
- **--depth D1|D2|D3|D4** (optional): force specific depth. Default: auto-detect

## Execution

Dispatch to the DELPHI PRO agent (`agents/delphi.md`) with:

```json
{
  "topic": "<user's topic>",
  "depth": "<auto|D1|D2|D3|D4>",
  "requester": "pafi",
  "output_format": "markdown"
}
```

The agent handles everything: depth routing, channel selection, scout dispatch, quality gates, distribution.

## Auto-Detect Logic

When depth is "auto", DELPHI PRO classifies based on:
- **D1**: single factual question, known topic, "what is X?"
- **D2**: needs multiple perspectives, "research X", exploratory
- **D3**: complex topic, user says "deep", >8 sources expected
- **D4**: only when explicitly requested via `--depth D4`

## Error Handling
- If DELPHI agent fails to start: display "Research agent unavailable. Try again or use /research-deep for manual depth control."
- If research times out (>10 min for D2, >30 min for D3): display partial results with "[PARTIAL] Research timed out. Showing available findings."
- If zero findings: display "No results found for this topic. Try rephrasing or specifying channels."

## Output
After research completes, display to user:
- D1: Direct text answer in chat (no file)
- D2: Markdown summary + "Full report saved to Cortex. Use `/research-pro-deep` for deeper analysis."
- D3: Markdown report + HTML link if generated + "EPR: X/20 | Sources: N | Duration: Xm"

## Examples

```
/research-pro What is Claude Code?                          → D1 instant
/research-pro multi-agent patterns 2026                     → D2 auto
/research-pro AI research agent best practices --depth D3   → D3 forced
/research-pro longevity interventions --depth D4             → D4 forced
```
