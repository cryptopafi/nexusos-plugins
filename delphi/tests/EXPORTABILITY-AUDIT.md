# EXPORTABILITY AUDIT REPORT — DELPHI PRO + NexusOS Procedures

**Date**: 2026-03-20
**Auditor**: Claude Opus 4.6 (1M context)
**Scope**: Full exportability assessment of DELPHI PRO plugin, 13 skills, 6 CLI scripts, 4 core procedures, audit output formats, and OpenClaw compatibility.
**Verdict**: **CONDITIONAL** — exportable with targeted fixes.

---

## Export Readiness: 62%

```
Plugin structure:      ████████░░  80%
Skills (SKILL.md):     ███████░░░  70%
CLI scripts:           █████░░░░░  50%
Core procedures:       █████░░░░░  45%
Audit output formats:  ██████░░░░  60%
OpenClaw compatibility:██████░░░░  55%
─────────────────────────────────────
Overall:               ██████░░░░  62%
```

---

## 1. DELPHI PRO Plugin Exportability

**Score: 4/5**

### What works

- `plugin.json` is a valid, well-structured manifest with skills, agents, commands, hooks, resources, and procedures enumerated
- Plugin declares `"exportable": true` and `"openclaw_compatible": true` (intent is there)
- Directory structure follows a clean convention: `skills/`, `agents/`, `commands/`, `hooks/`, `resources/`, `procedures/`, `tests/`
- No hardcoded absolute paths like `${HOME}/` anywhere in the plugin tree — all references use `~/.claude/plugins/delphi/` (tilde-relative)
- API keys accessed via environment variables (`OPENROUTER_API_KEY`, `NOTION_TOKEN`, `GROQ_API_KEY`, `GNEWS_API_KEY`, `GUARDIAN_API_KEY`, `REDDIT_CLIENT_ID/SECRET`) — not hardcoded
- State file (`resources/state.json`) is JSON with clean schema
- `resources/channel-config.yaml` is a separate config file (good separation of concerns)

### Blocking issues

| # | Issue | Severity | Fix time |
|---|-------|----------|----------|
| P1 | No `requirements.txt` or `dependencies.md` listing Python packages (yfinance, praw, feedparser, youtube-transcript-api, yt-dlp) | BLOCKING | 15 min |
| P2 | No `ENV.example` or `.env.template` documenting required API keys and their sources | BLOCKING | 15 min |
| P3 | No installation/setup script (`install.sh` or `setup.md`) | MEDIUM | 30 min |

### Quick fixes (<1 hour)

1. Create `requirements.txt`: `yfinance`, `praw`, `feedparser`, `youtube-transcript-api`
2. Create `.env.example` with all required env vars and comments
3. Add `README.md` with setup instructions (deps, env vars, MCP tools needed)
4. Document which MCP servers must be active (brave-search, tavily, exa, duckduckgo, arxiv, openalex, clinicaltrials, wikipedia, dexpaprika, ecb-sdw, cortex, notion, youtube-transcript)

---

## 2. Skills Exportability (13 SKILL.md files)

**Score: 3.5/5**

### Consistent strengths across all 13 skills

- YAML frontmatter with `name`, `description`, `model` on every skill
- Clear "What You Do" / "What You Do NOT Do" boundary sections
- Standardized JSON input/output contracts with field-level documentation
- Input validation section with error response format
- Error handling section with fallback chains
- Deduplication step documented where applicable
- Query templates per channel with concrete examples

### Per-skill exportability matrix

| Skill | I/O Contract | No Abs Paths | Tools Documented | Standalone? | Score |
|-------|-------------|-------------|-----------------|------------|-------|
| scout-web | Yes (JSON) | Yes (~/ only) | Yes (6 tools) | Partial (needs MCPs) | 4/5 |
| scout-social | Yes (JSON) | Yes | Yes (5 channels) | Yes (CLI fallback) | 4/5 |
| scout-video | Yes (JSON) | Yes | Yes (3-tier) | Yes (CLI primary) | 4/5 |
| scout-visual | Yes (JSON) | Yes | Yes (4 channels) | No (CLI not implemented) | 3/5 |
| scout-knowledge | Yes (JSON) | Yes | Yes (8 channels) | Partial (1 CLI) | 3.5/5 |
| scout-deep | Yes (JSON) | Yes | Yes (5 channels) | No (CLI not implemented) | 3/5 |
| scout-finance | Yes (JSON) | Yes | Yes (6 channels) | Yes (CLI primary) | 4/5 |
| store-cortex | Yes (JSON) | Yes | Yes (Cortex MCP) | No (CLI not implemented) | 3/5 |
| store-notion | Yes (JSON) | Yes | Yes (CLI + MCP) | Yes (CLI works) | 4/5 |
| store-vault | Yes (JSON) | Yes | Partial | No (CLI not implemented) | 2.5/5 |
| critic | Yes (JSON) | Yes | N/A (LLM-only) | Yes (pure prompt) | 4/5 |
| synthesizer | Yes (JSON) | Yes | N/A (LLM-only) | Yes (pure prompt) | 4/5 |
| reporter | Yes (JSON) | Yes | Partial (VPS scp) | No (needs VPS) | 3/5 |

### Blocking issues

| # | Issue | Severity | Affected Skills |
|---|-------|----------|----------------|
| S1 | 5 skills have CLI marked "NOT YET IMPLEMENTED" — no standalone execution path | MEDIUM | scout-web, scout-visual, scout-deep, store-cortex, store-vault |
| S2 | No `tools_required` field in frontmatter — another framework cannot auto-discover MCP dependencies | BLOCKING | All 13 |
| S3 | `model` field uses Claude-specific names (haiku, sonnet) — not portable to other LLM providers | MEDIUM | All 13 |
| S4 | No `version` field in YAML frontmatter | LOW | All 13 |
| S5 | Reporter skill references VPS deployment via `scp` with undocumented VPS credentials | MEDIUM | reporter |
| S6 | Perplexity Sonar Pro access documented as "via OpenRouter" but no CLI script exists for it | LOW | scout-web |

### Quick fixes (<1 hour)

1. Add `tools_required` list to every SKILL.md frontmatter (e.g., `tools: [mcp__brave-search__brave_web_search, mcp__tavily__tavily_search]`)
2. Add `version: 1.0.0` to all frontmatter
3. Add `model_family` field with generic capability level (e.g., `model_family: fast` / `model_family: standard` / `model_family: advanced`) alongside model-specific name

### Architecture recommendation

Create a `skill-manifest.json` at the plugin root that aggregates all skill metadata into a machine-readable registry:

```json
{
  "skills": [
    {
      "name": "scout-web",
      "path": "skills/scout-web/SKILL.md",
      "model": "haiku",
      "model_family": "fast",
      "tools_required": ["mcp__brave-search__brave_web_search", "mcp__tavily__tavily_search"],
      "has_cli": false,
      "input_schema": "skills/scout-web/input.schema.json",
      "output_schema": "skills/scout-web/output.schema.json"
    }
  ]
}
```

---

## 3. CLI Scripts Exportability (6 scripts)

**Score: 2.5/5**

### Script inventory

| Script | --help | JSON output | Hardcoded paths | macOS deps | Linux-ready? |
|--------|--------|-------------|----------------|-----------|-------------|
| youtube-search.sh | Yes | Yes | None | `security` (Keychain) | **NO** |
| reddit-search.sh | Yes | Yes | None | None | Yes |
| hn-search.sh | Yes | Yes | None | None | Yes |
| news-search.sh | Yes | Yes | None | None | Partial (feedparser) |
| yfinance-search.sh | Yes | Yes | None | None | Yes |
| notion-create.sh | Yes | Yes | `~/.claude/settings.json` | None | Partial |

### Blocking issues

| # | Issue | Severity | Fix time |
|---|-------|----------|----------|
| C1 | `youtube-search.sh` uses `security find-generic-password` (macOS Keychain) for GROQ_API_KEY — **will fail on Linux** | BLOCKING | 20 min |
| C2 | `notion-create.sh` reads `~/.claude/settings.json` for NOTION_TOKEN — couples to Claude Code installation | MEDIUM | 10 min |
| C3 | No `#!/usr/bin/env bash` — all use `#!/bin/bash` (minor portability) | LOW | 5 min |
| C4 | Python dependencies not checked at script start (except yt-dlp check in youtube-search.sh) — scripts will crash with cryptic errors if yfinance/praw/feedparser missing | MEDIUM | 30 min |
| C5 | No unified error code scheme across scripts — exit 1 for everything | LOW | 20 min |

### Quick fixes (<1 hour)

1. **C1 fix**: Replace `security find-generic-password` with env var fallback chain:
   ```bash
   GROQ_KEY="${GROQ_API_KEY:-$(security find-generic-password -s "GROQ_API_KEY" -w 2>/dev/null || echo "")}"
   ```
   This already works on Linux (env var) and falls back to Keychain on macOS.

2. **C2 fix**: Same pattern for notion-create.sh — check `NOTION_TOKEN` env var first, then settings.json.

3. **C4 fix**: Add dependency check function at top of each Python-embedding script:
   ```python
   for mod in ['yfinance']:
       try: __import__(mod)
       except ImportError: sys.exit(json.dumps({"status":"error","error":f"{mod} not installed"}))
   ```

---

## 4. Core Procedures Exportability

**Score: 2.5/5**

### Per-procedure assessment

| Procedure | Version | Self-Documenting | NexusOS Dependencies | Parseable Format | Exportable? |
|-----------|---------|-----------------|---------------------|-----------------|------------|
| FORGE.md v1.5 | Yes | Partial — Romanian language | Heavy (VK system, Cortex, ECHELON, procedure-health.json) | No YAML frontmatter | **NO** without adaptation |
| FIVE-STEPS-AGENTS v1.4 | Yes | Partial — Romanian mixed with English | Heavy (FORGE, PROMPTING, SOL, Cortex, procedure-health.json) | No YAML frontmatter | **NO** without adaptation |
| SOL v1.5 | Yes | Partial — English primary | Heavy (manifest.json, Cortex, PromptForge, LaunchAgent) | No YAML frontmatter | **NO** without adaptation |
| PROMPTING v1.7 | Yes | Partial — Romanian mixed | Heavy (PromptForge, Cortex VPS, ECHELON, WISH pipeline) | No YAML frontmatter | **NO** without adaptation |

### Blocking issues

| # | Issue | Severity | Impact |
|---|-------|----------|--------|
| PR1 | **No YAML frontmatter** — procedures use markdown headers only. Another system cannot programmatically extract name, version, status, scope | BLOCKING | All 4 |
| PR2 | **Mixed Romanian/English language** — FORGE and FIVE-STEPS use Romanian section names (Problema, Procedura, Protectii) making them unusable in English-only orgs | BLOCKING | FORGE, FIVE-STEPS, PROMPTING |
| PR3 | **Heavy NexusOS coupling** — references to VK system (verification checkpoints), Cortex API at specific IP (100.81.233.9), ECHELON daemon, procedure-health.json, WISH pipeline, LaunchAgent | BLOCKING | All 4 |
| PR4 | **No separation of universal logic vs NexusOS-specific integration** — the 5-step agent framework (FIVE-STEPS) is universal but interleaved with NexusOS enforcement loops | MEDIUM | FIVE-STEPS |
| PR5 | **Cortex IP hardcoded** — `100.81.233.9:6400` appears in PROMPTING.md | MEDIUM | PROMPTING |
| PR6 | **PromptForge references** — all procedures reference PromptForge v3.7 at `memory/promptforge.md` — this file is not included in the export | BLOCKING | SOL, PROMPTING |

### Architecture recommendation

Create "exportable editions" that strip NexusOS-specific integration:

1. **FORGE-EXPORT.md** — Universal procedure template (English, YAML frontmatter, no VK/Cortex/ECHELON refs)
2. **FIVE-STEPS-EXPORT.md** — Universal multi-agent design framework (English, standalone)
3. **SOL-EXPORT.md** — Universal prompt self-optimization loop (English, generic knowledge store instead of Cortex)
4. **PROMPTING-EXPORT.md** — Universal prompting decision tree (English, generic scoring instead of PromptForge-specific)

Each exportable edition should:
- Have YAML frontmatter (`name`, `version`, `description`, `author`, `license`)
- Be fully English
- Replace NexusOS-specific systems with generic placeholders (e.g., "knowledge store" instead of "Cortex")
- Include a "System Integration" appendix showing how NexusOS wires it up (for reference)

---

## 5. Audit Procedures — Exportable Output Assessment

**Score: 3/5**

### FORGE-AUDIT v1.7

- **Structured output**: Yes — defined report format with dimensions table, NPLF scoring, combined score, verdict
- **Machine-parseable**: Partial — report is markdown with consistent structure, but no JSON output schema
- **Standard schema**: No — the NPLF scoring system, DSE extensions (DSE-RESEARCH, DSE-WORKFLOW), and combined scoring formula are custom to NexusOS
- **Consumable by other systems**: Would require a parser to extract scores from markdown format

### SOL v1.5

- **Structured output**: Yes — audit JSON with scores, techniques, recommendations
- **Machine-parseable**: Yes — audit output is JSON (D1-D5 scores, techniques_present/missing, verdict)
- **Standard schema**: Partially — scoring rubric (D1-D5, 0-20 each) is well-defined but custom

### DELPHI-SOC

- **Structured output**: Planned — references `tool-scan-report.json`, `skills-optimize-report.json`, `quality-gate-report.json`
- **Machine-parseable**: Yes (JSON)
- **Standard schema**: No formal schema defined

### What is missing: No "audit result" schema

There is no standard `audit-result.schema.json` that all audit procedures produce. Each audit has its own output format:
- FORGE-AUDIT: markdown report with NPLF table
- SOL: JSON with D1-D5 scores
- DELPHI-SOC: planned JSONs with different structures

### Recommendation: Unified Audit Result Schema

```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "type": "object",
  "properties": {
    "audit_id": {"type": "string"},
    "timestamp": {"type": "string", "format": "date-time"},
    "auditor": {"type": "string"},
    "subject": {"type": "string"},
    "tier": {"enum": ["LIGHT", "STANDARD", "DEEP"]},
    "dimensions": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "name": {"type": "string"},
          "score": {"type": "number"},
          "max_score": {"type": "number"},
          "evidence": {"type": "string"},
          "level": {"enum": ["N", "P", "L", "F"]}
        }
      }
    },
    "combined_score": {"type": "number"},
    "max_score": {"type": "number"},
    "verdict": {"enum": ["PASS", "CONDITIONAL", "FAIL"]},
    "findings": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "id": {"type": "string"},
          "severity": {"enum": ["CRITICAL", "HIGH", "MEDIUM", "LOW"]},
          "description": {"type": "string"},
          "fix": {"type": "string"}
        }
      }
    }
  }
}
```

### Does FORGE-AUDIT have an "exportability" dimension?

**No.** Neither core dimensions (D1-D8) nor DSE extensions (DSE-RESEARCH, DSE-WORKFLOW) include exportability. This is a gap.

### Recommendation: Add DSE-EXPORT to FORGE-AUDIT

```
### 2d. DSE-EXPORT — Extension for Exportable Components

**When activated**: Subject is a plugin, skill, procedure, or system intended for use
outside NexusOS (another team, another agent framework, open-source release).

**4 dimensions DSE-EXPORT** (scale 1-5):

| # | Dimension | What it evaluates | Score guide |
|---|-----------|-------------------|-------------|
| E1 | Self-Containment | Can it run without NexusOS infrastructure? | 5=zero external deps beyond documented ones. 3=needs 1-2 undocumented systems. 1=deeply coupled |
| E2 | Documentation | Can someone without context install and use it? | 5=README + ENV.example + deps + examples. 3=partial docs. 1=no docs |
| E3 | Portability | Does it work on Linux + macOS? No platform-specific calls? | 5=cross-platform tested. 3=mostly portable, 1-2 platform deps. 1=single-platform only |
| E4 | Interoperability | Are I/O contracts in standard formats (JSON Schema)? Can another framework consume it? | 5=formal schemas + adapter guide. 3=documented but informal. 1=undocumented proprietary format |

Checklist:
- [ ] E1: List all external dependencies. Are they all documented?
- [ ] E2: Fresh-install test: can a new user set up from docs alone?
- [ ] E3: Platform-specific code identified and wrapped with fallbacks?
- [ ] E4: I/O schemas extractable as standalone JSON Schema files?
```

---

## 6. OpenClaw Compatibility

**Score: 2.5/5**

### Current state

- `plugin.json` declares `"openclaw_compatible": true` but this is aspirational, not verified
- OpenClaw procedures exist at `~/.nexus/procedures/openclaw/` (25+ files) showing familiarity with OpenClaw
- SKILL.md format is close to but not identical to OpenClaw skill format

### Compatibility gap analysis

| Feature | DELPHI PRO format | OpenClaw format | Compatible? | Adaptation needed |
|---------|------------------|-----------------|-------------|-------------------|
| Skill definition | SKILL.md with YAML frontmatter | SOUL.md with YAML frontmatter | **Partial** | Rename + adjust frontmatter fields |
| Input contract | JSON in markdown code block | JSON Schema file | **NO** | Extract to `input.schema.json` |
| Output contract | JSON in markdown code block | JSON Schema file | **NO** | Extract to `output.schema.json` |
| Plugin manifest | `plugin.json` (custom) | `plugin.json` (OpenClaw spec) | **Partial** | Field mapping needed |
| Model routing | `model: haiku` in frontmatter | `model: claude-haiku-3` (full ID) | **NO** | Use canonical model IDs |
| Tool declaration | Inline in Execution section | `tools` array in frontmatter | **NO** | Extract to frontmatter |
| CLI scripts | `skills/*/cli/*.sh` | `skills/*/cli/*.sh` | **YES** | Same convention |
| Hooks | `hooks/*.sh` | `hooks/*.sh` | **YES** | Same convention |
| Agent definition | `agents/delphi.md` with YAML | `agents/*.md` with YAML | **YES** | Compatible |

### What would need to change for direct OpenClaw use

1. **Rename SKILL.md to SOUL.md** or provide adapter mapping
2. **Extract JSON schemas** from markdown code blocks into standalone `.schema.json` files
3. **Add tools array to frontmatter** on every skill
4. **Use canonical model IDs** instead of short names
5. **Add version field** to all skill frontmatter
6. **Create adapter script** that converts DELPHI plugin.json to OpenClaw plugin.json format

### Adaptation effort estimate

- Automated schema extraction: 2-3 hours (write a script)
- Frontmatter standardization: 1 hour
- Plugin.json field mapping: 30 min
- Testing: 2 hours
- **Total: ~6-8 hours**

---

## Summary: Blocking Issues

| # | Component | Issue | Severity | Fix Time |
|---|-----------|-------|----------|----------|
| 1 | Plugin | No requirements.txt / dependency list | BLOCKING | 15 min |
| 2 | Plugin | No .env.example | BLOCKING | 15 min |
| 3 | Skills | No `tools_required` in frontmatter | BLOCKING | 30 min |
| 4 | CLI | youtube-search.sh uses macOS Keychain (`security` command) | BLOCKING | 20 min |
| 5 | Procedures | No YAML frontmatter — not machine-parseable | BLOCKING | 1 hr |
| 6 | Procedures | Mixed Romanian/English — not usable outside NexusOS | BLOCKING | 4 hr |
| 7 | Procedures | Heavy NexusOS coupling (Cortex IP, ECHELON, VK, WISH) | BLOCKING | 8 hr |
| 8 | Skills | No JSON Schema files for I/O contracts | BLOCKING | 2 hr |

---

## Quick Fixes (completable in <1 hour total)

1. Create `~/.claude/plugins/delphi/requirements.txt` with Python deps
2. Create `~/.claude/plugins/delphi/.env.example` with all env vars
3. Add `tools_required` array to all 13 SKILL.md frontmatter blocks
4. Fix youtube-search.sh to use env var before Keychain fallback
5. Add `version: 1.0.0` to all SKILL.md frontmatter
6. Add `model_family` field (fast/standard/advanced) alongside model-specific names

---

## Architecture Recommendations (requires redesign)

### R1: Create "Exportable Edition" procedures
Strip NexusOS-specific integration from FORGE, FIVE-STEPS, SOL, PROMPTING into standalone English-only versions with YAML frontmatter. Keep the NexusOS versions as the canonical internal docs. **Effort: 2-3 days.**

### R2: Extract JSON Schemas from SKILL.md
Each skill's Input/Output JSON blocks should become standalone `input.schema.json` and `output.schema.json` files in the skill directory. The SKILL.md references them. This enables automated validation and cross-framework interop. **Effort: 1 day.**

### R3: Create skill-manifest.json
A single machine-readable registry of all skills with their metadata, dependencies, I/O schema paths, and tool requirements. Other frameworks can parse this one file to understand the entire plugin. **Effort: 2 hours.**

### R4: Add DSE-EXPORT to FORGE-AUDIT
Add a new Domain-Specific Extension for exportability (E1 Self-Containment, E2 Documentation, E3 Portability, E4 Interoperability) to the FORGE-AUDIT procedure. This ensures exportability is checked on every audit going forward. **Effort: 30 min.**

### R5: Create OpenClaw adapter layer
Write a `tools/export-openclaw.sh` script that auto-converts the DELPHI PRO plugin structure to OpenClaw format: renames files, extracts schemas, maps frontmatter fields, generates OpenClaw-compatible plugin.json. **Effort: 1 day.**

### R6: Create universal secret management abstraction
Replace all direct Keychain/env var calls with a `resolve-secret.sh` utility that checks: (1) env var, (2) `.env` file, (3) macOS Keychain, (4) Linux `pass`/`secret-tool`. All CLI scripts call this one utility. **Effort: 2 hours.**

---

## Component Exportability Scores

| Component | Score | Blocking Issues | Quick Fixes Available |
|-----------|-------|----------------|----------------------|
| plugin.json manifest | 4/5 | 2 (deps, env) | Yes |
| Agent definition (delphi.md) | 4/5 | 0 | N/A |
| Commands (research.md, research-deep.md) | 4/5 | 0 | N/A |
| Hooks (pre/post/error) | 3/5 | 1 (Keychain ref in logs path) | Yes |
| scout-web SKILL.md | 4/5 | 1 (no tools_required) | Yes |
| scout-social SKILL.md | 4/5 | 1 | Yes |
| scout-video SKILL.md | 4/5 | 1 | Yes |
| scout-visual SKILL.md | 3/5 | 2 (no CLI, no tools) | Partial |
| scout-knowledge SKILL.md | 3.5/5 | 1 | Yes |
| scout-deep SKILL.md | 3/5 | 2 (no CLI, no tools) | Partial |
| scout-finance SKILL.md | 4/5 | 1 | Yes |
| store-cortex SKILL.md | 3/5 | 2 (no CLI, no tools) | Partial |
| store-notion SKILL.md | 4/5 | 1 | Yes |
| store-vault SKILL.md | 2.5/5 | 2 (no CLI, no tools) | Partial |
| critic SKILL.md | 4/5 | 1 | Yes |
| synthesizer SKILL.md | 4/5 | 1 | Yes |
| reporter SKILL.md | 3/5 | 2 (VPS coupling, no tools) | Partial |
| youtube-search.sh | 3/5 | 1 (Keychain) | Yes |
| reddit-search.sh | 4.5/5 | 0 | N/A |
| hn-search.sh | 4.5/5 | 0 | N/A |
| news-search.sh | 4/5 | 0 (feedparser optional) | N/A |
| yfinance-search.sh | 4.5/5 | 0 | N/A |
| notion-create.sh | 3.5/5 | 1 (settings.json coupling) | Yes |
| FORGE.md v1.5 | 2/5 | 3 (lang, coupling, no frontmatter) | No |
| FIVE-STEPS-AGENTS v1.4 | 2.5/5 | 3 | No |
| SOL v1.5 | 2.5/5 | 3 | No |
| PROMPTING v1.7 | 2/5 | 4 (hardcoded IP too) | No |
| FORGE-AUDIT v1.7 | 3/5 | 2 (no JSON output, no DSE-EXPORT) | Partial |
| DELPHI-SOC v1.0 | 3/5 | 2 (coupling, no standalone) | Partial |
| OpenClaw compat | 2.5/5 | 5 (schemas, naming, model IDs) | Partial |

---

## Priority Order for Export Readiness

### Phase 1: Quick wins (1-2 hours) — raises score from 62% to ~72%
1. requirements.txt
2. .env.example
3. tools_required in all frontmatter
4. youtube-search.sh Keychain fix
5. version field in all frontmatter

### Phase 2: Schema extraction (1 day) — raises to ~80%
1. Extract input.schema.json / output.schema.json from all 13 skills
2. Create skill-manifest.json
3. Add DSE-EXPORT to FORGE-AUDIT

### Phase 3: Procedure export editions (2-3 days) — raises to ~90%
1. English-only export editions of FORGE, FIVE-STEPS, SOL, PROMPTING
2. YAML frontmatter on all procedures
3. NexusOS integration separated into appendix

### Phase 4: OpenClaw adapter (1 day) — raises to ~95%
1. export-openclaw.sh script
2. Universal secret management utility
3. Cross-platform CI test

---

## Appendix: Does any audit procedure have an "exportability" dimension?

**No.** Checked FORGE-AUDIT v1.7 exhaustively. The existing DSEs are:
- DSE-RESEARCH (R1-R4): Source Coverage, Prompt Quality, Token Scaling, Route Optimization
- DSE-WORKFLOW (W1-W4): Handoff Quality, State Management, Error Recovery, Idempotency

Neither covers exportability. **Recommendation: Add DSE-EXPORT (E1-E4)** as defined in Section 5 above. This should be added to FORGE-AUDIT as a new DSE that activates when the subject is intended for external use.
