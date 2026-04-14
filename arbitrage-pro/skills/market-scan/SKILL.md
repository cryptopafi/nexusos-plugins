---
name: market-scan
description: |
  Run market intelligence scan for arbitrage opportunities. Use when user says '/market-scan', 'scan the market', 'check signals', 'what opportunities exist', or for periodic market monitoring. Do NOT use for specific deal hunting (use /hunt).
model: claude-sonnet-4-6
tools: [Read, Write, Bash, Agent, mcp__cortex__cortex_search, mcp__cortex__cortex_store]
---

# /market-scan — Market Oracle Entry Skill

## What You Do

Entry point for the Arbitrage Pro market intelligence pipeline. Monitors macro-economic signals (fuel prices, FX rates, commodity prices, trends) and correlates them with product categories to identify arbitrage opportunities.

## What You Do NOT Do

- Deep deal analysis with full profitability calculation (use /hunt)
- Individual lot price checking
- Operate without scout-signals being available (Wave 2 requirement)

## CRITICAL — Data Integrity (NEVER violate)
- Signal data MUST come from verified API sources via scouts. NEVER fabricate macro-economic data points.
- Opportunities MUST cite specific signals with timestamps. No "general market feeling" opportunities.
- If scout-signals returns empty (Wave 1 stub): explicitly state "no signal data available" — do NOT invent signals.

## Input

From user command: `/market-scan [filter]`

## Input Validation

- `filter`: optional string. Valid values: "fuel", "fx", "commodities", "trends", "news", or a product category name. Default: broad (all signals).

## Execution

1. Parse and validate user input
2. Check if scout-signals is available (Wave 2)
3. If not available → return message: "Market scan is scheduled for Wave 2. Use /hunt for deal hunting."
4. If available → delegate to orchestrator with:
   ```
   { command: "market-scan", filter }
   ```
5. Orchestrator runs 6-step pipeline: signals → analyze → opportunities → report → distribute

## Output

Clickable VPS URL to market scan report + brief summary in chat.

## Error Handling

- Wave 1: return informative message about Wave 2 availability
- Signal sources down: proceed with available sources, report gaps

## NOTE

This skill becomes fully functional in Wave 2.
