#!/bin/bash
# youtube-search.sh — YouTube search + transcript extraction
# 3-tier fallback: youtube-transcript-api → yt-dlp subs → yt-dlp audio + Groq Whisper
# Replaces broken YouTube MCP (playerCaptionsTracklistRenderer crash)

set -euo pipefail

# Portable key resolution (.env -> env var -> macOS Keychain)
source "$(dirname "$0")/../../../lib/resolve-key.sh"

TOPIC=""
MAX_RESULTS=5
EXTRACT_TRANSCRIPT="true"
VIDEO_ID=""
MODE="search"
SUBTITLE_LANG="en"

usage() {
  echo "Usage: youtube-search.sh --topic TOPIC [--max N] [--no-transcript] [--lang CODE]"
  echo "       youtube-search.sh --video-id ID [--transcript-only]"
  echo ""
  echo "3-Tier Fallback Chain:"
  echo "  Tier 1: youtube-transcript-api (0.9s, Python CLI, free)"
  echo "  Tier 2: yt-dlp subtitles (7s, auto-captions, free)"
  echo "  Tier 3: yt-dlp audio + Groq Whisper STT (20-30s, universal)"
  exit 0
}

while [[ $# -gt 0 ]]; do
  case $1 in
    --topic) TOPIC="$2"; MODE="search"; shift 2 ;;
    --video-id) VIDEO_ID="$2"; MODE="transcript"; shift 2 ;;
    --max) MAX_RESULTS="$2"; shift 2 ;;
    --no-transcript) EXTRACT_TRANSCRIPT="false"; shift ;;
    --transcript-only) MODE="transcript"; shift ;;
    --lang) SUBTITLE_LANG="$2"; shift 2 ;;
    --help) usage ;;
    *) echo "Unknown arg: $1" >&2; exit 1 ;;
  esac
done

if [[ -z "$TOPIC" && -z "$VIDEO_ID" ]]; then
  echo '{"status":"error","error":"topic_or_video_id_required","agent":"scout-video"}' >&2
  exit 1
fi

if ! command -v yt-dlp &>/dev/null; then
  echo '{"status":"error","error":"yt-dlp_not_installed","agent":"scout-video"}' >&2
  exit 1
fi

TMPDIR=$(mktemp -d)
trap "rm -rf \"$TMPDIR\"" EXIT
START_TIME=$(date +%s)

# Resolve Groq API key (for Tier 3 Whisper fallback)
GROQ_KEY=$(resolve_key "GROQ_API_KEY" || echo "")

export TOPIC MAX_RESULTS EXTRACT_TRANSCRIPT VIDEO_ID MODE TMPDIR START_TIME SUBTITLE_LANG GROQ_KEY

python3 << 'PYEOF'
import os, json, subprocess, sys, time, re

topic = os.environ.get('TOPIC', '')
max_results = int(os.environ.get('MAX_RESULTS', '5'))
extract_transcript = os.environ.get('EXTRACT_TRANSCRIPT', 'true') == 'true'
video_id = os.environ.get('VIDEO_ID', '')
mode = os.environ.get('MODE', 'search')
tmpdir = os.environ.get('TMPDIR', '/tmp')
start_time = int(os.environ.get('START_TIME', '0'))
lang = os.environ.get('SUBTITLE_LANG', 'en')
groq_key = os.environ.get('GROQ_KEY', '')

findings = []
errors = []

# ========== TIER 1: youtube-transcript-api (fastest, 0.9s) ==========
def tier1_transcript(vid):
    """Use youtube-transcript-api Python library"""
    try:
        r = subprocess.run(
            ['youtube_transcript_api', vid, '--format', 'text', '--languages', lang],
            capture_output=True, text=True, timeout=10
        )
        if r.returncode == 0 and r.stdout.strip():
            text = r.stdout.strip()
            # Filter out error messages that look like transcripts
            if 'Could not retrieve a transcript' in text or 'TranscriptsDisabled' in text:
                errors.append({"tier": 1, "tool": "youtube-transcript-api", "error": "no transcript available", "video_id": vid})
                return None, None
            return text, "youtube-transcript-api"
    except FileNotFoundError:
        pass  # Not installed, fall through
    except Exception as e:
        errors.append({"tier": 1, "tool": "youtube-transcript-api", "error": str(e), "video_id": vid})
    return None, None

# ========== TIER 2: yt-dlp subtitles (5-10s) ==========
def tier2_transcript(vid):
    """Use yt-dlp to extract auto-generated or manual subtitles"""
    try:
        sub_path = os.path.join(tmpdir, f't2-{vid}')
        r = subprocess.run(
            ['yt-dlp', '--write-auto-sub', '--sub-lang', lang, '--sub-format', 'vtt',
             '--skip-download', '--no-warnings', '-o', sub_path,
             f'https://www.youtube.com/watch?v={vid}'],
            capture_output=True, text=True, timeout=30
        )
        # Find subtitle file
        for ext in [f'.{lang}.vtt', '.en.vtt']:
            path = sub_path + ext
            if os.path.exists(path):
                with open(path, 'r') as f:
                    content = f.read()
                lines = []
                seen = set()
                for line in content.split('\n'):
                    line = line.strip()
                    if not line or line.startswith('WEBVTT') or line.startswith('Kind:') or line.startswith('Language:'):
                        continue
                    if '-->' in line or re.match(r'^\d+$', line):
                        continue
                    clean = re.sub(r'<[^>]+>', '', line).strip()
                    if clean and clean not in seen:
                        seen.add(clean)
                        lines.append(clean)
                if lines:
                    return ' '.join(lines), "yt-dlp-subtitles"
    except Exception as e:
        errors.append({"tier": 2, "tool": "yt-dlp-subs", "error": str(e), "video_id": vid})
    return None, None

# ========== TIER 3: yt-dlp audio + Groq Whisper STT (20-30s) ==========
def tier3_transcript(vid):
    """Download audio via yt-dlp, transcribe via Groq Whisper API"""
    if not groq_key:
        errors.append({"tier": 3, "tool": "groq-whisper", "error": "GROQ_API_KEY not found in keychain", "video_id": vid})
        return None, None
    try:
        audio_path = os.path.join(tmpdir, f't3-{vid}.mp3')
        # Download audio only (android client bypasses SABR restrictions)
        r = subprocess.run(
            ['yt-dlp', '-x', '--audio-format', 'mp3', '--audio-quality', '9',
             '--extractor-args', 'youtube:player_client=android',
             '--no-warnings', '-o', audio_path,
             f'https://www.youtube.com/watch?v={vid}'],
            capture_output=True, text=True, timeout=120
        )
        if not os.path.exists(audio_path):
            errors.append({"tier": 3, "tool": "yt-dlp-audio", "error": "audio download failed", "video_id": vid})
            return None, None

        # Check file size (Groq free tier: 25MB limit)
        size_mb = os.path.getsize(audio_path) / (1024 * 1024)
        if size_mb > 25:
            errors.append({"tier": 3, "tool": "groq-whisper", "error": f"audio {size_mb:.1f}MB > 25MB limit", "video_id": vid})
            return None, None

        # Transcribe via Groq Whisper API
        import urllib.request
        import io

        # Build multipart form data manually
        boundary = '----FormBoundary' + str(int(time.time()))
        body = b''
        # File field
        body += f'--{boundary}\r\n'.encode()
        body += f'Content-Disposition: form-data; name="file"; filename="{vid}.mp3"\r\n'.encode()
        body += b'Content-Type: audio/mpeg\r\n\r\n'
        with open(audio_path, 'rb') as f:
            body += f.read()
        body += b'\r\n'
        # Model field
        body += f'--{boundary}\r\n'.encode()
        body += b'Content-Disposition: form-data; name="model"\r\n\r\n'
        body += b'whisper-large-v3\r\n'
        # Response format
        body += f'--{boundary}\r\n'.encode()
        body += b'Content-Disposition: form-data; name="response_format"\r\n\r\n'
        body += b'text\r\n'
        # Language
        body += f'--{boundary}\r\n'.encode()
        body += b'Content-Disposition: form-data; name="language"\r\n\r\n'
        body += f'{lang}\r\n'.encode()
        body += f'--{boundary}--\r\n'.encode()

        req = urllib.request.Request(
            'https://api.groq.com/openai/v1/audio/transcriptions',
            data=body,
            headers={
                'Authorization': f'Bearer {groq_key}',
                'Content-Type': f'multipart/form-data; boundary={boundary}'
            }
        )
        with urllib.request.urlopen(req, timeout=60) as resp:
            text = resp.read().decode('utf-8').strip()
            if text:
                return text, "groq-whisper-stt"

    except Exception as e:
        errors.append({"tier": 3, "tool": "groq-whisper", "error": str(e), "video_id": vid})
    return None, None

# ========== COMBINED: 3-tier fallback ==========
def get_transcript(vid):
    """Try all 3 tiers in order"""
    # Tier 1: youtube-transcript-api (0.9s)
    text, method = tier1_transcript(vid)
    if text:
        return text, method

    # Tier 2: yt-dlp subtitles (5-10s)
    text, method = tier2_transcript(vid)
    if text:
        return text, method

    # Tier 3: yt-dlp audio + Groq Whisper (20-30s)
    text, method = tier3_transcript(vid)
    if text:
        return text, method

    return None, None

def get_metadata(vid):
    """Get video metadata via yt-dlp --dump-json"""
    try:
        r = subprocess.run(
            ['yt-dlp', '--dump-json', '--skip-download', '--no-warnings',
             f'https://www.youtube.com/watch?v={vid}'],
            capture_output=True, text=True, timeout=30
        )
        if r.returncode == 0:
            return json.loads(r.stdout)
    except Exception as e:
        errors.append({"channel": "youtube", "error": f"metadata: {e}", "video_id": vid})
    return None

def search_youtube(query, max_n):
    """Search YouTube via yt-dlp ytsearch"""
    try:
        r = subprocess.run(
            ['yt-dlp', '--dump-json', '--skip-download', '--no-warnings',
             '--flat-playlist', f'ytsearch{max_n}:{query}'],
            capture_output=True, text=True, timeout=60
        )
        if r.returncode == 0:
            results = []
            for line in r.stdout.strip().split('\n'):
                if line.strip():
                    try:
                        results.append(json.loads(line))
                    except:
                        pass
            return results
    except Exception as e:
        errors.append({"channel": "youtube", "error": f"search: {e}"})
    return []

# ---- MAIN ----
transcripts_extracted = 0
transcript_methods_used = set()

if mode == "search":
    results = search_youtube(topic, max_results)

    for item in results[:max_results]:
        vid = item.get('id', item.get('url', ''))
        if 'youtube.com' in str(vid):
            vid = vid.split('v=')[-1].split('&')[0]

        title = item.get('title', 'Unknown')
        channel = item.get('channel', item.get('uploader', 'Unknown'))
        duration = item.get('duration', 0)
        views = item.get('view_count', 0)

        finding = {
            "source_url": f"https://www.youtube.com/watch?v={vid}",
            "source_tier": "T2",
            "channel": "youtube",
            "title": title,
            "content_summary": f"Video by {channel}, {duration}s, {views or 0} views",
            "relevance_score": 0.7,
            "has_transcript": False,
            "transcript_method": None,
            "video_metadata": {
                "channel": channel,
                "duration": duration,
                "views": views or 0,
                "video_id": vid
            }
        }

        if extract_transcript and vid:
            transcript, method = get_transcript(vid)
            if transcript:
                finding["has_transcript"] = True
                finding["transcript_method"] = method
                finding["transcript_preview"] = transcript[:500]
                finding["content_summary"] = transcript[:300]
                finding["relevance_score"] = 0.85
                transcripts_extracted += 1
                transcript_methods_used.add(method)

        findings.append(finding)

elif mode == "transcript":
    vid = video_id
    meta = get_metadata(vid)
    transcript, method = get_transcript(vid) if extract_transcript else (None, None)

    if meta or transcript:
        finding = {
            "source_url": f"https://www.youtube.com/watch?v={vid}",
            "source_tier": "T2",
            "channel": "youtube",
            "title": meta.get('title', 'Unknown') if meta else 'Unknown',
            "content_summary": transcript[:500] if transcript else (meta.get('description', '')[:300] if meta else ''),
            "relevance_score": 0.9 if transcript else 0.6,
            "has_transcript": bool(transcript),
            "transcript_method": method,
            "video_metadata": {
                "channel": meta.get('channel', 'Unknown') if meta else 'Unknown',
                "duration": meta.get('duration', 0) if meta else 0,
                "views": meta.get('view_count', 0) if meta else 0,
                "upload_date": meta.get('upload_date', '') if meta else '',
                "video_id": vid
            }
        }
        if transcript:
            finding["transcript_preview"] = transcript[:1000]
            transcripts_extracted = 1
            transcript_methods_used.add(method)
        findings.append(finding)

end_time = int(time.time())
duration_ms = (end_time - start_time) * 1000

output = {
    "agent": "scout-video",
    "status": "complete" if findings else ("partial" if errors else "empty"),
    "topic": topic or video_id,
    "findings": findings,
    "errors": errors,
    "metadata": {
        "items_total": len(findings),
        "items_returned": len(findings),
        "duration_ms": duration_ms,
        "channels_queried": ["youtube"],
        "transcripts_extracted": transcripts_extracted,
        "transcript_methods": list(transcript_methods_used),
        "method": "3-tier-fallback",
        "fallback_chain": "youtube-transcript-api → yt-dlp-subs → groq-whisper-stt"
    }
}

print(json.dumps(output, ensure_ascii=False))
PYEOF
