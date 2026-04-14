# DELPHI PRO — Research Orchestrator Plugin

AI research orchestrator that decides depth (D1-D4), selects channels, spawns scouts, and delivers premium HTML reports.

## Quick Start

1. Copy this plugin directory to `~/.claude/plugins/delphi/`
2. Install Python dependencies: `pip install -r requirements.txt`
3. Copy `.env.example` to `~/.nexus/.env` and fill in API keys
4. Restart Claude Code

## Commands

- `/research-pro [topic]` — Auto-depth research (D1-D4)
- `/research-pro-deep [topic]` — Force D3+ deep research

## Architecture

- **9 scouts**: web, social, video, visual, knowledge, deep, finance, domain, brand
- **3 store skills**: cortex, notion, vault
- **3 processing**: critic, synthesizer, reporter
- **1 orchestrator**: delphi.md (Sonnet 4.6)

## API Keys Required

| Key | For | Where to get |
|-----|-----|-------------|
| OPENROUTER_API_KEY | Perplexity Sonar / Sonar Pro (via `skills/scout-web/cli/nexus-perplexity.py`) and OpenRouter fallback for direct-Perplexity calls | openrouter.ai |
| PERPLEXITY_API_KEY | Optional: direct Perplexity API (if present, `nexus-perplexity.py` uses it as primary path; OpenRouter is fallback) | perplexity.ai/settings/api |
| BRAVE_SEARCH_API_KEY | Brave web search | brave.com/search/api |
| NAMESILO_API_KEY | Domain availability checks | namesilo.com |
| APIFY_API_KEY | Instagram, Google Search scraping | apify.com |
| GROQ_API_KEY | YouTube Whisper transcription fallback | groq.com |
| NOTION_TOKEN | Notion page creation | notion.so/my-integrations |

## Reports

Research reports are generated as self-contained HTML files:
- **Tier 1** (D2): Quick report card — dark mode, EPR score, key findings
- **Tier 2** (D3): Full report — TOC sidebar, charts, dark/light toggle
- **Tier 3** (D4): Premium immersive — scrollytelling, animations, magazine quality

## OpenClaw Compatibility Notes

- **Skills** use `SKILL.md` — compatible with both Claude Code plugin format and OpenClaw conventions.
- **Agents** use `agents/delphi.md` — OpenClaw convention is `SOUL.md` for agents. If migrating to OpenClaw, rename `agents/delphi.md` to `agents/delphi/SOUL.md`.
- **Manifest**: `plugin.json` serves as both Claude Code and OpenClaw manifest. No separate `.openclaw.json` is needed — OpenClaw does not use a dedicated manifest file; it discovers skills via `SKILL.md` files directly.

## License

Private — NexusOS project.
