# NEW PROCEDURES REPORT — Session 2026-03-20

**Generated**: 2026-03-20
**Scope**: FORGE v1.5 upgrade, Hookify integration, PROCEDURE-TO-SKILL creation and archival
**Auditor**: Opus 4.6 (post-session verification)

---

## Section 1: FORGE.md v1.5 — §8 Conversion Annex

### What was added

FORGE.md was upgraded from v1.4 to v1.5 with a new **§8 Conversion Annex** (lines 261-363, ~103 lines). This annex provides a standardized 5-phase pipeline for converting any NexusOS procedure into an executable artifact.

### 5-Phase Conversion Pipeline

| Phase | Name | Purpose |
|---|---|---|
| Phase 1 | ASSESS | Classification via decision tree (SKILL/CLI/EMBEDDED/REFERENCE/PLUGIN) + duplication check + consumer scope |
| Phase 2 | DECOMPOSE | Extract I/O contracts, map steps to SKILL.md sections (Input, Output, Execution, Validation, Error Handling) |
| Phase 3 | CONVERT | Build the artifact (4 paths: standalone SKILL.md, CLI script, embedded in existing skill, full plugin bundle) |
| Phase 4 | AUDIT | Verify with Skill Creator 3.0 (>=70), PromptForge v3.6 (>=70), FORGE-AUDIT STANDARD (>=3.5/4.0) |
| Phase 5 | INTEGRATE | Wire into system, update manifests, run integration test, archive original with CONVERTED status |

### Decision Tree Summary

```
Executable procedure?
  NO  → REFERENCE ONLY (add to existing skill's References)
  YES → Complexity?
        1-3 steps, clear I/O     → SKILL (standalone SKILL.md)
        Shell/Python wrapper      → CLI (script + optional SKILL.md)
        Small, fits existing      → EMBEDDED (integrate, don't duplicate)
        Multiple related procs    → PLUGIN (bundle of skills + commands)
```

### Quality Gates (6 gates, all blockers)

| Gate | When | Blocker? |
|---|---|---|
| Duplication check | Phase 1 | Yes |
| I/O contracts extracted | Phase 2 | Yes |
| Skill Creator >= 70 | Phase 4 | Yes |
| PromptForge >= 70 | Phase 4 | Yes |
| Integration test green | Phase 5 | Yes |
| Original archived | Phase 5 | Yes |

### Integration with existing FORGE workflow

§8 sits after the template sections (§0-§6) and before the Checklist Pre-Publicare (implicit §7). It does NOT modify the existing template — it adds a conversion annex that is used AFTER a procedure exists. The flow is:

1. Create procedure via FORGE template (§0-§6) — unchanged
2. When ready to convert → use §8 Conversion Annex pipeline
3. Validate via Checklist Pre-Publicare (§7) — forge_version updated to 1.5

### FORGE-AUDIT LIGHT Results

**Overall: PASS (3.8/4.0)**

| Check | Status | Notes |
|---|---|---|
| §0 SKILL-SEARCH Gate | PASS | Present, well-structured, Tier 0-2 search |
| §1-§6 Template sections | PASS | All present, unchanged from v1.4 |
| §4 Enforcement Loop | PASS | WHERE/WHEN/HOW/CONNECT/VERIFY all present |
| §4b Prompting notes | PASS | Context Engineering + Promptware references intact |
| §8 Conversion Annex | PASS | 9 sub-sections (8.1-8.9), decision tree, 5 phases, quality gates, examples, anti-patterns |
| Checklist Pre-Publicare | PASS | forge_version updated to 1.5 |
| Changelog | PASS | v1.5 entry present with accurate description |
| Section numbering | NOTE | §7 is implicit (Checklist Pre-Publicare, referenced at line 31 as "§7 mai jos"). No explicit `## §7` header. This is consistent with prior versions — not a defect, but could be clarified in a future version. |
| No inline code > 10 lines | PASS | Decision tree code block is pseudocode/ASCII art, not executable code |

**Conclusion**: §8 integrates cleanly without disrupting existing structure. No fixes needed.

---

## Section 2: Hookify Integration

### What was installed

**hookify-plus** — a community-maintained fork of Anthropic's hookify plugin.

| Property | Value |
|---|---|
| Plugin name | hookify-plus |
| Version | 0.1.0-plus.3 (README badge) / 1.0.0 (plugin.json) |
| Source | https://github.com/adrozdenko/hookify-plus |
| Location | `~/.claude/plugins/hookify/` |
| Upstream backup | `~/.claude/plugins/hookify.upstream.bak/` |

**Hookify-plus adds over upstream**: `not_regex_match` operator, `value` key syntax, `read` event type, global rules support, `Update` tool firing + 6 bug fixes (11 total improvements).

### 5 Hooks Created

| # | Name | File | Event | Action | Purpose |
|---|---|---|---|---|---|
| 1 | `forge-compliance-gate` | `hookify.forge-compliance.local.md` | `file` | `block` | Blocks saving procedure files in `procedures/` that lack required FORGE section `## 1. Problema` |
| 2 | `sol-research-reminder` | `hookify.sol-research-reminder.local.md` | `stop` | `warn` | Warns at session end if research activity detected (EPR/DELPHI/scout keywords) but post-research cleanup not done |
| 3 | `delphi-html-report-required` | `hookify.delphi-html-report.local.md` | `stop` | `warn` | Enforces DELPHI PRO Iron Law: D2+ research must produce HTML report. Warns if D2/D3/D4 keywords found but no `.html` in transcript |
| 4 | `protect-credentials` | `hookify.protect-credentials.local.md` | `file` | `warn` | Warns when editing files matching credential patterns (`.env`, `.pem`, `.key`, `credentials`, `secrets`, `tokens`) |
| 5 | `block-dangerous-bash` | `hookify.dangerous-bash.local.md` | `bash` | `block` | Blocks destructive bash commands (`rm -rf /`, `chmod 777`, `dd if=...of=/dev`, `mkfs`) |

### Fixes Applied During Audit (3 regex fixes, Loop 3 convergence)

The hookify audit ran 3 loops before converging:

| Loop | Fix | Hook affected |
|---|---|---|
| 1 | Initial creation — all 5 hooks drafted | All |
| 2 | Regex tightening on `delphi-html-report-required` — D-level pattern refined to `\bD[234]\b` to avoid false positives on words containing "D2" | Hook #3 |
| 2 | Regex improvement on `block-dangerous-bash` — added `\s` after `rm` to prevent matching `rm` as substring | Hook #5 |
| 3 | Final regex refinement on `protect-credentials` — pattern expanded to cover `.env.local`, `.env.production` variants via `\.env(\.[a-z]+)?$` | Hook #4 |

**Final scores**: All 5 hooks scored 9.8-10/10 after Loop 3. Converged.

### How Hooks Complement Existing settings.json Hooks

`settings.json` already has 4 hook categories:

| settings.json Hook | Hookify Complement |
|---|---|
| `SessionStart` — Cortex search on startup | No hookify overlap (prompt event could extend) |
| `Stop` — MCP cleanup script | `sol-research-reminder` + `delphi-html-report-required` add research-specific stop checks |
| `PostToolUse (Edit/Write)` — quality gate reminder | `forge-compliance-gate` adds structural validation on procedure files |
| `PostToolUse (Bash)` — error checking | `block-dangerous-bash` adds PRE-execution blocking (settings.json only has post-execution) |
| `SubagentStop` — quality gate reminder | No hookify overlap |

**Key differentiation**: settings.json hooks are shell commands that execute code. Hookify hooks are declarative rules with pattern matching — they are simpler to write, easier to audit, and support block/warn actions natively. Hookify is better for content-based guards; settings.json is better for script execution.

### Where Hookify Adds Value Per Procedure

| Procedure/Rule | Hookify Hook | Value Added |
|---|---|---|
| FORGE.md (META-H-002) | `forge-compliance-gate` | Prevents non-compliant procedures from being saved — enforcement at write time |
| DELPHI-SOC (research optimization) | `sol-research-reminder` | Catches forgotten post-research cleanup at session end |
| DELPHI PRO Iron Law (HTML reports) | `delphi-html-report-required` | Enforces D2+ HTML report requirement at session end |
| Security practices | `protect-credentials` | Warns on credential file edits — defense in depth |
| System safety | `block-dangerous-bash` | Prevents catastrophic bash commands — pre-execution gate |

---

## Section 3: Conversion Examples from DELPHI PRO

These conversions were executed during the DELPHI PRO build (Phase 6 of the plan). The §8 Conversion Annex documents the patterns learned.

| # | Original Procedure | Converted To | Type | Target Path | Notes |
|---|---|---|---|---|---|
| 1 | X-EXTRACTION v1.1 (7-step X/Twitter pipeline) | scout-social SKILL.md query template section | EMBEDDED | `~/.claude/plugins/delphi/skills/scout-social/SKILL.md` | ~30 lines added. Only one consumer. |
| 2 | EPR modules (epr.py + 3 scoring modules) | critic SKILL.md 5-dimension evaluation | EMBEDDED | `~/.claude/plugins/delphi/skills/critic/SKILL.md` | Python calc replaced with LLM reasoning. Expanded from 3 to 5 dimensions. |
| 3 | research.py CLI | commands/research.md + agents/delphi.md | COMMAND + SKILL | `~/.claude/plugins/delphi/commands/research.md` + `agents/delphi.md` | Python script replaced with LLM-native orchestration. |
| 4 | RESEARCH-S-001 (Self-Grade Gate) | Referenced in Critic SKILL.md | REFERENCE | N/A (reference only) | Policy/rule, not executable. |
| 5 | RESEARCH-S-002 (T1 Mandatory) | Referenced in all scouts + Critic | REFERENCE | N/A (reference only) | Policy/rule, not executable. |
| 6 | QUAL-H-004 (Devil's Advocate) | Referenced in Critic Council D4 | REFERENCE | N/A (reference only) | Policy/rule for D4 depth. |
| 7 | Source Eval 5-dim (from Cortex) | Embedded in Critic SKILL.md | EMBEDDED | `~/.claude/plugins/delphi/skills/critic/SKILL.md` | 5 evaluation dimensions. |
| 8 | KSL (from Cortex) | Embedded in DELPHI-SOC procedure | EMBEDDED | `~/.claude/plugins/delphi/procedures/DELPHI-SOC.md` | Self-optimization Faza 0. |

### Lessons Learned

1. **EMBEDDED is the most common conversion type** — 4 of 8 conversions were embeddings. Small procedures rarely justify standalone skills.
2. **REFERENCE is second most common** — 3 of 8 were reference-only. Policy/rule procedures are not executable and should not be force-converted.
3. **Python-to-LLM is a pattern** — EPR modules and research.py both replaced Python logic with LLM reasoning. The conversion is not just format change but paradigm shift.
4. **Dimension expansion is natural** — EPR went from 3 to 5 dimensions during conversion because the LLM approach enabled richer evaluation without code complexity.
5. **CLI-to-Command mapping works** — research.py's arg parsing (`--topic`, `--depth`) mapped cleanly to command syntax (`/research [topic] [--depth D1-D4]`).

### Procedures Still Pending Conversion (from Plan Phase 6)

| Procedure | Planned Type | Status |
|---|---|---|
| GITHUB-EXTRACTION | SKILL (scout-web/github-monitor) | Sprint 1 — not yet converted |
| PRISM (business eval) | PLUGIN (plugin-prism) | Future — not yet started |
| SUPERDELPHI-BRIDGE | 2 sub-skills (academic + epr) | Sprint 2 — not yet converted |

---

## Section 4: Audit Status

### FORGE.md v1.5

| Item | Status |
|---|---|
| Audited? | Yes — FORGE-AUDIT LIGHT in this session |
| Score | 3.8/4.0 |
| Converged? | Yes — no structural issues found |
| §8 integration | Clean — does not break existing §0-§6 structure |
| One note | §7 is implicit (Checklist Pre-Publicare). Referenced at line 31 but has no explicit `## §7` header. Cosmetic only. |

### 5 Hookify Rules

| Item | Status |
|---|---|
| Audited? | Yes — 3-loop audit |
| Converged? | Yes — Loop 3 |
| Fixes applied | 3 regex fixes (D-level pattern, rm whitespace, env variants) |
| Final scores | 9.8-10/10 across all 5 hooks |

### PROCEDURE-TO-SKILL.md

| Item | Status |
|---|---|
| Created? | Yes — full FORGE-compliant procedure (367 lines) |
| Archived? | Yes — Status: ARCHIVED, pointer to FORGE.md §8 |
| Content preserved? | Yes — all content merged into FORGE.md v1.5 §8 (condensed from 367 to 103 lines) |
| Standalone enforcement loop? | No longer needed — FORGE.md §4 covers enforcement |

---

## Section 5: Recommendations

### Procedures Still Needing Conversion

1. **GITHUB-EXTRACTION** — Should become a scout-web sub-skill or standalone skill. Sprint 1 priority.
2. **SUPERDELPHI-BRIDGE** — Academic search + EPR bridging. Sprint 2 priority. May be partially obsoleted by scout-knowledge.
3. **PRISM** — Business evaluation framework. Future sprint. Could become `plugin-prism` or embed in scout-finance.

### Hooks Still Needed

1. **Pre-commit hook** — Validate `procedure-health.json` entries exist for all procedures in `~/.nexus/procedures/`. Currently no automated check.
2. **Cortex save verification** — After any procedure creation, verify Cortex logging was done. Could be a `stop` event hook checking transcript for `[CORTEX]` VK.
3. **Skill Creator score gate** — When writing to `plugins/*/skills/*/SKILL.md`, warn if no audit score is mentioned in the session. Lower priority since this is enforced procedurally.

### Gaps in the Conversion Pipeline

1. **No automated conversion tracker** — The plan lists conversion sprints but there is no `conversion-status.json` or similar tracking file. Conversions are tracked only in the plan markdown. Recommend adding a structured tracker.
2. **§7 numbering** — FORGE.md Checklist Pre-Publicare is implicitly §7 (referenced at line 31) but has no `## §7` header. Cosmetic issue — recommend adding `## §7 Checklist Pre-Publicare` header in next version for clarity.
3. **hookify-plus version mismatch** — README says `0.1.0-plus.3`, plugin.json says `1.0.0`. Should be aligned to avoid confusion during updates.
4. **No regression test for hooks** — The 5 hooks were audited manually. A test script that fires synthetic events and verifies hook triggers/blocks would prevent regressions during hookify updates.

---

## Summary

| Deliverable | Status | Quality |
|---|---|---|
| FORGE.md v1.5 §8 Conversion Annex | Complete, audited | 3.8/4.0 |
| PROCEDURE-TO-SKILL.md | Created and archived | Content in FORGE §8 |
| Hookify-plus installed | Complete | 5 features + 6 bug fixes over upstream |
| 5 hookify rules | Complete, audited Loop 3 | 9.8-10/10 all hooks |
| DELPHI PRO conversions (Phase 6) | 8/11 complete | 3 pending (GITHUB-EXTRACTION, SUPERDELPHI-BRIDGE, PRISM) |

All audited items have converged. No blocking issues found.
