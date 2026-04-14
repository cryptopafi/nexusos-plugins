# DELPHI PRO — Handoff Contracts

This file defines the canonical JSON output contracts for all DELPHI PRO skills. Every skill output MUST conform to its contract. These contracts are the source of truth for orchestrator ↔ skill communication.

---

## Contract 1: Scout Contract

**Applies to**: All 9 scout skills — `scout-web`, `scout-social`, `scout-video`, `scout-visual`, `scout-knowledge`, `scout-deep`, `scout-finance`, `scout-brand`, `scout-domain`

The Scout contract is the standard output format for any skill that searches for and returns findings from external sources.

### Full Example

```json
{
  "agent": "scout-web",
  "status": "complete",
  "findings": [
    {
      "source_url": "https://example.com/article",
      "source_tier": "T1",
      "channel": "brave",
      "title": "Article Title",
      "content_summary": "First 500 chars of content or snippet...",
      "relevance_score": 0.85
    },
    {
      "source_url": "https://arxiv.org/abs/2401.00001",
      "source_tier": "T1",
      "channel": "perplexity-sonar-pro",
      "title": "Research Paper Title",
      "content_summary": "Abstract summary...",
      "relevance_score": 0.92
    }
  ],
  "errors": [
    {
      "channel": "exa",
      "error": "timeout",
      "retried": true
    }
  ],
  "metadata": {
    "items_total": 30,
    "items_returned": 22,
    "items_deduplicated": 8,
    "duration_ms": 12000,
    "channels_queried": ["brave", "perplexity-sonar-pro", "tavily"]
  }
}
```

### Field Reference

| Field | Type | Required | Description |
|:---|:---|:---:|:---|
| `agent` | string | Yes | Skill name (e.g. `"scout-web"`, `"scout-social"`) |
| `status` | string | Yes | Enum: `complete`, `partial`, `empty`, `error` |
| `findings` | array | Yes | Array of finding objects (may be empty if status=empty) |
| `findings[].source_url` | string | Yes | Full URL of the source |
| `findings[].source_tier` | string | Yes | Enum: `T1` (authoritative), `T2` (practitioner), `T3` (unverified) |
| `findings[].channel` | string | Yes | Search channel that returned this result (e.g. `brave`, `tavily`, `perplexity-sonar-pro`) |
| `findings[].title` | string | Yes | Title of the source document/page |
| `findings[].content_summary` | string | Yes | Up to 500 chars of content preview or snippet |
| `findings[].relevance_score` | number | Yes | 0.0–1.0 relevance to the research topic |
| `errors` | array | Yes | Per-channel errors (empty array if no errors) |
| `errors[].channel` | string | Yes | Channel that errored |
| `errors[].error` | string | Yes | Error type (e.g. `timeout`, `rate_limited`, `auth_failed`) |
| `errors[].retried` | boolean | No | Whether the channel was retried |
| `metadata` | object | Yes | Execution metadata |
| `metadata.items_total` | number | Yes | Raw results before deduplication |
| `metadata.items_returned` | number | Yes | Results after deduplication |
| `metadata.items_deduplicated` | number | No | How many duplicates were removed |
| `metadata.duration_ms` | number | Yes | Total execution time in milliseconds |
| `metadata.channels_queried` | array | Yes | List of channels that were actually queried |

### Status Enum Values

| Value | Meaning |
|:---|:---|
| `complete` | All requested channels returned results |
| `partial` | Some channels errored but at least one returned results |
| `empty` | All channels returned zero results |
| `error` | All channels failed |

### Source Tier Definitions

| Tier | Examples |
|:---|:---|
| `T1` | Official docs, `.gov`/`.edu` domains, peer-reviewed papers, known authoritative product sites |
| `T2` | Blog posts from practitioners, conference talks, reputable tech publications |
| `T3` | Forum posts, social comments, Reddit threads, unverified sources |

---

## Contract 2: Critic Contract

**Applies to**: `critic`

The Critic contract covers per-finding evaluation and EPR (Evidence-Precision-Relevance-Novelty) scoring.

### Full Example

```json
{
  "agent": "critic",
  "status": "complete",
  "errors": [],
  "evaluations": [
    {
      "finding_index": 0,
      "relevance": 0.9,
      "novelty": 0.7,
      "credibility": 0.85,
      "authority": 0.8,
      "temporal": 0.9,
      "average": 0.83,
      "verdict": "INCLUDE",
      "tier_override": null,
      "reason": "Highly relevant peer-reviewed paper from recognized authors"
    },
    {
      "finding_index": 1,
      "relevance": 0.4,
      "novelty": 0.3,
      "credibility": 0.5,
      "authority": 0.4,
      "temporal": 0.6,
      "average": 0.44,
      "verdict": "EXCLUDE",
      "tier_override": null,
      "reason": "Low relevance, duplicate information already covered by finding_index 0"
    }
  ],
  "summary": {
    "total": 25,
    "included": 18,
    "deprioritized": 4,
    "excluded": 3,
    "avg_quality": 0.72,
    "tier_overrides": 2
  },
  "epr_score": 17,
  "epr_breakdown": {
    "evidence": 4,
    "precision": 4,
    "relevance": 5,
    "novelty": 4
  },
  "devils_advocate": null,
  "metadata": {
    "duration_ms": 3200,
    "depth": "D3",
    "model": "sonnet"
  }
}
```

### Field Reference

| Field | Type | Required | Description |
|:---|:---|:---:|:---|
| `agent` | string | Yes | Always `"critic"` |
| `status` | string | Yes | Enum: `complete`, `empty`, `error` |
| `errors` | array | Yes | Error array (empty if no errors) |
| `evaluations` | array | Yes | Per-finding evaluation objects |
| `evaluations[].finding_index` | number | Yes | Index into the input findings array |
| `evaluations[].relevance` | number | Yes | 0.0–1.0 relevance to research topic |
| `evaluations[].novelty` | number | Yes | 0.0–1.0 information novelty vs other findings |
| `evaluations[].credibility` | number | Yes | 0.0–1.0 source credibility |
| `evaluations[].authority` | number | Yes | 0.0–1.0 author/institutional authority |
| `evaluations[].temporal` | number | Yes | 0.0–1.0 recency/timeliness |
| `evaluations[].average` | number | Yes | Mean of the 5 dimensions |
| `evaluations[].verdict` | string | Yes | Enum: `INCLUDE`, `DEPRIORITIZE`, `EXCLUDE` |
| `evaluations[].tier_override` | string/null | No | Override source tier if warranted (e.g. `"T1"` → `"T2"`), null if no override |
| `evaluations[].reason` | string | Yes | One-sentence justification for verdict |
| `summary` | object | Yes | Aggregate summary across all findings |
| `summary.total` | number | Yes | Total findings evaluated |
| `summary.included` | number | Yes | Count with verdict=INCLUDE |
| `summary.deprioritized` | number | Yes | Count with verdict=DEPRIORITIZE |
| `summary.excluded` | number | Yes | Count with verdict=EXCLUDE |
| `summary.avg_quality` | number | Yes | Mean average score across all findings |
| `summary.tier_overrides` | number | Yes | Count of findings where tier was overridden |
| `epr_score` | number | Yes | Composite EPR score (0–20) |
| `epr_breakdown` | object | Yes | EPR score broken down by dimension |
| `epr_breakdown.evidence` | number | Yes | Evidence dimension (0–5) |
| `epr_breakdown.precision` | number | Yes | Precision dimension (0–5) |
| `epr_breakdown.relevance` | number | Yes | Relevance dimension (0–5) |
| `epr_breakdown.novelty` | number | Yes | Novelty dimension (0–5) |
| `devils_advocate` | object/null | No | Devil's Advocate council output at D4 (null at D1–D3) |
| `metadata` | object | Yes | Execution metadata |
| `metadata.duration_ms` | number | Yes | Total execution time in ms |
| `metadata.depth` | string | Yes | Research depth: `D1`, `D2`, `D3`, `D4` |
| `metadata.model` | string | Yes | Model used: `sonnet`, `opus` |

### Verdict Enum Values

| Value | Meaning | EPR Gate Action |
|:---|:---|:---|
| `INCLUDE` | Finding passes all quality dimensions — include in synthesis | Normal inclusion |
| `DEPRIORITIZE` | Finding has moderate quality — include but flag as secondary | Lower weight in synthesis |
| `EXCLUDE` | Finding fails quality threshold — do not pass to Synthesizer | Dropped from pipeline |

### EPR Quality Gates

| EPR Score | Action |
|:---|:---|
| >= 16 | PASS — proceed to Synthesizer |
| 12–15 | FLAG — orchestrator decides retry |
| < 12 | ESCALATE — flag to Pafi with partial results |

---

## Contract 3: Synthesizer Contract

**Applies to**: `synthesizer`

The Synthesizer contract covers the final research report produced from curated findings.

### Full Example

```json
{
  "agent": "synthesizer",
  "status": "complete",
  "result": {
    "report_markdown": "# Research Report: AI Agent Orchestration\n\n## Executive Summary\n...\n\n## Key Findings\n...",
    "epr_score": 17,
    "self_grade": 78,
    "source_count": {
      "T1": 5,
      "T2": 8,
      "T3": 3
    },
    "key_findings": [
      "Finding 1: Multi-agent orchestration patterns have shifted toward...",
      "Finding 2: Haiku-class models now perform comparably to Sonnet for...",
      "Finding 3: Tool isolation per agent reduces cost by 40-60%..."
    ],
    "word_count": 2100,
    "confidence": 0.82
  },
  "errors": [],
  "metadata": {
    "duration_ms": 15000,
    "depth": "D3",
    "model": "sonnet",
    "themes_identified": 4
  }
}
```

### Field Reference

| Field | Type | Required | Description |
|:---|:---|:---:|:---|
| `agent` | string | Yes | Always `"synthesizer"` |
| `status` | string | Yes | Enum: `complete`, `INSUFFICIENT_DATA`, `partial`, `error` |
| `result` | object | Yes | Report output object |
| `result.report_markdown` | string | Yes | Full research report in Markdown format |
| `result.epr_score` | number | Yes | EPR score passed in from Critic (0–20) |
| `result.self_grade` | number | Yes | Synthesizer's self-assessed report quality (0–100) |
| `result.source_count` | object | Yes | Count of sources used per tier |
| `result.source_count.T1` | number | Yes | Number of T1 sources referenced |
| `result.source_count.T2` | number | Yes | Number of T2 sources referenced |
| `result.source_count.T3` | number | Yes | Number of T3 sources referenced |
| `result.key_findings` | array | Yes | 3–5 one-sentence key findings (plain text) |
| `result.word_count` | number | Yes | Word count of report_markdown |
| `result.confidence` | number | Yes | 0.0–1.0 synthesizer's confidence in the report |
| `errors` | array | Yes | Error array (empty if no errors) |
| `metadata` | object | Yes | Execution metadata |
| `metadata.duration_ms` | number | Yes | Total execution time in ms |
| `metadata.depth` | string | Yes | Research depth: `D1`, `D2`, `D3`, `D4` |
| `metadata.model` | string | Yes | Model used: `sonnet`, `opus` |
| `metadata.themes_identified` | number | No | Number of distinct themes found in findings |

### Status Enum Values

| Value | Meaning |
|:---|:---|
| `complete` | Report generated successfully |
| `INSUFFICIENT_DATA` | Fewer than 3 included findings after Critic evaluation |
| `partial` | Report generated but flagged as low quality (self_grade < 50) |
| `error` | Synthesizer failed |

### Self-Grade Quality Gates

| self_grade | Action |
|:---|:---|
| >= 70 | PASS — deliver report |
| 50–69 | RETRY — re-synthesize focusing on weak areas (1 retry max) |
| < 50 | ESCALATE — flag to Pafi |

---

## Contract 4: Store Contract

**Applies to**: `store-cortex`, `store-notion`, `store-vault`

All three store skills share a common output envelope. The `result` object varies per store type (see sub-schemas below).

### Full Example (store-cortex)

```json
{
  "agent": "store-cortex",
  "status": "complete",
  "result": {
    "operation": "search",
    "matches": 3,
    "items": [
      {
        "text": "Previous finding about AI agent orchestration...",
        "similarity": 0.87,
        "collection": "research"
      }
    ]
  },
  "errors": [],
  "metadata": {
    "duration_ms": 450,
    "collection": "research",
    "operation": "search"
  }
}
```

### Full Example (store-notion)

```json
{
  "agent": "store-notion",
  "status": "created",
  "result": {
    "page_id": "1a2b3c4d-5e6f-7890-abcd-ef1234567890",
    "url": "https://notion.so/Report-Title-1a2b3c4d",
    "title": "Research Report: AI Agent Orchestration"
  },
  "errors": [],
  "metadata": {
    "duration_ms": 1200,
    "blocks_total": 45,
    "chunks": 1
  }
}
```

### Full Example (store-vault)

```json
{
  "agent": "store-vault",
  "status": "complete",
  "result": {
    "path": "~/Documents/Obsidian/Research/ai-agents-2026-03-20.md",
    "title": "Research Report: AI Agent Orchestration",
    "tags": ["research", "ai-agents", "delphi-pro"]
  },
  "errors": [],
  "metadata": {
    "duration_ms": 320,
    "vault_path": "~/Documents/Obsidian",
    "operation": "write"
  }
}
```

### Common Envelope Field Reference

| Field | Type | Required | Description |
|:---|:---|:---:|:---|
| `agent` | string | Yes | Skill name: `store-cortex`, `store-notion`, `store-vault` |
| `status` | string | Yes | See status enum below |
| `result` | object | Yes | Store-specific result object |
| `errors` | array | Yes | Error array (empty if no errors) |
| `metadata` | object | Yes | Execution metadata |
| `metadata.duration_ms` | number | Yes | Total execution time in ms |
| `metadata.operation` | string | No | Operation type (search, store, checkpoint, write, etc.) |

### Status Enum Values (Store Contract)

| Value | Applies to | Meaning |
|:---|:---|:---|
| `complete` | All stores | Operation succeeded |
| `skipped` | store-cortex | Store skipped due to deduplication (similarity >= 0.85 with existing item) |
| `no_checkpoint` | store-cortex | Resume operation found no valid checkpoint |
| `created` | store-notion | New Notion page created successfully |
| `duplicate` | store-notion | Dedup mode — page already exists, skipped |
| `error` | All stores | Operation failed (see `errors` array) |

### store-cortex: Operation Types

| operation | Description |
|:---|:---|
| `search` | Search Cortex for existing knowledge |
| `store` | Store new finding in Cortex |
| `checkpoint` | Save pipeline state for resume |
| `resume` | Load pipeline checkpoint |
| `find_procedure` | Look up a procedure by name |
| `store_procedure` | Save a procedure |
| `session_log` | Log session summary |
| `procedure_feedback` | Submit procedure feedback |

---

## Contract 5: Reporter Contract

**Applies to**: `reporter`

The Reporter contract covers multi-format report generation and optional VPS deployment.

### Full Example

```json
{
  "agent": "reporter",
  "status": "published",
  "result": {
    "files": {
      "html": "${PLUGIN_BASE_DIR}/reports/ai-agents-2026-03-20.html",
      "pdf": "${PLUGIN_BASE_DIR}/reports/ai-agents-2026-03-20.pdf",
      "slides": "${PLUGIN_BASE_DIR}/reports/ai-agents-2026-03-20-slides.html"
    },
    "vps_url": "https://vps.domain/research/ai-agents-2026-20260319.html",
    "share_url": "https://vps.domain/research/ai-agents-2026-20260319.html"
  },
  "errors": [],
  "metadata": {
    "duration_ms": 8500,
    "tier": 2,
    "output_format": "html",
    "deployed_to_vps": true
  }
}
```

### Field Reference

| Field | Type | Required | Description |
|:---|:---|:---:|:---|
| `agent` | string | Yes | Always `"reporter"` |
| `status` | string | Yes | Enum: `published`, `local_only`, `error` |
| `result` | object | Yes | Report output paths and URLs |
| `result.files` | object | Yes | Local file paths for each generated format |
| `result.files.html` | string | Yes | Absolute path to HTML report |
| `result.files.pdf` | string | No | Absolute path to PDF (null/absent if PDF generation failed) |
| `result.files.slides` | string | No | Absolute path to reveal.js slides (null/absent if not generated) |
| `result.vps_url` | string | No | Full URL on VPS (null/absent if VPS deploy skipped) |
| `result.share_url` | string | No | Shareable URL (same as vps_url if deployed, null if local only) |
| `errors` | array | Yes | Error array (empty if no errors) |
| `metadata` | object | Yes | Execution metadata |
| `metadata.duration_ms` | number | Yes | Total execution time in ms |
| `metadata.tier` | number | Yes | Report tier: `1` (Card), `2` (Full), `3` (Immersive) |
| `metadata.output_format` | string | Yes | Primary format generated: `html`, `pdf`, `slides` |
| `metadata.deployed_to_vps` | boolean | Yes | Whether VPS deployment succeeded |

### Status Enum Values

| Value | Meaning |
|:---|:---|
| `published` | Report generated and deployed to VPS successfully |
| `local_only` | Report generated locally but VPS deploy was skipped or failed |
| `error` | Report generation failed |

### Report Tier Definitions

| Tier | Name | Description |
|:---|:---|:---|
| `1` | Card | Single-page summary card — executive overview, 3–5 key points |
| `2` | Full | Multi-section HTML report with charts, sources, analysis sections |
| `3` | Immersive | Full report + reveal.js presentation slides + PDF export |

---

## Contract 6: Checkpoint Contract (Lobster Pattern 2)

**Applies to**: dispatch-research (6 steps) and research-pro (8 steps). Stored in PROGRESS.md frontmatter.

### dispatch-research steps
`read-dispatch`, `update-progress-start`, `spawn-agent`, `collect-results`, `write-output`, `update-progress-final`

### research-pro steps (D3/D4)
`depth-route`, `promptforge`, `grillgate`, `scout-dispatch`, `critic`, `synthesis`, `quality-gate`, `distribution`

Schema: same as GENIE Contract 11 (Checkpoint). Validated by: `validate-contract.sh checkpoint`

---

## Contract 7: Approval Gate Contract (Lobster Pattern 1)

**Applies to**: D4 dispatch, VPS deploy, D4 Notion writes. Files at `~/.nexus/workspace/active/{task_id}/approval-{step_id}.json`.

Same schema as GENIE Contract 12 (Approval Gate). Validated by: `validate-contract.sh approval-gate`

---

## Contract Versioning

| Contract | Version | Last Updated | Compatible Skills |
|:---|:---:|:---:|:---|
| Scout | 1.0 | 2026-03-20 | scout-web, scout-social, scout-video, scout-visual, scout-knowledge, scout-deep, scout-finance, scout-brand, scout-domain |
| Critic | 1.0 | 2026-03-20 | critic |
| Synthesizer | 1.0 | 2026-03-20 | synthesizer |
| Store | 1.0 | 2026-03-20 | store-cortex, store-notion, store-vault |
| Reporter | 1.0 | 2026-03-20 | reporter |
| Checkpoint | 1.0 | 2026-03-28 | dispatch-research, research-pro |
| Approval Gate | 1.0 | 2026-03-28 | dispatch-research, reporter, store-notion |

---

## Contract 8: Orchestrator Join Contract (Critic -> Synthesizer)

**Applies to**: DELPHI PRO orchestrator (the join step between critic output and synthesizer input)

The Critic produces `evaluations[]` indexed by `finding_index`. The Synthesizer expects `curated_findings[]` with `quality_score` and `verdict`. The orchestrator performs the join.

### Join Logic

For each `evaluations[i]`:
1. Look up the original finding at `findings[evaluations[i].finding_index]`
2. Merge the finding fields with the evaluation fields
3. Map: `evaluations[i].average` -> `curated_findings[i].quality_score`
4. Copy: `evaluations[i].verdict` -> `curated_findings[i].verdict`
5. If `evaluations[i].tier_override` is non-null, replace `source_tier` with the override value
6. Filter: only pass findings where `verdict` is `INCLUDE` or `DEPRIORITIZE` (drop `EXCLUDE`)

### Field Mapping Table

| Critic Output (`evaluations[]`) | Synthesizer Input (`curated_findings[]`) | Transform |
|:---|:---|:---|
| `finding_index` | (used for join lookup, not passed) | Join key into `findings[]` |
| `findings[idx].source_url` | `source_url` | Direct copy |
| `findings[idx].source_tier` | `source_tier` | Copy, unless `tier_override` is non-null |
| `findings[idx].title` | `title` | Direct copy |
| `findings[idx].content_summary` | `content_summary` | Direct copy |
| `average` | `quality_score` | Rename |
| `verdict` | `verdict` | Direct copy |
| `reason` | (not passed to synthesizer) | Consumed by orchestrator logs |

### Resulting curated_findings[] Schema

```json
{
  "source_url": "https://example.com/...",
  "source_tier": "T1",
  "title": "Article Title",
  "content_summary": "Content preview...",
  "verdict": "INCLUDE",
  "quality_score": 0.83
}
```

### Validation

Orchestrator MUST verify:
- Every `finding_index` in evaluations maps to a valid entry in `findings[]`
- `quality_score` is a number between 0.0 and 1.0 (this is the per-finding average, NOT the EPR average)
- `verdict` is one of: `INCLUDE`, `DEPRIORITIZE` (EXCLUDE entries are dropped)
- `curated_findings` array length = `summary.included` + `summary.deprioritized`
- All `finding_index` values in evaluations resolve to valid indices in the original `findings[]` array (no out-of-bounds)

If validation fails, orchestrator MUST abort synthesizer dispatch with error: "Contract 8 join validation failed: {specific failure reason}". Do NOT pass malformed curated_findings to synthesizer.

---

## Contract 8b: Scout Contract Extended Notes

**scout-deep exception**: `content_summary` may be up to 1000 chars (extended from the 500-char base Scout contract limit). This reflects deep research reports which produce richer summaries. All consumers (critic, synthesizer, reporter) MUST handle both 500-char and 1000-char content_summary fields without truncation errors.
