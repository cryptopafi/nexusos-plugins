# Integral E2E Test: scout-social + scout-video

**Date:** 2026-03-20
**Topic:** "AI research agents 2026"
**Runner:** Claude Opus 4.6

---

## scout-social Results

### 1. Reddit CLI
- **Command:** `reddit-search.sh --topic "AI research agents" --max 3`
- **Output:** `/tmp/reddit-integral.json`
- **Status:** PASS
- **Results:** 3 posts returned
- **Details:**
  - r/ChatGPT: "GPT-4 Week 3... AI Agents are the future" (score: 13168)
  - r/SideProject: "I built a virtual office where 8 AI agents show up to work" (score: 1030)
  - r/n8n: "I Built an AI Agent Army in n8n" (score: 1969)
- **Method:** json_api_fallback
- **Errors:** None

### 2. HackerNews CLI
- **Command:** `hn-search.sh --topic "AI research agents" --max 3`
- **Output:** `/tmp/hn-integral.json`
- **Status:** PASS
- **Results:** 3 stories returned (from 2149 total matches)
- **Details:**
  - "Prism AI - A research agent that generates 2D/3D visualizations" (2026-02-02)
  - "AI Market Research Agent" (2023-10-27)
  - "The rise of WORKING AI research agents: Andrej Karpathy" (2026-03-10)
- **Method:** Algolia HN Search API
- **Errors:** None

### 3. Bluesky (Public API)
- **Command:** `curl https://public.api.bsky.app/xrpc/app.bsky.feed.searchPosts?q=AI+research+agents&limit=3`
- **Status:** FAIL
- **Results:** 0 (HTTP 403 Forbidden)
- **Error:** Bluesky public API returned 403 Forbidden. The unauthenticated search endpoint appears to be blocked or rate-limited for this environment.
- **Note:** This is an external API limitation, not a scout-social bug. Auth-based access or a proxy may be required.

### 4. X/Twitter (Brave Web Search Proxy)
- **Command:** `brave_web_search "site:x.com AI research agents 2026" count:3`
- **Status:** FAIL (quota)
- **Results:** 0
- **Error:** Brave Search API rate limit exceeded
- **Note:** This is a quota/billing limitation on the Brave Search API key, not a logic error. The proxy approach is valid when quota is available.

### 5. LinkedIn (Brave Web Search Proxy)
- **Command:** `brave_web_search "site:linkedin.com AI research agents 2026" count:3`
- **Status:** FAIL (quota)
- **Results:** 0
- **Error:** Brave Search API rate limit exceeded
- **Note:** Same quota limitation as X/Twitter test above.

---

## scout-video Results

### 1. YouTube Search CLI
- **Command:** `youtube-search.sh --topic "AI research agents 2026" --max 3`
- **Output:** `/tmp/youtube-integral.json`
- **Status:** PASS
- **Results:** 3 videos returned, all with transcripts
- **Details:**
  | # | Title | Channel | Views | Duration | Transcript |
  |---|-------|---------|-------|----------|------------|
  | 1 | Top 6 AI Trends That Will Define 2026 | Jeff Su | 379,822 | 13:13 | Yes |
  | 2 | How I'm Using AI Agents in 2026 | Tech With Tim | 27,950 | 22:57 | Yes |
  | 3 | AI Trends 2026: Quantum, Agentic AI & Smarter Automation | IBM Technology | 368,695 | 11:39 | Yes |
- **Transcript method:** youtube-transcript-api (tier 1 of 3-tier fallback)
- **Errors:** None

### 2. YouTube Transcript (MCP tool)
- **Video tested:** B23W1gRT9eY, BikPUaT76i8, zt0JA5rxdfM
- **Status:** FAIL (all 3 videos)
- **Error:** `Cannot destructure property 'playerCaptionsTracklistRenderer' from null or undefined`
- **Note:** The MCP youtube-transcript tool is broken (likely a YouTube API change). However, the CLI's built-in transcript extraction via `youtube-transcript-api` Python package works correctly -- all 3 transcripts were successfully extracted by the CLI during the search step.

---

## Summary

| Test | Channel | Status | Results |
|------|---------|--------|---------|
| Reddit CLI | reddit | PASS | 3/3 |
| HackerNews CLI | hackernews | PASS | 3/3 |
| Bluesky API | bluesky | FAIL | 0 (403 Forbidden) |
| X/Twitter (Brave) | x.com | FAIL | 0 (rate limit) |
| LinkedIn (Brave) | linkedin | FAIL | 0 (rate limit) |
| YouTube Search CLI | youtube | PASS | 3/3 |
| YouTube Transcript (CLI) | youtube | PASS | 3/3 transcripts |
| YouTube Transcript (MCP) | youtube | FAIL | broken tool |

**Overall: 4 PASS / 4 FAIL**

### Key Findings

1. **Core CLI tools work reliably:** Reddit, HackerNews, and YouTube (search + transcript) all produce correct, well-structured JSON output with the expected number of results.

2. **Bluesky public API is blocked:** The unauthenticated `app.bsky.feed.searchPosts` endpoint returns 403. This may require authenticated access or a different approach (e.g., Brave search proxy when quota is available).

3. **Brave Search quota exhausted:** Both X/Twitter and LinkedIn proxy tests failed due to Brave API rate limits. These channels depend on having available Brave API quota.

4. **MCP youtube-transcript tool is broken:** The `youtube-transcript` MCP server fails on all tested videos with a JS destructuring error. The CLI's Python-based `youtube-transcript-api` works fine as a replacement.

### Recommendations

- Add Bluesky authenticated search or fallback to web search proxy
- Monitor Brave Search API quota; consider backup search provider (DuckDuckGo, Tavily)
- Do NOT rely on MCP youtube-transcript tool; CLI transcript extraction is the reliable path
- All `/tmp/*.json` output files validated and well-formed
