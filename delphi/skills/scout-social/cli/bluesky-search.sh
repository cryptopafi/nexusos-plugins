#!/bin/bash
# bluesky-search.sh — Search Bluesky via AT Protocol SDK
# Usage: bluesky-search.sh --topic "query" [--max 10] [--since 2026-01-01]
set -euo pipefail

TOPIC=""
MAX=10
SINCE="2026-01-01"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --topic) TOPIC="$2"; shift 2 ;;
    --max) MAX="$2"; shift 2 ;;
    --since) SINCE="$2"; shift 2 ;;
    *) shift ;;
  esac
done

if [[ -z "$TOPIC" ]]; then
  echo '{"error": "Usage: bluesky-search.sh --topic \"query\" [--max 10] [--since 2026-01-01]"}'
  exit 1
fi

# Resolve credentials from .env or Keychain
PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "$0")/../../.." && pwd)}"
source "${PLUGIN_ROOT}/lib/resolve-key.sh" 2>/dev/null || true

BSKY_HANDLE=$(resolve_key "BLUESKY_HANDLE" 2>/dev/null || echo "")
BSKY_PASSWORD=$(resolve_key "BLUESKY_APP_PASSWORD" 2>/dev/null || echo "")

if [[ -z "$BSKY_HANDLE" || -z "$BSKY_PASSWORD" ]]; then
  # Fallback: Brave site:bsky.app search
  BRAVE_KEY=$(resolve_key "BRAVE_SEARCH_API_KEY" 2>/dev/null || echo "")
  if [[ -n "$BRAVE_KEY" ]]; then
    ENCODED=$(echo "site:bsky.app \"${TOPIC}\"" | /opt/homebrew/bin/python3.11 -c "import sys,urllib.parse; print(urllib.parse.quote(sys.stdin.read().strip()))")
    RESULT=$(curl -s --connect-timeout 10 --max-time 20 \
      -H "X-Subscription-Token: ${BRAVE_KEY}" \
      "https://api.search.brave.com/res/v1/web/search?q=${ENCODED}&count=${MAX}" 2>/dev/null)
    echo "$RESULT" | /opt/homebrew/bin/python3.11 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    results = data.get('web', {}).get('results', [])
    output = []
    for r in results:
        output.append({
            'title': r.get('title', ''),
            'url': r.get('url', ''),
            'snippet': r.get('description', ''),
            'source': 'bluesky-via-brave',
            'source_tier': 'T3'
        })
    print(json.dumps({'results': output, 'method': 'brave-proxy', 'note': 'Bluesky credentials not set. Using Brave site:bsky.app fallback.'}, indent=2))
except Exception as e:
    print(json.dumps({'error': str(e), 'method': 'brave-proxy'}))
"
  else
    echo '{"error": "No Bluesky credentials and no Brave key for fallback. Set BLUESKY_HANDLE + BLUESKY_APP_PASSWORD in ~/.nexus/.env"}'
  fi
  exit 0
fi

# Direct AT Protocol search via atproto SDK
/opt/homebrew/bin/python3.11 - "$TOPIC" "$MAX" "$SINCE" "$BSKY_HANDLE" "$BSKY_PASSWORD" << 'PYEOF'
import sys, json
from atproto import Client

topic = sys.argv[1]
max_results = int(sys.argv[2])
since = sys.argv[3]
handle = sys.argv[4]
password = sys.argv[5]

try:
    client = Client()
    client.login(handle, password)

    response = client.app.bsky.feed.search_posts(
        params={'q': topic, 'limit': min(max_results, 25), 'since': f'{since}T00:00:00Z'}
    )

    results = []
    for post in response.posts:
        author = post.author
        record = post.record
        results.append({
            'title': f'@{author.handle}',
            'url': f'https://bsky.app/profile/{author.handle}/post/{post.uri.split("/")[-1]}',
            'snippet': record.text[:300] if record.text else '',
            'author': author.display_name or author.handle,
            'likes': post.like_count or 0,
            'reposts': post.repost_count or 0,
            'created_at': record.created_at if hasattr(record, 'created_at') else '',
            'source': 'bluesky-direct',
            'source_tier': 'T3'
        })

    print(json.dumps({
        'results': results,
        'total': len(results),
        'method': 'atproto-direct',
        'query': topic
    }, indent=2, default=str))

except Exception as e:
    print(json.dumps({'error': str(e), 'method': 'atproto-direct'}))
    sys.exit(1)
PYEOF
