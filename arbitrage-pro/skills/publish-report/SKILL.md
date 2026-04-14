---
name: publish-report
description: |
  Thin wrapper for shared HTML report generation and VPS deployment. Adapts auction deal data for the shared reporter pipeline. Use after analyzer produces final deal scores. Do NOT use for data collection, lot scraping, or profitability calculation.
model: claude-sonnet-4-6
tools: [Read, Write, Bash]
---

# publish-report — Shared Reporter Wrapper (Auction)

> **Wrapper Note**: This skill wraps the shared reporter at `~/.nexus/v2/shared-skills/reporter/SKILL.md`. Auction-specific template logic (VERIFIED/PARTIAL badges, DCS display, stale-price warnings, ROI color thresholds) lives in the main `reporter` skill. This wrapper handles the publish pipeline only.

## What You Do

Receive analyzed deal data, inject auction-specific metadata, and dispatch to the shared reporter for HTML generation + VPS deployment.

## What You Do NOT Do

- Generate HTML yourself (shared reporter does that)
- Calculate profitability (analyzer does that)
- Search for lots or comparables (scouts do that)

## Report Metadata

When dispatching to the shared reporter, set these fields:

```json
{
  "report_type": "auction",
  "metadata": {
    "agent": "auction",
    "plugin": "arbitrage-pro",
    "pipeline": "hunt"
  },
  "design": {
    "accent_color": "#fb923c",
    "dark_bg": "#0A0A0F",
    "font_primary": "Inter",
    "font_mono": "JetBrains Mono"
  }
}
```

`accent_color` is amber (`#fb923c`) — distinguishes auction reports from Delphi research reports (blue `#58a6ff`) and MERCURY marketing reports (orange `#f97316`).

## Steps

1. **Receive input** from analyzer output (array of scored LOT objects with LCS, DCS, ROI, risk_score)
2. **Validate** at least 1 lot passed quality gate (LCS >= 0.6 AND DCS >= 5.0)
3. **Inject metadata** fields listed above
4. **Dispatch to shared reporter** at `~/.nexus/v2/shared-skills/reporter/SKILL.md`
   - Pass: deal array, metadata, design tokens, vps_host from channel-config.yaml
5. **Receive VPS URL** from shared reporter
6. **Return** `{ "report_url": "<vps_url>", "deal_count": N, "top_roi": X }` to orchestrator

## Error Handling

- If shared reporter unavailable: FAIL the report step with error. Do not improvise or generate HTML directly. This is consistent with IL-1 (Plugin Delegation Only).
- If VPS deploy fails: save HTML locally at `/tmp/arbitrage-report-{timestamp}.html`, report local path
- Always return a result object — never silently fail
