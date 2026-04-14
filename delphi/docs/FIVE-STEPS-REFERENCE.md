# FIVE-STEPS-REFERENCE — DELPHI PRO Quick Reference

> Slim English summary of `~/.nexus/procedures/FIVE-STEPS-AGENTS.md` v1.4.
> Covers the 5-step multi-agent design framework used when building or auditing DELPHI PRO components.

---

## What Five-Steps-Agents Is

A standardized framework for designing any multi-agent system (2+ agents). Applies 5 mandatory steps to every agent, plus a 15-question intake process. Used when creating new pipeline components or auditing existing ones.

**Rule**: Minimum 10/12 on the validation checklist to pass. Fewer than 10 → rework.

---

## Phase 0: INTAKE — Structured Discovery (15 Questions)

Before any design work, run 3 question rounds. Skip conditions: pipelines with ≤3 agents skip Round 3.

### Round 1: Scope & Purpose (always)

| # | Question | Determines |
|:---:|:---|:---|
| Q1 | What problem does this system solve? | Pipeline purpose |
| Q2 | Who is the end user? (you/team/clients/fully-automated) | Human-in-the-loop, error handling |
| Q3 | What INPUT does it receive? (data, URLs, commands, events, cron) | Trigger mechanism |
| Q4 | What OUTPUT does it produce? (report, files, actions, notifications) | Output format, last-agent responsibility |
| Q5 | How many DISTINCT tasks? List briefly. | Agent decomposition |

### Round 2: Architecture Constraints (based on R1)

| # | Question | Determines |
|:---:|:---|:---|
| Q6 | Where does it run? (Claude Code / VPS / API / mix) | Deployment target |
| Q7 | Cost budget? (free / low-cost / no limit) | Model routing |
| Q8 | Frequency? (one-shot / on-demand / scheduled / real-time) | State management |
| Q9 | What tools/APIs needed? | Tool isolation |
| Q10 | What happens on failure? (retry / flag / alert / stop) | Error handling |

### Round 3: Quality & Integration (4+ agents only)

| # | Question | Determines |
|:---:|:---|:---|
| Q11 | Integrate with existing agents or systems? | Handoff points |
| Q12 | Autonomy level? (full-auto / human-approval / manual) | Approval gates |
| Q13 | Persistent state between runs? | State management |
| Q14 | How to verify success? What does "done" look like? | Success criteria |
| Q15 | Matches a known pattern? (lead finder, content pipeline, competitive intel) | Template matching |

---

## The 5 Steps — Applied to Every Agent

### Step 1: Boundaries

Each agent MUST have explicit "You do NOT..." section. Zero overlap between agents. Orchestrator does NOT do the sub-agents' work.

```markdown
## Boundaries
You find hiring signals on job boards.
You return structured data per company.

You do NOT research companies.
You do NOT write outreach copy.
```

### Step 2: Signal Tiers

For detection/classification agents: define minimum 3 tiers (HIGH/MED/LOW) with concrete, measurable criteria. Each tier must be mutually exclusive.

```markdown
## Signal Tiers
- HIGH → Prioritize: VP or Director-level product hire
- MEDIUM → Include: Multiple mid-level PM hires within 30 days
- LOW → Deprioritize: Single junior hire, no pattern
```

### Step 3: Error Handling

Default rule: **flag incomplete, never drop.** Every failure path documented explicitly.
- If Q2 = human-in-the-loop: flag → "needs manual review"
- If Q2 = fully automated: flag + alerting mandatory (webhook, log, notification)
- Circuit breaker: if ALL sub-agents fail → orchestrator emits error status and triggers alerting regardless

### Step 4: Tool Handling

Each agent gets ONLY the tools it needs. Zero shared tools unless explicitly justified. Orchestrator has NO tools (it coordinates, not executes).

### Step 5: Model Routing

Cheapest viable model per agent:

| Task Complexity | Model | Relative Cost |
|:---|:---:|:---:|
| Scraping, formatting, detection | Haiku | 1x (baseline) |
| Synthesis, assessment, qualification | Sonnet | ~5x |
| Orchestration, complex reasoning, edge cases | Opus | ~30–60x |

A well-routed pipeline (Haiku detection + Sonnet enrichment + Sonnet orchestration) costs ~80% less than all-Opus.

---

## Handoff Contracts

Output of Agent N = Input of Agent N+1. Always include `status` field:

```json
{
  "agent": "signal-detector",
  "status": "complete|partial|error",
  "items": [{ "company": "Acme", "signal_tier": "HIGH", "confidence": 0.85 }],
  "errors": [],
  "metadata": { "items_total": 5, "items_complete": 4 }
}
```

Confidence calibration:
- `> 0.8` (HIGH): verified from primary sources — process directly
- `0.5–0.8` (MEDIUM): inferred or secondary sources — process but mark "needs verification"
- `< 0.5` (LOW): unreliable or contradictory — flag as "needs manual review"

---

## Validation Checklist (12 Points)

| # | Check |
|:---:|:---|
| 1 | Every agent has boundaries (does + does NOT)? |
| 2 | Signal tiers defined with concrete criteria (min 3)? |
| 3 | Error handling: "flag, don't drop" on every path? |
| 4 | Tools isolated per agent, zero unjustified overlap? |
| 5 | Model routing: cheapest viable per agent? |
| 6 | Token budget: sub-agents ≤800 tokens, orchestrator ≤1500 tokens? |
| 7 | Orchestrator does NOT execute (only coordinates)? |
| 8 | Handoff contract: Output Agent N = Input Agent N+1, with `status` field? |
| 9 | Output format specified per agent (structured data)? |
| 10 | Idempotency: re-run safe? No duplicates? Timestamps on outputs? |
| 11 | State management: stateless explicit OR persistent pattern implemented? |
| 12 | If Q2=fully-automated → alerting mechanism defined (not just "flag")? |

**Pass threshold**: ≥ 10/12

---

## Known Pipeline Templates

| Template | Agents | Use When |
|:---|:---|:---|
| Lead Finder | Signal Detector (Haiku) → Enrichment (Sonnet) → Orchestrator | Finding companies with buying signals |
| Client Onboarding | Intake (Sonnet) → Setup (Haiku) → Orchestrator | Provisioning accounts from client data |
| Content Pipeline | Research (Sonnet) → Writer (Sonnet) → Orchestrator | Research a topic and produce content |
| Competitive Intel | Monitor (Haiku) → Analyst (Sonnet) → Orchestrator | Weekly competitive monitoring |

Source: `~/.nexus/procedures/FIVE-STEPS-AGENTS.md` v1.4
