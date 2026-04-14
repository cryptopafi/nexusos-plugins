# Channel Research: X/Twitter Data Extraction (March 2026)

> Research date: 2026-03-20
> Purpose: Evaluate methods for DELPHI PRO scout-social to search and extract X/Twitter data

---

## 1. Official X API Status (March 2026)

### Pricing Tiers

| Tier | Cost | Read Limit | Write Limit | Search | Notes |
|------|------|-----------|-------------|--------|-------|
| **Free** | $0 | ~1 req/15min | 1,500 tweets/mo | NO search | Dev/testing only |
| **Basic** | $200/mo | 10K tweets/mo | 3K tweets/mo | Basic search | Small projects |
| **Pro** | $5,000/mo | 1M tweets/mo | 300K tweets/mo | Full-archive search, filtered stream | Production apps |
| **Enterprise** | $42K+/mo | Custom | Custom | Full access, SLA | Mission-critical |
| **Pay-As-You-Go** | Variable | 2M cap/mo | Variable | Per-request pricing | NEW Feb 2026 |

### New Pay-As-You-Go Model (Feb 6, 2026)

X announced consumption-based billing, similar to AWS/GCP:
- Buy credits upfront in Developer Console
- Different operations have different per-request costs (read, search, write)
- Monthly cap: 2M post reads
- Spend $200+/mo and get 10-20% back as xAI API credits
- Legacy free tier users get a one-time $10 voucher
- Basic and Pro fixed plans remain available as alternatives
- Developers can set max monthly spend caps

### Verdict for DELPHI PRO
- Free tier is **useless** (no search, severe limits)
- Basic ($200/mo) might work for light research but limited
- Pro ($5K/mo) is the real deal but expensive
- Pay-as-you-go is interesting but needs cost modeling
- **Not recommended as primary method** due to cost

---

## 2. Free Alternatives That WORK (March 2026)

### A. Twikit (RECOMMENDED - Top Pick for Free)

- **Repo**: https://github.com/d60/twikit
- **Status**: Actively maintained, last push 2026-03-10
- **Stars**: 4,151 | MIT License
- **Install**: `pip install twikit`
- **Python**: 3.10, 3.11, 3.12, 3.13
- **Requires**: Twitter account cookies (no API key)
- **Features**: Search tweets, post tweets, get trends, user profiles
- **Also**: `twikit_grok` extension for Grok AI integration

**Pros**: Free, no API key, actively maintained, good Python API
**Cons**: Requires Twitter account, subject to anti-bot detection, rate limits
**Risk**: Account suspension if aggressive scraping detected

### B. Twscrape

- **Repo**: https://github.com/vladkens/twscrape
- **Status**: Actively maintained (marked "2025!")
- **Features**: Search, user profiles, followers/following, tweets, retweeters, trends
- **Auth**: Supports cookies (more stable) or login/password
- **CLI**: Has command-line interface in addition to Python API
- **Install**: `pip install twscrape`

**Pros**: CLI + Python API, account pool support, async
**Cons**: Requires Twitter accounts, may break with X updates

### C. Snscrape (UNRELIABLE)

- **Repo**: https://github.com/JustAnotherArchivist/snscrape
- **Status**: Inconsistent/broken after X backend changes
- **Verdict**: NOT recommended for production. Some functionality with older pinned versions, but unreliable. Maintenance is inconsistent.

### D. Twint (DEAD)

- **Repo**: https://github.com/twintproject/twint
- **Status**: Dead for practical purposes
- **Verdict**: Do not use

### E. Apify Actors (RECOMMENDED - Paid but Reliable)

Top actors on Apify marketplace:

| Actor | Cost | Speed | Notes |
|-------|------|-------|-------|
| **Tweet Scraper V2** (apidojo) | $0.50/1K tweets | 30-80 tweets/sec | 26K+ users, most popular |
| **X.com Twitter API Scraper** (xtdata) | ~$0.50/1K | Good | Profile + tweet scraping |
| **Twitter Scraper Unlimited** (apidojo) | Variable | Good | No limits variant |
| **Scweet** (altimis) | Variable | Good | Search + profiles |

**Features**: Keyword search, hashtag search, user timelines, advanced filters, media extraction
**Output**: JSON, CSV, Excel, XML, HTML
**Pros**: Reliable, maintained by Apify team, scalable, API access
**Cons**: Costs money (though cheap per tweet), rate limits apply

---

## 3. Third-Party Twitter API Providers

These provide API endpoints that mirror official X API but at lower cost:

| Provider | Cost | Speed | Auth Required |
|----------|------|-------|---------------|
| **TwitterAPI.io** | $0.15/1K tweets | 1000+ req/sec | API key (theirs) |
| **SocialData.tools** | $0.20/1K tweets | Good | API key (theirs) |
| **Bright Data** | Variable | High | Account |

**TwitterAPI.io** is notable: drop-in replacement for official API, REST + WebSocket, real-time + historical data, no Twitter auth needed.

---

## 4. MCP Servers for X/Twitter

### Available MCP Servers

| Server | Repo | Method | Features |
|--------|------|--------|----------|
| **mcp-twikit** (adhikasp) | [github](https://github.com/adhikasp/mcp-twikit) | Twikit (no API key) | Search tweets, get timeline, rate limiting, markdown output |
| **twitter-mcp** (EnesCinr) | [github](https://github.com/EnesCinr/twitter-mcp) | Official API | Post + search tweets |
| **mcp-twitter-server** (crazyrabbitLTC) | [github](https://github.com/crazyrabbitLTC/mcp-twitter-server) | Official API v2 | Full CRUD, workflow automation |
| **twitter-mcp** (Dishant27) | [github](https://github.com/Dishant27/twitter-mcp) | Official API | CRUD operations, lists |
| **x-mcp** (lord-dubious) | [github](https://github.com/lord-dubious/x-mcp) | Unknown | Bridging Twitter + AI |
| **twitter-client-mcp** (mzkrasner) | [github](https://github.com/mzkrasner/twitter-client-mcp) | ElizaOS agent-twitter-client | Secure client integration |
| **x-mcp-server** (BioInfo) | [github](https://github.com/BioInfo/x-mcp-server) | Official API v2 | Post tweets + threads |

### Best for DELPHI PRO: `mcp-twikit`
- Uses twikit (no API key needed, free)
- Has search functionality built in
- Python-based, MIT license
- Lightweight, focused on data retrieval
- Dependencies: fastmcp, twikit, requests

---

## 5. CLI Tools

### pip-installable

| Tool | Install | Auth | Features |
|------|---------|------|----------|
| **twikit** | `pip install twikit` | Cookies | Search, post, profiles, trends |
| **twscrape** | `pip install twscrape` | Cookies/login | Search, profiles, followers, CLI built-in |
| **snscrape** | `pip install snscrape` | None (broken) | Was great, now unreliable |

### npm packages
- Most Twitter npm packages require official API keys
- No standout free npm CLI tools found

### Best CLI approach
```bash
# twscrape has native CLI
pip install twscrape
twscrape search "query" --limit 20
twscrape user_by_login "elonmusk"
twscrape tweet_details 123456789
```

---

## 6. Web Search Proxy Method

### Using `site:x.com` / `site:twitter.com` with search APIs

**Approach**: Use Brave Search, Tavily, or Exa with site-restricted queries.

```
site:x.com "artificial intelligence" since:2026-03-01
site:twitter.com/elonmusk "announcement"
```

**Effectiveness**:
- **Moderate** — web search engines index public tweets, but:
  - Not real-time (hours to days delay for indexing)
  - Limited to indexed tweets only (not comprehensive)
  - Cannot filter by engagement metrics
  - Cannot get full thread context
  - No structured data (must parse HTML snippets)
  - X has been blocking crawlers intermittently

**When useful**:
- Quick topic pulse check
- Finding viral/popular tweets (search engines favor popular content)
- Cross-referencing with other sources
- When no Twitter account is available

**Verdict**: Good as a fallback/supplement, NOT as primary method.

---

## 7. Nitter Instances (March 2026)

### Status: Effectively DEAD

- **Official project**: Discontinued February 2024
- **Reason**: X removed guest account feature that Nitter relied on
- **Remaining instances**: ~3 known (e.g., xcancel.com), but:
  - Reduced functionality compared to original
  - Guest accounts only work ~30 days
  - Require unique IP per account
  - Not reliable for production use

### Verdict
Do NOT rely on Nitter for any production workflow. It is dead as a reliable data source.

---

## 8. Rate Limits & Anti-Bot Measures

### X's Current Anti-Bot Stack (2026)
- **IP-based rate limiting**: Temporary blocks (30min-1hr) for excessive requests
- **Browser fingerprinting**: TLS and HTTP/2 fingerprint analysis
- **CAPTCHA challenges**: Triggered by suspicious patterns
- **Behavioral analysis**: X announced aggressive detection in Feb 2026 — "If a human is not tapping on the screen, the account and all associated accounts will likely be suspended"
- **Account linking**: Suspends all accounts associated with a flagged one

### Practical Limits
- Guest/unauthenticated: ~50 requests before blocks
- Authenticated (twikit/twscrape): Hundreds per session, but need rotation
- API (official): Documented per-endpoint limits

### Workarounds Used in Practice
1. **Account pools**: Multiple accounts with twscrape
2. **Rotating residential proxies**: Distribute requests across IPs
3. **Request throttling**: 1-3 second delays between requests
4. **Cookie rotation**: Fresh sessions periodically
5. **CAPTCHA solving services**: CapSolver, 2Captcha for blocks

### Recommendations for DELPHI PRO
- Use 2-3 second delays between requests minimum
- Rotate through 3-5 accounts
- Use residential proxies if available
- Implement exponential backoff on errors
- Stay under ~500 requests per account per day

---

## 9. X Search Operators (Advanced Search Syntax)

### Essential Operators

```
# Content filters
"exact phrase"          — Exact match
word1 OR word2          — Either term
word1 -word2            — Exclude term
#hashtag                — Hashtag search
$TSLA                   — Cashtag search

# User filters
from:username           — Tweets from user
to:username             — Replies to user
@username               — Mentioning user
filter:follows           — Only from people you follow

# Date filters
since:2026-03-01        — On or after date
until:2026-03-20        — Before date (not inclusive)
since:2026-03-01_00:00:00_UTC  — With time precision

# Engagement filters
min_retweets:100        — Minimum retweets
min_faves:500           — Minimum likes
min_replies:50          — Minimum replies
filter:has_engagement   — Has some engagement

# Media filters
filter:media            — Has images/videos
filter:images           — Has images
filter:videos           — Has videos
filter:links            — Contains URLs
filter:native_video     — Twitter-native video

# Type filters
filter:replies          — Only replies
-filter:replies         — Exclude replies
filter:quote            — Only quote tweets
filter:verified         — From verified accounts
filter:blue_verified    — From Blue subscribers

# Language
lang:en                 — English tweets
lang:es                 — Spanish tweets

# Location
near:"New York"         — Near location
within:15mi             — Within radius
geocode:lat,long,radius — Precise geo filter
```

### Example Queries for Research
```
"artificial intelligence" min_faves:100 lang:en since:2026-03-01 -filter:replies
from:elonmusk since:2026-01-01 until:2026-03-20
#AI OR #MachineLearning min_retweets:50 filter:links since:2026-03-01
"GPT-5" OR "Claude 4" min_faves:200 lang:en
```

---

## 10. Legal Considerations

### Key Court Rulings

- **X Corp v. Bright Data (2024)**: X lost. Judge ruled X "failed to plausibly allege" ToS violation for public data scraping. Noted X was "happy to allow extraction and copying of users' content so long as it gets paid."
- **Meta v. Bright Data (2024)**: Meta also lost on similar grounds.
- **hiQ v. LinkedIn (2022)**: Established that scraping publicly available data is not a CFAA violation.

### Legal Safe Zone
1. Only scrape **publicly available data** (accessible without login in incognito)
2. Do NOT create fake accounts to bypass restrictions
3. Do NOT bypass technical security measures (CAPTCHAs, etc.)
4. Do NOT scrape private/DM data
5. Respect `robots.txt` (though not legally binding, shows good faith)
6. Do NOT republish scraped data at scale (aggregation is fine)
7. Comply with GDPR/CCPA for personal data handling

### Gray Zone (Use with Caution)
- Using cookies from real accounts to scrape (technically logged-in access)
- Automated searching at scale (can trigger ToS violations)
- Using third-party proxy APIs (they assume legal risk)

### Verdict for DELPHI PRO
- **Safest**: Use official API or third-party providers (TwitterAPI.io, Apify)
- **Moderate risk**: Twikit/twscrape with real account credentials
- **Avoid**: Fake accounts, CAPTCHA bypassing, aggressive scraping

---

## 11. Recommendation for scout-social (Ranked)

### Tier 1: Primary Method (RECOMMENDED)

#### Option A: Twikit + mcp-twikit (FREE, Best for AI Agent)
```
Cost: $0
Reliability: 7/10 (can break with X updates)
Output: Python objects, JSON-serializable
Setup: pip install twikit, provide Twitter cookies
MCP: github.com/adhikasp/mcp-twikit
```
- Best free option for direct integration
- MCP server already exists
- Search + timeline + profile retrieval
- Risk: account suspension if aggressive

#### Option B: Apify Tweet Scraper V2 (PAID, Most Reliable)
```
Cost: ~$0.50/1K tweets ($15-50/mo for moderate use)
Reliability: 9/10
Output: JSON, CSV (structured, clean)
Setup: Apify API key, actor configuration
```
- Most reliable option overall
- Scalable, maintained by Apify team
- Already have Apify integration in DELPHI
- 30-80 tweets/sec throughput

### Tier 2: Supplementary Methods

#### Option C: TwitterAPI.io (PAID, API-Compatible)
```
Cost: $0.15/1K tweets
Reliability: 8/10
Output: JSON (mimics official API format)
Setup: API key from their service
```
- Drop-in replacement for official API endpoints
- No Twitter auth needed
- Good for high-volume needs

#### Option D: Web Search Proxy (FREE, Limited)
```
Cost: $0 (uses existing Brave/Exa credits)
Reliability: 5/10 for Twitter-specific queries
Output: Unstructured text snippets
Setup: site:x.com queries via existing search tools
```
- Good for quick pulse checks
- Not real-time, not comprehensive
- Use as fallback when other methods fail

### Tier 3: Backup/Advanced

#### Option E: Twscrape CLI (FREE, Technical)
```
Cost: $0
Reliability: 6/10
Output: JSON via CLI
Setup: pip install twscrape, add accounts with cookies
```
- Good CLI for one-off queries
- Account pool support for rotation
- Less maintained than twikit

#### Option F: Official X API Pay-As-You-Go (PAID, Official)
```
Cost: Variable (potentially $50-200/mo for research use)
Reliability: 10/10
Output: Official JSON format
Setup: X Developer account, credit purchase
```
- Most reliable and legal
- Full-archive search access
- Cost may be acceptable for specific high-value queries

---

## 12. Implementation Plan for scout-social

### Phase 1: Quick Win
1. Install `twikit` and `mcp-twikit`
2. Configure with a dedicated Twitter account's cookies
3. Implement search with 2-3 second delays
4. Parse results into DELPHI's standard format

### Phase 2: Reliability Layer
1. Add Apify Tweet Scraper V2 as fallback
2. Implement circuit breaker: twikit -> Apify -> web search proxy
3. Add account rotation (2-3 accounts for twikit)

### Phase 3: Production Hardening
1. Evaluate X API pay-as-you-go for critical queries
2. Implement result caching (tweets don't change often)
3. Add rate limit monitoring and adaptive throttling
4. Consider TwitterAPI.io for high-volume needs

### Data Schema (Unified Output)
```json
{
  "id": "tweet_id",
  "author": {"username": "...", "display_name": "...", "verified": true},
  "text": "full tweet text",
  "created_at": "ISO8601",
  "metrics": {"likes": 0, "retweets": 0, "replies": 0, "views": 0},
  "media": [{"type": "image|video", "url": "..."}],
  "urls": ["expanded URLs"],
  "hashtags": ["..."],
  "in_reply_to": "tweet_id or null",
  "quoted_tweet": "tweet_id or null",
  "source_method": "twikit|apify|api|websearch"
}
```

---

## Sources

- [X API Official Pricing](https://docs.x.com/x-api/getting-started/pricing)
- [X API Pay-Per-Use Announcement](https://devcommunity.x.com/t/announcing-the-x-api-pay-per-use-pricing-pilot/250253)
- [Twikit GitHub](https://github.com/d60/twikit)
- [Twscrape GitHub](https://github.com/vladkens/twscrape)
- [mcp-twikit GitHub](https://github.com/adhikasp/mcp-twikit)
- [Apify Tweet Scraper V2](https://apify.com/apidojo/tweet-scraper)
- [TwitterAPI.io](https://twitterapi.io/)
- [SocialData.tools](https://docs.socialdata.tools/)
- [X Advanced Search Operators](https://developer.x.com/en/docs/x-api/v1/rules-and-filtering/search-operators)
- [Twitter Search Operators Cheatsheet](https://www.exportdata.io/blog/advanced-twitter-search-operators/)
- [X Corp v. Bright Data Ruling](https://scrapecreators.com/blog/the-legality-of-scraping-twitter-what-you-need-to-know)
- [Nitter Wikipedia](https://en.wikipedia.org/wiki/Nitter)
- [Snscrape Status](https://snscrape.com/does-snscrape-still-work/)
