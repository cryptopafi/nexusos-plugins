#!/usr/bin/env bash
set -euo pipefail

# sonar-query.sh — Perplexity Sonar Pro via OpenRouter
# Usage: ./sonar-query.sh "prompt text" [max_tokens]
# Output: Sonar Pro response content to stdout

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ROOT="$(dirname "$SCRIPT_DIR")"
source "$PLUGIN_ROOT/lib/resolve-key.sh"

PROMPT="${1:-}"
MAX_TOKENS="${2:-2000}"
[[ "$MAX_TOKENS" =~ ^[0-9]+$ ]] || MAX_TOKENS=2000

if [[ -z "$PROMPT" ]]; then
  echo '{"error": "No prompt provided", "content": ""}' >&2
  exit 1
fi

OPENROUTER_KEY=$(resolve_key "OPENROUTER_API_KEY")
if [[ -z "$OPENROUTER_KEY" ]]; then
  echo '{"error": "OPENROUTER_API_KEY not found", "content": ""}' >&2
  exit 1
fi

# Build JSON safely with jq
if ! command -v jq &>/dev/null; then
  echo '{"error": "jq not installed — run: brew install jq", "content": ""}' >&2
  exit 1
fi

PAYLOAD=$(jq -n \
  --arg model "perplexity/sonar-pro" \
  --arg prompt "$PROMPT" \
  --argjson max_tokens "$MAX_TOKENS" \
  '{model: $model, messages: [{role: "user", content: $prompt}], max_tokens: $max_tokens}')

# Call OpenRouter with exponential backoff (max 3 retries)
RETRY=0
MAX_RETRY=3
DELAY=1

while [[ $RETRY -lt $MAX_RETRY ]]; do
  HTTP_CODE=0
  RESPONSE=$(curl -s -w "\n%{http_code}" --max-time 60 \
    -X POST "https://openrouter.ai/api/v1/chat/completions" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $OPENROUTER_KEY" \
    -d "$PAYLOAD" 2>/dev/null) || {
    RETRY=$((RETRY + 1))
    sleep $DELAY
    DELAY=$((DELAY * 2))
    continue
  }

  # Extract HTTP status code (last line) and body (everything else)
  HTTP_CODE=$(echo "$RESPONSE" | tail -1)
  BODY=$(echo "$RESPONSE" | sed '$d')

  # Retry on transient HTTP errors (429, 502, 503)
  if [[ "$HTTP_CODE" =~ ^(429|502|503)$ ]]; then
    RETRY=$((RETRY + 1))
    sleep $DELAY
    DELAY=$((DELAY * 2))
    continue
  fi

  # Hard fail on auth errors (401, 403) — no point retrying
  if [[ "$HTTP_CODE" =~ ^(401|403)$ ]]; then
    echo "{\"error\": \"Sonar Pro: HTTP $HTTP_CODE — check OPENROUTER_API_KEY\", \"content\": \"\"}" >&2
    exit 1
  fi

  # Check for valid response
  if echo "$BODY" | jq -e '.choices[0].message.content' &>/dev/null; then
    echo "$BODY" | jq -r '.choices[0].message.content'
    exit 0
  fi

  # Check for error in body
  if echo "$BODY" | jq -e '.error' &>/dev/null; then
    ERROR_MSG=$(echo "$BODY" | jq -r '.error.message // .error // "unknown error"')
    echo "{\"error\": \"Sonar Pro: $ERROR_MSG\", \"content\": \"\"}" >&2
    exit 1
  fi

  RETRY=$((RETRY + 1))
  sleep $DELAY
  DELAY=$((DELAY * 2))
done

echo '{"error": "Sonar Pro: max retries exceeded", "content": ""}' >&2
exit 1
