# Social Platform Data Access Research - March 2026

Research for Delphi AI scout-social agents. Covers current API status, rate limits, MCP servers, and practical recommendations for each platform.

---

## 1. REDDIT

### 1.1 Official API (PRAW)

**Status**: Active. Free tier still available for non-commercial use.

**Rate Limits (OAuth authenticated)**:
- 100 queries per minute (QPM) for free-tier apps (non-commercial, <100 QPM)
- 60 requests per minute baseline for authenticated OAuth clients
- 10-minute rolling window per OAuth client ID
- Rate limit headers returned on every response (`X-Ratelimit-Remaining`, `X-Ratelimit-Reset`)

**What Changed 2023-2026**:
- 2023: Reddit introduced paid API tiers ($0.24 per 1,000 API calls for commercial use)
- 2025: Reddit introduced **pre-approval requirements** for new apps — personal projects now need approval before getting API access
- PRAW remains maintained and handles auth + rate limiting automatically
- Free tier still works for research/non-commercial but Reddit is increasingly restrictive

**Getting Credentials**:
1. Create Reddit account
2. Go to https://www.reddit.com/prefs/apps
3. Create "script" type app (for personal use) or "web app" (for OAuth flow)
4. Note: Reddit may now require justification/approval before granting access

**PRAW Example**:
```python
import praw
reddit = praw.Reddit(
    client_id="YOUR_CLIENT_ID",
    client_secret="YOUR_SECRET",
    user_agent="scout-social/1.0 by YourUsername"
)
for submission in reddit.subreddit("artificial").search("LLM agents", limit=25):
    print(submission.title, submission.score, submission.num_comments)
```

### 1.2 JSON API Fallback (`.json` Trick)

**Status**: Still works as of March 2026. Append `.json` to any Reddit URL.

**Rate Limits (Unauthenticated)**:
- ~10 requests per minute for posts
- ~3-5 requests per minute for search endpoints
- Behavior is erratic and not well-documented
- **Must set a proper User-Agent** or you'll get rate-limited aggressively

**Example**:
```
https://old.reddit.com/r/MachineLearning/search.json?q=RAG&sort=new&restrict_sr=1&limit=25
```

**Pros**: No auth required, simple to use, works with `old.reddit.com` (lighter responses)
**Cons**: Very low rate limits, unreliable throttling behavior, no guarantee of continued support

**Recommendation**: Use as emergency fallback only. Primary path should be PRAW.

### 1.3 Search Operators & Subreddit Discovery

**Native Reddit Search Operators** (case-sensitive booleans):
- `cats AND dogs` — both terms required
- `cats OR dogs` — either term
- `cats NOT dogs` — exclude term
- `subreddit:MachineLearning` — restrict to subreddit
- `title:"review"` — search in title only
- `url:arxiv.org` — search by URL domain
- `author:username` — filter by author
- `self:yes` — self-posts only
- `nsfw:no` — exclude NSFW

**Combining Operators**:
```
subreddit:MachineLearning title:"RAG" (retrieval OR generation) NOT survey
```

**Sort Options**: `relevance`, `hot`, `top`, `new`, `comments`
**Time Filters**: `hour`, `day`, `week`, `month`, `year`, `all`

**Subreddit Discovery Techniques**:
1. Search Reddit main search, filter by "Communities"
2. Google: `site:reddit.com [keyword]` — surfaces top subreddits organically
3. `/r/findareddit` — dedicated discovery subreddit
4. Subreddit Stats (subredditstats.com) — growth/activity metrics
5. Anvaka's subreddit map (anvaka.github.io/map-of-reddit) — visual relationships
6. Check sidebars of known subreddits for "Related Communities"

### 1.4 Pushshift Status (2026)

**Status: Effectively dead for real-time ingestion.**

- Pushshift stopped real-time data collection after Reddit's 2023 API changes
- Historical archives (pre-2023) still accessible but no longer updated
- The Pushshift API itself is unreliable/offline for most queries

**Arctic Shift** — the primary replacement:
- GitHub: `ArthurHeitmann/arctic_shift`
- Provides: large data dumps, API, and web interface
- Data retrieved through Jan/Feb 2025 (subreddit metadata, rules, wikis)
- Web UI: https://arctic-shift.photon-reddit.com/
- Best for: historical research, bulk analysis, subreddit metadata
- NOT suitable for real-time monitoring

### 1.5 MCP Servers for Reddit

**Best Option: `reddit-mcp-buddy`** (karanb192)
- npm: `reddit-mcp-buddy`
- Stars: 436 | Last updated: March 2026
- **No API keys required** — uses Reddit's public endpoints
- Features: browse posts, search content, analyze users
- TypeScript, MIT license
- Install: `npx -y @smithery/cli install reddit-mcp-buddy --client claude`

Other options exist but reddit-mcp-buddy is the most maintained and popular.

### 1.6 Recommendation for scout-social

**Primary**: PRAW with OAuth credentials. 100 QPM is sufficient for research-grade scanning. Set up a proper app registration. PRAW handles rate limiting, pagination, and auth refresh automatically.

**Fallback**: `.json` endpoint for lightweight, no-auth checks (e.g., checking if a subreddit exists, sampling a few posts). Limit to 5 QPM to be safe.

**Historical**: Arctic Shift for any pre-2023 data needs.

**MCP**: reddit-mcp-buddy if running through Claude Desktop/Code workflows.

---

## 2. HACKER NEWS

### 2.1 Algolia API (HN Search)

**Status**: Active and well-maintained. This is the **primary search interface** for HN.

**Endpoint**: `https://hn.algolia.com/api/v1/`

**Rate Limits**:
- 10,000 requests per hour per IP (no auth needed)
- Max 1,000 hits per query
- Default `hitsPerPage`: 20 (configurable up to 1,000)
- No API key required for basic usage

**Key Endpoints**:
| Endpoint | Description |
|---|---|
| `search?query=RAG` | Full-text search (relevance-sorted) |
| `search_by_date?query=RAG` | Full-text search (date-sorted) |
| `search?tags=story&query=RAG` | Stories only |
| `search?tags=comment&query=RAG` | Comments only |
| `search?tags=ask_hn` | Ask HN posts |
| `search?tags=show_hn` | Show HN posts |

**Query Syntax** (Algolia standard):
- `query=foo bar` — AND by default
- `tags=story` — filter by type (story, comment, poll, job, ask_hn, show_hn, front_page)
- `tags=author_dang` — filter by author
- `numericFilters=points>100` — filter by points
- `numericFilters=num_comments>50` — filter by comment count
- `numericFilters=created_at_i>1709251200` — filter by Unix timestamp
- `hitsPerPage=50` — results per page
- `page=0` — pagination

**Example: High-signal AI agent posts from last 30 days**:
```
https://hn.algolia.com/api/v1/search_by_date?query=AI%20agents&tags=story&numericFilters=points>10,created_at_i>1708387200&hitsPerPage=50
```

### 2.2 Official HN API (Firebase)

**Status**: Active. Real-time data, no search capability.

**Base URL**: `https://hacker-news.firebaseio.com/v0/`

**Key Endpoints**:
| Endpoint | Returns |
|---|---|
| `/topstories.json` | Top 500 story IDs |
| `/newstories.json` | Newest 500 story IDs |
| `/beststories.json` | Best 500 story IDs |
| `/askstories.json` | Ask HN story IDs |
| `/showstories.json` | Show HN story IDs |
| `/jobstories.json` | Job story IDs |
| `/item/{id}.json` | Single item (story, comment, etc.) |
| `/user/{id}.json` | User profile |
| `/updates.json` | Changed items and profiles |

**Rate Limits**: No documented hard limits, but Firebase has implicit limits. Be reasonable.

**When to Use Firebase vs Algolia**:
- **Algolia**: Search by keyword, filter by points/date/type, bulk discovery
- **Firebase**: Real-time monitoring (top stories, new stories), fetching specific items by ID, getting full comment trees

### 2.3 Search Operators & Filtering

**By Date**: Use `search_by_date` endpoint + `numericFilters=created_at_i>UNIX_TIMESTAMP`
**By Points**: `numericFilters=points>50`
**By Comments**: `numericFilters=num_comments>20`
**By Author**: `tags=author_USERNAME`
**By Type**: `tags=story` or `tags=comment`
**Combined**: Multiple numericFilters separated by commas

**Pro Tip**: For date range queries, combine `created_at_i>START` and `created_at_i<END`.

### 2.4 MCP Servers for HN

Several well-maintained options:

1. **`hn-mcp`** (karanb192) — Same author as reddit-mcp-buddy
   - Stars: actively maintained, last push March 2026
   - 50MB LRU cache with adaptive TTLs
   - No API keys required
   - Install: `npx -y @smithery/cli install @karanb192/hn-mcp --client claude`

2. **`Hackernews_mcp`** (sam3690) — Uses HN Algolia API
   - Powered by SpecKit, Node.js & TypeScript
   - Search stories, retrieve comments, access user profiles

3. **`mcp-claude-hackernews`** (imprvhub) — 5 tools
   - `hn_latest`, `hn_top`, `hn_best`, `hn_story`, `hn_comments`

4. **`claude_skill_hn_mcp_server`** (az9713) — 9 tools
   - Built with Claude skill mcp-builder

### 2.5 Recommendation for scout-social

**Primary**: Algolia API directly. 10,000 requests/hour with no auth is extremely generous. Use `search_by_date` for chronological scanning, `search` for relevance. Filter with `numericFilters=points>5` to cut noise.

**Real-time**: Firebase API for monitoring current front page, new stories.

**MCP**: `hn-mcp` by karanb192 if integrating with Claude workflows.

**No authentication, no cost, no approval process.** HN is the easiest platform to integrate.

---

## 3. BLUESKY

### 3.1 AT Protocol API

**Status**: Fully open, actively developed, generous limits.

**Authentication**:
- Many endpoints work WITHOUT auth via `https://public.api.bsky.app`
- For authenticated requests: call `com.atproto.server.createSession` with handle + app password
- Returns `accessJwt` (short-lived) and `refreshJwt` (long-lived)
- Use `accessJwt` as Bearer token in Authorization header

**Rate Limits (Bluesky PDS)**:
| Resource | Limit |
|---|---|
| Overall API requests (all endpoints) | 3,000 per 5 minutes (by IP) |
| Session creation | 30 per 5 min / 300 per day (per account) |
| Content write operations | 5,000 points/hour, 35,000 points/day |
| CREATE record | 3 points |
| UPDATE record | 2 points |
| DELETE record | 1 point |

**Public API (unauthenticated)**: `https://public.api.bsky.app` — "generous rate limits" per Bluesky docs. No auth needed. Cached responses.

### 3.2 CLI Tools

**`goat`** — Official Bluesky CLI (Go)
- GitHub: `bluesky-social/goat` (160 stars)
- Install: `brew install goat`
- Features: fetch `at://` URIs, firehose monitoring, account management, lexicon development
- Most commands work without auth
- Latest release: v0.2.2 (Jan 2026)

**Python SDKs**:
- `atproto` (Python AT Protocol SDK) — mature, well-documented
- `atprototools` (ianklatzco) — simpler, ergonomic wrapper

**Go SDK**: `bluesky-social/indigo` — full Go implementation with services (relay, tap, palomar search)

### 3.3 Search Capabilities

**YES — Full keyword search is available.**

**Endpoint**: `app.bsky.feed.searchPosts`
```
GET https://public.api.bsky.app/xrpc/app.bsky.feed.searchPosts?q=AI+agents&limit=25
```

**No auth required for search.** Supports CORS (client-side apps work).

**Parameters**:
| Parameter | Description |
|---|---|
| `q` (required) | Search query string (Lucene syntax) |
| `limit` | Results per page (max 100) |
| `cursor` | Pagination cursor |
| `sort` | `top` or `latest` |
| `since` | Filter posts after date (ISO format) |
| `until` | Filter posts before date (ISO format) |
| `author` | Filter by handle or DID |
| `domain` | Filter posts with URLs from domain |
| `lang` | Filter by post language |

**Example**:
```
https://public.api.bsky.app/xrpc/app.bsky.feed.searchPosts?q=%22retrieval%20augmented%22&sort=latest&limit=50
```

**Also available**: `app.bsky.actor.searchActors` for finding users by keyword.

### 3.4 MCP Servers for Bluesky

**`bluesky-mcp`** (semioz)
- Listed on mcpservers.org
- Features: posting, liking, reposting, timeline management, profile operations
- Install: `npx -y @smithery/cli install @semioz/bluesky-mcp --client claude`
- Requires: `BLUESKY_IDENTIFIER` and `BLUESKY_PASSWORD` env vars
- Auto-login on startup

### 3.5 Recommendation for scout-social

**Primary**: Direct HTTP calls to `public.api.bsky.app`. No auth needed for search. Use `app.bsky.feed.searchPosts` with `sort=latest` for chronological scanning. The API is clean, well-documented, and has generous limits.

**Firehose**: For real-time monitoring, use the Jetstream service (`bluesky-social/jetstream`) — simplified JSON event stream. Or `goat firehose` for CLI access.

**MCP**: `bluesky-mcp` by semioz for Claude integration.

**Bluesky is the most developer-friendly platform of the four.** Open protocol, no API keys for read, generous limits, full search.

---

## 4. LINKEDIN

### 4.1 Official API

**Status**: Extremely restricted without partnership approval.

**What's Available Without Partnership**:
- **Sign In with LinkedIn (OpenID Connect)**: OAuth login flow, get basic profile of the authenticated user
- **Share on LinkedIn API**: Post content on behalf of authenticated users
- **Marketing/Advertising API**: Manage ad campaigns, conversion tracking (requires approved marketing developer app)
- **Community Management API**: Create posts (text, image, video, carousel, polls) on behalf of organizations

**What Requires Partnership** (not available to general developers):
- Profile search / lookup of other users
- Company search / company data enrichment
- People search by name/title/company
- Job posting data
- Skills, endorsements, recommendations
- Network graph / connections data

**Bottom Line**: LinkedIn's official API only lets you read the **authenticated user's own profile**. You cannot search for or access other people's data. For research/scouting purposes, the official API is nearly useless.

### 4.2 Scraping Reality 2026

**Proxycurl**: Dead. LinkedIn sued them (Jan 2026) for creating hundreds of thousands of fake accounts. Shut down July 2026 (upcoming).

**Legal Landscape**:
- LinkedIn aggressively litigates scrapers (Proxycurl, ProAPIs both sued)
- `hiQ v. LinkedIn` (Supreme Court) was scrapped/remanded — no clear legal precedent protecting scrapers
- Scraping *public* data (viewable without login) is in a legal gray area
- Scraping data behind login **clearly violates** LinkedIn ToS and risks CFAA claims
- GDPR/CCPA treat scraped personal data as "processing" — compliance obligations apply

**What Still Works (with caveats)**:
1. **Bright Data**: Industry leader, has defended scraping in U.S. courts (2024). Offers LinkedIn Scraper API, Profile Scraper, Company Scraper. Most legally defensible option.
2. **Netrows**: 48+ LinkedIn endpoints — profiles, companies, jobs, posts. Real-time monitoring with webhooks.
3. **ScrapIn / Scrapin.io**: Profile data extraction, focuses on public data.
4. **Scrapingdog**: Public profile extraction without cookies/accounts.

### 4.3 Apify Actors

Several LinkedIn actors available on Apify Store:

| Actor | What It Does | Cost |
|---|---|---|
| `supreme_coder/linkedin-profile-scraper` | Full profiles (work, education, skills) | $3 per 1K profiles |
| `curious_coder/linkedin-profile-scraper` | Profile extraction | Variable |
| `curious_coder/linkedin-post-search-scraper` | Post search/scraping | Variable |
| `fetchclub/linkedin-jobs-scraper` | Job listings | $19.99/month |
| `harvestapi/linkedin-profile-search` | People search | $0.10/page + $0.004/profile |
| `bebity/linkedin-premium-actor` | Bulk profiles & companies | Pay per result |

**Platform Pricing**: Apify free tier: 30 seconds/month compute. Paid plans from $49/month. Actor rental fees are separate.

**Reliability Warning**: LinkedIn constantly updates anti-scraping measures. Any actor can break at any time. Budget for maintenance and fallback strategies.

### 4.4 Legal Risks

**HIGH RISK. Be explicit about this.**

- LinkedIn actively sues scrapers (budget: Microsoft-backed legal team)
- Creating fake accounts = federal fraud risk
- Using real account for automated scraping = account ban + ToS violation
- GDPR: scraping EU resident data without consent = potential fines
- No clear "safe harbor" for research scraping post-hiQ

**Risk Mitigation**:
- Only scrape publicly visible data (no login required)
- Use established providers (Bright Data) who have legal precedent
- Never create fake accounts
- Implement data retention/deletion policies
- Document legitimate research purpose

### 4.5 Web Search Proxy

**`site:linkedin.com` via search engines** — the safest approach for research:

```
site:linkedin.com/in/ "machine learning" "San Francisco"
site:linkedin.com/company/ "AI startup" "series A"
site:linkedin.com/pulse/ "RAG" "retrieval augmented generation"
```

**Effectiveness**:
- Brave, Google, Bing all index LinkedIn public profiles
- Returns profile snippets (name, title, company, location)
- Limited to what's publicly indexed (not all profiles)
- No rate limit concerns (you're querying the search engine, not LinkedIn)
- Completely legal
- Cannot get full profile data, just search-result-level snippets

**Best For**: Discovery (who's talking about X topic), not data extraction.

### 4.6 MCP Servers for LinkedIn

1. **`linkedin-mcp-server`** (stickerdaniel)
   - Uses Patchright (Playwright fork) with persistent browser profiles
   - Can scrape profiles, companies, jobs, perform searches
   - Requires: `uv` and `uvx patchright install chromium`
   - **Risk**: Uses browser automation = fragile + ToS violation

2. **`mcp-linkedin`** (timkulbaev)
   - Wraps Unipile API for posting, commenting, reactions
   - More focused on content creation than data extraction

3. **LinkedIn Ads MCP** (danielpopamd)
   - For advertising data analysis only

### 4.7 Recommendation for scout-social (Honest Assessment)

**LinkedIn is the hardest platform to access programmatically.** There is no good, legal, reliable, cheap solution.

**Recommended Approach (tiered)**:

1. **Tier 1 — Safe & Free**: Web search proxy (`site:linkedin.com` via Brave/Google). Good for discovery, bad for structured data.

2. **Tier 2 — Paid & Semi-reliable**: Apify actors for specific, targeted scraping needs. Budget $50-100/month. Accept that actors break regularly.

3. **Tier 3 — Enterprise**: Bright Data or Netrows for production-grade LinkedIn data. More expensive but legally defensible and maintained.

4. **Avoid**: Building custom scrapers, creating fake accounts, using free/untested tools.

**For scout-social specifically**: Start with Tier 1 (search proxy) for discovery. Escalate to Tier 2 only when you need structured profile data for specific leads. Keep LinkedIn integration as "best-effort" — do not make it a critical dependency.

---

## Summary Comparison

| Feature | Reddit | HackerNews | Bluesky | LinkedIn |
|---|---|---|---|---|
| **Auth Required** | Yes (OAuth) | No | No (for search) | N/A (no useful API) |
| **Rate Limit** | 100 QPM | 10K/hour | 3K/5min | Varies by scraper |
| **Search Quality** | Decent | Excellent | Good | Via web proxy only |
| **Cost** | Free (non-commercial) | Free | Free | $0-100+/month |
| **Legal Risk** | Low | None | None | High |
| **MCP Server** | reddit-mcp-buddy | hn-mcp | bluesky-mcp | linkedin-mcp-server |
| **Best For** | Community sentiment | Tech signal | Real-time tech discourse | Professional discovery |
| **Integration Difficulty** | Medium | Easy | Easy | Hard |

## Implementation Priority for scout-social

1. **HackerNews** — Start here. Zero friction, excellent search, high signal-to-noise.
2. **Bluesky** — Second priority. Open API, no auth for search, growing tech community.
3. **Reddit** — Third. Requires OAuth setup, but massive breadth of communities.
4. **LinkedIn** — Last and lowest priority. Use search proxy only unless specific use case demands it.

---

*Research conducted: 2026-03-20*
*Sources: Brave Search, Exa, WebSearch, official API documentation*
