#!/bin/bash
# reddit-search.sh — Search Reddit via PRAW or JSON API fallback (FREE)
# Returns structured JSON with top results
#
# Usage:
#   reddit-search.sh --topic "AI agents" [--subreddit ClaudeAI] [--max 10] [--sort relevance|hot|new|top]

set -euo pipefail

TOPIC=""
SUBREDDIT=""
MAX_RESULTS=10
SORT="relevance"

while [[ $# -gt 0 ]]; do
  case $1 in
    --topic) TOPIC="$2"; shift 2 ;;
    --subreddit) SUBREDDIT="$2"; shift 2 ;;
    --subreddits) SUBREDDIT="$2"; shift 2 ;;
    --max) MAX_RESULTS="$2"; shift 2 ;;
    --sort) SORT="$2"; shift 2 ;;
    --help)
      echo "Usage: reddit-search.sh --topic TOPIC [--subreddit SUB] [--max 10] [--sort relevance|hot|new|top]"
      exit 0 ;;
    *) echo "Unknown arg: $1" >&2; exit 1 ;;
  esac
done

if [[ -z "$TOPIC" ]]; then
  echo '{"status": "error", "error": "Missing --topic", "agent": "scout-social/reddit"}' >&2
  exit 1
fi

export TOPIC SUBREDDIT MAX_RESULTS SORT

python3 << 'PYEOF'
import json, os, sys

topic = os.environ.get('TOPIC', '')
subreddit = os.environ.get('SUBREDDIT', '')
max_results = int(os.environ.get('MAX_RESULTS', '10'))
sort = os.environ.get('SORT', 'relevance')

all_findings = []

def normalize_finding(title, permalink, subreddit_name, author, score, num_comments, selftext='', created_utc=0):
    return {
        'title': title,
        'url': f'https://reddit.com{permalink}' if permalink.startswith('/') else permalink,
        'subreddit': subreddit_name,
        'author': author,
        'score': score,
        'comments': num_comments,
        'created_utc': created_utc,
        'content_preview': (selftext[:300] + '...') if selftext and len(selftext) > 300 else (selftext or ''),
        'channel': 'reddit',
        'source_tier': 'T2'
    }

# Try PRAW first
praw_worked = False
try:
    import praw
    client_id = os.environ.get('REDDIT_CLIENT_ID', '')
    client_secret = os.environ.get('REDDIT_CLIENT_SECRET', '')
    user_agent = os.environ.get('REDDIT_USER_AGENT', 'DELPHI-PRO-Scout/2.0')

    if client_id and client_secret:
        reddit = praw.Reddit(client_id=client_id, client_secret=client_secret, user_agent=user_agent)

        def praw_search(sub_name, limit):
            results = []
            for post in reddit.subreddit(sub_name).search(topic, sort=sort, limit=limit):
                results.append(normalize_finding(
                    post.title, post.permalink, str(post.subreddit),
                    str(post.author) if post.author else '[deleted]',
                    post.score, post.num_comments,
                    post.selftext or '', post.created_utc
                ))
            return results

        # Step 1: specified subreddit(s)
        if subreddit:
            subs = [s.strip() for s in subreddit.replace(',', '+').split('+') if s.strip()]
            all_findings = praw_search('+'.join(subs), max_results)

        # Step 2: site-wide search (NOT r/all — uses subreddit('') which is reddit.com/search)
        if not all_findings:
            for post in reddit.subreddit('all').search(topic, sort=sort, limit=max_results):
                # Filter: only keep posts with score >= 5 to avoid garbage
                if post.score >= 5:
                    all_findings.append(normalize_finding(
                        post.title, post.permalink, str(post.subreddit),
                        str(post.author) if post.author else '[deleted]',
                        post.score, post.num_comments,
                        post.selftext or '', post.created_utc
                    ))

        praw_worked = bool(all_findings)
except (ImportError, Exception):
    pass

# Fallback: Reddit JSON API (no auth needed)
if not praw_worked:
    import urllib.request, urllib.parse, time
    query = urllib.parse.quote(topic)
    headers = {'User-Agent': 'DELPHI-PRO-Scout/2.0 (research bot)'}

    TOPIC_SUBREDDIT_MAP = {
        'crypto': 'cryptocurrency,defi,ethfinance,bitcoin',
        'bitcoin': 'bitcoin,cryptocurrency', 'ethereum': 'ethereum,ethfinance,defi',
        'defi': 'defi,cryptocurrency,ethfinance', 'nft': 'nft,cryptocurrency',
        'ai': 'artificial,MachineLearning,LocalLLaMA,ClaudeAI',
        'llm': 'LocalLLaMA,MachineLearning,artificial,ClaudeAI',
        'ml': 'MachineLearning,artificial,datascience',
        'agent': 'artificial,MachineLearning,ClaudeAI,LangChain',
        'tech': 'technology,programming,compsci',
        'python': 'Python,learnpython', 'javascript': 'javascript,webdev',
        'startup': 'startups,Entrepreneur,SaaS',
        'marketing': 'marketing,digital_marketing,SEO',
        'seo': 'SEO,bigseo,TechSEO',
        'finance': 'finance,investing,stocks,wallstreetbets',
        'health': 'health,Fitness,longevity,Supplements',
        'longevity': 'longevity,Supplements,Biohackers',
        'gaming': 'gaming,pcgaming,Games',
        'science': 'science,askscience,Physics',
        'space': 'space,spacex,SpaceXLounge',
        'quantum': 'QuantumComputing,Physics,science',
        'fusion': 'nuclear,energy,Futurology',
        'regulation': 'law,technology,politics',
        'identity': 'privacy,selfhosted,technology',
        'vehicle': 'SelfDrivingCars,electricvehicles,technology',
    }

    def guess_subreddits(topic_text):
        """Map topic keywords to relevant subreddits."""
        topic_lower = topic_text.lower()
        matched = set()
        for keyword, subs in TOPIC_SUBREDDIT_MAP.items():
            if keyword in topic_lower:
                matched.update(s.strip() for s in subs.split(','))
        return list(matched)[:5] if matched else []

    def fetch_reddit_json(url):
        """Fetch a single Reddit JSON API URL, return parsed data or raise."""
        req = urllib.request.Request(url, headers=headers)
        with urllib.request.urlopen(req, timeout=30) as resp:
            return json.loads(resp.read())

    def search_subreddit(sub_name, per_sub_limit):
        """Search a single subreddit and return findings list."""
        findings = []
        url = f'https://www.reddit.com/r/{sub_name.strip()}/search.json?q={query}&restrict_sr=on&sort={sort}&limit={per_sub_limit}'
        data = fetch_reddit_json(url)
        for child in data.get('data', {}).get('children', []):
            d = child.get('data', {})
            findings.append(normalize_finding(
                d.get('title', ''), d.get('permalink', ''),
                d.get('subreddit', ''), d.get('author', ''),
                d.get('score', 0), d.get('num_comments', 0),
                d.get('selftext', ''), d.get('created_utc', 0)
            ))
        return findings

    try:
        if subreddit and ',' in subreddit:
            # Multiple subreddits: search each separately, merge results
            subs = [s.strip() for s in subreddit.split(',') if s.strip()]
            per_sub_limit = max(1, max_results // len(subs)) + 2  # fetch slightly more, trim later
            errors = []
            for i, sub_name in enumerate(subs):
                try:
                    all_findings.extend(search_subreddit(sub_name, per_sub_limit))
                except Exception as e:
                    errors.append(f'{sub_name}: {e}')
                if i < len(subs) - 1:
                    time.sleep(1)  # respect rate limits between requests
            if not all_findings and errors:
                raise Exception('; '.join(errors))
            # Sort merged results by score descending, trim to max_results
            all_findings.sort(key=lambda x: x.get('score', 0), reverse=True)
            all_findings = all_findings[:max_results]
        elif subreddit:
            # Single subreddit search
            all_findings.extend(search_subreddit(subreddit, max_results))
        else:
            # Step 2: Site-wide Reddit search (relevance-filtered, NOT r/all browse)
            search_scope = 'site_wide'
            url = f'https://www.reddit.com/search.json?q={query}&sort={sort}&limit={max_results}'
            try:
                data = fetch_reddit_json(url)
                for child in data.get('data', {}).get('children', []):
                    d = child.get('data', {})
                    if d.get('score', 0) >= 3:  # filter low-quality
                        all_findings.append(normalize_finding(
                            d.get('title', ''), d.get('permalink', ''),
                            d.get('subreddit', ''), d.get('author', ''),
                            d.get('score', 0), d.get('num_comments', 0),
                            d.get('selftext', ''), d.get('created_utc', 0)
                        ))
            except Exception:
                pass

            # Step 3: Topic-mapped subreddits if site-wide returned too few
            if len(all_findings) < 3:
                search_scope = 'topic_mapped'
                mapped_subs = guess_subreddits(topic)
                for i, sub_name in enumerate(mapped_subs):
                    try:
                        all_findings.extend(search_subreddit(sub_name, max(3, max_results // len(mapped_subs))))
                    except Exception:
                        pass
                    if i < len(mapped_subs) - 1:
                        import time; time.sleep(1)
                all_findings.sort(key=lambda x: x.get('score', 0), reverse=True)
                all_findings = all_findings[:max_results]

            # Step 4: If still empty, return with flag — NEVER fall back to r/all
            if not all_findings:
                search_scope = 'exhausted'
    except Exception as e:
        print(json.dumps({'status': 'error', 'error': f'Reddit API failed: {e}'}), file=sys.stderr)
        sys.exit(1)

search_scope = 'specified' if subreddit else locals().get('search_scope', 'site_wide')
result = {
    'status': 'complete',
    'agent': 'scout-social/reddit',
    'topic': topic,
    'findings': all_findings,
    'metadata': {
        'items_returned': len(all_findings),
        'subreddit': subreddit or 'auto',
        'sort': sort,
        'method': 'praw' if praw_worked else 'json_api_fallback',
        'search_scope': search_scope,
        'no_relevant_results': len(all_findings) == 0
    }
}
print(json.dumps(result, indent=2))
PYEOF
