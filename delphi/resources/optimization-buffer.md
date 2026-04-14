# DELPHI PRO — Optimization Buffer
# MAX 200 lines. Reviewed weekly by Pafi in DELPHI-SOC Faza 5.5.
# DELPHI PRO writes proposed changes here. NEVER applies them directly.
# Format: - [DATE] [TYPE] [TARGET] proposed change description

## Pending Architecture Tasks

- [2026-03-23] [ARCHITECTURE] [MCP] **MCP-CONSOLIDATE**: Group all 8 separate DELPHI_* MCP servers into a single unified Delphi MCP. Reduces MCP spawn count (8→1), cuts ~350MB RAM per Claude session, eliminates 7 orphan-prone node processes. Requires: merge tool definitions, single entry in settings.json, backward-compat tool names.

## Deferred from KSL Carpați Build (2026-03-22)

- [2026-03-22] [SECURITY] [delphi-soc.sh] **M4**: state.json CHANGE_SUMMARY sanitization — prompt injection defense. Auto-apply writes CHANGE_SUMMARY back into next experiment's prompt context. Unsanitized free-text from LLM output could inject instructions. Fix: strip non-alphanum except spaces/hyphens, truncate to 100 chars before JSON write.

- [2026-03-22] [TUNING] [ksl-config.yaml] **S2**: Per-experiment cost cap bump for auto-apply ($0.20 → $0.35). Auto-apply experiments are longer (structured output + DIFF block) and need more headroom. Current $0.20 may cause premature abort.

- [2026-03-22] [FEATURE] [ksl.sh] **S3**: `--skill-file` flag for future multi-target SKILL.md support. Currently hardcoded in epr.sh. Genericize so any profile can target arbitrary files.

## Pending Proposals (newest first)

- [2026-03-22] [SKILL-UPDATE] [scout-web/SKILL.md] **KSL K010+K018 (K-B4/K-B13)**: WebSearch co-primary channel. WebSearch query template added. Description updated. STATUS: **APPLIED** (2026-03-22).

- [2026-03-22] [SKILL-UPDATE] [scout-web/SKILL.md] **KSL K019 (K-B14)**: Exa numResults=20 for finance/institutional topics. Long-tail T1 boost (+83% T1 count, +70% diversity). STATUS: **APPLIED** (2026-03-22).

- [2026-03-21] [SKILL-UPDATE] [scout-web/SKILL.md] **KSL K002**: Add Exa `category: "research paper"` dual-query for T1 boost. For non-academic topics (tech, finance, business), run a SECOND Exa query with `category: "research paper"` alongside the default neural query. Merge results before dedup. Tested: crypto topic T1 went from 0/10 (0%) to 8/10 (80%) — all arxiv, springer, iacr, ethresear.ch. Academic topics unaffected (already 62% T1). Cost: zero (same Exa call, different param). Condition: only when topic is NOT inherently academic/medical.

- [2026-03-21] [OBSERVATION] [scout-web/SKILL.md] **KSL K001**: Exa `additionalQueries` parameter has ZERO effect for closely-related sub-queries — returns identical results. Do NOT add this to query templates.

- [2026-03-21] [CRITICAL] [channel_health] ~~STALE (2026-03-22): Brave fixed (new key), OpenRouter live ($5/day), Exa healthy. Only Tavily still at 0 credits.~~

- [2026-03-20] [SKILL-UPDATE] [critic/SKILL.md] Orthogonal Lens Critic Council for D4: Critic 1=ACCURACY lens, Critic 2=ACTIONABILITY lens, Critic 3=ADVERSARIAL lens. Replace current same-rubric 3x with forced single-dimension evaluation. Source: mattpocock/design-an-interface + CCP-003 pr-review-toolkit (6 single-lens agents, production-validated by Anthropic). Adds anti-convergence instruction + synthesis step. Requires EPR merge logic design.

- [2026-03-20] [INFRASTRUCTURE] [DELPHI-SOC] Consider Ralph Loop (CCP-009) for KSL overnight runs instead of custom LaunchAgent. Stop hook + re-inject + completion-promise + max-iterations. Already production-ready.

- [2026-03-20] [PROCEDURE-UPDATE] [FORGEBUILD.md] Add from CCP-004 plugin-dev: ${CLAUDE_PLUGIN_ROOT} for portable paths in hooks, validate-hook-schema.sh utility reference, test-hook.sh pattern for hook testing before deploy.

- [2026-03-20] [SKILL-UPDATE] [agents/delphi.md] New Step 0.4 "GrillGate" — D4 mandatory intake clarification. 3-7 questions with recommended answers, Cortex pre-fill, batch presentation, skip mechanism. Source: mattpocock/grill-me pattern (3 principles adopted, vagueness removed). D1/D2=never, D3=optional, D4=mandatory.

- [2026-03-20] [PROCEDURE-UPDATE] [FORGEBUILD.md] 4 additions from mattpocock/write-a-skill: (1) Description "why" framing to SKILL.md Format Standard, (2) "When to Add Scripts" 3 criteria to §8.4, (3) "When to Split Files" positive guidance + 250-line threshold to §8.9, (4) "No time-sensitive info" check to §7 Pre-Publication Checklist. Total: ~10 lines. STATUS: APPLIED in FORGEBUILD v1.7.

- [2026-03-20] [OBSERVATION] [store-vault/SKILL.md] Mattpocock obsidian-vault skill uses backlink search via `grep -rl "\[\[Note Title\]\]"` — simpler than Smart Connections for quick lookups. Consider adding: (1) RESEARCH-INDEX.md listing all DELPHI PRO reports with wikilinks, (2) backlink grep as fast search fallback when Smart Connections is slow/down. Low priority — current store-vault works fine.

- [2026-03-20] [OBSERVATION] [reporter/SKILL.md] CCP-012 frontend-design plugin auto-activates for frontend work with "anti-AI-slop" opinionated aesthetic choices. Consider integrating this philosophy into Reporter SKILL.md as design principle: "Make a clear, intentional aesthetic choice BEFORE implementing. Never default to generic/safe."

- [2026-03-20] [OBSERVATION] [hookify rules] CCP-013 security-guidance uses PreToolUse hook with session-scoped deduplication (fires once per file+rule per session). Our hookify rules don't deduplicate — same warning can fire multiple times. Consider adding dedup logic to hookify-plus rules.

- [2026-03-20] [OBSERVATION] [DELPHI-SOC] CCP-005 skill-creator has eval-driven iteration loop (draft → eval → iterate) with benchmarking and variance analysis. Current DELPHI-SOC Faza 2 (Skill Optimize) uses Skill Creator 3.0 survey but no eval runs. Consider adding automated eval runs during skill optimization cycles.

## Review History

| Date | Proposals | Approved | Rejected | Deferred |
|------|-----------|----------|----------|----------|
<!-- Populated during weekly SOC review -->
