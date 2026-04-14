#!/bin/bash
# news-search.sh — Search news via free APIs (GNews + Guardian + RSS)
# Zero cost, no API keys required for basic usage
#
# Usage:
#   news-search.sh --topic "AI agents" [--max 10] [--source gnews|guardian|rss|all]

set -euo pipefail

TOPIC=""
MAX_RESULTS=10
SOURCE="all"

while [[ $# -gt 0 ]]; do
  case $1 in
    --topic) TOPIC="$2"; shift 2 ;;
    --max) MAX_RESULTS="$2"; shift 2 ;;
    --source) SOURCE="$2"; shift 2 ;;
    --help)
      echo "Usage: news-search.sh --topic TOPIC [--max 10] [--source gnews|guardian|rss|all]"
      exit 0 ;;
    *) echo "Unknown arg: $1" >&2; exit 1 ;;
  esac
done

if [[ -z "$TOPIC" ]]; then
  echo '{"status": "error", "error": "Missing --topic", "agent": "scout-knowledge/news"}' >&2
  exit 1
fi

export TOPIC MAX_RESULTS SOURCE

python3 << 'PYEOF'
import json, sys, os, urllib.request, urllib.parse

topic = os.environ.get('TOPIC', '')
max_results = int(os.environ.get('MAX_RESULTS', '10'))
source = os.environ.get('SOURCE', 'all')

all_findings = []
all_errors = []

def search_gnews():
    try:
        api_key = os.environ.get('GNEWS_API_KEY', '')
        if not api_key:
            return
        query = urllib.parse.quote(topic)
        url = f"https://gnews.io/api/v4/search?q={query}&lang=en&max={min(max_results, 10)}&apikey={api_key}"
        req = urllib.request.Request(url, headers={'User-Agent': 'DELPHI-PRO/2.0'})
        with urllib.request.urlopen(req, timeout=10) as resp:
            data = json.loads(resp.read())
        for article in data.get('articles', []):
            all_findings.append({
                'title': article.get('title', ''),
                'url': article.get('url', ''),
                'source_name': article.get('source', {}).get('name', ''),
                'published': article.get('publishedAt', ''),
                'description': (article.get('description', '') or '')[:300],
                'channel': 'gnews',
                'source_tier': 'T2'
            })
    except Exception as e:
        all_errors.append({'channel': 'gnews', 'error': str(e)})

def search_guardian():
    try:
        api_key = os.environ.get('GUARDIAN_API_KEY', 'test')
        query = urllib.parse.quote(topic)
        url = f"https://content.guardianapis.com/search?q={query}&page-size={min(max_results, 10)}&api-key={api_key}&show-fields=trailText"
        req = urllib.request.Request(url, headers={'User-Agent': 'DELPHI-PRO/2.0'})
        with urllib.request.urlopen(req, timeout=10) as resp:
            data = json.loads(resp.read())
        for r in data.get('response', {}).get('results', []):
            all_findings.append({
                'title': r.get('webTitle', ''),
                'url': r.get('webUrl', ''),
                'section': r.get('sectionName', ''),
                'published': r.get('webPublicationDate', ''),
                'description': (r.get('fields', {}).get('trailText', '') or '')[:300],
                'channel': 'guardian',
                'source_tier': 'T1'
            })
    except Exception as e:
        all_errors.append({'channel': 'guardian', 'error': str(e)})

def search_rss():
    try:
        import feedparser
        feeds = {
            'TechCrunch AI': 'https://techcrunch.com/category/artificial-intelligence/feed/',
            'Ars Technica': 'https://feeds.arstechnica.com/arstechnica/technology-lab',
            'The Verge AI': 'https://www.theverge.com/rss/ai-artificial-intelligence/index.xml',
            'MIT Tech Review': 'https://www.technologyreview.com/feed/',
        }
        topic_lower = topic.lower()
        topic_words = topic_lower.split()
        for feed_name, feed_url in feeds.items():
            try:
                feed = feedparser.parse(feed_url)
                for entry in feed.entries[:3]:
                    title_lower = entry.get('title', '').lower()
                    summary_lower = entry.get('summary', '').lower()
                    if any(w in title_lower or w in summary_lower for w in topic_words):
                        all_findings.append({
                            'title': entry.get('title', ''),
                            'url': entry.get('link', ''),
                            'source_name': feed_name,
                            'published': entry.get('published', ''),
                            'description': (entry.get('summary', '') or '')[:300],
                            'channel': 'rss',
                            'source_tier': 'T1'
                        })
            except Exception as e:
                all_errors.append({'channel': f'rss/{feed_name}', 'error': str(e)})
    except ImportError:
        all_errors.append({'channel': 'rss', 'error': 'feedparser not installed'})

# Execute selected sources
if source in ('all', 'gnews'):
    search_gnews()
if source in ('all', 'guardian'):
    search_guardian()
if source in ('all', 'rss'):
    search_rss()

valid = [f for f in all_findings if 'error' not in f]
status = 'complete' if valid and not all_errors else ('partial' if valid else 'empty')

result = {
    'status': status,
    'agent': 'scout-knowledge/news',
    'topic': topic,
    'findings': valid[:max_results],
    'errors': all_errors,
    'metadata': {
        'items_returned': len(valid[:max_results]),
        'sources_queried': source,
        'sources_errored': len(all_errors)
    }
}
print(json.dumps(result, indent=2))
PYEOF
