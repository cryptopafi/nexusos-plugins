---
name: hunt
description: "Hunt for profitable deals at European auctions. Usage: /hunt [category] [--region NL,DE,RO] [--min-margin 30]"
user-invocable: true
---

# /hunt — Deal Hunter

Thin dispatcher for the Arbitrage Pro deal hunting pipeline.

## Trigger

User says `/hunt [category]`, `/hunt espresoare`, `/hunt --region NL`, or any variation requesting a deal search.

## Input Parsing

Extract from user input:
- `category` (optional): product category to search (e.g., "espresoare", "office-furniture", "electronics")
- `--region` (optional): comma-separated country codes (e.g., "NL,DE,RO"). Default: all.
- `--min-margin` (optional): minimum ROI% threshold. Default: 30.
- `--limit` (optional): max deals to return. Default: 10.

## Dispatch

1. Load the `hunt` entry skill (`skills/hunt/SKILL.md`)
2. Pass parsed parameters to the orchestrator (`agents/arbitrage.md`)
3. The orchestrator executes the 10-step /hunt pipeline

## Output

HTML report with ranked deals, deployed to VPS. Clickable link returned to user.

## Error Handling

If no lots found → report "No lots found matching criteria" with suggestions for broader search.
If analysis fails → report partial results with warning.
