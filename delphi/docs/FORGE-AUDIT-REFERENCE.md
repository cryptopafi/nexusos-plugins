# FORGE-AUDIT-REFERENCE — DELPHI PRO Quick Reference

> Slim English summary of `~/.nexus/procedures/FORGE-AUDIT.md` v1.7.
> Covers all audit tiers, 8 NPLF dimensions, DSE extensions, and scoring methodology.

---

## What FORGE-AUDIT Is

A universal, scalable quality audit framework. It applies the same checklist to any subject — procedures, code, skills, infrastructure, configurations. Three tiers: LIGHT (3 min), STANDARD (15 min), DEEP (30 min).

**Key rule**: FORGE-AUDIT MUST be executed by Opus subagent on all tiers — never self-audit.

---

## Step 1: Classify the Audit Tier

| Tier | When | Dimensions | Steps |
|:---:|:---|:---:|:---|
| **LIGHT** | Minor fix, config change, quick review | 3 | 1 → 2 → 6 |
| **STANDARD** | New procedure, feature, Codex delivery, security change | 6 | 1 → 2 → 3 → 4 → 6 |
| **DEEP** | Architecture, production audit, HARD rule, full security | 8 | 1 → 2 → 3 → 4 → 5 → 6 |

Auto-escalation: if LIGHT finds a **N** score on any dimension → escalate to STANDARD.

---

## 8 NPLF Dimensions

Scoring scale: **F** = Fully achieved (86–100%), **L** = Largely achieved (51–85%), **P** = Partially achieved (16–50%), **N** = Not achieved (0–15%)

Numeric conversion: F=4, L=3, P=2, N=1

| # | Dimension | Key Question |
|:---:|:---|:---|
| **D1** | **Completeness** | Are all sections, steps, and edge cases present? |
| **D2** | **Accuracy** | Is it technically correct? All paths executable? Zero contradictions? |
| **D3** | **Verifiability** | Can you objectively verify it works? Checklist? Measurable criteria? |
| **D4** | **Clarity** | Understandable by target user on first read? No undefined jargon? |
| **D5** | **Consistency** | No conflicts with other procedures, rules, or configs? |
| **D6** | **Safety** | Prohibited actions defined? Boundaries clear? NEVER list present? |
| **D7** | **Adequacy** | Solves the actual problem? Covers all use cases? (DEEP only) |
| **D8** | **Maintainability** | Changelog, versioning, ownership, update protocol? (DEEP only) |

### NPLF Calibration Anchors

| Dim | F (86–100%) | L (51–85%) | P (16–50%) | N (0–15%) |
|:---:|:---|:---|:---|:---|
| D1 | All sections + test cases + enforcement loop | All sections present, 1–2 test cases missing | Major section missing | Skeleton only |
| D2 | All claims verified, zero contradictions | Mostly correct, 1 minor inaccuracy | Multiple inaccuracies or untested claims | Fundamentally wrong |
| D3 | Objective checklist, measurable criteria, VK format | Checklist present, some items subjective | Vague criteria, no checklist | No way to verify |
| D4 | Understandable on first read | Clear overall, 1–2 terms undefined | Confusing structure, ambiguous steps | Incomprehensible |
| D5 | Zero conflicts, all refs valid | 1 minor inconsistency | Contradicts an active rule | Violates HARD rule |
| D6 | All prohibitions defined, NEVER list present | Safety section incomplete | Vague ("be careful"), no explicit prohibitions | No safety at all |
| D7 | Solves problem completely, covers all use cases | Solves main problem, 1–2 edge cases uncovered | Partially solves, significant gaps | Does not solve the stated problem |
| D8 | Changelog + version + ownership + health entry | Most present, missing 1 item | Ownership unclear, no version control | Monolithic, no version, no ownership |

**Reasoning requirement**: For each dimension, state the evidence found BEFORE assigning a score.

---

## Subject-Type Focus

| Subject | Focus Dimensions | Reason |
|:---|:---|:---|
| FORGE procedure | D1, D4, D8 | Must be complete, clear, maintainable |
| Code / Codex delivery | D2, D3, D6 | Must work, be testable, and safe |
| Infrastructure / config | D2, D6, D3 | Must be accurate, secure, observable |
| Skill / agent prompt | D1, D4, D5 | Must be complete, clear, consistent with system |
| Architecture / design | D7, D8, D5 | Must be adequate, evolvable, fitting ecosystem |

All dimensions in the tier are still scored — this table indicates which to scrutinize most.

---

## DSE Extensions (Domain-Specific Extensions)

After tier classification, check if DSE extensions apply:

| DSE | Trigger | Extra Dimensions |
|:---:|:---|:---:|
| **DSE-RESEARCH** | Research engine, search pipeline, data aggregator, multi-source scraper | +4 (R1–R4) |
| **DSE-WORKFLOW** | Multi-agent workflow, handoff protocol, multi-step pipeline, daemon+queue | +4 (W1–W4) |

Multiple DSEs are allowed if the subject qualifies for more than one (e.g. DELPHI PRO = both).

### DSE-RESEARCH Dimensions (scale 1–5)

| # | Dimension | What It Evaluates |
|:---:|:---|:---|
| **R1** | Source Coverage | Are all relevant sources covered? Any critical gaps? |
| **R2** | Prompt Quality | Are AI source prompts optimized? System prompt, role, output format, constraints? |
| **R3** | Token/Resource Scaling | Do max_tokens, limits, timeouts scale with research depth (D1→D4)? |
| **R4** | Route Optimization | Is each query type routed to the highest-authority source? Fallbacks optimal? |

### DSE-WORKFLOW Dimensions (scale 1–5)

| # | Dimension | What It Evaluates |
|:---:|:---|:---|
| **W1** | Handoff Quality | Are handoffs between components fully documented with format, validation, error path? |
| **W2** | State Management | Is state persistent, recoverable, and observable? History? Rollback? |
| **W3** | Error Recovery | What happens when a component fails? Retry, fallback, alerting per component? |
| **W4** | Idempotency | Are operations safe to re-execute? No duplicates or side effects on re-run? |

---

## Scoring

**Core score** = arithmetic mean of NPLF dimensions (F=4, L=3, P=2, N=1)

**DSE score** = arithmetic mean of DSE dimensions (1–5 scale), normalized: `dse_normalized = dse_raw × 4 / 5`

**Combined score**:
- No DSE: combined = core (100%)
- 1 DSE: `(core × 0.6) + (dse_normalized × 0.4)`
- 2+ DSEs: `(core × 0.5) + (dse1_normalized × 0.25) + (dse2_normalized × 0.25)`

### Verdict Thresholds

| Combined Score | Verdict | Action |
|:---:|:---:|:---|
| ≥ 3.5 | **PASS** | Approved. Minor notes optional. |
| 2.5–3.4 | **CONDITIONAL** | Approved with conditions. List required fixes. |
| < 2.5 | **FAIL** | Rejected. List all gaps. Re-audit required after fix. |

**Hard exception**: Any single dimension with score N (core) or 1/5 (DSE) → max CONDITIONAL, regardless of total average.

---

## Convergence Loop Methodology

1. Audit subject (STANDARD tier minimum for new DELPHI skills)
2. If CONDITIONAL/FAIL → list findings with concrete action items
3. Fix findings
4. Re-audit the same subject with same tier
5. Compare delta against previous audit (track improvement per dimension)
6. Repeat until PASS or escalate to Pafi

**Delta tracking**: When a previous audit exists in Cortex, calculate score movement per dimension (↑/↓/=) and trend.

---

## DELPHI PRO Audit Configuration

Per DELPHI-SOC.md (Faza 4: Quality Gate), DELPHI components audit at:
- Skills: tier STANDARD + DSE-RESEARCH
- Orchestrator agent (`delphi.md`): tier DEEP + DSE-WORKFLOW
- CLI scripts: tier LIGHT

Minimum passing score for all components: **≥ 3.5/4.0**

Source: `~/.nexus/procedures/FORGE-AUDIT.md` v1.7
