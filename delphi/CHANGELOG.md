# DELPHI PRO Plugin — Changelog

## 2026-04-10 — Perplexity wiring + D3 infrastructure fixes

Three load-bearing fixes applied after the SolNest R-research session uncovered infrastructure gaps.

### 1. Perplexity Sonar Pro wired into scout-web (was documented but never invoked)

**Problem**: `scout-web/SKILL.md` and `channel-config.yaml` documented `perplexity-sonar-pro` as a primary scout-web channel, but no CLI wrapper was registered in `cli_tools`. The morning D4 SolNest run (`nx-20260410-1c58`) completed using only Tavily/Brave/Exa — Perplexity was never actually invoked. Documentation lied.

**Root cause**: `nexus-perplexity.py` existed in `~/.nexus/scripts/` since the IRIS era (pre-2026-04-01 IRIS→Delphi rename) but was never migrated to the Delphi plugin path. `perplexity-search.sh` was a 29-line duplicate in the same dir. Both had three latent bugs:
1. Citations extracted from wrong field (`data.citations`) — OpenRouter puts them in `choices[0].message.annotations[type==url_citation]`
2. Default `max_tokens=2000` — causes truncation per plugin's own `tests/PERPLEXITY-DEEP-FIX.md` (recommends 16000)
3. No exponential backoff — single attempt, fails hard on 429/5xx

**Fix**:
- Patched `~/.nexus/scripts/nexus-perplexity.py` with all 3 fixes, preserved dual-path (Perplexity-direct primary → OpenRouter fallback), returns Delphi scout-web JSON envelope
- Symlinked into plugin: `~/.claude/plugins/delphi/skills/scout-web/cli/nexus-perplexity.py → ~/.nexus/scripts/nexus-perplexity.py`
- Updated `resources/channel-config.yaml` scout-web `cli_tools` from `[brave-search.sh]` → `[brave-search.sh, nexus-perplexity.py]`
- Updated `skills/scout-web/SKILL.md` Perplexity Sonar Pro section with exact Bash invocation path, flags, JSON envelope shape, retry semantics
- Updated `skills/scout-deep/SKILL.md` Perplexity Deep Research section to point at `nexus-perplexity.py --depth deep` (still gated per existing HARD rule)
- Archived `~/.nexus/scripts/perplexity-search.sh` → `~/.nexus/.archive/scripts-2026-04-10/`

**Verified**: R1 SolNest France dispatch (`nx-20260410-r1fr`) made 8 Perplexity Sonar Pro calls via the wrapper. 9 primary citations from `businessfinland.fi` extracted via the fixed annotations parsing. R1-R5 all used the wired wrapper end to end.

**Canonical invocation**:
```bash
python3 ~/.claude/plugins/delphi/skills/scout-web/cli/nexus-perplexity.py \
  --query "<full question>" \
  --depth standard        # sonar-pro, $0.005/query, 8K max_tokens
# --depth deep = sonar-deep-research, $1.30/query — REQUIRES explicit Pafi approval per HARD rule
# --model sonar for D1 cheap variant ($1/M, 4K max_tokens)
```

**Cortex**: `f8f65051-dc9e-47c1-a82c-e761d677db53` (supersedes earlier wrong approach `931973ce-7e24-4b2c-83bb-77f3f34789e4`).

---

### 2. D3 dispatch MAX_TURNS fix (delphi + medium complexity)

**Problem**: `~/.nexus/scripts/nexus-task-create.sh` generic default for medium complexity was `MAX_TURNS=25`. Only `delphi + high` had the override to 250 (added in AM session for D4). D3 (medium) dispatches ran with only 25 turns — not enough for 5 scouts + critic + synthesizer. Symptoms: orchestrator times out mid-run, IL-4 fallback trigger.

**Fix**: Added a parallel override for `delphi + medium → MAX_TURNS=120`. Sized 120 for 5 scouts + critic + synthesizer realistic headroom without exceeding the 45-min medium timeout.

**Verified**: R1-R5 SolNest dispatches all ran with `--max-turns 120`, completed in 6.5-13.5 min wall clock each.

**Cortex**: `1df6d075-412b-4e88-9fec-53bc9cff17cd`. Sister fix to AM's `9fe3d4c7-4807-43ab-8c21-382b91ba3dcb` (PROC-NEXUSOS-D4-DISPATCH-001).

---

### 3. Delivery gate research bypass (post-delivery-gate.sh false-fail on ALL research)

**Problem**: `~/.nexus/v2/shared-skills/post-delivery-gate.sh` hardcoded two checks designed for tech/code deliveries:
1. `verify_build.completed==true && verdict in {PASS, WARN}` — research has no code to build
2. `audit_pro.score >= 3.0` — research tasks get `audit_pro` recorded at `score=0, verdict=PASS` because NPLF scoring doesn't apply to research

Result: **every** Delphi/Echelon research delivery was marked FAILED (prefixed `FAILED-` in `completed/`) despite producing valid intel. R1 SolNest France was the first victim — caught manually, unblocked by renaming the directory.

**Fix** in `check_gate()`:
- Added research bypass: if `PROGRESS.md` agent is `delphi` or `echelon`, `verify_build` is N/A (treat as passed)
- Audit-pro now accepts `verdict==PASS` regardless of score, falling back to the `score >= 3.0` check only when verdict is not PASS
- Added `audit_verdict` to the local variable extraction at the top of check_gate() (was missing)

**Tested**: R1 task PASSES after patch (research bypass logged to stderr). Tech task without `verify_build` still BLOCKS (no regression — verified with synthetic `agent: "tech"` + missing verify_build test case).

**Verified in production**: R2/R3/R4/R5 all delivered cleanly via the scanner → quality-gate → delivery-gate → completed/ path without manual unblock.

**Cortex**: `7f003833-f42b-45ee-8ab8-7e138d1933f2`.

---

### HARD rule added this session

**PERPLEXITY DEEP GATED** (`feedback_perplexity_deep_gated.md` in user memory, indexed in `MEMORY.md`):

> Never invoke `--depth deep` / `sonar-deep-research` ($1.30/query) without explicit Pafi approval. Default is always `--depth standard` (sonar-pro ~$0.005/query). 260x cost differential — prevents runaway burn from orchestrator auto-escalation.

This reinforces the existing `perplexity_deep_approved: true` gate in `skills/scout-deep/SKILL.md`. Applies to all dispatch paths (Delphi file-based, Genie direct Bash, subagent Agent() calls).

---

## 2026-04-10 AM — D4 dispatch 4-misconfig fix

Earlier today (AM session): First Delphi D4 attempt on SolNest (`nx-20260410-0ff3`) triggered IL-4 fallback (4 parallel general-purpose agents instead of real Delphi). Root cause: 4 misconfigurations in the file-based dispatch system:
1. `nexus-agent-execute.sh` missing `delphi)` case in `ADD_DIRS` → plugin not loaded
2. `agent-registry.yaml` delphi.allowed_tools missing `Agent` + all MCP search tools (Tavily, Brave, Exa, Cortex, Arxiv, Wikipedia, OpenAlex)
3. `routing-table.yaml` research.complexity_override.high used Sonnet → D4 requires Opus
4. `nexus-task-create.sh` hardcoded MAX_TURNS=25 for high complexity → D4 needs 150-250 for scout orchestration

All 4 fixed. Re-dispatch (`nx-20260410-1c58`) ran real Opus 4.6 D4 with 5 parallel scouts in 21 min.

**Cortex**: `9fe3d4c7-4807-43ab-8c21-382b91ba3dcb` (PROC-NEXUSOS-D4-DISPATCH-001).

---

## Prior history

See `HANDOFF.md` for pre-2026-04-10 plugin history and `HANDOFF-KSL.md` for the KSL Carpati research integration notes.
