# FORGEBUILD-REFERENCE — DELPHI PRO Quick Reference

> Slim English summary of `~/.nexus/procedures/FORGEBUILD.md` v1.7.
> Covers §8 Conversion Annex only — the sections relevant to DELPHI PRO plugin development.
> For §0-§7 (procedure creation template), read the original Romanian source.

---

## §8 Conversion Annex: Procedure → Skill/Plugin

### 8.1 Decision Tree — Conversion Type

```
Procedure → Is it executable (concrete steps with input/output)?
  │
  NO  → REFERENCE ONLY — add pointer in an existing SKILL.md References section
  │
  YES → How complex is the logic?
        ├── 1-3 steps, defined I/O            → SKILL (standalone SKILL.md)
        ├── Shell/Python script wrapper        → CLI (script + optional SKILL.md)
        ├── Small logic, fits existing skill   → EMBEDDED (integrate, don't duplicate)
        └── Multiple related procedures        → PLUGIN (bundle of skills + commands)
```

Before converting, always check:
1. `ls ~/.claude/plugins/` — existing plugins
2. `cortex_search "skill:<name>"` — Cortex registry
3. `grep -r "<name>" ~/.claude/plugins/*/skills/*/SKILL.md` — existing references
4. If similar exists → EMBEDDED or REFERENCE ONLY (no duplicates)

---

### 8.2–8.6 Five-Phase Pipeline

| Phase | Name | What You Do |
|:---:|:---|:---|
| **1** | ASSESS | Classify via decision tree; check consumer scope (multiple agents → shared skill, single agent → embed, standalone → CLI) |
| **2** | DECOMPOSE | Extract Input schema, Output schema, Tools needed, Error handling, Boundaries (does/does NOT) from the procedure |
| **3** | CONVERT | Create SKILL.md, CLI script, or PLUGIN directory per path rules below |
| **4** | AUDIT | Run quality checks: Skill Creator ≥70, PromptForge ≥70, FORGE-AUDIT STANDARD ≥3.5/4.0, manual CLI test |
| **5** | INTEGRATE | Update agents referencing the skill, update plugin.json, run end-to-end test with real data, archive original procedure |

---

### 8.3 Phase 2: DECOMPOSE — Component Mapping

| Component | Question to Answer | Maps to SKILL.md Section |
|:---|:---|:---|
| Input | What does it receive? | `## Input` JSON schema |
| Output | What does it produce? | `## Output` JSON schema |
| Tools | What MCP tools/APIs needed? | `## Execution` tool table |
| Errors | What can go wrong? | `## Error Handling` |
| Boundaries | What it does / does NOT do | `## What You Do` / `## What You Do NOT Do` |

Each step classifies as: execution (`## Execution`), validation (`## Input Validation`), routing (orchestrator), or reference (`## References`).

---

### 8.4 Phase 3: CONVERT — Path Rules

**SKILL path**: Create `~/.claude/plugins/{plugin}/skills/{name}/SKILL.md` with YAML frontmatter + required sections. Reference original: `Source: ~/.nexus/procedures/{original}.md (CONVERTED)`.

**CLI path**: Script with `set -euo pipefail`, arg parsing, `--help`, JSON on stdout, JSON errors on stderr. Exit 0/1.

**When to bundle scripts** (vs agent-generated code):
- Operation is deterministic (validation, formatting, API calls with fixed structure)
- Same code would be generated repeatedly across sessions
- Errors need explicit handling the agent might skip

**EMBEDDED path**: Add steps to existing SKILL.md `## Execution`. Add source comment. If embedding adds >50 lines → reconsider standalone.

**PLUGIN path**: Full directory structure (skills/, commands/, agents/, hooks/, resources/). Write `plugin.json` manifest.

---

### 8.5 Phase 4: AUDIT — Quality Gates

| Check | Tool | Min Score | Applies to |
|:---|:---|:---:|:---|
| Skill format | Skill Creator 3.0 | ≥ 70 | SKILL.md |
| Prompt quality | PromptForge v3.7 | ≥ 70 | All prompts |
| Procedure structure | FORGE-AUDIT STANDARD | ≥ 3.5/4.0 | FORGE procedures |
| CLI output | Manual test with real data | Valid JSON | CLI scripts |
| Contract compatibility | Compare I/O schemas | Exact match | All types |
| No duplication | grep across skills | Zero duplicates | All types |

---

### 8.6 Phase 5: INTEGRATE — Checklist

1. Update agents that should reference the new skill
2. Update `plugin.json` manifest
3. Update `channel-config.yaml` if new search channel
4. Run end-to-end integration test with real data
5. Archive original with header: `Status: CONVERTED | Converted to: {path} | Date: YYYY-MM-DD | Type: SKILL|CLI|EMBEDDED|REFERENCE`

---

### 8.7 Quality Gate Summary

| Gate | When | Blocker? |
|:---|:---:|:---:|
| Duplication check passed | Phase 1 | Yes |
| I/O contracts extracted | Phase 2 | Yes |
| Skill Creator score ≥ 70 | Phase 4 | Yes |
| PromptForge score ≥ 70 | Phase 4 | Yes |
| Integration test green | Phase 5 | Yes |
| Original archived | Phase 5 | Yes |

---

### 8.9 Anti-Patterns to Avoid

1. **Over-atomization** — Too many tiny skills → embed small procedures instead
2. **Context loss** — Splitting one procedure across 5+ skills → keep cohesive logic together
3. **CLI for everything** — Shell wrappers for things that should be MCP tools → use MCP for real-time interaction
4. **Ghost procedures** — Not archiving originals after conversion → always mark CONVERTED
5. **Mega-skills** — SKILL.md >200 lines → split at 250-line threshold, extract to REFERENCE.md
6. **Blind conversion** — Converting without duplication check → always run Phase 1 first

---

### 8.10 Plugin Bundle (Path E) — Key Points

#### E.1 Plugin Manifest (`plugin.json`)

Path: `~/.claude/plugins/{plugin}/.claude-plugin/plugin.json`

Required fields: `name`, `version`, `description`, `skills[]`, `agents[]`, `commands[]`, `hooks{}`, `procedures[]`, `resources{}`

Optional fields: `author`, `command_names[]`, `openclaw_compatible`, `exportable`

Rules:
- All paths in the manifest are relative to plugin root
- `exportable: true` means the plugin can be copied to another machine and still work
- `hooks` object uses named lifecycle keys — each maps to a single script path string
- `resources` is an object with named keys mapping to relative paths (not an array)
- `command_names[]` lists the user-facing slash commands (e.g. `["/research-pro"]`)

#### E.2 Command Creation Rules

- Commands are thin user-facing dispatchers only — no business logic
- YAML frontmatter with `name`, `description`, `user-invocable: true`
- Trigger: `/command-name` format, lowercase, hyphen-separated
- Must dispatch to a specific agent or skill — never contain scoring, API calls, or transformation

#### E.3 Hook Creation Rules

- Bash script with `#!/usr/bin/env bash` and `set -euo pipefail`
- Uses `resolve_key()` from `lib/resolve-key.sh` for ALL API keys — zero hardcoded keys
- Outputs to stderr (`>&2`) — NOT stdout — to avoid polluting tool output
- Idempotent: safe to run twice with same input, same result
- Types: `pre-action` (before), `post-action` (after), `error` (on failure)

#### E.4 Hookify Rule Creation Rules

- YAML frontmatter: `name`, `enabled: true`, `event: bash|file|stop|prompt`, `action: warn|block`
- Pattern is a valid regex — test for false positives AND false negatives
- Each rule enforces a clear IRON LAW or quality gate
- Check for conflicts: `ls ~/.claude/hookify.*.md .claude/hookify.*.md`

#### E.5 Plugin Assembly Checklist

Component Quality:
- All skills pass Skill Creator 3.0 (≥ 70)
- All prompts pass PromptForge (≥ 70)
- All components pass FORGE-AUDIT (≥ 3.5/4.0)

Portability:
- `.env.example` lists all required API keys with descriptions
- No hardcoded absolute paths — use `$HOME`, `~`, or relative paths
- `lib/resolve-key.sh` used for all API key resolution
- `state.json` initialized with correct schema (empty but valid)

#### E.6 DELPHI PRO as Reference Implementation

DELPHI PRO (`~/.claude/plugins/delphi/`) is the canonical plugin reference:
- 9 scout skills, 3 infrastructure skills (critic, synthesizer, reporter), 3 store skills
- 1 orchestrator agent, 2 commands, 4 hooks (pre/post/error/quota), 8 hookify rules
- 1 procedure (DELPHI-SOC.md), 5+ resources

Source: `~/.nexus/procedures/FORGEBUILD.md` v1.7
