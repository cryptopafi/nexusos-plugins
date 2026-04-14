---
name: research-pro-deep
description: "Run DELPHI PRO deep research (D3 minimum, D4 if specified). Forces multi-scout pipeline with critic evaluation. Use: /research-pro-deep [topic] [--depth D4]"
argument-hint: <topic> [--depth D4]
allowed-tools: [Bash, Read, Write, Agent, mcp__cortex__cortex_search, mcp__cortex__cortex_store, mcp__brave-search__brave_web_search]
---

# /research-pro-deep — DELPHI PRO Deep Research

Run a deep research query through DELPHI PRO. Forces D3 minimum (multi-scout + critic + synthesizer).

## Arguments

- **topic** (required): the research topic
- **--depth D4** (optional): force exhaustive depth with Gemini Deep Research + Critic Council. Default: D3

## Execution

Dispatch to the DELPHI PRO agent with:

```json
{
  "topic": "<user's topic>",
  "depth": "D3_minimum",
  "requester": "pafi",
  "output_format": "markdown",
  "timeout_seconds": 1200
}
```
Note: DELPHI will auto-escalate to D4 if complexity warrants it or user specifies `--depth D4`.

If `--depth D4` specified:
```json
{
  "topic": "<user's topic>",
  "depth": "D4",
  "requester": "pafi",
  "output_format": "auto",
  "timeout_seconds": 3600
}
```
Note: `output_format: "auto"` = markdown for D3, markdown + HTML for D4.

D4 automatically includes: Gemini Deep Research, Critic Council (3x), Opus Synthesizer, HTML Tier 3 on VPS.

## Deliverables

- **D3**: markdown + HTML Tier 2 on VPS + Cortex + Vault + Notion
- **D4**: markdown + HTML Tier 3 Premium on VPS + Cortex + Vault + Notion + Telegram

## Error Handling

- If DELPHI agent fails to start: display "Research agent unavailable. Try again or check agent configuration."
- If research times out (>20 min for D3, >60 min for D4): display partial results with "[PARTIAL] Research timed out. Showing available findings."
- If zero findings: display "No results found for this topic. Try rephrasing or specifying channels."
- Scout failures: continue with available scouts, flag gaps in methodology.
- EPR < 16: DELPHI retries with Opus Synthesizer (1x max).

## Output Display

After research completes, display to user:
- D3: Markdown report + HTML Tier 2 link + "EPR: X/20 | Sources: N | Duration: Xm"
- D4: Markdown report + HTML Tier 3 Premium link + "EPR: X/20 | Sources: N | Duration: Xm" + Telegram notification sent

## Examples

```
/research-pro-deep AI research agent best practices         → D3
/research-pro-deep longevity interventions --depth D4        → D4
```
