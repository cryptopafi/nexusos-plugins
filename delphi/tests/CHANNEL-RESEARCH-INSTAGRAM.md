# Instagram Data Extraction Research (March 2026)

**Purpose:** Evaluate all viable methods for DELPHI PRO's `scout-visual` agent to search and extract data from Instagram programmatically.

**Research Date:** 2026-03-20

---

## 1. Official API Status (2026)

### Instagram Basic Display API -- DEAD
- **Fully deprecated December 4, 2024.** All requests return errors.
- Personal account access via API is gone entirely.
- Source: [Meta Developer Blog](https://developers.facebook.com/blog/post/2024/09/04/update-on-instagram-basic-display-api/)

### Instagram Graph API -- Active but Limited
- Only supports **Business** and **Creator** accounts (not personal).
- Requires Meta App with approved permissions + Facebook Page linkage.
- **Rate limit: 200 calls/hour per Instagram account** (down from 5,000 -- a 96% reduction).
- Hashtag search: limited to **last 24 hours**, max **30 unique hashtags per 7-day window**.
- App review takes days to weeks.
- Good for: analyzing your **own** account insights (reach, impressions, engagement).
- Bad for: competitor analysis, public data at scale, hashtag exploration.
- Source: [Meta Graph API Docs](https://developers.facebook.com/docs/instagram-platform/instagram-graph-api/reference/ig-hashtag-search/)

### Verdict for DELPHI PRO
The official API is **not suitable** for a general research agent. It only accesses accounts you own/manage, has harsh rate limits, and requires business account setup per target. We need alternative approaches.

---

## 2. Free/Open-Source Tools That Work (March 2026)

### A. Instaloader (Python) -- WORKS with caveats
- **Package:** `pip install instaloader` (v4.15, Nov 2025)
- **GitHub:** [instaloader/instaloader](https://github.com/instaloader/instaloader)
- **Capabilities:** Download photos, videos, captions, metadata, profile info, hashtag posts, stories (with login)
- **Login required?** No for public profiles/hashtags. Yes for private profiles, stories, saved posts.
- **Rate limits:** ~1-2 requests per 30 seconds unauthenticated. Slightly better with login.
- **Risk:** Account security warnings, temporary locks, even permanent bans if aggressive.
- **Best practice:** Single instance, generous delays, use a throwaway account.
- **Verdict:** Best free Python tool, but fragile at scale. Good for small-batch extraction.

### B. instatouch (Node.js CLI) -- WORKS for public data
- **Package:** `npm install -g instatouch`
- **No login required** for public data
- **CLI commands** for scraping posts by username, hashtag, or location
- Source: [instatouch on npm](https://www.npmjs.com/package/instatouch)

### C. instagram-media-scraper (Node.js)
- **GitHub:** [ahmedrangel/instagram-media-scraper](https://github.com/ahmedrangel/instagram-media-scraper)
- Gets public info + media from post/reel URLs without API
- Confirmed working 2025

### D. @aduptive/instagram-scraper (TypeScript)
- Lightweight library for public profile scraping without auth
- Respects rate limits
- Source: [@aduptive/instagram-scraper on npm](https://www.npmjs.com/package/@aduptive/instagram-scraper)

### E. fast-instagram-scraper (Python)
- **GitHub:** [do-me/fast-instagram-scraper](https://github.com/do-me/fast-instagram-scraper)
- Accesses Instagram's JSON objects in batches of 50 (hashtags) or ~150 (locations)
- Uses Tor for IP rotation

### F. instagram-scraper (pip) -- LIKELY BROKEN
- The original `instagram-scraper` pip package is largely unmaintained and reported broken against current Instagram anti-bot systems. **Do not rely on it.**

---

## 3. Apify Actors -- BEST Managed Option

### Top Actors (March 2026)

| Actor | Users | What It Does |
|-------|-------|-------------|
| [Instagram Scraper](https://apify.com/apify/instagram-scraper) | 192K+ | Profiles, posts, comments, hashtags -- most comprehensive |
| [Instagram Profile Scraper](https://apify.com/apify/instagram-profile-scraper) | -- | Bio, followers, posts, related profiles |
| [Instagram Hashtag Scraper](https://apify.com/apify/instagram-hashtag-scraper) | -- | Posts + reels by hashtag |
| [Instagram Search Scraper](https://apify.com/apify/instagram-search-scraper) | -- | Search by keyword across profiles/hashtags |
| [Instagram API Scraper](https://apify.com/apify/instagram-api-scraper) | -- | Uses internal Instagram APIs |

### Key Details
- **Residential proxies required** -- datacenter IPs blocked instantly. Apify actors are pre-configured for this.
- **Cost:** Free tier gives some compute units; paid plans for volume.
- **Output:** JSON with full post metadata (caption, timestamp, likes, comments, location, media URLs).
- **Programmable:** Apify API lets you trigger actors programmatically -- ideal for DELPHI PRO integration.
- **Reliability:** Apify maintains scrapers when Instagram changes endpoints (every 2-4 weeks for doc_ids).

### Verdict
**Apify is the #1 recommended approach for DELPHI PRO.** It handles proxy rotation, anti-bot evasion, and endpoint maintenance. The Apify SDK/API allows programmatic triggering from our orchestrator.

---

## 4. MCP Servers for Instagram

Several MCP (Model Context Protocol) servers exist:

| Server | GitHub | Focus | Notes |
|--------|--------|-------|-------|
| **ig-mcp** | [jlbadano/ig-mcp](https://github.com/jlbadano/ig-mcp) | Full Business account management | Profile, posts, insights, publish, DMs |
| **instagram-engagement-mcp** | [Bob-lance/instagram-engagement-mcp](https://github.com/Bob-lance/instagram-engagement-mcp) | Analytics & leads | Comment analysis, demographics, engagement reports |
| **instagram-mcp (mcpware)** | [Glama listing](https://glama.ai/mcp/servers/mcpware/instagram-mcp) | 23 tools via Graph API | Posts, comments, DMs, stories, hashtags, reels, analytics |
| **instagram-server-next-mcp** | [duhlink/instagram-server-next-mcp](https://github.com/duhlink/instagram-server-next-mcp) | Post fetching | Uses Chrome's existing login session |
| **instagram_dm_mcp** | [trypeggy/instagram_dm_mcp](https://github.com/trypeggy/instagram_dm_mcp) | DMs only | Session management, instagrapi-based |
| **CData Instagram MCP** | [CDataSoftware](https://github.com/CDataSoftware/instagram-mcp-server-by-cdata) | Read-only queries | JDBC driver, Claude Desktop integration |
| **mcp-instagram** | [anand-kamble/mcp-instagram](https://github.com/anand-kamble/mcp-instagram) | AI assistant integration | General Instagram interaction |
| **Composio Instagram MCP** | [Composio](https://mcp.composio.dev/instagram) | Managed MCP | Composio platform integration |

### Verdict for DELPHI PRO
- **ig-mcp** and **instagram-mcp (mcpware)** are the most feature-rich.
- All require Instagram Business/Creator account + Graph API tokens.
- **Not suitable for general research** (searching arbitrary profiles/hashtags) -- they're designed for managing your own account.
- Could be useful if DELPHI PRO needs to **post** or **analyze own account**, but not for discovery/research.

---

## 5. Web Search Proxy (`site:instagram.com`)

### Approach
Use Brave Search, Tavily, or Exa with queries like:
```
site:instagram.com "topic keyword" OR #hashtag
```

### Effectiveness
- **Profile discovery:** Works moderately well. Search engines index public Instagram profiles and some posts.
- **Post content:** Very limited. Instagram renders content client-side (React/JS), so search engines only index basic metadata, profile bios, and some captions.
- **Hashtag pages:** Poorly indexed. Instagram's `/explore/tags/` pages are heavily dynamic.
- **Reels/Stories:** Not indexed at all.

### What You Get
- Profile names, bios, and sometimes recent post snippets
- Links to specific posts (but not the full content/engagement data)
- Basic existence verification ("does this account exist?")

### What You Don't Get
- Post engagement metrics (likes, comments, shares)
- Full captions (often truncated)
- Media content or detailed metadata
- Follower/following counts (not reliably indexed)

### Verdict
**Useful as a discovery/existence layer only.** Good for finding relevant profiles and posts to then scrape via Apify or Instaloader. Not a replacement for actual data extraction.

---

## 6. Hashtag Search Without API

### Can We Do It?
Yes, but with significant friction:

1. **Apify Instagram Hashtag Scraper** -- best option, handles anti-bot automatically.
2. **Instaloader** -- `instaloader "#hashtag"` works but rate-limited heavily.
3. **Instagram's internal GraphQL endpoints** -- undocumented, change `doc_id`s every 2-4 weeks, require residential proxies + TLS fingerprint spoofing.
4. **instatouch CLI** -- `instatouch hashtag <tag>` for public hashtag posts.
5. **fast-instagram-scraper** -- batches of 50 hashtag posts via JSON endpoints.

### Official API Hashtag Limits
- 30 unique hashtags per 7-day rolling window
- Only recent 24 hours of content
- Requires business account

### Verdict
Apify or Instaloader are the practical choices. Direct GraphQL scraping is possible but requires constant maintenance as endpoints rotate.

---

## 7. Profile Data Extraction

### What's Extractable (Public Profiles)
- Username, full name, bio, external URL
- Follower count, following count, post count
- Profile picture URL
- Whether account is verified, is business, is private
- Recent posts (caption, timestamp, media URLs, like count, comment count)
- Tagged location data on posts

### Best Methods (Ranked)
1. **Apify Instagram Profile Scraper** -- most reliable, handles anti-bot
2. **Instaloader** -- `instaloader profile <username>` with `--no-pictures` for metadata only
3. **@aduptive/instagram-scraper** -- lightweight TypeScript option
4. **Direct GraphQL** -- `https://www.instagram.com/api/v1/users/web_profile_info/?username=X` (requires proper headers + residential proxy)

---

## 8. Rate Limits & Anti-Bot Detection (2026 State)

### Instagram's 5-Layer Detection Stack
1. **IP Quality** -- datacenter IPs blocked before first request completes. ASN database cross-referencing.
2. **TLS Fingerprinting** -- Python `requests`/`httpx` have detectable TLS signatures. Must use `curl_cffi` to impersonate Chrome.
3. **Rate Limits** -- ~200 requests/hour per IP. ~100 profile views/hour safe. ~50 search queries/hour safe.
4. **Behavioral Analysis** -- Mouse movement entropy, session velocity, geographic consistency, request pattern analysis.
5. **GraphQL doc_id Rotation** -- Endpoint identifiers change every 2-4 weeks.

### 2025-2026 Escalations
- Meta integrated real-time threat intel, increasing IP intervention rates by 30%.
- 60+ signals analyzed per session (canvas rendering, WebGL, header order, etc.)
- Warm-up period of 5-7 days needed for new accounts/IPs before heavy use.

### Practical Safe Limits
| Action | Safe/hr | Aggressive/hr |
|--------|---------|---------------|
| Profile views | 100 | 200 |
| Post views | 200 | 400 |
| Search queries | 50 | 100 |
| Comment fetches | 100 | 200 |

### What Gets You Banned
- Datacenter IPs (instant ban)
- No delays between requests
- Multiple accounts per IP (max 1:1 for important accounts)
- Python `requests` library (detectable TLS fingerprint)
- Login from multiple geolocations rapidly
- Ignoring 429/checkpoint responses

---

## 9. Image/Video Content -- Captions Without Media Download

### Yes, You Can Extract Text Without Downloading Media

**What's available without downloading images/videos:**
- **Captions** (full text of the post)
- **Alt text** (Instagram's auto-generated or user-provided alt text, accessible in post metadata)
- **Hashtags and mentions** in captions
- **Location tags**
- **Tagged users**
- **Timestamps**
- **Engagement counts** (likes, comments, views, shares)
- **Comment text**
- **Reel transcripts** (via some tools)

**How:**
- Instaloader with `--no-pictures --no-videos` flag downloads only metadata/captions
- Apify actors return JSON with all text metadata; media URLs are included but you don't have to download them
- GraphQL endpoints return structured JSON with caption, alt_text, accessibility_caption fields

### What You Can't Get Without Media Download
- Visual content analysis (what's actually in the image)
- Audio transcription from reels (need to download video first)
- OCR of text overlaid on images/stories

---

## 10. Recommendation for scout-visual (Ranked)

### Tier 1: PRIMARY (Use These)

**1. Apify Instagram Scraper (via API)**
- **Why:** Most reliable, handles anti-bot, maintained by Apify team, programmable via API
- **Cost:** Free tier available, paid for volume (~$49/mo for moderate use)
- **Integration:** REST API -- trigger from DELPHI PRO orchestrator, get JSON results
- **Covers:** Profiles, posts, hashtags, search, comments, reels
- **Setup:** Create Apify account, get API token, call actor via HTTP

**2. Web Search Proxy (Brave/Tavily/Exa with `site:instagram.com`)**
- **Why:** Free, no auth needed, good for discovery
- **Cost:** Free (within existing search API quotas)
- **Integration:** Already available in DELPHI PRO's search tools
- **Covers:** Profile discovery, basic post snippets, existence checks
- **Limitation:** Surface-level data only, no engagement metrics

### Tier 2: SECONDARY (Fallback/Supplementary)

**3. Instaloader (Python, local)**
- **Why:** Free, open-source, good for targeted single-profile/hashtag extraction
- **Cost:** Free
- **Integration:** Python subprocess or library call
- **Risk:** Rate limiting, account bans, needs throwaway account for login features
- **Best for:** One-off deep dives on specific profiles

**4. MCP Server (ig-mcp or mcpware/instagram-mcp)**
- **Why:** Native MCP integration with Claude/agents
- **Limitation:** Requires own Business account + Graph API token, only for own-account data
- **Best for:** If DELPHI PRO ever needs to manage/post to an Instagram account

### Tier 3: AVOID for our use case

**5. Direct GraphQL scraping** -- High maintenance, breaks every 2-4 weeks
**6. Selenium/Playwright browser automation** -- Slow, detectable, resource-heavy
**7. instagram-scraper pip** -- Unmaintained, broken
**8. Paid scraping APIs (ScrapFly, Oxylabs, Bright Data)** -- Expensive, overkill if we have Apify

---

## Implementation Plan for DELPHI PRO

### Phase 1: Quick Win (Now)
```
# In scout-visual, add Instagram search via web proxy:
query = f'site:instagram.com {topic}'
results = brave_search(query)  # or tavily/exa
```
This gives immediate Instagram awareness with zero setup.

### Phase 2: Apify Integration
```python
# Trigger Apify Instagram Scraper actor
import requests

APIFY_TOKEN = "apify_api_xxx"
actor_id = "apify/instagram-scraper"

run = requests.post(
    f"https://api.apify.com/v2/acts/{actor_id}/runs",
    params={"token": APIFY_TOKEN},
    json={
        "search": "topic keyword",
        "searchType": "hashtag",  # or "user", "place"
        "resultsLimit": 20
    }
)
# Poll for results or use webhook
```

### Phase 3: Instaloader Fallback
```python
import instaloader
L = instaloader.Instaloader(
    download_pictures=False,
    download_videos=False,
    download_comments=True,
    save_metadata=True
)
# L.login("throwaway_user", "password")  # optional
profile = instaloader.Profile.from_username(L.context, "target_username")
# Access profile.biography, profile.mediacount, profile.followers, etc.
```

---

## Key Takeaways

1. **No free lunch.** Instagram is one of the hardest platforms to scrape in 2026. Every method has tradeoffs.
2. **Apify is the sweet spot** -- managed reliability without building anti-bot infrastructure.
3. **Web search proxy is free and immediate** -- but only for surface discovery.
4. **Residential proxies are non-negotiable** for any direct scraping at scale.
5. **Captions and metadata are extractable without downloading media** -- this is great for text-based research.
6. **MCP servers exist but are account-management focused**, not research/discovery focused.
7. **The official Graph API is too restrictive** for a general research agent.
8. **Python `requests` library is instantly detected** -- use `curl_cffi` if building custom scrapers.
9. **Rate limits are real** -- plan for ~100 requests/hour maximum for safe operation.
10. **Legal note:** Public data scraping is legal under US Ninth Circuit precedent, but violates Instagram TOS. Use responsibly.
