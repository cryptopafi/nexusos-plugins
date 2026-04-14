# Publish-Social Skill Research Report

**Date:** 2026-03-21
**Purpose:** Comprehensive research for building a `publish-social` skill in DELPHI PRO that can WRITE to social platforms
**Status:** Complete

---

## Table of Contents

1. [Tools & APIs Per Platform](#1-tools--apis-per-platform)
2. [Legal & Compliance](#2-legal--compliance)
3. [Best Practices](#3-best-practices-for-automated-social-posting)
4. [Use Cases for a Research Agent](#4-use-cases-for-a-research-agent)
5. [Architecture Patterns](#5-architecture-patterns)
6. [Existing Solutions & Competitors](#6-existing-solutions--competitors)
7. [Recommendations for DELPHI PRO](#7-recommendations-for-delphi-pro)

---

## 1. Tools & APIs Per Platform

### Reddit

| Aspect | Detail |
|--------|--------|
| **Best Tool** | PRAW (Python Reddit API Wrapper) |
| **Write Method** | `subreddit.submit(title, selftext=...)` or `subreddit.submit(title, url=...)` |
| **Cost** | Free for personal bots at <=100 requests/minute |
| **Auth** | OAuth2 required (cookie-based auth deprecated) |
| **Status (2026)** | PRAW still works. Reddit now requires agreement to Responsible Builder Policy before API access. Personal/research projects approved in days; commercial use may take weeks or be denied |
| **Rate Limits** | 100 requests/minute for OAuth clients; PRAW handles rate limiting automatically |
| **Bot Rules** | Must identify as bot in user-agent. Subreddit-specific rules vary. Avoid spamming popular subreddits. Many subreddits require minimum account age/karma. r/botwatch monitors bot behavior |
| **Key Risk** | Reddit API access is more restricted since 2023 pricing changes. Pre-approval now required for all new apps. Some endpoints may be blocked for new developers |

**Code pattern:**
```python
import praw
reddit = praw.Reddit(client_id="...", client_secret="...", user_agent="delphi-research-bot/1.0", username="...", password="...")
submission = reddit.subreddit("test").submit("Research Question", selftext="Body text here")
```

### X / Twitter

| Aspect | Detail |
|--------|--------|
| **Official API** | X API v2 with tiered pricing |
| **Unofficial** | twikit library (free, no API key, uses internal Twitter API) |
| **Cost (Official)** | Free tier: 1,500 tweets/month write-only. Basic: $200/month (50K writes). Pro: $5,000/month (1M tweets). Enterprise: $42,000+/month |
| **New Model (Feb 2026)** | Pay-per-use pricing launched. New developers can ONLY use pay-per-use; legacy tiers grandfathered |
| **Rate Limits** | Free: ~17 tweets/day. Basic: ~1,667/day. Per-endpoint limits vary |
| **MCP Server** | `adhikasp/mcp-twikit` - MCP server using twikit for Twitter interaction |

**twikit (unofficial, free):**
```python
from twikit import Client
client = Client('en-US')
await client.login(auth_info_1='username', password='password')
await client.create_tweet('Hello from DELPHI!')
```

**Official API v2:**
```python
import tweepy
client = tweepy.Client(bearer_token="...", consumer_key="...", consumer_secret="...", access_token="...", access_token_secret="...")
client.create_tweet(text="Hello from DELPHI!")
```

**Risk Assessment:**
- twikit uses unofficial API -- account suspension risk if detected as bot
- Official Free tier severely limited but sufficient for occasional research sharing
- Pay-per-use model may be cost-effective for low-volume posting

### Bluesky

| Aspect | Detail |
|--------|--------|
| **Best Tool** | AT Protocol SDK (`atproto` Python package) |
| **Write Method** | `client.send_post(text="...")` |
| **Cost** | Completely FREE. No paid tiers for API access |
| **Auth** | App passwords (simple) or OAuth2 |
| **Rate Limits** | 5,000 points/hour, 35,000 points/day per account (DID). createRecord costs 3 points each. Practical: ~1,667 posts/hour, ~11,667 posts/day |
| **Platform Size** | 41.4M users as of end 2025, growing 60% YoY. 1.41 billion posts in 2025 |
| **Bot Policy** | Friendly to bots. Official bot starter templates provided. Must respect opt-in for user interactions. Authenticate once per session, persist session tokens |

**Code pattern:**
```python
from atproto import Client
client = Client()
client.login('handle.bsky.social', 'app-password')
post = client.send_post(text='Research finding: ...')
```

**VERDICT: Best platform for automated posting. Free, generous limits, bot-friendly, growing fast.**

### LinkedIn

| Aspect | Detail |
|--------|--------|
| **Official API** | Pages API for company pages (approved partners only). No personal profile posting API |
| **Third-party** | All automation tools violate ToS unless built on official API |
| **Legal Status** | ToS explicitly prohibits scraping, crawling, and automated access. hiQ v. LinkedIn (2022) ruled public data scraping not CFAA violation, but ToS enforcement is separate |
| **Enforcement** | LinkedIn removes comments posted through third-party scripts from "Most Relevant" section. Repeat offenders face account restrictions |
| **Workarounds** | Buffer, Hootsuite, Later all support LinkedIn posting through official API partnerships |
| **Risk** | HIGH. Personal account automation carries significant ban risk |

**VERDICT: Avoid direct API integration. Use official partner tools (Buffer API) if LinkedIn posting is needed.**

### Hacker News

| Aspect | Detail |
|--------|--------|
| **Official API** | READ-ONLY. Firebase API at `hacker-news.firebaseio.com/v0/` |
| **Write Access** | No official write API. Posting requires web scraping: login, extract CSRF token (FNID), POST to submission endpoint |
| **Rules** | Automated submission explicitly discouraged. HN has aggressive anti-spam measures. Accounts need karma to submit |
| **Rate Limits** | Implicit -- too-frequent posting triggers detection |
| **Detection** | HN uses behavior analysis; bot submissions are often flagged and killed |

**VERDICT: Not recommended for automated posting. Read-only API only. Manual submission or very careful web automation with human oversight.**

### Instagram

| Aspect | Detail |
|--------|--------|
| **Official API** | Meta Graph API (Instagram Content Publishing API) |
| **Requirements** | Business or Creator account + linked Facebook Page + Meta Developer App with approved permissions (`instagram_business_content_publish`) |
| **Approval Process** | App review required with screencasts; takes 2-4 weeks |
| **Supported Content** | Images, carousels, Reels, Stories (added late 2025) |
| **Rate Limits** | Reduced from 5,000 to 200 API calls/hour. ~25 posts/day |
| **Cost** | Free (API access), but requires business account setup |
| **Restrictions** | Publishing automation allowed. Engagement automation (auto-likes, auto-follows, auto-comments) strictly banned |

**VERDICT: Possible but heavy setup. Only viable if DELPHI needs visual content distribution. Not a priority for text-based research sharing.**

### YouTube

| Aspect | Detail |
|--------|--------|
| **Comments API** | YouTube Data API v3 supports posting comments via OAuth2 |
| **Community Posts** | NO API for creating community posts. Read-only via scraping |
| **Quota** | 10,000 units/day. Comment insert costs ~50 units. ~200 comments/day |
| **Cost** | Free within quota limits |
| **Risk** | Comment spam detection is aggressive. Automated comments easily flagged |

**VERDICT: Comment posting technically possible but high risk of spam flagging. Community posts not available via API. Low priority.**

---

## 2. Legal & Compliance

### FTC Disclosure Requirements (United States)

**Current Rules (2025-2026):**
- FTC updated Endorsement Guides in 2023 to explicitly cover AI-generated content
- **"Double Disclosure" requirement**: If content is both sponsored AND AI-generated, BOTH must be disclosed
- Penalties: Up to $53,088 per violation
- AI-generated text, images, videos, and translations in advertising all require disclosure
- March 2025 FTC staff guidance emphasized transparency for AI-generated endorsements
- Operation AI Comply (2024) actively targets deceptive AI content

**What This Means for DELPHI:**
- All automated posts SHOULD disclose AI involvement
- Recommended footer: "Generated with AI assistance" or similar
- If sharing research that could be construed as endorsement/promotion, explicit disclosure required
- Non-commercial research sharing has lower risk but disclosure is still best practice

**State Laws:**
- New York AI disclosure law (effective June 2026): Mandates proximity-based disclosures for AI-generated content targeting NY residents

### EU AI Act Requirements

**Timeline:**
- Transparency obligations under Article 50 become applicable **August 2, 2026**
- Code of Practice on marking/labeling AI-generated content expected finalized May-June 2026

**Requirements:**
- Providers of generative AI systems must mark outputs in **machine-readable format** and make them detectable as AI-generated
- Deployers must disclose when AI creates synthetic content, including deepfakes
- Multi-layered approach: labeling icon must be clear at "first exposure"
- For text: machine-readable watermarking + human-visible disclosure

**What This Means for DELPHI:**
- Posts to platforms used by EU citizens should include AI disclosure
- Machine-readable metadata should be embedded where possible
- Watermarking standards still being finalized; monitor Code of Practice

### Platform-Specific ToS Analysis

| Platform | Bots Allowed? | Disclosure Required? | Key Risk |
|----------|--------------|---------------------|----------|
| Reddit | Yes, with rules | Bot user-agent required | Subreddit bans, shadowban |
| X/Twitter | Yes (official API) | Not explicitly, but recommended | Account suspension if using unofficial API |
| Bluesky | Yes, encouraged | Community norm | Minimal risk |
| LinkedIn | No (personal) | N/A | Account ban, legal action |
| HN | No | N/A | Post killed, account flagged |
| Instagram | Yes (official API) | Business accounts have ad disclosure rules | Shadowban if using unofficial methods |
| YouTube | Yes (comments API) | Recommended | Comment removed, channel strike |

### Account Suspension Risk Mitigation

1. **Use official APIs** wherever possible
2. **Respect rate limits** -- stay well below maximums (use 50-70% of limits)
3. **Implement exponential backoff** on rate limit errors
4. **Use dedicated bot accounts** -- never automate a personal account
5. **Include clear bot identification** in user-agent and profile
6. **Human-in-the-loop** approval before posting to high-risk platforms
7. **Keep logs** of all automated posts for compliance audit trail

---

## 3. Best Practices for Automated Social Posting

### Rate Limits Summary Table

| Platform | Posts/Hour | Posts/Day | API Calls/Hour | Notes |
|----------|-----------|-----------|----------------|-------|
| Reddit | ~10 (practical) | ~100 | 6,000 | Per-subreddit cooldowns apply |
| X (Free) | 1 | 17 | Very limited | Write-only on free tier |
| X (Basic) | 70 | 1,667 | Higher | $200/month |
| Bluesky | ~1,667 | ~11,667 | 5,000 pts/hr | Most generous |
| LinkedIn | N/A | N/A | N/A | Via partner tools only |
| Instagram | ~8 | ~25 | 200/hr | Business accounts only |
| YouTube | ~8 | ~200 | Quota-based | Comments only |

### Content Authenticity

**Should AI posts disclose they are AI-generated?**

**YES.** For multiple reasons:
1. Legal requirement in many jurisdictions (FTC, EU AI Act by Aug 2026)
2. Platform communities increasingly expect transparency
3. Builds trust -- research shared transparently is more credible
4. Avoids deceptive practice accusations
5. Reddit specifically penalizes undisclosed bots

**Recommended Disclosure Patterns:**
```
[Post content]

---
Generated by DELPHI Research Agent | AI-assisted analysis
```

### Anti-Spam Patterns to AVOID

1. **Identical cross-posts** -- Adapt content per platform
2. **Exact scheduling intervals** -- Randomize timing (e.g., not every 6 hours exactly)
3. **Bulk posting** -- Space posts out, max 2-3 per platform per day for research
4. **Link-only posts** -- Always include context/summary with links
5. **Repetitive hashtags** -- Vary hashtags and keywords
6. **Posting to irrelevant communities** -- Target only relevant subreddits/threads
7. **No engagement** -- Respond to comments/replies on your posts

### Timing and Frequency Recommendations

| Platform | Best Times (UTC) | Recommended Frequency |
|----------|-----------------|----------------------|
| Reddit | 13:00-15:00 weekdays | 1-2 posts/day max across all subreddits |
| X/Twitter | 12:00-15:00 weekdays | 3-5 tweets/day (mix of original + replies) |
| Bluesky | 14:00-17:00 weekdays | 2-4 posts/day |
| LinkedIn | 07:00-09:00, 17:00-18:00 weekdays | 1 post/day max (via partner tool) |

### Engagement vs. Broadcasting

**Broadcasting (post and forget):** Lower risk, lower impact, easier to automate
**Engagement (reply, discuss):** Higher impact, higher risk, requires more intelligence

**Recommendation for DELPHI:** Start with broadcasting (sharing research findings), graduate to engagement (replying to relevant discussions) once the system is proven reliable.

---

## 4. Use Cases for a Research Agent

### Tier 1: Low Risk, High Value (Implement First)

#### A. Report Sharing
- Post research summaries to Bluesky and X with link to full report
- Auto-generate platform-specific summaries (280 chars for X, longer for Bluesky/Reddit)
- Include relevant hashtags and mentions

#### B. Signal Amplification
- Share interesting findings on Bluesky for visibility in tech/research community
- Cross-post to X for broader reach
- Track engagement to measure research impact

### Tier 2: Medium Risk, High Value

#### C. Community Engagement
- Reply to relevant Reddit threads with research findings (human approval required)
- Comment on relevant HN discussions with insights (manual posting recommended)
- Engage with Bluesky threads where research is relevant

#### D. Primary Research: Posting Questions
- Post research questions to relevant subreddits to gather community input
- Create Bluesky polls for quick sentiment analysis
- Requires careful community norm adherence

### Tier 3: Higher Risk / More Complex

#### E. Cross-Platform Distribution
- Same research adapted per platform: full analysis on Reddit, thread on X, summary on Bluesky
- Requires content adaptation engine
- Schedule for optimal timing per platform

#### F. Monitoring & Response
- Monitor mentions of research topics
- Auto-draft responses to questions about published research
- Always with human approval before sending

---

## 5. Architecture Patterns

### Recommended Architecture: Split by Concern, Not Platform

```
publish-social/
  SKILL.md                    # Main skill entry point
  lib/
    platforms/
      reddit.py               # Reddit PRAW adapter
      twitter.py              # X/Twitter adapter (twikit + official)
      bluesky.py              # Bluesky AT Protocol adapter
      linkedin.py             # LinkedIn via Buffer API (if needed)
    content/
      adapter.py              # Adapts content per platform constraints
      templates.py            # Post templates for different use cases
    queue/
      scheduler.py            # Queue and schedule posts
      rate_limiter.py         # Platform-aware rate limiting
    approval/
      gate.py                 # Human-in-the-loop approval
    analytics/
      tracker.py              # Track post engagement
    compliance/
      disclosure.py           # Add required disclosures
      audit_log.py            # Log all posts for compliance
```

### Key Design Decisions

#### One Skill or Split Per Platform?
**One skill with platform adapters.** Reasons:
- Content adaptation is the core logic (shared across platforms)
- Approval gate is unified
- Analytics/tracking is cross-platform
- Platform-specific code is isolated in adapters

#### Approval Gates (Human-in-the-Loop)

```
Approval Levels:
  - AUTO:     Bluesky original posts (low risk)
  - REVIEW:   X/Twitter posts, Reddit posts to known subreddits
  - APPROVE:  Reddit posts to new subreddits, any reply/comment
  - MANUAL:   HN submissions, LinkedIn, anything flagged
```

Implementation: Write proposed post to a review queue (Notion page, local file, or Telegram message). Wait for approval before posting. Timeout after 24h if no response.

#### Content Adaptation Per Platform

| Platform | Max Length | Format | Special |
|----------|-----------|--------|---------|
| X/Twitter | 280 chars (10K for Premium) | Plain text + links | Thread support for longer content |
| Bluesky | 300 chars (grapheme limit) | Rich text, facets for links/mentions | Link cards auto-generated |
| Reddit | 40K chars (selftext) | Markdown | Title + body separate |
| LinkedIn | 3,000 chars | Rich text | Hashtags important |
| Instagram | 2,200 chars caption | Requires image/video | Hashtags in comments pattern |

#### Queue System

```python
# Post Queue Entry
{
  "id": "uuid",
  "content": {
    "title": "Research finding: ...",
    "body": "Full analysis text...",
    "url": "https://link-to-full-report",
    "tags": ["AI", "research"],
  },
  "platforms": ["bluesky", "twitter", "reddit"],
  "platform_adaptations": {
    "bluesky": {"text": "Adapted 300-char version..."},
    "twitter": {"text": "Adapted 280-char version..."},
    "reddit": {"subreddit": "MachineLearning", "title": "...", "selftext": "..."},
  },
  "schedule": "2026-03-21T14:00:00Z",  # or "immediate"
  "approval_status": "pending",  # pending | approved | rejected | auto
  "posted": {},  # filled with post URLs after publishing
}
```

#### Analytics Tracking

Track per post:
- Platform, timestamp, content hash
- Post URL / ID
- Impressions, likes, reposts, replies (poll periodically)
- Click-through rate (if using tracked links)
- Engagement rate = (interactions / impressions)

Store in local JSON or SQLite for analysis.

---

## 6. Existing Solutions & Competitors

### SaaS Platforms

| Tool | Pricing | Platforms | Key Feature |
|------|---------|-----------|-------------|
| **Buffer** | Free (3 channels, 10 posts/channel) to $6/mo/channel | X, FB, IG, LinkedIn, Bluesky, Mastodon | Simple, affordable, good API |
| **Hootsuite** | $99-$249/mo (annual) | X, FB, IG, LinkedIn, TikTok, Pinterest, YouTube | Enterprise features, social listening |
| **Later** | From $18.75/mo (annual) | IG, FB, X, LinkedIn, TikTok, Pinterest | Visual content calendar, link in bio |
| **Planable** | From $33/mo | Most major platforms | Content approval workflows |
| **Sprout Social** | From $249/mo | All major platforms | Enterprise, analytics, CRM |

### Open-Source Alternatives

| Tool | GitHub | Platforms | Notes |
|------|--------|-----------|-------|
| **Postiz** | `gitroomhq/postiz-app` (very active, updated daily) | 30+ platforms incl. X, IG, LinkedIn, Reddit, Threads, Mastodon | Self-hosted Buffer alternative. AI content generation. Most promising OSS option |
| **Mixpost** | `inovector/mixpost` | Major platforms | Laravel-based, team collaboration, approval workflows |
| **Shoutify** | Open source | Multiple | Simpler, for individual creators |
| **Socioboard** | Open source (since 2014) | Multiple + CRM | Veteran platform, bulk scheduling |

### MCP Servers for Social Media

| Server | Platform | Capabilities |
|--------|----------|-------------|
| **mcp-twikit** (`adhikasp/mcp-twikit`) | X/Twitter | Read + Write tweets via twikit (unofficial API) |
| **Twikit MCP** (mcpmarket.com) | X/Twitter | Twitter interaction via MCP |

**Gap:** No MCP servers found for Bluesky posting, Reddit posting, or cross-platform publishing. This is an opportunity for DELPHI.

### Automation Platforms

| Tool | Approach | Social Capabilities |
|------|----------|-------------------|
| **n8n** | Self-hosted workflow automation | Omni-channel distributor, AI content generation, cross-platform scheduling. Very capable but requires setup |
| **Make.com** | Cloud workflow automation | Social media connectors for most platforms |
| **Zapier** | Cloud workflow automation | Simple social posting triggers/actions |

**n8n Standout Workflows:**
- Omni-Channel Distributor: simultaneous posting to 5+ platforms
- Repurposing Engine: turn blog posts into platform-specific content
- AI-powered caption generation per platform
- RSS-to-social automation

### Unified API Services

| Service | Approach |
|---------|----------|
| **Late API** | Unified posting API across platforms (getlate.dev) |
| **Zernio** | Centralized social media API |
| **Gravity Social** | Multi-platform scheduling API |

---

## 7. Recommendations for DELPHI PRO

### Priority Platform Ranking

1. **Bluesky** -- FREE, generous limits, bot-friendly, growing tech community. **Implement first.**
2. **X/Twitter** -- High visibility, pay-per-use model manageable for low volume. Use twikit for MVP, migrate to official API for production.
3. **Reddit** -- Best for research questions and community engagement. PRAW works well. Requires careful subreddit targeting.
4. **LinkedIn** -- Only via Buffer API or similar partner tool. Lower priority.
5. **HN** -- Manual posting only. Not suitable for automation.
6. **Instagram/YouTube** -- Skip unless visual content becomes a priority.

### Implementation Phases

#### Phase 1: Bluesky MVP (Week 1)
- Implement Bluesky adapter using `atproto` Python package
- Simple post creation with research summaries
- AI disclosure footer on all posts
- Local queue with immediate posting
- Basic engagement tracking

#### Phase 2: X/Twitter + Reddit (Week 2-3)
- Add twikit adapter for X (free, unofficial)
- Add PRAW adapter for Reddit
- Content adaptation engine (length, format per platform)
- Human-in-the-loop approval gate (Telegram notification or local file)
- Cross-posting with platform-specific formatting

#### Phase 3: Queue & Analytics (Week 4)
- Scheduled posting queue
- Rate limiter with platform awareness
- Engagement tracking (poll for likes/reposts/replies)
- Compliance audit log
- Post-performance analysis

#### Phase 4: Production Hardening (Week 5+)
- Migrate X/Twitter to official API (pay-per-use)
- Add Buffer integration for LinkedIn if needed
- Content A/B testing (different summaries, measure engagement)
- Automated report on posting performance

### Compliance Checklist

- [ ] All posts include AI disclosure footer
- [ ] Bot user-agent set for Reddit
- [ ] Bluesky profile identifies as bot/research agent
- [ ] X/Twitter account bio mentions automated posting
- [ ] Rate limits enforced at 50% of platform maximums
- [ ] Audit log captures every post attempt (success/failure)
- [ ] Human approval gate for replies and comments
- [ ] Content adaptation prevents identical cross-posts
- [ ] EU AI Act machine-readable marking (by August 2026)
- [ ] FTC disclosure on any content that could be construed as endorsement

### Cost Estimate (Monthly)

| Item | Cost |
|------|------|
| Bluesky API | $0 |
| X/Twitter (pay-per-use, ~50 tweets/month) | ~$5-20 |
| Reddit API (personal bot) | $0 |
| Buffer (if LinkedIn needed, 1 channel) | $6 |
| **Total** | **$6-26/month** |

### Key Technical Decisions

1. **Python-first** -- PRAW, atproto, twikit are all Python. Keep the skill in Python.
2. **Async where possible** -- twikit is async; atproto supports async. Use asyncio for concurrent multi-platform posting.
3. **Session persistence** -- Store auth tokens/sessions to avoid repeated logins (especially for Bluesky rate limits on login).
4. **Idempotent posting** -- Hash content to prevent duplicate posts. Check if already posted before submitting.
5. **Graceful degradation** -- If one platform fails, continue posting to others. Log failures for retry.

---

## Sources

### Platform APIs & Documentation
- [Bluesky Rate Limits](https://docs.bsky.app/docs/advanced-guides/rate-limits)
- [Bluesky Posting via API](https://docs.bsky.app/blog/create-post)
- [Bluesky Bot Starter Templates](https://docs.bsky.app/docs/starter-templates/bots)
- [X API Pay-Per-Use Announcement](https://devcommunity.x.com/t/announcing-the-launch-of-x-api-pay-per-use-pricing/256476)
- [X API Pricing Comparison (xpoz.ai)](https://www.xpoz.ai/blog/guides/understanding-twitter-api-pricing-tiers-and-alternatives/)
- [twikit GitHub](https://github.com/d60/twikit)
- [mcp-twikit MCP Server](https://github.com/adhikasp/mcp-twikit)
- [PRAW Documentation](https://praw.readthedocs.io/en/latest/)
- [Reddit API Credentials Guide 2025](https://www.wappkit.com/blog/reddit-api-credentials-guide-2025)
- [HackerNews API (read-only)](https://github.com/HackerNews/API)
- [HN Programmatic Posting (workaround)](https://davidbieber.com/snippets/2020-05-02-hackernews-submit/)
- [Instagram Graph API Publishing Guide](https://dev.to/fermainpariz/how-to-automate-instagram-posts-in-2026-without-getting-banned-3nc0)
- [Instagram Reels API Publishing](https://postproxy.dev/blog/instagram-reels-api-publishing-guide/)
- [YouTube Data API v3 Comments](https://getlate.dev/blog/youtube-comments-api)
- [LinkedIn API Terms of Use](https://www.linkedin.com/legal/l/api-terms-of-use)
- [LinkedIn API Guide 2026](https://www.outx.ai/blog/linkedin-api-guide)

### Legal & Compliance
- [FTC AI Content Disclosure (humanadsai)](https://humanadsai.com/blog/ftc-ai-generated-content-disclosure)
- [FTC Operation AI Comply Guide](https://www.depthera.ai/blog/ftc-operation-ai-comply-2026-guide)
- [FTC Endorsement Guide for AI Content](https://www.affiversemedia.com/the-ftc-is-watching-ai-generated-endorsements-affiliate-links-and-what-compliance-looks-like-in-2026/)
- [EU AI Act Code of Practice](https://digital-strategy.ec.europa.eu/en/policies/code-practice-ai-generated-content)
- [EU AI Act Transparency Draft (Cooley)](https://www.cooley.com/news/insight/2025/2025-12-18-eu-ai-act-first-draft-code-of-practice-on-transparency-and-watermarking-released)
- [EU AI Act Transparency (Kirkland & Ellis)](https://www.kirkland.com/publications/kirkland-alert/2026/02/illuminating-ai-the-eus-first-draft-code-of-practice-on-transparency-for-ai)
- [AI Labeling Requirements 2026 (weventure)](https://weventure.de/en/blog/ai-labeling)

### Architecture & Best Practices
- [Social Media API Rules & Rate Limits 2026](https://postproxy.dev/blog/social-media-platform-api-rules-rate-limits-media-specs)
- [Platform Rate Limiting Management](https://www.conbersa.ai/learn/platform-rate-limiting-management)
- [Complete Guide Social Media API Automation (Zernio)](https://zernio.com/blog/complete-guide-social-media-api-automation)
- [Twitter Automation Rules 2026](https://opentweet.io/blog/twitter-automation-rules-2026)
- [Social Media API Limitations 2026](https://www.contentdrifter.com/blog/social-media-api-limitations-2026)
- [n8n Social Media Workflows](https://n8nlab.io/blog/best-n8n-social-media-workflows-automation)
- [Late API Social Media Automation](https://getlate.dev/blog/automate-social-media-posting-with-n8n)

### Open-Source Tools
- [Postiz (gitroomhq/postiz-app)](https://github.com/gitroomhq/postiz-app)
- [Mixpost](https://github.com/inovector/mixpost)
- [Bluesky 2025 Transparency Report](https://bsky.social/about/blog/01-29-2026-transparency-report-2025)

### Competitor Pricing
- [Buffer vs Hootsuite](https://buffer.com/resources/buffer-vs-hootsuite/)
- [Hootsuite Alternatives](https://buffer.com/resources/alternatives-to-hootsuite-free-how-buffer-and-hootsuite-compare/)
- [Social Media Scheduling Tools 2026](https://buffer.com/resources/social-media-scheduling-tools/)
- [LinkedIn Safe Automation Guide](https://salesflow.io/blog/the-ultimate-guide-to-safe-linkedin-automation-in-2025)
