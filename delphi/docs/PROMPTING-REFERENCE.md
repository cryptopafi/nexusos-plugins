# PROMPTING-REFERENCE — DELPHI PRO Quick Reference

> Slim English summary of `~/.nexus/procedures/PROMPTING.md` v1.8.
> Covers the Classification Gate, PromptForge pipeline phases, scoring, and key techniques.

---

## What the Prompting System Is

A unified entry point that orchestrates the full prompting pipeline (PromptForge v3.7 + 73+ PE techniques + Cortex knowledge base) for every non-trivial prompt in the system. Every DELPHI PRO skill prompt flows through this when being created or optimized.

---

## Classification Gate (Step 1)

Before any prompting work, classify the request:

| Class | Criteria | PromptForge Path | Techniques |
|:---:|:---|:---|:---:|
| **TRIVIAL** | Simple lookup, direct command, follow-up in active context | SKIP | None |
| **STANDARD** | Single-domain, clear scope, low stakes | F0 → F1 → F2(partial) → F3 → F5(fast) → F6 | 2–3 |
| **COMPLEX** | Multi-step, high-stakes, ambiguous intent, >3 sub-tasks | F0 → F1 → F2(full) → F3 → F4 → F5 → F6 | 4–6 |
| **PRODUCTION** | Will run in API / batch / repeated execution | COMPLEX + F7 (library save + Promptfoo eval) | Include C-072, C-073 |
| **Agentic** | Subset of COMPLEX with tool-use | COMPLEX + agentic techniques | ART + ReAct + ONE-tool |

Detection heuristics:
- Length >200 chars with no structure → STANDARD minimum
- Vague terms ("improve", "make better") → STANDARD minimum
- Multiple unrelated topics → COMPLEX
- Explicit deployment/API context → PRODUCTION

---

## PromptForge Pipeline Phases (F0–F7)

| Phase | Name | When to Run |
|:---:|:---|:---|
| **F0** | Intake & Triage (injection guard, classification, fast-path) | Always — entry point |
| **F1** | Analysis (agent detection, chain detection, complexity matrix) | STANDARD+ |
| **F2** | SCOPE (8Q bank, max 3 asked, conflict resolver) | STANDARD+ |
| **F3** | Construction (8 techniques, per-level allocation) | STANDARD+ |
| **F4** | Format Final (verification checklist) | COMPLEX+ |
| **F5** | Scoring & Gate (5 dims × 20pts = /100, Self-Refine Loop) | STANDARD+ |
| **F6** | Delivery (level-specific output) | STANDARD+ |
| **F7** | Library (storage, reuse tracking, pruning) | PRODUCTION only |

**Full docs**: `memory/promptforge.md`

---

## F5 Scoring — 5 Dimensions

Each dimension: 0–20 points. Total: 0–100.

| Dimension | What It Measures |
|:---|:---|
| **D1 Claritate** (Clarity) | Is the prompt unambiguous? Does the model know exactly what to do? |
| **D2 Completitudine** (Completeness) | Are all necessary context, constraints, and output format specified? |
| **D3 Corectitudine** (Correctness) | Is the prompt factually accurate? No contradictions? |
| **D4 Focalizare** (Focus) | Is the prompt free of irrelevant instructions? Stays on topic? |
| **D5 Adecvare agent** (Agent Fit) | Is the prompt optimized for the target model (Claude/Haiku/Sonnet/Opus)? |

### Quality Gates

| Score | Action |
|:---:|:---|
| Any D < 12 | BLOCKED → Self-Refine Loop |
| Total < 65 | BLOCKED → Self-Refine Loop |
| Total 65–74 | Independent review (re-score D5→D1) |
| Total ≥ 75 + all D ≥ 12 | PASS → Execute |

Self-Refine Loop: max 2 iterations per dimension, 4 total. After 4 → escalate to Pafi.
Global iteration cap: max 6 iterations combined (Self-Refine + OPRO) per session.

---

## Technique Selection (Step 3)

Select 1–3 techniques for STANDARD, 3–6 for COMPLEX/PRODUCTION:

| Task Type | Primary Techniques |
|:---|:---|
| Reasoning / Analysis | C-058 Few-Shot CoT, C-062 Step-Back, Contrastive CoT (C-063) |
| Creative / Generation | C-042 Persona, C-045 Audience Persona, C-053 Outline Expansion |
| Ambiguous / Vague | C-070 Intention Prompting, RAR (C-067), C-043 Question Refinement |
| Code / Technical | CRITIC/Tool-Verify (C-068), C-059 ReAct, C-060 Self-Grading |
| Complex multi-step | C-050 Recipe Pattern, C-044 Cognitive Verifier, Auto-Decomposition |
| Production / API | C-072 Prompt Caching, C-073 Promptware Lifecycle, Promptfoo eval |
| Agentic / Tool-Use | ReAct (C-059), ART (Cortex DAIR), ONE-tool-per-iteration |
| Agent Communication | MVCP handoff JSON, subagent briefing, context budget (C-071) |
| Self-Improvement | Self-Refine+stop (PR-046), Reflexion, CRITIC (C-068) |

Technique procedure paths:
- C-042..C-073: `~/.nexus/procedures/training/ai-prompt-engineering/`
- PR-001..PR-057, ND-001..ND-022: Cortex collection `technical`

---

## Cortex Pre-Search (Step 2)

Before crafting any STANDARD+ prompt, search Cortex for existing high-scoring variants:

```
mcp__cortex__cortex_search(query="<PROMPT_SUMMARY>", collection="procedures", limit=3)
```

Score thresholds:
- **≥ 0.7** → use Cortex variant as base; skip to technique selection
- **≥ 0.5** → use as starting point; run SCOPE questions for gaps
- **< 0.5** → build from scratch via full pipeline

---

## Promptware Lifecycle — PRODUCTION Only (Step 7)

For PRODUCTION class prompts (C-073):
1. **Version**: assign `v{MAJOR}.{MINOR}`, store in Cortex with version metadata
2. **Test suite**: define 3–5 test cases (happy path + edge cases + adversarial input)
3. **Eval gate**: run `npx promptfoo eval` comparing candidate vs current baseline before deploy
4. **Deploy**: stable prefix → cache with `cache_control: {type: ephemeral}`
5. **Monitor**: cache hit rate >70%, latency, task completion rate
6. **Rollback criterion**: any metric drops >10% → revert immediately

---

## Model Routing for Prompting Tasks

| Activity | Model |
|:---|:---:|
| Classification gate (Step 1) | Sonnet (lightweight heuristic) |
| Full pipeline execution (Steps 2–6) | Sonnet (orchestration role) |
| Novel/complex technique selection | Opus subagent (deep PE knowledge) |
| ECHELON technique evaluation | Opus |
| Promptfoo eval gate (Step 7) | Deterministic (npx — not LLM) |

---

## DELPHI PRO Relevance

- All 15 SKILL.md prompts are STANDARD or COMPLEX class
- `delphi.md` orchestrator prompt is COMPLEX class (multi-step, tool-use, agentic)
- Any skill prompt optimization runs through this pipeline
- SOC Faza 2 (Skill Optimize) applies PromptForge v3.7 to skills scoring < 75

Source: `~/.nexus/procedures/PROMPTING.md` v1.8
