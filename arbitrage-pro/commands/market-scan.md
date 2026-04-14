---
name: market-scan
description: "Run a market intelligence scan for arbitrage opportunities. Usage: /market-scan [filter]"
user-invocable: true
---

# /market-scan — Market Oracle

Thin dispatcher for the Arbitrage Pro market intelligence pipeline.

## Trigger

User says `/market-scan`, `/market-scan fuel`, `/market-scan electronics`, or any variation requesting market intelligence.

## Input Parsing

Extract from user input:
- `filter` (optional): specific signal type or category to focus on (e.g., "fuel", "fx", "electronics", "vehicles"). Default: broad (all signals).

## Dispatch

1. Load the `market-scan` entry skill (`skills/market-scan/SKILL.md`)
2. Pass parsed parameters to the orchestrator (`agents/arbitrage.md`)
3. The orchestrator executes the 6-step /market-scan pipeline

## Output

HTML report with signals, opportunities, and recommendations. Deployed to VPS.

## Error Handling

If signal sources unavailable → report with reduced confidence, list which sources failed.

## NOTE

This command is Wave 2. At MVP, it returns a message indicating market-scan is not yet active.
