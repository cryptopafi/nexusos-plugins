#!/bin/bash
# hn-search.sh — Search HackerNews via Algolia API (FREE, no auth)
# Returns structured JSON with top results
#
# Usage:
#   hn-search.sh --topic "AI agents" [--max 10] [--sort date|popularity]
#   hn-search.sh --topic "Claude Code" --type story|comment

set -euo pipefail

TOPIC=""
MAX_RESULTS=10
SORT="popularity"
TYPE=""

while [[ $# -gt 0 ]]; do
  case $1 in
    --topic) TOPIC="$2"; shift 2 ;;
    --max) MAX_RESULTS="$2"; shift 2 ;;
    --sort) SORT="$2"; shift 2 ;;
    --type) TYPE="$2"; shift 2 ;;
    --help)
      echo "Usage: hn-search.sh --topic TOPIC [--max 10] [--sort date|popularity] [--type story|comment]"
      exit 0 ;;
    *) echo "Unknown arg: $1" >&2; exit 1 ;;
  esac
done

if [[ -z "$TOPIC" ]]; then
  echo '{"status": "error", "error": "Missing --topic", "agent": "scout-social/hn"}' >&2
  exit 1
fi

# Export early — all Python blocks read from env
export TOPIC SORT MAX_RESULTS TYPE

# URL encode safely via env var
ENCODED_TOPIC=$(python3 -c "import urllib.parse, os; print(urllib.parse.quote(os.environ['TOPIC']))")

if [[ "$SORT" == "date" ]]; then
  BASE_URL="https://hn.algolia.com/api/v1/search_by_date"
else
  BASE_URL="https://hn.algolia.com/api/v1/search"
fi

TAGS=""
if [[ -n "$TYPE" ]]; then
  TAGS="&tags=$TYPE"
fi

URL="${BASE_URL}?query=${ENCODED_TOPIC}&hitsPerPage=${MAX_RESULTS}${TAGS}"

# Fetch to temp file, then parse safely
TMPFILE=$(mktemp)
trap "rm -f \"$TMPFILE\"" EXIT
curl -s "$URL" > "$TMPFILE"

export TMPFILE
python3 << 'PYEOF'
import json, sys, os

topic = os.environ.get('TOPIC', '')
sort_mode = os.environ.get('SORT', 'popularity')
tmpfile = os.environ.get('TMPFILE', '')

with open(tmpfile) as f:
    data = json.load(f)
hits = data.get('hits', [])

findings = []
for h in hits:
    finding = {
        'title': h.get('title') or h.get('story_title', ''),
        'url': h.get('url') or f"https://news.ycombinator.com/item?id={h.get('objectID', '')}",
        'hn_url': f"https://news.ycombinator.com/item?id={h.get('objectID', '')}",
        'author': h.get('author', ''),
        'points': h.get('points', 0),
        'comments': h.get('num_comments', 0),
        'created_at': h.get('created_at', ''),
        'channel': 'hackernews',
        'source_tier': 'T2'
    }
    if finding['title']:
        findings.append(finding)

result = {
    'status': 'complete',
    'agent': 'scout-social/hn',
    'topic': topic,
    'findings': findings,
    'metadata': {
        'items_total': data.get('nbHits', 0),
        'items_returned': len(findings),
        'sort': sort_mode
    }
}
print(json.dumps(result, indent=2))
PYEOF
