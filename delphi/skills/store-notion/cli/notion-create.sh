#!/bin/bash
# notion-create.sh — Create a page in Notion via CLI
# Replaces Notion MCP for DELPHI PRO scouts (saves ~12K tokens when used as CLI)
#
# Usage:
#   notion-create.sh --db DATABASE_ID --title "Page Title" --content "Markdown content"
#   notion-create.sh --parent PAGE_ID --title "Child Page" --content "Content"
#   echo "content" | notion-create.sh --db DATABASE_ID --title "Title" --stdin
#
# Metadata (optional):
#   --topic "AI agents"       Sets Topic property (select)
#   --depth "D3"              Sets Depth property (select)
#   --epr 17                  Sets EPR Score property (number)
#   --tags "tag1,tag2"        Sets Tags property (multi_select)
#   --source "delphi-pro"     Sets Source property (select)
#   --dedup                   Check for existing page with same title before creating

set -euo pipefail

# --- Config ---
NOTION_TOKEN="${NOTION_TOKEN:-$(python3 -c "import json,os; d=json.load(open(os.path.expanduser('~/.claude/settings.json'))); print(d['mcpServers']['notion']['env']['NOTION_TOKEN'])" 2>/dev/null || echo "")}"

if [[ -z "$NOTION_TOKEN" ]]; then
  echo '{"status": "error", "error": "NOTION_TOKEN not found. Set env var or configure in settings.json", "agent": "store-notion"}' >&2
  exit 1
fi

# --- Args ---
DB_ID=""
PARENT_ID=""
TITLE=""
CONTENT=""
USE_STDIN=false
TOPIC=""
DEPTH=""
EPR_SCORE=""
TAGS=""
SOURCE=""
DEDUP=false

while [[ $# -gt 0 ]]; do
  case $1 in
    --db) DB_ID="$2"; shift 2 ;;
    --parent) PARENT_ID="$2"; shift 2 ;;
    --title) TITLE="$2"; shift 2 ;;
    --content) CONTENT="$2"; shift 2 ;;
    --stdin) USE_STDIN=true; shift ;;
    --topic) TOPIC="$2"; shift 2 ;;
    --depth) DEPTH="$2"; shift 2 ;;
    --epr) EPR_SCORE="$2"; shift 2 ;;
    --tags) TAGS="$2"; shift 2 ;;
    --source) SOURCE="$2"; shift 2 ;;
    --dedup) DEDUP=true; shift ;;
    --help)
      echo "Usage: notion-create.sh --db DB_ID --title TITLE [--content CONTENT|--stdin]"
      echo "  --topic TOPIC --depth D1-D4 --epr SCORE --tags tag1,tag2 --source SOURCE --dedup"
      exit 0 ;;
    *) echo "Unknown arg: $1" >&2; exit 1 ;;
  esac
done

if [[ -z "$TITLE" ]]; then
  echo '{"status": "error", "error": "Missing --title", "agent": "store-notion"}' >&2
  exit 1
fi

if [[ -z "$DB_ID" && -z "$PARENT_ID" ]]; then
  echo '{"status": "error", "error": "Provide --db or --parent", "agent": "store-notion"}' >&2
  exit 1
fi

if $USE_STDIN; then
  CONTENT=$(cat)
fi

# --- Build and send via Python (safe, no shell injection) ---
export NOTION_TOKEN DB_ID PARENT_ID TITLE CONTENT TOPIC DEPTH EPR_SCORE TAGS SOURCE
export DEDUP_FLAG="$DEDUP"

python3 << 'PYEOF'
import json, os, sys, urllib.request, urllib.error, time, re
from datetime import date

token = os.environ.get('NOTION_TOKEN', '')
db_id = os.environ.get('DB_ID', '')
parent_id = os.environ.get('PARENT_ID', '')
title = os.environ.get('TITLE', '')
content = os.environ.get('CONTENT', '')
topic = os.environ.get('TOPIC', '')
depth = os.environ.get('DEPTH', '')
epr_score = os.environ.get('EPR_SCORE', '')
tags = os.environ.get('TAGS', '')
source = os.environ.get('SOURCE', '')
dedup = os.environ.get('DEDUP_FLAG', 'false') == 'true'

API_VERSION = '2022-06-28'
BASE_URL = 'https://api.notion.com/v1'
MAX_BLOCK_CHARS = 2000
MAX_BLOCKS_PER_REQUEST = 100
MAX_RETRIES = 3

_start = time.time()

def api_request(method, endpoint, payload=None, retry_on_429=True):
    """Make Notion API request with retry on 429 rate limit."""
    url = f'{BASE_URL}/{endpoint}'
    headers = {
        'Authorization': f'Bearer {token}',
        'Content-Type': 'application/json',
        'Notion-Version': API_VERSION
    }
    data = json.dumps(payload).encode('utf-8') if payload else None
    for attempt in range(MAX_RETRIES):
        req = urllib.request.Request(url, data=data, headers=headers, method=method)
        try:
            with urllib.request.urlopen(req, timeout=30) as resp:
                return json.loads(resp.read())
        except urllib.error.HTTPError as e:
            if e.code == 429 and retry_on_429 and attempt < MAX_RETRIES - 1:
                retry_after = int(e.headers.get('Retry-After', 1))
                time.sleep(retry_after)
                continue
            raise
    raise Exception(f'Notion API: max retries ({MAX_RETRIES}) exhausted for {endpoint}')

def make_rich_text(text):
    """Build rich_text array, splitting at 2000-char boundary."""
    parts = []
    while len(text) > MAX_BLOCK_CHARS:
        parts.append({'type': 'text', 'text': {'content': text[:MAX_BLOCK_CHARS]}})
        text = text[MAX_BLOCK_CHARS:]
    if text:
        parts.append({'type': 'text', 'text': {'content': text}})
    return parts

def markdown_to_blocks(md_content):
    """Convert markdown to Notion blocks. Supports headings, bullets, code, paragraphs."""
    blocks = []
    lines = md_content.split('\n')
    i = 0
    while i < len(lines):
        line = lines[i]

        # Code blocks (fenced)
        if line.strip().startswith('```'):
            lang = line.strip()[3:].strip()
            code_lines = []
            i += 1
            while i < len(lines) and not lines[i].strip().startswith('```'):
                code_lines.append(lines[i])
                i += 1
            if i < len(lines):
                i += 1  # skip closing ```
            code_text = '\n'.join(code_lines)
            blocks.append({
                'type': 'code',
                'code': {
                    'rich_text': make_rich_text(code_text),
                    'language': lang if lang else 'plain text'
                }
            })
            continue

        # Headings
        h_match = re.match(r'^(#{1,3})\s+(.+)$', line)
        if h_match:
            level = len(h_match.group(1))
            heading_text = h_match.group(2).strip()
            h_type = f'heading_{level}'
            blocks.append({
                'type': h_type,
                h_type: {'rich_text': make_rich_text(heading_text)}
            })
            i += 1
            continue

        # Bullet list items
        b_match = re.match(r'^[\s]*[-*+]\s+(.+)$', line)
        if b_match:
            blocks.append({
                'type': 'bulleted_list_item',
                'bulleted_list_item': {'rich_text': make_rich_text(b_match.group(1).strip())}
            })
            i += 1
            continue

        # Numbered list items
        n_match = re.match(r'^[\s]*\d+[.)]\s+(.+)$', line)
        if n_match:
            blocks.append({
                'type': 'numbered_list_item',
                'numbered_list_item': {'rich_text': make_rich_text(n_match.group(1).strip())}
            })
            i += 1
            continue

        # Divider
        if re.match(r'^---+\s*$', line.strip()):
            blocks.append({'type': 'divider', 'divider': {}})
            i += 1
            continue

        # Blockquote
        q_match = re.match(r'^>\s*(.*)', line)
        if q_match:
            blocks.append({
                'type': 'quote',
                'quote': {'rich_text': make_rich_text(q_match.group(1).strip())}
            })
            i += 1
            continue

        # Empty line — skip
        if not line.strip():
            i += 1
            continue

        # Paragraph: accumulate consecutive non-empty, non-special lines
        para_lines = [line]
        i += 1
        while i < len(lines):
            next_line = lines[i]
            if not next_line.strip():
                break
            if re.match(r'^#{1,3}\s', next_line) or re.match(r'^[-*+]\s', next_line.strip()) or \
               re.match(r'^\d+[.)]\s', next_line.strip()) or next_line.strip().startswith('```') or \
               re.match(r'^---+\s*$', next_line.strip()) or re.match(r'^>\s', next_line):
                break
            para_lines.append(next_line)
            i += 1
        para_text = ' '.join(l.strip() for l in para_lines)
        blocks.append({
            'type': 'paragraph',
            'paragraph': {'rich_text': make_rich_text(para_text)}
        })

    return blocks

def check_duplicate(database_id, page_title):
    """Query database for pages with matching title. Returns page_id if found."""
    try:
        payload = {
            'filter': {
                'property': 'title',
                'title': {'equals': page_title}
            },
            'page_size': 1
        }
        result = api_request('POST', f'databases/{database_id}/query', payload)
        if result and result.get('results'):
            page = result['results'][0]
            return page.get('id'), page.get('url', '')
    except Exception:
        pass  # dedup is best-effort; failure should not block page creation
    return None, None

def append_blocks_chunked(page_id, blocks):
    """Append blocks to page in chunks of MAX_BLOCKS_PER_REQUEST (100)."""
    for i in range(0, len(blocks), MAX_BLOCKS_PER_REQUEST):
        chunk = blocks[i:i + MAX_BLOCKS_PER_REQUEST]
        api_request('PATCH', f'blocks/{page_id}/children', {'children': chunk})

# --- Dedup check ---
if dedup and db_id:
    existing_id, existing_url = check_duplicate(db_id, title)
    if existing_id:
        _duration_ms = int((time.time() - _start) * 1000)
        print(json.dumps({
            'agent': 'store-notion',
            'status': 'duplicate',
            'result': {'page_id': existing_id, 'url': existing_url, 'title': title},
            'errors': [],
            'metadata': {'duration_ms': _duration_ms, 'action': 'skipped_duplicate'}
        }))
        sys.exit(0)

# --- Build parent ---
if db_id:
    parent = {"database_id": db_id}
else:
    parent = {"page_id": parent_id}

# --- Build properties ---
properties = {
    'title': {'title': [{'text': {'content': title}}]}
}

# Add metadata properties (best-effort: if property doesn't exist in DB schema, Notion ignores it)
if topic:
    properties['Topic'] = {'select': {'name': topic}}
if depth:
    properties['Depth'] = {'select': {'name': depth}}
if epr_score:
    try:
        properties['EPR Score'] = {'number': float(epr_score)}
    except ValueError:
        pass
if tags:
    tag_list = [t.strip() for t in tags.split(',') if t.strip()]
    properties['Tags'] = {'multi_select': [{'name': t} for t in tag_list]}
if source:
    properties['Source'] = {'select': {'name': source}}

# Always set Date property to today
properties['Date'] = {'date': {'start': date.today().isoformat()}}

# --- Parse content to blocks ---
children = markdown_to_blocks(content) if content else []

# --- Determine if we need chunked append ---
# Notion allows max 100 blocks in page creation payload
initial_blocks = children[:MAX_BLOCKS_PER_REQUEST]
overflow_blocks = children[MAX_BLOCKS_PER_REQUEST:]

payload = {
    'parent': parent,
    'properties': properties
}
if initial_blocks:
    payload['children'] = initial_blocks

# --- Create page ---
try:
    result = api_request('POST', 'pages', payload)
    page_id = result.get('id', '')
    url = result.get('url', '')

    # Append overflow blocks if content exceeded 100 blocks
    if overflow_blocks and page_id:
        append_blocks_chunked(page_id, overflow_blocks)

    _duration_ms = int((time.time() - _start) * 1000)
    print(json.dumps({
        'agent': 'store-notion',
        'status': 'created',
        'result': {'page_id': page_id, 'url': url, 'title': title},
        'errors': [],
        'metadata': {
            'duration_ms': _duration_ms,
            'blocks_total': len(children),
            'chunks': 1 + (len(overflow_blocks) + MAX_BLOCKS_PER_REQUEST - 1) // MAX_BLOCKS_PER_REQUEST if overflow_blocks else 1
        }
    }))
except urllib.error.HTTPError as e:
    error_body = e.read().decode('utf-8', errors='replace')
    try:
        error_msg = json.loads(error_body).get('message', error_body)
    except Exception:
        error_msg = error_body
    _duration_ms = int((time.time() - _start) * 1000)
    print(json.dumps({
        'agent': 'store-notion',
        'status': 'error',
        'result': {},
        'errors': [{'error': error_msg, 'code': e.code}],
        'metadata': {'duration_ms': _duration_ms}
    }), file=sys.stderr)
    sys.exit(1)
except Exception as e:
    _duration_ms = int((time.time() - _start) * 1000)
    print(json.dumps({
        'agent': 'store-notion',
        'status': 'error',
        'result': {},
        'errors': [{'error': str(e)}],
        'metadata': {'duration_ms': _duration_ms}
    }), file=sys.stderr)
    sys.exit(1)
PYEOF
