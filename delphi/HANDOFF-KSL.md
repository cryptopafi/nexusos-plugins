---
type: handoff
created: 2026-03-22
session: DELPHI PRO Stress Test + KSL Burst
next_session: KSL — Karpathy Self-Learning Auto-Optimize
---

# HANDOFF: DELPHI PRO → KSL Session

## What was done (2026-03-21 — 2026-03-22)

### Infrastructure fixes
1. **Brave Search**: new key active (`BSAJSV72i0f_jteU8mM0SMMO8uNzVma`), curl CLI (not MCP)
2. **OpenRouter**: $5/day daily limit (not total), Perplexity Sonar + Sonar Pro both tested OK
3. **pre-research-quota.sh**: live probe override (counter says exhausted but API works → healthy), OpenRouter uses `limit_remaining` not `usage`
4. **Tavily**: 0/1000 credits, no key in .env — decision pending (vs Apify)
5. **twikit** 2.3.3 installed, **atproto** 0.0.65 installed
6. **bluesky-search.sh**: dual-mode (atproto direct if credentials, Brave fallback otherwise)
7. **SOC LaunchAgents**: 3 loaded (karpathy 02:00, tool-scan Sun 21:00, sol Sun 22:00)
8. **Legacy plists**: removed (com.delphi.nightly-sweep, com.delphi.weekly-synthesis)
9. **Git**: delphi/ now tracked in cryptopafi/claude-plugins, pushed

### Feature builds
1. **GrillGate Step 0.4**: D4 intake questions (3-7 batch questions, Cortex pre-fill, skip mechanism) — in delphi.md
2. **K002 Exa optimization**: `category: "research paper"` dual-query for non-academic topics — APPROVED, applied to scout-web/SKILL.md
3. **Critic Council test**: 3×Sonnet, EPR 16/20 PASS, 4 verdict changes vs single critic — council adds value
4. **karpathy-burst**: continuous calibration mode added to delphi-soc.sh

### Karpathy Burst results (18 total experiments)

**Burst 1** (3 exp, 9 min): All DISCARD, STABLE
- Brave count=20: more results ≠ better quality
- Exa startPublishedDate: kills T1 (arxiv lacks date metadata)
- Exa includeDomains whitelist: helps T1 but kills diversity

**Burst 2** (15 exp, 61 min): 3 KEEP, 12 DISCARD
- **KEEP K-B4**: WebSearch as Brave fallback → T1: 20%→50% (gov/institutional sources)
- **KEEP K-B13**: WebSearch confirmed on finance topic → generalizes cross-topic
- **KEEP K-B14**: Exa numResults=20 on finance → +83% T1, +70% diversity (topic-specific)
- Notable DISCARDs: Exa type='fast' (loses T1), Exa excludeDomains (zero effect), Exa category='news' (marginal), arXiv MCP alone (monoculture), Exa includeText=["2026"] (kills T1)

**Key insight**: WebSearch (built-in, zero quota, zero cost) is the most valuable channel discovered. Exa parameter space is mostly optimized — category='research paper' (K002) was the big win, rest is marginal.

### Audit scores
- **Plugin full**: 3.55/4.0 PASS (10 files, 12 findings)
- **delphi-soc.sh**: 3.44/4.0 CONDITIONAL (converged after 2 iterations)
- Previous full audit: 3.44/4.0 CONDITIONAL

### Pending in optimization-buffer.md
- K002: APPROVED + applied
- K-B4/K-B13: WebSearch as co-primary channel (pending Pafi approval)
- K-B14: Exa numResults=20 for finance topics (pending)
- Orthogonal Lens Critic Council (from earlier session)
- GrillGate proposal (APPLIED)

---

## Next session: KSL — Karpathy Self-Learning

### Goal
Build `--auto-apply` mode for karpathy-burst that applies KEEP changes automatically, so each subsequent experiment builds on improvements.

### Key design decisions needed
1. **Multi-metric guard**: KEEP only if ALL metrics improve (T1 ratio + domain diversity + tested on 2+ topics)
2. **Rollback trigger**: auto-revert if 3 consecutive experiments post-apply ALL score worse
3. **Git strategy**: don't do git commits (sync-memory.sh handles it every 1 min), use atomic writes (write .tmp then mv)
4. **Race condition with sync**: Karpathy writes SKILL.md → sync picks up in <1 min → no git ops in Karpathy
5. **Rollback method**: save pre-change version to `.bak`, overwrite to rollback (not git revert)
6. **Phase name**: `ksl-burst` (already aliased in delphi-soc.sh by user edit)
7. **Cost model**: $5/day OpenRouter cap, ~$0.15/experiment → max ~33 experiments/day on OpenRouter alone

### Files to modify
- `scripts/delphi-soc.sh` — add auto-apply logic to karpathy-burst
- `resources/state.json` — track auto-applied changes and rollback history
- Possibly: `skills/scout-web/SKILL.md` (first target for auto-optimization)

### Risk analysis (discussed with Pafi)
| Risk | Mitigation |
|------|-----------|
| Cascading degradation | Git history via sync + rollback trigger |
| Overfitting to test topic | Multi-topic validation before apply |
| Metric gaming | Multi-metric eval (T1 + diversity) |
| Prompt drift | Max 1 edit per SKILL.md per burst |
| Sync race condition | No git ops in Karpathy, atomic writes |

### State at handoff
- 5 web channels active: Brave, Sonar, Sonar Pro, Exa, DDG (+ WebSearch discovered)
- SOC automated: 3 LaunchAgents running
- state.json: 27 runs, 18 Karpathy experiments (4 KEEP total including K002)
- OpenRouter: $5/day, ~$4.50 remaining today
- Plugin: 91 files tracked in git, pushed to cryptopafi/claude-plugins
