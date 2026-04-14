---
type: procedure
name: DELPHI-SOC
version: "1.0"
status: ACTIVE
created: 2026-03-19
scope: Self-Optimization Cycle for DELPHI PRO research orchestrator
rule: META-S-013 (Research Agent Self-Optimization)
---

# DELPHI-SOC — Self-Optimization Cycle

## 1. Problema

Without continuous optimization, DELPHI PRO's research quality degrades over time: tools change APIs, new channels appear, prompt templates become stale, best practices evolve. Manual maintenance is unsustainable at scale.

## 2. Procedura

### Faza 0: KSL — Karpathy Skill Loop (nightly, 02:00-06:00)

**Purpose**: Micro-experiments with binary evaluation to improve EPR scores.

**Steps**:
1. Read `human-program.md` for current focus area and allowed experiments
2. Pick random topic from research history (`state.json`)
3. Apply ONE modification to ONE skill prompt (query template, channel priority, etc.)
4. Run D2 research with modification
5. Binary eval: EPR_new > EPR_baseline?
   - YES → `git commit` (KEEP modification)
   - NO → `git revert` (DISCARD)
6. Log result to `state.json` ksl section
7. Repeat until time budget exhausted

**Constraints**:
- Max 50-100 experiments per night
- STABLE mark after 3 cycles no improvement >= 2pts → skip 30 days
- Never modify: delphi.md SOUL, handoff contracts, human-program.md
- Cost: ~$0.50-2.00/night

### Faza 1: Tool Scan (weekly, duminica 21:00)

**Purpose**: Discover new tools, MCP servers, API changes.

**Steps**:
1. Run DELPHI PRO D2 research: "new AI research tools + MCP servers + API changes, last 7 days"
   - Discovery stack: Perplexity Sonar Pro (via OpenRouter) → Social (Reddit r/ClaudeAI, X #MCPservers, YouTube, GitHub trending) → News/RSS → Cortex
2. Parse findings for actionable tool discoveries
3. Per new tool found:
   - SKILL-DISCOVERY v1.2 Trust Score (min 8/15)
   - SEC-SKILL-001 Security Gate
   - If PASS → add to backlog
4. Check existing tool health:
   - Each CLI: run with test query, verify JSON output
   - Each MCP: verify still in session tools list
   - Flag broken/deprecated tools
5. Output: `tool-scan-report.json`
6. If changes found → trigger Faza 4 (Quality Gate)

### Faza 2: Skill Optimize (bi-weekly, 1st + 15th)

**Purpose**: Optimize skill prompts using Skill Creator 3.0.

**Steps**:
1. Load all 14 SKILL.md files
2. Per skill, evaluate with Skill Creator 3.0:
   - Format score (0-20)
   - Description accuracy (0-20)
   - Boundaries clarity (0-20)
   - Contract correctness (0-20)
   - Reusability (0-20)
3. Only optimize skills with total score < 75 or performance issues in state.json
4. Per skill to optimize:
   - Apply max 3 PE techniques from PromptForge v3.6 (English reference: see docs/PROMPTING-REFERENCE.md)
   - Preserve handoff contract format
   - Preserve frontmatter structure
5. Output: `skills-optimize-report.json`
6. If any skill modified → trigger Faza 4

**Anti-over-optimization**: Max 3 techniques per skill per cycle. If score oscillates (up, down, up) → freeze 60 days.

### Faza 3: Research Scan (bi-weekly, 8th + 22nd)

**Purpose**: Discover new research best practices and PE techniques.

**Steps**:
1. Run DELPHI PRO D3 research: "AI research agent best practices + prompt engineering techniques, last 14 days"
   - Discovery stack: Perplexity Sonar Pro (via OpenRouter) → Social (Reddit, X, YouTube, GitHub) → ArXiv → News → Cortex
2. Classify findings by priority:
   - HIGH: architectural changes, new paradigms
   - MEDIUM: optimizations, new techniques
   - LOW: nice-to-have improvements
3. HIGH priority → flag Pafi for review (never auto-apply architectural changes)
4. MEDIUM → add to backlog for next Skill Optimize cycle
5. Save findings to Cortex (collection: research, tag: delphi-soc)
6. If applicable changes found → trigger Faza 4

### Faza 4: Quality Gate (triggered, not scheduled)

**Purpose**: Verify changes from Faza 1/2/3 don't degrade quality.

**Trigger**: Any change from Faza 1, 2, or 3.

**Steps**:
1. FORGE-AUDIT v1.7 on each modified component: (English reference: see docs/FORGE-AUDIT-REFERENCE.md)
   - Skills: tier STANDARD + DSE-RESEARCH
   - Agent: tier DEEP + DSE-WORKFLOW
   - CLI scripts: tier LIGHT
2. Min score: >= 3.5/4.0
3. If FAIL → `git revert` change + flag Pafi
4. If PASS → apply changes permanently
5. Integration test:
   - D1 test: <30s, valid result
   - D2 test: 3+ sources, EPR >= 14
6. Output: `quality-gate-report.json`

### Faza 5: SOL (weekly, duminica 22:00)

**Purpose**: Standard Self-Optimization Loop on all prompts.

**Steps**: Follow SOL v1.5 procedure:
1. Discover: scan all DELPHI PRO prompts (20 total)
2. Audit: Opus evaluates on 5 dimensions
3. Build: Sonnet applies PE techniques to weakest dimensions
4. Approve: auto if delta >= +5, Pafi if < +5
5. Track: update manifest.json

### Faza 5.5: Buffer Review (weekly, after SOL)

1. Read `optimization-buffer.md`
2. For each pending proposal:
   - Present to Pafi with context
   - Pafi decides: APPROVE / REJECT / DEFER
   - APPROVE → apply change, log in Review History
   - REJECT → remove from buffer, log rejection reason
   - DEFER → keep in buffer for next week
3. Trim buffer to max 200 lines
4. Update Review History table
5. If buffer was empty → log "No proposals this week"

## 3. Calendar

```
Week 1:
  Mon 1st    → Faza 2 (Skill Optimize)
  Sun 7th    → Faza 1 (Tool Scan) + Faza 5 (SOL)

Week 2:
  Wed 8th    → Faza 3 (Research Scan)
  Sun 14th   → Faza 1 (Tool Scan) + Faza 5 (SOL)

Week 3:
  Tue 15th   → Faza 2 (Skill Optimize)
  Sun 21st   → Faza 1 (Tool Scan) + Faza 5 (SOL)

Week 4:
  Wed 22nd   → Faza 3 (Research Scan)
  Sun 28th   → Faza 1 (Tool Scan) + Faza 5 (SOL)

Faza 0 (KSL): EVERY NIGHT 02:00-06:00
Faza 4 (Quality Gate): TRIGGERED by changes only
Faza 5.5 (Buffer Review): WEEKLY, after SOL (Sunday evening)
```

## 4. Cost

| Faza | Freq/month | Cost/run | Total/month |
|:---:|:---:|:---:|:---:|
| KSL | 30x | ~$0.50-1.00 | ~$15-30 |
| Tool Scan | 4x | ~$0.50 | ~$2.00 |
| Skill Optimize | 2x | ~$1.50 | ~$3.00 |
| Research Scan | 2x | ~$1.00 | ~$2.00 |
| Quality Gate | ~2x | ~$2.00 | ~$4.00 |
| SOL | 4x | ~$1.00 | ~$4.00 |
| **TOTAL** | | | **~$30-45/month** |

**Cost cap**: $60/month max. If exceeded, reduce KSL frequency.

## 5. Protectii

| Protection | How |
|:---:|:---:|
| STABLE mark | 3 cycles no improvement >= 2pts → skip 30 days |
| Max 3 techniques/cycle | No technique stuffing |
| Revert on fail | FORGE-AUDIT fail → git revert automatic | (English reference: see docs/FORGE-AUDIT-REFERENCE.md) |
| Pafi gate on HIGH | Architectural changes never auto-applied |
| Cost cap | $60/month max |
| Circular detection | Score oscillates → freeze 60 days |
| human-program.md | Only Pafi modifies, never auto-touched |

## 6. Metrics

### buffer_review_rate
- **Definition**: Percentage of buffer proposals reviewed per weekly cycle
- **Target**: 100% (all pending proposals reviewed)
- **Source**: `optimization-buffer.md` → Review History
- **Formula**: `proposals_reviewed / proposals_pending * 100`

### critic_compliance_rate
- **Definition**: Percentage of D3+ runs that included Critic evaluation
- **Target**: 100%
- **Source**: `state.json` → `critic_stats`
- **Formula**: `(d3_runs_with_critic + d4_runs_with_critic) / (d3_runs_total + d4_runs_total) * 100`
- **Alert**: If compliance_rate drops below 100%, trigger Telegram notification and flag in SOC report
- **Tracking**: Updated after every D3/D4 run by DELPHI PRO orchestrator (pipeline step 12)

## 7. Enforcement

- LaunchAgent deployment: see Sprint 5 deploy checklist in main plan
- All outputs logged to `~/.nexus/logs/delphi-soc.log`
- Telegram notification on: Quality Gate FAIL, HIGH priority finding, cost cap warning
- Procedures stored at `~/.nexus/procedures/`

## 8. Referenced Procedures (English References)

The following external procedures govern DELPHI SOC execution. English-language quick reference summaries are available in the `docs/` directory:

| Procedure | Path | English Reference |
|:---|:---|:---|
| FORGE-AUDIT v1.7 | `~/.nexus/procedures/FORGE-AUDIT.md` | (English reference: see docs/FORGE-AUDIT-REFERENCE.md) |
| FORGEBUILD v1.7 | `~/.nexus/procedures/FORGEBUILD.md` | (English reference: see docs/FORGEBUILD-REFERENCE.md) |
| FIVE-STEPS-AGENTS v1.4 | `~/.nexus/procedures/FIVE-STEPS-AGENTS.md` | (English reference: see docs/FIVE-STEPS-REFERENCE.md) |
| PROMPTING v1.8 | `~/.nexus/procedures/PROMPTING.md` | (English reference: see docs/PROMPTING-REFERENCE.md) |
