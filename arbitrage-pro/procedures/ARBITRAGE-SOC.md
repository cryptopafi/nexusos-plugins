---
type: procedure
name: ARBITRAGE-SOC
version: "1.0"
status: ACTIVE
created: 2026-03-22
scope: Self-Optimization Cycle for Arbitrage Pro deal hunting pipeline
rule: META-S-014 (Arbitrage Agent Self-Optimization)
parent: DELPHI-SOC v1.0 (adapted pattern)
---

# ARBITRAGE-SOC — Self-Optimization Cycle

## 1. Problema

Arbitrage Pro's deal quality depends on accurate prices, correct transport costs, and valid sell comparables — all of which change daily. Without continuous optimization, the pipeline degrades: extraction patterns break (DOM changes), transport rates drift, new marketplaces appear, and the system's "category intelligence" (which categories are profitable) stays frozen at build-time knowledge.

## 2. Procedura

### Faza 0: Karpathy Loop (per session, after every /hunt run)

**Purpose**: Micro-experiments with binary evaluation to improve Deal Quality Score (DQS).

**What is DQS (Deal Quality Score)?**
Binary metric per deal: was the pipeline's prediction correct?
- After a deal is acted upon (bid placed), track actual outcome
- DQS = 1 if final_buy_price was within 20% of predicted AND sell_price achieved was within 30% of estimated
- DQS = 0 otherwise

**Steps (automated after each /hunt)**:
1. Save pipeline run to `state/run-log.json`:
   ```json
   {
     "run_id": "hunt-2026-03-22-001",
     "timestamp": "ISO8601",
     "category": "industrial",
     "platform": "troostwijk",
     "lots_scanned": 10,
     "deals_found": 3,
     "tools_used": {"agent-browser": 5, "exa": 8, "webfetch": 2},
     "tool_failures": {"agent-browser": 0, "exa": 1, "webfetch": 3},
     "extraction_success_rate": 0.85,
     "avg_dcs": 7.2,
     "categories_tested": ["industrial"],
     "sell_sources": {"machineseeker": 2, "ebay": 3, "olx": 1},
     "quality_gate_results": {"passed": 2, "warned": 1, "failed": 0},
     "reverification_deltas": [{"lot": "A7-43477-4", "original": 750, "reverified": 750, "delta_pct": 0}]
   }
   ```
2. Compare with previous runs for same category:
   - extraction_success_rate improved? → log IMPROVEMENT
   - tool_failures decreased? → log IMPROVEMENT
   - avg_dcs increased? → log IMPROVEMENT
3. If any metric degraded by >10% vs previous run:
   - Identify which tool/step caused the degradation
   - Log to `state/optimization-proposals.json`
   - Flag for next Faza 2 (Skill Optimize)

**Binary eval per micro-experiment** (when testing a prompt change):
1. Pick ONE skill prompt modification (e.g., change Exa query structure)
2. Run /hunt with modification on SAME category as last successful run
3. Compare: avg_dcs_new > avg_dcs_baseline?
   - YES → keep modification (commit to SKILL.md)
   - NO → revert
4. Max 3 experiments per session

### Faza 1: Category Intelligence (weekly)

**Purpose**: Learn which categories are profitable and which to avoid.

**Steps**:
1. Read all entries from `state/run-log.json`
2. Build category profitability matrix:
   ```
   | Category | Runs | Avg ROI | Win Rate | Avg DCS | Best Platform |
   |----------|------|---------|----------|---------|---------------|
   | vehicles | 3 | 45% | 67% | 7.5 | troostwijk |
   | industrial-branded | 2 | 43% | 50% | 7.0 | troostwijk |
   | electronics | 1 | -16% | 0% | 4.0 | — |
   | collectibles | 1 | -10% | 0% | 5.0 | catawiki |
   ```
3. Update `state/category-intelligence.yaml`:
   ```yaml
   profitable:
     - vehicles: {avg_roi: 45, confidence: HIGH, best_source: troostwijk}
     - industrial-branded: {avg_roi: 43, confidence: MEDIUM, best_source: troostwijk}
     - tools-generators: {avg_roi: 128, confidence: LOW, runs: 1}
   unprofitable:
     - electronics-individual: {avg_roi: -16, reason: "margin too thin after premium+transport"}
     - watches-catawiki: {avg_roi: -10, reason: "Catawiki expert estimates = market price"}
     - industrial-generic: {avg_roi: -51, reason: "no-brand = no resale premium, transport kills margin"}
   untested: [office-furniture, medical, agricultural, construction]
   ```
4. Feed category-intelligence into /hunt — when user searches a category flagged unprofitable, WARN before running full pipeline

### Faza 2: Extraction Pattern Optimization (bi-weekly)

**Purpose**: Keep extraction JS patterns working as platforms change DOMs.

**Steps**:
1. For each enabled platform (Troostwijk, Catawiki):
   - Run agent-browser on 3 known lots with verified prices
   - Compare extracted price with known-good value
   - If extraction fails or delta >10% → DOM changed, pattern broken
2. If pattern broken:
   - agent-browser screenshot the lot page
   - Analyze screenshot for new price element location
   - Update JS eval pattern in `scout-source/SKILL.md`
   - Re-test on 3 lots → if 3/3 pass → commit
3. For each Exa query pattern:
   - Re-run on 5 known lots
   - Compare results with baseline
   - If quality dropped (fewer results, wrong prices) → adjust query structure
4. Log results to `state/extraction-health.json`

### Faza 3: Transport Rate Refresh (monthly)

**Purpose**: Keep transport-rates.yaml accurate as market prices shift.

**Steps**:
1. Run Exa search for current groupage/LTL rates NL→RO, DE→RO, BE→RO
2. Cross-reference with Cargopedia spot rates (if API integrated)
3. Compare with current `transport-rates.yaml` values
4. If delta >15% on any route → update rate, bump version
5. Log to `state/transport-rate-history.json` for trend analysis

### Faza 4: Quality Gate Learning (per session)

**Purpose**: Quality gate improves by learning from verification results.

**Steps**:
1. After each /hunt, quality-gate logs its reverification results
2. Track per-platform verification success:
   ```
   | Platform | WebFetch | agent-browser | Exa | Best Tool |
   |----------|----------|---------------|-----|-----------|
   | troostwijk | 0/5 | 5/5 | 4/5 | agent-browser |
   | catawiki | 0/3 | 0/3 | 3/3 | exa |
   | olx.ro | 3/3 | 3/3 | 3/3 | any |
   | ebay | 1/4 | 1/4 | 4/4 | exa |
   ```
3. Update tool priority order per platform based on success rate
4. If a tool's success rate drops below 30% for a platform → disable it for that platform, reduce unnecessary API calls

### Faza 5: SOL Integration (weekly, with NexusOS SOL cycle)

**Purpose**: Standard Self-Optimization Loop on all Arbitrage Pro prompts.

**Steps**: Follow SOL v1.5:
1. Discover: scan all 14 SKILL.md files
2. Audit: Opus evaluates D1-D5
3. Build: apply PE techniques to lowest-scoring skills
4. Approve: auto if delta >= +5
5. Track: update manifest

## 3. State Files

All learning persists across sessions in `state/`:

| File | Purpose | Updated |
|------|---------|---------|
| `run-log.json` | Every /hunt run with full metrics | Per run |
| `category-intelligence.yaml` | Profitable vs unprofitable categories | Weekly |
| `extraction-health.json` | Platform extraction pattern status | Bi-weekly |
| `transport-rate-history.json` | Rate drift tracking over time | Monthly |
| `optimization-proposals.json` | Queued improvements from Karpathy loop | Per run |
| `tool-success-matrix.json` | Per-platform tool verification success rates | Per run |

## 4. Karpathy Loop — Cross-Session Learning

**How the agent gets better every session:**

```
Session 1: /hunt vehicles → 2 deals (46%, 44%) → log to run-log
Session 2: /hunt industrial → 1 deal (43%), 1 skip (-51%) → log
           Karpathy: "industrial-generic unprofitable" → category-intelligence updated
Session 3: /hunt vehicles → pipeline knows vehicles=HIGH, skips pre-screening
           Karpathy: "Troostwijk extraction 100% success" → raise confidence
Session 4: /hunt electronics → pipeline WARNS "electronics flagged unprofitable in category-intelligence"
           User overrides → run anyway → confirms -16% → reinforces learning
Session 5: Troostwijk changes DOM → extraction fails → Faza 2 detects, updates pattern
           Quality gate: "agent-browser success rate dropped to 40%" → flags for fix
Session N: Pipeline has learned: best categories, best platforms per category,
           optimal tool per site, accurate transport rates, common false positives
```

**Key principle**: State files are the "memory" — they persist between sessions. Each /hunt run writes to them, each subsequent run reads from them. The agent never starts from zero.

## 5. Protecții

| Protection | How |
|---|---|
| STABLE mark | 3 cycles no DQS improvement → skip 30 days |
| Max 3 experiments/session | No over-optimization in single session |
| Revert on fail | Extraction pattern broken → git revert |
| Pafi gate on architecture | Category removal, new platform, cost model changes → Pafi approval |
| Cost awareness | Track Exa/Sonar API costs per run in run-log |
| Circular detection | If category flips profitable↔unprofitable 3 times → flag for manual review |

## 6. Metrics

| Metric | Target | Formula |
|---|---|---|
| extraction_success_rate | >90% | lots_with_price / lots_attempted |
| avg_dcs | >7.0 | mean of all deal DCS scores per run |
| category_coverage | >6 categories tested | unique categories in run-log |
| reverification_match_rate | >85% | reverified_within_10pct / total_reverified |
| tool_failure_rate | <15% | tool_failures / total_tool_calls |
| transport_rate_accuracy | <15% drift | abs(current - verified) / verified |

## 7. Calendar

```
Every /hunt run:      Faza 0 (Karpathy metrics logging)
Weekly (Sunday):      Faza 1 (Category Intelligence) + Faza 5 (SOL)
Bi-weekly (1st+15th): Faza 2 (Extraction Pattern Check)
Monthly (1st):        Faza 3 (Transport Rate Refresh)
Per change:           Faza 4 (Quality Gate Learning — automatic)
```
