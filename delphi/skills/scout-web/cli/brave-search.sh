#!/bin/bash
# brave-search.sh — Brave Web Search via curl CLI (replaces MCP)
# Usage: brave-search.sh --query "search terms" [--count 10]
set -euo pipefail

QUERY=""
COUNT=10

while [[ $# -gt 0 ]]; do
  case $1 in
    --query) QUERY="$2"; shift 2 ;;
    --count) COUNT="$2"; shift 2 ;;
    --help) echo "Usage: brave-search.sh --query QUERY [--count 10]"; exit 0 ;;
    *) echo "Unknown arg: $1" >&2; exit 1 ;;
  esac
done

if [[ -z "$QUERY" ]]; then
  echo '{"status": "error", "error": "Missing --query"}' >&2
  exit 1
fi

# Resolve API key
BRAVE_KEY=""
if [[ -f "$HOME/.nexus/.env" ]]; then
  BRAVE_KEY=$(grep -E '^BRAVE_SEARCH_API_KEY=' "$HOME/.nexus/.env" | cut -d= -f2- | tr -d '"' | tr -d "'")
fi
if [[ -z "$BRAVE_KEY" ]]; then
  BRAVE_KEY="${BRAVE_SEARCH_API_KEY:-}"
fi
if [[ -z "$BRAVE_KEY" ]]; then
  echo '{"status": "error", "error": "No BRAVE_SEARCH_API_KEY found in ~/.nexus/.env or environment"}' >&2
  exit 1
fi

# URL-encode query
ENCODED_QUERY=$(echo "$QUERY" | python3 -c "import sys, urllib.parse; print(urllib.parse.quote(sys.stdin.read().strip()))")

# Call Brave API with 30s timeout
RESPONSE=$(curl -s --connect-timeout 10 --max-time 30 \
  -H "Accept: application/json" \
  -H "Accept-Encoding: gzip" \
  -H "X-Subscription-Token: ${BRAVE_KEY}" \
  --compressed \
  "https://api.search.brave.com/res/v1/web/search?q=${ENCODED_QUERY}&count=${COUNT}" 2>/dev/null)

HTTP_CHECK=$(echo "$RESPONSE" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    if 'error' in d:
        print(json.dumps({'status': 'error', 'error': d['error'].get('detail', str(d['error']))}))
    else:
        results = []
        for r in d.get('web', {}).get('results', []):
            results.append({
                'title': r.get('title', ''),
                'url': r.get('url', ''),
                'description': r.get('description', ''),
                'age': r.get('age', ''),
                'channel': 'brave',
                'source_tier': 'T2'
            })
        print(json.dumps({
            'status': 'complete',
            'agent': 'scout-web/brave',
            'query': '$QUERY',
            'findings': results,
            'metadata': {
                'items_returned': len(results),
                'engine': 'brave_web_search',
                'method': 'curl_cli'
            }
        }, indent=2))
except Exception as e:
    print(json.dumps({'status': 'error', 'error': str(e)}))
" 2>/dev/null)

echo "$HTTP_CHECK"
