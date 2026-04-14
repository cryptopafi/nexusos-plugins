---
name: store-notion
description: "Create Notion pages for research reports and project docs. CLI-based. Use from DELPHI PRO, Reporter, or Marketing Agent for team-visible storage."
model: claude-haiku-4-5
tools: [Bash]
user-invocable: false
allowed-tools: [Bash]
---

# store-notion — Notion Page Store

## What You Do

Create pages in Notion databases to store research reports, findings, and project documentation. Uses CLI wrapper instead of MCP to save ~12K tokens of context. Supports markdown-to-blocks conversion, database metadata properties, content chunking for large reports, and duplicate detection.

## What You Do NOT Do

- You do NOT read or query existing Notion pages (use Notion MCP for that)
- You do NOT delete or archive pages
- You do NOT modify page permissions or sharing
- You do NOT create databases (only pages within existing databases)
- You do NOT evaluate or synthesize research (Critic/Synthesizer do that)

## Input

You receive a JSON task from DELPHI PRO or Reporter:

```json
{
  "task": "create-page",
  "db": "DATABASE_ID_UUID",
  "title": "Research Report: AI Agents 2026",
  "content": "Report content in markdown...",
  "metadata": {
    "topic": "AI agents",
    "depth": "D3",
    "epr_score": 17,
    "tags": "ai,agents,2026",
    "source": "delphi-pro"
  },
  "dedup": true,
  "stdin": false
}
```

## Structural Approval Gate (Lobster Pattern 1)

For D4 research writes, call gate before creating the Notion page:
```bash
if [ "${depth}" = "D4" ]; then
    bash ~/.nexus/v2/shared-skills/approval-gate.sh \
        "${task_id:-store-notion-$(date +%s)}" "notion-d4-gate" \
        "D4 write to Notion: ${title}" --timeout 120
    gate_exit=$?
    if [ $gate_exit -ne 0 ]; then
        echo '{"status": "skipped", "reason": "gate_denied_or_timeout"}'
        exit 0
    fi
fi
```

D1-D3 stores proceed without any gate.

## Input Validation
- Empty `title`: return `{"status": "error", "error": "title_required"}`
- Empty `content`: return `{"status": "error", "error": "content_required"}`
- Missing `db` (database ID): check NOTION_RESEARCH_DB / NOTION_PROJECTS_DB env vars; if neither set, return error
- Missing `NOTION_TOKEN`: return `{"status": "error", "error": "notion_token_missing"}`

## Operations

### CREATE PAGE
Create a new page in a Notion database with title, metadata properties, and markdown content converted to native Notion blocks.

```bash
~/.claude/plugins/delphi/skills/store-notion/cli/notion-create.sh \
  --db DATABASE_ID \
  --title "Research Report: AI Agents 2026" \
  --content "# Summary\n\nReport content in markdown..." \
  --topic "AI agents" \
  --depth "D3" \
  --epr 17 \
  --tags "ai,agents,2026" \
  --source "delphi-pro" \
  --dedup
```

### CREATE WITH STDIN
Pipe content from another command:

```bash
cat report.md | ~/.claude/plugins/delphi/skills/store-notion/cli/notion-create.sh \
  --db DATABASE_ID \
  --title "Report Title" \
  --stdin \
  --topic "Topic" \
  --depth "D3"
```

### CREATE AS CHILD PAGE
Create the page as a child of an existing page instead of a database entry:

```bash
~/.claude/plugins/delphi/skills/store-notion/cli/notion-create.sh \
  --parent PAGE_ID \
  --title "Section: Methodology" \
  --content "Section content..."
```

## Database Properties

The CLI sets these properties on database pages (properties must exist in the target database schema; unrecognized properties are silently ignored by Notion):

| Property | Type | Flag | Description |
|----------|------|------|-------------|
| title | title | --title | Page title (required) |
| Topic | select | --topic | Research topic category |
| Depth | select | --depth | Research depth: D1, D2, D3, D4 |
| EPR Score | number | --epr | Evidence-Perspective-Relevance score |
| Tags | multi_select | --tags | Comma-separated tags |
| Source | select | --source | Originating agent (delphi-pro, reporter, etc.) |
| Date | date | (auto) | Set automatically to today's date |

## Content Handling

### Markdown-to-Blocks Conversion
The CLI converts markdown to native Notion block types:
- `# H1`, `## H2`, `### H3` become heading_1, heading_2, heading_3 blocks
- `- item` or `* item` become bulleted_list_item blocks
- `1. item` become numbered_list_item blocks
- `> quote` becomes quote blocks
- `` ```lang `` fenced code blocks become code blocks with language
- `---` becomes divider blocks
- All other text becomes paragraph blocks

### Large Content Chunking
Notion enforces these limits:
- **2000 chars** per rich_text element: text is split across multiple rich_text entries within the same block
- **100 blocks** per API request: content is split into chunks; first 100 blocks go with page creation, remaining blocks are appended via PATCH /blocks/{id}/children in batches of 100
- **3 req/s** rate limit: retry with exponential backoff on HTTP 429

### Duplicate Detection
When `--dedup` is passed and `--db` is set, the CLI queries the database for pages with an exact title match before creating. If found:
- Returns `status: "duplicate"` with the existing page_id and URL
- Does NOT create a new page
- Dedup is best-effort: if the query fails, page creation proceeds normally

## When to Use

| Caller | When |
|:---:|:---:|
| DELPHI PRO | After D3/D4 research — save report to Notion |
| Reporter | After HTML generation — save link + metadata |
| Marketing Agent | Save competitor intel, campaign reports |

## How to Call (from DELPHI PRO skill)

Build the CLI command from the task JSON:

```bash
NOTION_CLI=~/.claude/plugins/delphi/skills/store-notion/cli/notion-create.sh

ARGS=(--db "$DB_ID" --title "$TITLE")
[[ -n "$TOPIC" ]] && ARGS+=(--topic "$TOPIC")
[[ -n "$DEPTH" ]] && ARGS+=(--depth "$DEPTH")
[[ -n "$EPR" ]] && ARGS+=(--epr "$EPR")
[[ -n "$TAGS" ]] && ARGS+=(--tags "$TAGS")
[[ -n "$SOURCE" ]] && ARGS+=(--source "$SOURCE")
ARGS+=(--dedup --stdin)
echo "$CONTENT" | "$NOTION_CLI" "${ARGS[@]}"
```

## Configuration

- `NOTION_TOKEN`: auto-read from `~/.claude/settings.json` mcpServers.notion.env.NOTION_TOKEN
- Database IDs configured in environment variables: NOTION_RESEARCH_DB for research reports, NOTION_PROJECTS_DB for project docs. Set these in ~/.nexus/.env or export before calling.
- API version: CLI uses Notion API version 2022-06-28 (stable, long-term support). The Notion MCP uses 2025-09-03. Both versions are compatible for page creation operations.

## Notion Down — Not Critical

If Notion is unavailable, DELPHI PRO continues normally. Notion storage is non-critical — Cortex and Vault are the primary stores. Notion is for team visibility only.

## Output

> Follows the Store contract. See `resources/contracts.md` for the shared schema.

### Success
```json
{
  "agent": "store-notion",
  "status": "created",
  "result": {
    "page_id": "uuid",
    "url": "https://notion.so/...",
    "title": "Report Title"
  },
  "errors": [],
  "metadata": {
    "duration_ms": 1200,
    "blocks_total": 45,
    "chunks": 1
  }
}
```

### Duplicate Found (with --dedup)
```json
{
  "agent": "store-notion",
  "status": "duplicate",
  "result": {
    "page_id": "existing-uuid",
    "url": "https://notion.so/...",
    "title": "Report Title"
  },
  "errors": [],
  "metadata": {
    "duration_ms": 300,
    "action": "skipped_duplicate"
  }
}
```

## Error Handling

- Notion API unavailable: return `status: "error"`, skip (non-critical store)
- NOTION_TOKEN missing: return `status: "error"` with `notion_token_missing`
- Database ID invalid: return `status: "error"` with `invalid_database_id`
- HTTP 429 rate limit: retry up to 3 times with Retry-After header
- Content too large: auto-chunked (2000 chars per rich_text, 100 blocks per request)
- Dedup query fails: silently proceed with page creation (best-effort)

## CLI Usage

```bash
# Minimal
~/.claude/plugins/delphi/skills/store-notion/cli/notion-create.sh \
  --db DATABASE_ID --title "Report" --content "markdown..."

# Full metadata + dedup
~/.claude/plugins/delphi/skills/store-notion/cli/notion-create.sh \
  --db DATABASE_ID --title "Report" --content "markdown..." \
  --topic "AI agents" --depth "D3" --epr 17 --tags "ai,research" \
  --source "delphi-pro" --dedup

# Child page under existing page
~/.claude/plugins/delphi/skills/store-notion/cli/notion-create.sh \
  --parent PAGE_ID --title "Child Page" --content "Content"

# Stdin mode
cat report.md | ~/.claude/plugins/delphi/skills/store-notion/cli/notion-create.sh \
  --db DATABASE_ID --title "Title" --stdin --dedup
```
