# OpenClaw Documentation Analysis for Plugin Compatibility

**Source:** github.com/openclaw/openclaw (main branch)
**Date:** 2026-03-20
**Purpose:** Drive Delphi plugin compatibility work with OpenClaw

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [A. SKILL Format](#a-skill-format)
3. [B. AGENT/SOUL Format](#b-agentsoul-format)
4. [C. PLUGIN Format](#c-plugin-format)
5. [D. JSON Schema Requirements](#d-json-schema-requirements)
6. [E. Configuration Management](#e-configuration-management)
7. [F. Hooks System](#f-hooks-system)
8. [G. Slash Commands](#g-slash-commands)
9. [H. MCP Integration](#h-mcp-integration)
10. [I. Export/Import (Plugin Installation)](#i-exportimport-plugin-installation)
11. [J. Differences from Claude Code](#j-differences-from-claude-code)
12. [Bundle Compatibility Matrix](#bundle-compatibility-matrix)
13. [Key Takeaways for Delphi](#key-takeaways-for-delphi)

---

## 1. Executive Summary

OpenClaw is a gateway-based AI agent platform with a rich plugin system. There are **two distinct plugin types**:

1. **Native OpenClaw plugins** -- TypeScript modules that execute in-process via `openclaw.plugin.json` manifest + `register(api)` entry point. These register capabilities (providers, channels, tools, speech, etc.).

2. **Compatible bundles** -- Content/metadata packs from Codex, Claude, or Cursor ecosystems. OpenClaw reads their metadata and maps supported surfaces (skills, MCP config, settings) into native OpenClaw features **without executing bundle runtime code**.

For Delphi, the **Claude bundle format** is the most relevant compatibility path, as it allows a single plugin to work across Claude Code, OpenClaw, and potentially Codex/Cursor.

---

## A. SKILL Format

### What is a Skill?

A skill is a directory containing a `SKILL.md` file with YAML frontmatter and Markdown instructions. Skills teach the agent how to use tools. They follow the **AgentSkills** spec (https://agentskills.io).

### Directory Structure

```
my-skill/
  SKILL.md       # Required: frontmatter + instructions
  scripts/       # Optional: helper scripts
  resources/     # Optional: any supporting files
```

### SKILL.md Format

```markdown
---
name: my_skill
description: Short description of the skill
---

# Skill Instructions

Markdown body with instructions for the LLM on how to use this skill.
Use {baseDir} to reference the skill folder path.
```

### Mandatory Frontmatter Fields

- `name` (string) -- skill identifier
- `description` (string) -- short description

### Optional Frontmatter Fields

- `homepage` -- URL for UI display
- `user-invocable` -- `true|false` (default: true). Exposes skill as a slash command.
- `disable-model-invocation` -- `true|false` (default: false). Excludes from model prompt.
- `command-dispatch` -- `tool` (optional). Bypasses model, dispatches directly to a tool.
- `command-tool` -- tool name for direct dispatch.
- `command-arg-mode` -- `raw` (default). For tool dispatch, forwards raw args.
- `metadata` -- single-line JSON object for gating and config.

### Metadata Gating (metadata.openclaw)

```yaml
metadata: {"openclaw": {"requires": {"bins": ["uv"], "env": ["GEMINI_API_KEY"], "config": ["browser.enabled"]}, "primaryEnv": "GEMINI_API_KEY"}}
```

Fields under `metadata.openclaw`:

- `always: true` -- skip gates, always include
- `emoji` -- display emoji
- `homepage` -- URL
- `os` -- platform filter: `["darwin", "linux", "win32"]`
- `requires.bins` -- required binaries on PATH
- `requires.anyBins` -- at least one required
- `requires.env` -- required env vars
- `requires.config` -- required config paths
- `primaryEnv` -- env var for apiKey config
- `install` -- installer specs (brew/node/go/uv/download)
- `skillKey` -- custom key for config entries

### Skill Locations (Precedence: highest to lowest)

1. `<workspace>/skills/` -- workspace skills (per-agent)
2. `~/.openclaw/skills` -- managed/local skills (shared)
3. Bundled skills (shipped with install)
4. `skills.load.extraDirs` paths (lowest)
5. Plugin-declared skill directories

### Key Notes

- Parser supports **single-line** frontmatter keys only
- `metadata` must be a single-line JSON object
- Use `{baseDir}` placeholder in instructions
- Skills are injected as XML list in system prompt (name + description + location)
- Model reads SKILL.md on demand via `read` tool
- Session snapshots skills at start; hot-reload via watcher

---

## B. AGENT/SOUL Format

### Workspace Bootstrap Files

OpenClaw agents use a **workspace directory** with these injected files:

| File | Purpose | Injected? |
|------|---------|-----------|
| `AGENTS.md` | Operating instructions, memory conventions, group chat rules | Yes, every turn |
| `SOUL.md` | Persona, boundaries, tone, identity | Yes, every turn |
| `TOOLS.md` | User-maintained tool notes (SSH hosts, camera names, etc.) | Yes, every turn |
| `IDENTITY.md` | Agent name, creature type, vibe, emoji, avatar | Yes, every turn |
| `USER.md` | User profile (name, pronouns, timezone) | Yes, every turn |
| `HEARTBEAT.md` | Periodic task checklist | Yes, every turn |
| `BOOTSTRAP.md` | One-time first-run ritual (deleted after) | Only on new workspace |
| `MEMORY.md` | Long-term curated memory | Yes (main session only) |
| `BOOT.md` | Startup instructions (run via hook) | Via boot-md hook |

### SOUL.md

Defines agent personality and behavioral guidelines. Key sections:
- Core behavioral truths
- Boundaries (privacy, external actions)
- Tone/vibe
- Continuity instructions

This is the agent's "soul" -- its persona definition. It is **user-editable** and the agent itself can update it.

### AGENTS.md

Main operating instructions covering:
- Session startup sequence (read SOUL.md, USER.md, memory)
- Memory management conventions
- Red lines (no data exfiltration, trash > rm)
- External vs internal action rules
- Group chat behavior
- Heartbeat behavior
- Tool usage notes

### Multi-Agent

Each agent has its own workspace. Skills in workspace are per-agent; skills in `~/.openclaw/skills` are shared. Sub-agents only get `AGENTS.md` and `TOOLS.md` injected.

### Bootstrap Limits

- Per-file max: `agents.defaults.bootstrapMaxChars` (default: 20,000)
- Total max: `agents.defaults.bootstrapTotalMaxChars` (default: 150,000)
- Large files truncated with marker

---

## C. PLUGIN Format

### Native OpenClaw Plugin

#### Required Files

```
my-plugin/
  package.json          # npm metadata + openclaw config block
  openclaw.plugin.json  # Plugin manifest (REQUIRED)
  index.ts              # Entry point
```

#### Optional Files

```
  setup-entry.ts        # Setup wizard
  api.ts                # Public exports
  runtime-api.ts        # Internal exports
  src/
    provider.ts         # Capability implementation
    runtime.ts          # Runtime wiring
    *.test.ts           # Tests
```

#### package.json -- openclaw block

```json
{
  "name": "@myorg/openclaw-my-plugin",
  "version": "1.0.0",
  "type": "module",
  "openclaw": {
    "extensions": ["./index.ts"],
    "providers": ["my-provider"],
    "channel": {
      "id": "my-channel",
      "label": "My Channel",
      "blurb": "Description"
    }
  }
}
```

#### openclaw.plugin.json (Manifest)

```json
{
  "id": "my-plugin",
  "configSchema": {
    "type": "object",
    "additionalProperties": false,
    "properties": {}
  }
}
```

Required keys:
- `id` (string): canonical plugin id
- `configSchema` (object): JSON Schema for plugin config

Optional keys:
- `kind`: plugin kind (`"memory"`, `"context-engine"`)
- `channels`: channel ids array
- `providers`: provider ids array
- `providerAuthEnvVars`: auth env vars
- `providerAuthChoices`: onboarding metadata
- `skills`: skill directories (relative to plugin root)
- `name`: display name
- `description`: short summary
- `uiHints`: config field labels/placeholders
- `version`: informational

#### Entry Point Pattern

```typescript
import { definePluginEntry } from "openclaw/plugin-sdk/core";

export default definePluginEntry({
  id: "my-plugin",
  name: "My Plugin",
  register(api) {
    api.registerProvider({ /* ... */ });
    api.registerTool({ /* ... */ });
  },
});
```

For channels: use `defineChannelPluginEntry` instead.

#### Plugin API Registration Methods

- `api.registerProvider(...)` -- text inference (LLM)
- `api.registerChannel(...)` -- chat channel
- `api.registerSpeechProvider(...)` -- TTS/STT
- `api.registerMediaUnderstandingProvider(...)` -- image/audio/video analysis
- `api.registerImageGenerationProvider(...)` -- image generation
- `api.registerWebSearchProvider(...)` -- web search
- `api.registerTool(...)` -- agent tools
- `api.registerHook(...)` -- lifecycle hooks
- `api.registerHttpRoute(...)` -- HTTP routes
- `api.registerCommand(...)` -- CLI commands
- `api.registerCli(...)` -- CLI extensions
- `api.registerContextEngine(...)` -- context engine
- `api.registerService(...)` -- background services

#### Plugin SDK Subpaths (Import From)

```typescript
import { definePluginEntry } from "openclaw/plugin-sdk/core";
import { createPluginRuntimeStore } from "openclaw/plugin-sdk/runtime-store";
import { buildOauthProviderAuthResult } from "openclaw/plugin-sdk/provider-oauth";
```

Key subpaths: `core`, `channel-setup`, `channel-pairing`, `channel-reply-pipeline`, `channel-config-schema`, `channel-policy`, `secret-input`, `webhook-ingress`, `runtime-store`, `allow-from`, `reply-payload`, `provider-oauth`, `provider-onboard`, `testing`.

### Compatible Bundle Format (Claude Bundle)

This is the **most relevant format for Delphi**.

#### Claude Bundle Detection

OpenClaw recognizes two layouts:

1. **Manifest-based:** `.claude-plugin/plugin.json`
2. **Manifestless (default layout):** detected by presence of known directories

#### Default Claude Layout Markers

```
skills/              # Skill roots -> loaded as OpenClaw skills
commands/            # Claude commands -> treated as skill roots
agents/              # Detected but NOT executed
hooks/hooks.json     # Detected but NOT executed
.mcp.json            # MCP config -> merged into Pi settings
.lsp.json            # Detected but NOT executed
settings.json        # Imported as embedded Pi settings
```

#### Claude Bundle Manifest (.claude-plugin/plugin.json)

Can declare custom component paths:
- `skills`, `commands`, `agents`, `hooks`, `mcpServers`, `lspServers`, `outputStyles`

Custom paths are **additive** (don't replace defaults).

#### What OpenClaw Maps from Claude Bundles (TODAY)

| Claude Surface | OpenClaw Mapping | Status |
|---------------|-----------------|--------|
| `skills/` | Loaded as OpenClaw skill roots | **Supported** |
| `commands/` | Treated as skill roots | **Supported** |
| `settings.json` | Embedded Pi settings | **Supported** |
| `.mcp.json` + mcpServers | Merged into Pi MCP settings + stdio tool exposure | **Supported** |
| `agents/` | Detected, capability reported | **NOT executed** |
| `hooks/hooks.json` | Detected, capability reported | **NOT executed** |
| `.lsp.json` / `lspServers` | Detected | **NOT executed** |
| `outputStyles` | Detected | **NOT executed** |

#### Codex Bundle Markers

```
.codex-plugin/plugin.json
skills/
hooks/                    # Hook packs (HOOK.md + handler.ts) -- SUPPORTED
.mcp.json
.app.json
```

#### Cursor Bundle Markers

```
.cursor-plugin/plugin.json
skills/
.cursor/commands/          # Treated as skill roots
.cursor/agents/            # Detect-only
.cursor/rules/             # Detect-only
.cursor/hooks.json         # Detect-only
.mcp.json
```

---

## D. JSON Schema Requirements

### Native Plugins

**Every native plugin MUST ship a JSON Schema** in `openclaw.plugin.json` via `configSchema`, even if it accepts no config:

```json
{
  "id": "my-plugin",
  "configSchema": {
    "type": "object",
    "additionalProperties": false,
    "properties": {}
  }
}
```

- Schemas validated at config read/write time, not runtime
- Unknown config keys = errors
- OpenClaw uses TypeBox for internal schema definitions

### Agent Tools

Tool parameters use JSON Schema (or TypeBox):

```typescript
import { Type } from "@sinclair/typebox";

api.registerTool({
  name: "my_tool",
  description: "Do a thing",
  parameters: Type.Object({
    input: Type.String(),
  }),
  async execute(_id, params) {
    return { content: [{ type: "text", text: params.input }] };
  },
});
```

### Compatible Bundles

Bundles do **not** expose native OpenClaw config schemas. No JSON Schema required for bundle format.

---

## E. Configuration Management

### Main Config File

`~/.openclaw/openclaw.json` (JSON5 supported)

### Config Hierarchy

- Global config: `~/.openclaw/openclaw.json`
- Per-agent overrides: `agents.list[].tools`, `agents.list[].sandbox`, etc.
- Runtime overrides: `/debug set` (memory-only, not persisted)
- Environment variables for secrets

### Plugin Config

```json5
{
  plugins: {
    enabled: true,
    allow: ["voice-call"],
    deny: ["untrusted-plugin"],
    load: { paths: ["~/Projects/oss/my-plugin"] },
    slots: { memory: "memory-core", contextEngine: "legacy" },
    entries: {
      "voice-call": { enabled: true, config: { provider: "twilio" } }
    }
  }
}
```

### Skills Config

```json5
{
  skills: {
    allowBundled: ["gemini", "peekaboo"],
    load: {
      extraDirs: ["~/skills-pack/skills"],
      watch: true,
      watchDebounceMs: 250
    },
    entries: {
      "my-skill": {
        enabled: true,
        apiKey: { source: "env", provider: "default", id: "MY_API_KEY" },
        env: { MY_VAR: "value" },
        config: { endpoint: "https://example.com" }
      }
    }
  }
}
```

### Secrets

- `skills.entries.<key>.apiKey` -- plaintext or SecretRef `{ source, provider, id }`
- `skills.entries.<key>.env` -- env vars injected per-run (host only)
- Environment variables: standard `process.env`
- `secrets` CLI: `openclaw secrets` for managing encrypted secrets

---

## F. Hooks System

### What Hooks Are

Event-driven automation scripts that run inside the Gateway when agent events fire.

### Hook Structure

```
my-hook/
  HOOK.md          # Metadata in YAML frontmatter + docs
  handler.ts       # TypeScript handler implementation
```

### HOOK.md Format

```markdown
---
name: my-hook
description: "Description"
metadata: {"openclaw": {"emoji": "🎯", "events": ["command:new"], "requires": {"bins": ["node"]}}}
---

# My Hook

Documentation...
```

### Handler Pattern

```typescript
const handler = async (event) => {
  if (event.type !== "command" || event.action !== "new") return;
  // Logic here
  event.messages.push("Message to user");
};
export default handler;
```

### Event Types

| Category | Events |
|----------|--------|
| Command | `command`, `command:new`, `command:reset`, `command:stop` |
| Session | `session:compact:before`, `session:compact:after` |
| Agent | `agent:bootstrap` |
| Gateway | `gateway:startup` |
| Message | `message`, `message:received`, `message:transcribed`, `message:preprocessed`, `message:sent` |
| Plugin API | `tool_result_persist`, `before_compaction`, `after_compaction` |

### Hook Locations (Precedence)

1. `<workspace>/hooks/` -- per-agent, highest
2. `~/.openclaw/hooks/` -- managed, shared
3. Bundled hooks

### Hook Packs (npm)

```json
{
  "name": "@acme/my-hooks",
  "openclaw": {
    "hooks": ["./hooks/my-hook", "./hooks/other-hook"]
  }
}
```

Install: `openclaw hooks install @acme/my-hooks`

### Bundle Hook Compatibility

- Codex hook packs (HOOK.md + handler.ts layout) -- **Supported**
- Claude `hooks/hooks.json` -- **Detected but NOT executed**

---

## G. Slash Commands

### How Skills Become Commands

Skills with `user-invocable: true` (default) are automatically exposed as slash commands.

- Names sanitized to `a-z0-9_` (max 32 chars)
- Collisions get numeric suffixes (`_2`)
- `/skill <name> [input]` runs any skill by name
- Default behavior: forwarded to model as normal request
- With `command-dispatch: tool`: routes directly to a tool (deterministic, no model)

### Built-in Commands

Extensive list including: `/help`, `/commands`, `/status`, `/skill`, `/model`, `/think`, `/fast`, `/verbose`, `/new`, `/reset`, `/stop`, `/btw`, `/context`, `/subagents`, `/acp`, `/focus`, `/unfocus`, `/kill`, `/steer`, `/config`, `/mcp`, `/plugins`, `/debug`, `/usage`, `/tts`, `/bash`, etc.

### Config

```json5
{
  commands: {
    native: "auto",        // Register native platform commands
    nativeSkills: "auto",  // Register skill commands natively
    text: true,            // Parse /... in chat
    bash: false,           // Enable ! <cmd>
    config: false,         // Enable /config
    mcp: false,            // Enable /mcp
    plugins: false,        // Enable /plugins
    debug: false,          // Enable /debug
    allowFrom: { "*": ["user1"] }
  }
}
```

---

## H. MCP Integration

### OpenClaw-Managed MCP

Stored under `mcp.servers` in `openclaw.json`. Managed via `/mcp` command or `openclaw` CLI.

### Bundle MCP

Enabled bundles can contribute MCP server config:
- Merged into effective embedded Pi settings as `mcpServers`
- OpenClaw launches supported **stdio** MCP servers as subprocesses
- Project-local Pi settings can override bundle MCP entries

### .mcp.json

Both Claude and Codex bundles can include `.mcp.json` for MCP server definitions. OpenClaw reads this and exposes supported stdio tools to the embedded Pi agent.

### Runtime Adapters

Runtime adapters decide which MCP transports are executable. Currently stdio is supported for bundle MCP.

---

## I. Export/Import (Plugin Installation)

### Native Plugin Install

```bash
# From npm
openclaw plugins install @myorg/openclaw-my-plugin
openclaw plugins install @myorg/plugin@1.0.0

# From local path
openclaw plugins install ./my-plugin
openclaw plugins install -l ./my-plugin  # symlink for dev

# From archive
openclaw plugins install ./plugin.tgz
openclaw plugins install ./plugin.zip
```

### Bundle Install

```bash
# Local directory
openclaw plugins install ./my-claude-bundle
openclaw plugins install ./my-codex-bundle

# From archive
openclaw plugins install ./my-bundle.tgz

# From Claude marketplace
openclaw plugins marketplace list <marketplace-name>
openclaw plugins install <plugin-name>@<marketplace-name>
```

### Marketplace Support

OpenClaw reads Claude marketplace registry at `~/.claude/plugins/known_marketplaces.json`. Entries resolve to bundle-compatible directories/archives or native plugin sources.

### Plugin Management

```bash
openclaw plugins list              # Show all plugins
openclaw plugins inspect <id>      # Deep detail
openclaw plugins enable <id>       # Enable
openclaw plugins disable <id>      # Disable
openclaw plugins update <id>       # Update
openclaw plugins update --all      # Update all
openclaw plugins doctor            # Diagnostics
openclaw plugins status            # Operational summary
```

### Skills Install (via ClawHub)

```bash
clawhub install <skill-slug>       # Install skill
clawhub update --all               # Update all
clawhub sync --all                 # Scan + publish
```

ClawHub is the public skills registry at https://clawhub.com.

### Hook Pack Install

```bash
openclaw hooks install <path-or-spec>
openclaw hooks enable <name>
openclaw hooks disable <name>
```

---

## J. Differences from Claude Code

### Plugin System

| Aspect | Claude Code | OpenClaw |
|--------|-------------|----------|
| Plugin type | Skills/commands in `.claude/` | Native plugins (in-process TypeScript) + compatible bundles |
| Runtime | No plugin runtime code | Full in-process plugin runtime via `register(api)` |
| Manifest | None or `.claude-plugin/plugin.json` | `openclaw.plugin.json` (required for native) |
| Capabilities | Skills + MCP + hooks | Providers, channels, speech, media, image gen, web search, tools, hooks, services, CLI, HTTP routes |
| Distribution | Local or marketplace | npm + local + marketplace |
| Config schema | Not enforced | JSON Schema required in manifest |

### Skills vs Commands

| Aspect | Claude Code | OpenClaw |
|--------|-------------|----------|
| Format | SKILL.md (AgentSkills) | Same SKILL.md format (AgentSkills-compatible) |
| Locations | `.claude/commands/`, project skills | `<workspace>/skills/`, `~/.openclaw/skills/`, bundled, plugin skills |
| Commands directory | `commands/` contains slash commands | `commands/` treated as skill roots (same as skills/) |
| Gating | Not gated | Rich gating: bins, env, config, OS |
| Config | Per-skill in settings | Per-skill in `skills.entries` with env injection |
| Registry | Claude marketplace | ClawHub (clawhub.com) |

### Hooks

| Aspect | Claude Code | OpenClaw |
|--------|-------------|----------|
| Format | `hooks.json` + scripts | `HOOK.md` + `handler.ts` directories |
| Events | Pre/post command hooks | Rich event system: command, session, agent, gateway, message events |
| Execution | Shell commands | TypeScript handlers (async, in-process) |
| Bundle compat | Claude `hooks.json` detected but NOT executed | Must use OpenClaw hook-pack format for execution |

### Agent Identity

| Aspect | Claude Code | OpenClaw |
|--------|-------------|----------|
| Identity | CLAUDE.md / system prompt | SOUL.md + IDENTITY.md + AGENTS.md + USER.md + TOOLS.md |
| Persona | Defined by Anthropic | User-editable, agent-editable |
| Memory | Project memory | MEMORY.md + memory/*.md daily files |
| Bootstrap | CLAUDE.md | BOOTSTRAP.md (one-time ritual, then deleted) |

### MCP

| Aspect | Claude Code | OpenClaw |
|--------|-------------|----------|
| Config | `.mcp.json` / `mcp_servers` in settings | `mcp.servers` in openclaw.json + bundle MCP |
| Transport | stdio, sse | stdio for bundle MCP; runtime adapters for managed |
| Bundle MCP | Native | Supported (stdio only) |

---

## Bundle Compatibility Matrix

### For a Claude-format bundle to work in OpenClaw:

| Component | Will It Work? | Notes |
|-----------|--------------|-------|
| `skills/` directory with SKILL.md files | YES | Loaded as native skill roots |
| `commands/` directory with .md files | YES | Treated as skill roots |
| `.mcp.json` | YES | Merged into Pi settings, stdio servers launched |
| `settings.json` | YES | Imported as Pi settings (shell keys sanitized) |
| `agents/` | NO | Detected but not executed |
| `hooks/hooks.json` | NO | Detected but not executed |
| `.lsp.json` | NO | Detected only |
| `outputStyles` | NO | Detected only |

### For a bundle to also work as a Codex bundle:

| Component | Will It Work? | Notes |
|-----------|--------------|-------|
| `skills/` | YES | Same as Claude |
| `hooks/` (HOOK.md + handler.ts) | YES | OpenClaw hook-pack format works |
| `.mcp.json` | YES | Same as Claude |
| `.codex-plugin/plugin.json` | YES | Alternative detection path |

---

## Key Takeaways for Delphi

### Recommended Approach: Claude Bundle Format

For maximum compatibility across Claude Code + OpenClaw, use the **Claude bundle layout**:

```
delphi-plugin/
  .claude-plugin/
    plugin.json              # Bundle manifest
  skills/
    delphi-research/
      SKILL.md               # AgentSkills format
    delphi-brainstorm/
      SKILL.md
  commands/
    /research.md             # Slash command (treated as skill)
  .mcp.json                  # MCP server definitions (if needed)
  settings.json              # Default settings (if needed)
```

### SKILL.md Must Follow

1. YAML frontmatter with `name` and `description` (required)
2. Single-line `metadata` JSON (if using gating)
3. Markdown body with instructions
4. Use `{baseDir}` for self-referencing paths

### What Will NOT Transfer to OpenClaw

- Claude `hooks.json` automation (use OpenClaw HOOK.md format instead)
- Claude `agents/` definitions
- Claude `outputStyles`
- Claude LSP server configs

### What WILL Transfer

- All skills and commands (as skill roots)
- MCP server definitions (stdio transport)
- Settings defaults (sanitized)

### If Going Native OpenClaw

For full OpenClaw integration (tools, hooks, commands, capabilities):

1. Create `openclaw.plugin.json` with `id` + `configSchema`
2. Create `package.json` with `openclaw.extensions` block
3. Use `definePluginEntry` from `openclaw/plugin-sdk/core`
4. Register tools via `api.registerTool()` with TypeBox/JSON Schema parameters
5. Publish to npm: `openclaw plugins install @myorg/delphi`

### Dual-Format Strategy

Ship both formats for maximum reach:

```
delphi-plugin/
  # Claude bundle (detected by OpenClaw too)
  .claude-plugin/plugin.json
  skills/
    delphi-research/SKILL.md
  commands/
    research.md
  .mcp.json
  settings.json

  # Native OpenClaw (takes precedence if present)
  openclaw.plugin.json
  package.json
  index.ts
```

Native OpenClaw format takes precedence over bundle detection if both are present.

### ClawHub Publishing

For skill-only distribution, publish to ClawHub (clawhub.com) for OpenClaw discovery.

### Critical Implementation Notes

1. **Parser limitation:** OpenClaw's embedded agent parser supports single-line frontmatter keys only. Multi-line YAML values in SKILL.md will break.
2. **Skills are NOT code:** Skills are prompt instructions, not executable code. The agent reads them and follows instructions using available tools.
3. **Token budget:** Each skill adds ~97 chars + field lengths to system prompt. Keep skill lists manageable.
4. **Session snapshot:** Skills are snapshotted at session start. Changes need new session or watcher-based hot reload.
5. **Bundle trust boundary:** Bundle code is never executed in-process. Only metadata/content is read. This is safer but more limited than native plugins.
6. **JSON Schema is mandatory** for native plugins, even for empty configs.
7. **SDK imports must use focused subpaths** (`openclaw/plugin-sdk/<subpath>`), not the deprecated monolithic import.
