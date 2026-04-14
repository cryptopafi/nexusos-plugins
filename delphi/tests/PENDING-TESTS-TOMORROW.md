# PENDING TESTS — 2026-03-21

## BLOCKER: OpenRouter daily limit needs to be set to $15+ on key `a5eb89...b43e`
Dashboard: https://openrouter.ai/settings/keys

## Test 1: Tongyi complementar D2 (~$0.003)
Feed D2 scout findings to Tongyi, ask for: root causes, counter-arguments, missing angles, pricing, risks.
Compare D2 WITHOUT Tongyi vs D2 WITH Tongyi.

## Test 2: Tongyi complementar D3 (~$0.003)
Feed D3 report to Tongyi, ask for: gaps, counter-evidence, deeper drill, competitors, pricing validation.
Compare D3 WITHOUT Tongyi vs D3 WITH Tongyi.

## Test 3: Perplexity Deep 40K tokens (~$1.30)
Same market analysis prompt, max_tokens=40000. See if it completes ALL 5 parts this time.

## Total cost: ~$1.35

## Prompt to use (SAME for all, same as all previous benchmarks):
The full market pain point analysis prompt (6 stakeholders × 7 regions × 14 products × financial sizing × emerging opportunities).

## What we already have for comparison:
- DELPHI D2: EPR 19, 38 sources, 77s, $0.04
- DELPHI D3: EPR 17, 33 sources, 435s, $0.80
- DELPHI D4: EPR 17, 63 sources, ~10min, $3-5
- Tongyi standalone: 145 lines, 5/5 parts, $0.003
- Perplexity Deep 16K: 534 lines, 4.5/5 parts (truncated), $1.30
- o4-mini Deep: 70 lines, 1/5 parts, $0.33 (WORST)
