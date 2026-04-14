#!/bin/bash
# domain-search.sh — Domain & website intelligence via WHOIS, DNS, HTTP headers, SSL, sitemap
# Part of scout-domain skill for DELPHI PRO
#
# Usage:
#   domain-search.sh --domain example.com [--mode all|whois|dns|headers|ssl|sitemap|tech]
#   domain-search.sh --url "https://www.example.com/page" [--mode all]
#   domain-search.sh --topic "What tech does stripe.com use?" [--mode all]
#
# 3-tier approach:
#   Primary: Tavily crawl (if TAVILY_API_KEY set) for content extraction
#   Fallback: curl + dig + whois + openssl (always available, FREE)
#   Fallback: Basic curl-only extraction if dig/whois unavailable
#
# Environment variables (optional):
#   TAVILY_API_KEY — enables Tavily content extraction
#   DOMAIN_SEARCH_TIMEOUT — per-command timeout in seconds (default: 10)

set -euo pipefail

# === Argument parsing ===
DOMAIN=""
URL=""
TOPIC=""
MODE="all"
TIMEOUT="${DOMAIN_SEARCH_TIMEOUT:-10}"

while [[ $# -gt 0 ]]; do
  case $1 in
    --domain) DOMAIN="$2"; shift 2 ;;
    --url) URL="$2"; shift 2 ;;
    --topic) TOPIC="$2"; shift 2 ;;
    --mode) MODE="$2"; shift 2 ;;
    --timeout) TIMEOUT="$2"; shift 2 ;;
    --help)
      cat <<'USAGE'
Usage: domain-search.sh --domain DOMAIN [--mode MODE] [--timeout SECS]
       domain-search.sh --url URL [--mode MODE]
       domain-search.sh --topic TOPIC [--mode MODE]

Modes: all, whois, dns, headers, ssl, sitemap, tech
Default mode: all (runs whois + dns + headers + ssl + sitemap + tech)

Environment:
  TAVILY_API_KEY          — Enables Tavily content extraction (optional)
  DOMAIN_SEARCH_TIMEOUT   — Per-command timeout in seconds (default: 10)
USAGE
      exit 0 ;;
    *) echo "{\"status\": \"error\", \"error\": \"unknown_arg: $1\", \"agent\": \"scout-domain\"}" >&2; exit 1 ;;
  esac
done

# === Input validation and domain extraction ===
# Use Python for safe parsing — no eval, no shell injection
export DOMAIN URL TOPIC MODE TIMEOUT

python3 << 'PYEOF'
import json, subprocess, sys, os, re, time
from urllib.parse import urlparse

domain_raw = os.environ.get('DOMAIN', '')
url_raw = os.environ.get('URL', '')
topic_raw = os.environ.get('TOPIC', '')
mode = os.environ.get('MODE', 'all')
timeout = int(os.environ.get('TIMEOUT', '10'))

def error_exit(msg):
    print(json.dumps({"status": "error", "error": msg, "agent": "scout-domain"}))
    sys.exit(0)

# --- Extract domain ---
domain = ''

if domain_raw:
    # Strip protocol, www, path
    d = domain_raw.strip()
    if '://' in d:
        d = urlparse(d).hostname or d
    d = re.sub(r'^www\.', '', d)
    d = d.split('/')[0].strip()
    domain = d
elif url_raw:
    parsed = urlparse(url_raw.strip())
    d = parsed.hostname or ''
    d = re.sub(r'^www\.', '', d)
    domain = d
elif topic_raw:
    # Extract domain-like patterns from topic
    match = re.search(r'([a-zA-Z0-9][-a-zA-Z0-9]*\.[a-zA-Z]{2,}(?:\.[a-zA-Z]{2,})?)', topic_raw)
    if match:
        domain = re.sub(r'^www\.', '', match.group(1))
    else:
        error_exit("no_domain_found_in_topic")
else:
    error_exit("domain_or_url_or_topic_required")

# Validate domain format
if not domain or '.' not in domain or not re.match(r'^[a-zA-Z0-9][-a-zA-Z0-9.]*[a-zA-Z0-9]\.[a-zA-Z]{2,}$', domain):
    error_exit("invalid_domain_format")

url_base = f"https://{domain}"
url_www = f"https://www.{domain}"

# --- Helper: run command with timeout ---
def run_cmd(cmd, timeout_secs=None):
    t = timeout_secs or timeout
    try:
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=t)
        return result.stdout.strip(), result.stderr.strip(), result.returncode
    except subprocess.TimeoutExpired:
        return '', 'timeout', 1
    except FileNotFoundError:
        return '', 'command_not_found', 1

# --- Channel: WHOIS ---
def do_whois():
    stdout, stderr, rc = run_cmd(['whois', domain])
    if rc != 0 or not stdout:
        return {"channel": "whois", "status": "error", "error": stderr or "whois_failed"}

    data = {}
    patterns = {
        'registrar': r'Registrar:\s*(.+)',
        # ICANN/gTLD format
        'creation_date': r'Creation Date:\s*(\S+)',
        'updated_date': r'Updated Date:\s*(\S+)',
        'expiry_date': r'(?:Registry Expiry Date|Registrar Registration Expiration Date|Expiry Date|Expiration Date):\s*(\S+)',
        'registrant_org': r'Registrant Organization:\s*(.+)',
        'registrant_country': r'Registrant Country:\s*(\S+)',
        # IANA/RIPE-style fallbacks (lowercase field names, colon-separated)
        'registrar_fallback': r'^registrar:\s*(.+)',
        'creation_date_fallback': r'^created:\s*(\S+)',
        'expiry_date_fallback': r'^expires?:\s*(\S+)',
        'organisation_fallback': r'^ou?rg(?:anisation)?:\s*(.+)',
        'domain_name': r'Domain Name:\s*(.+)',
    }
    for key, pat in patterns.items():
        # Skip fallback keys if primary already populated
        base_key = key.replace('_fallback', '')
        if base_key in data:
            continue
        match = re.search(pat, stdout, re.IGNORECASE | re.MULTILINE)
        if match:
            val = match.group(1).strip()
            # Store under canonical key (strip _fallback suffix)
            data[base_key] = val

    # Remove helper-only key not needed in output
    data.pop('domain_name', None)

    # Extract nameservers (ICANN "Name Server:" and IANA "nserver:")
    ns_matches = re.findall(r'(?:Name Server|nserver):\s*(\S+)', stdout, re.IGNORECASE)
    if ns_matches:
        # nserver lines may contain IP after hostname — keep only the hostname part
        data['nameservers'] = sorted(set(s.split()[0].lower().rstrip('.') for s in ns_matches))

    # Extract all status lines (e.g. clientTransferProhibited)
    status_matches = re.findall(r'Domain Status:\s*(\S+)', stdout, re.IGNORECASE)
    if status_matches:
        data['status'] = status_matches  # list of all EPP status codes

    # If still no structured data, include truncated raw output as fallback
    if not data:
        data['raw'] = stdout[:2000] if len(stdout) > 2000 else stdout

    # Build human-readable summary
    summary_parts = []
    for k in ('registrar', 'creation_date', 'expiry_date', 'updated_date',
               'registrant_org', 'registrant_country'):
        if k in data:
            label = k.replace('_', ' ').title()
            summary_parts.append(f"{label}: {data[k]}")
    if 'nameservers' in data:
        summary_parts.append(f"NS: {', '.join(data['nameservers'][:3])}")
    if not summary_parts and 'raw' in data:
        summary_parts.append('raw WHOIS data captured (non-standard format)')

    return {
        "channel": "whois",
        "status": "complete",
        "source_tier": "T1",
        "title": f"WHOIS: {domain}",
        "source_url": f"whois://{domain}",
        "data": data,
        "content_summary": '; '.join(summary_parts),
        "relevance_score": 1.0
    }

# --- Channel: DNS ---
def do_dns():
    records = {}
    inferences = {}

    for rtype in ['A', 'AAAA', 'MX', 'TXT', 'NS', 'CNAME']:
        stdout, _, rc = run_cmd(['dig', '+short', domain, rtype])
        if rc == 0 and stdout:
            records[rtype] = [line.strip() for line in stdout.split('\n') if line.strip()]

    # Infer email provider from MX
    mx_list = records.get('MX', [])
    mx_str = ' '.join(mx_list).lower()
    if 'google' in mx_str or 'aspmx' in mx_str:
        inferences['email_provider'] = 'Google Workspace'
    elif 'outlook' in mx_str or 'microsoft' in mx_str:
        inferences['email_provider'] = 'Microsoft 365'
    elif 'protonmail' in mx_str:
        inferences['email_provider'] = 'ProtonMail'
    elif 'zoho' in mx_str:
        inferences['email_provider'] = 'Zoho Mail'

    # Infer CDN from A records and NS
    a_list = records.get('A', [])
    ns_list = records.get('NS', [])
    ns_str = ' '.join(ns_list).lower()
    if 'cloudflare' in ns_str:
        inferences['cdn'] = 'Cloudflare'
    elif 'awsdns' in ns_str:
        inferences['cdn'] = 'AWS Route 53'
    elif 'dnsimple' in ns_str:
        inferences['dns_provider'] = 'DNSimple'

    return {
        "channel": "dns",
        "status": "complete",
        "source_tier": "T1",
        "title": f"DNS: {domain}",
        "source_url": f"dns://{domain}",
        "data": {"records": records, "inferences": inferences},
        "content_summary": f"A: {', '.join(records.get('A', ['none']))}; MX: {', '.join(records.get('MX', ['none'])[:2])}; NS: {', '.join(records.get('NS', ['none'])[:2])}",
        "relevance_score": 1.0
    }

# --- Channel: HTTP Headers ---
def do_headers():
    # Try www variant first (many sites redirect bare domain)
    for url in [url_www, url_base]:
        stdout, _, rc = run_cmd(['curl', '-sI', '-L', '--max-redirs', '3', url])
        if rc == 0 and stdout:
            break
    else:
        return {"channel": "headers", "status": "error", "error": "http_request_failed"}

    headers = {}
    security_headers = {}
    for line in stdout.split('\n'):
        if ':' in line:
            key, _, val = line.partition(':')
            key = key.strip().lower()
            val = val.strip()
            if key == 'server':
                headers['server'] = val
            elif key == 'x-powered-by':
                headers['x_powered_by'] = val
            elif key in ('strict-transport-security', 'x-frame-options',
                         'x-content-type-options', 'x-xss-protection',
                         'content-security-policy', 'referrer-policy',
                         'permissions-policy'):
                security_headers[key] = val[:200]  # Truncate long CSP

    # Security score (simple heuristic)
    sec_score = 0
    if 'strict-transport-security' in security_headers: sec_score += 1
    if 'x-frame-options' in security_headers or 'content-security-policy' in security_headers: sec_score += 1
    if 'x-content-type-options' in security_headers: sec_score += 1
    sec_grade = ['F', 'D', 'C', 'B', 'A'][min(sec_score, 4)] if sec_score <= 4 else 'A'

    return {
        "channel": "headers",
        "status": "complete",
        "source_tier": "T1",
        "title": f"HTTP Headers: {domain}",
        "source_url": url_www,
        "data": {"headers": headers, "security_headers": security_headers, "security_grade": sec_grade},
        "content_summary": f"Server: {headers.get('server', 'unknown')}; Security: {sec_grade}; HSTS: {'yes' if 'strict-transport-security' in security_headers else 'no'}",
        "relevance_score": 0.9
    }

# --- Channel: SSL ---
def do_ssl():
    cmd = f"echo | openssl s_client -servername {domain} -connect {domain}:443 2>/dev/null | openssl x509 -noout -subject -issuer -dates -ext subjectAltName 2>/dev/null"
    try:
        result = subprocess.run(cmd, shell=True, capture_output=True, text=True, timeout=timeout)
        stdout = result.stdout.strip()
    except (subprocess.TimeoutExpired, Exception):
        return {"channel": "ssl", "status": "error", "error": "ssl_connection_failed"}

    if not stdout:
        return {"channel": "ssl", "status": "error", "error": "no_ssl_data"}

    data = {}
    for line in stdout.split('\n'):
        line = line.strip()
        if line.startswith('subject='):
            data['subject'] = line.split('=', 1)[1].strip()
        elif line.startswith('issuer='):
            data['issuer'] = line.split('=', 1)[1].strip()
        elif line.startswith('notBefore='):
            data['valid_from'] = line.split('=', 1)[1].strip()
        elif line.startswith('notAfter='):
            data['valid_until'] = line.split('=', 1)[1].strip()
        elif 'DNS:' in line:
            sans = re.findall(r'DNS:([^\s,]+)', line)
            if sans:
                data['alt_names'] = sans[:10]

    return {
        "channel": "ssl",
        "status": "complete",
        "source_tier": "T1",
        "title": f"SSL: {domain}",
        "source_url": f"ssl://{domain}",
        "data": data,
        "content_summary": f"Issuer: {data.get('issuer', 'unknown')}; Valid until: {data.get('valid_until', 'unknown')}",
        "relevance_score": 0.85
    }

# --- Channel: Sitemap ---
def do_sitemap():
    data = {}

    # Fetch robots.txt
    for url in [f"{url_www}/robots.txt", f"{url_base}/robots.txt"]:
        stdout, _, rc = run_cmd(['curl', '-sL', '--max-time', str(timeout), url])
        if rc == 0 and stdout and 'User-Agent' in stdout:
            disallow = re.findall(r'Disallow:\s*(.+)', stdout)
            sitemap_urls = re.findall(r'Sitemap:\s*(\S+)', stdout, re.IGNORECASE)
            data['robots_txt'] = {
                'disallow_rules': [d.strip() for d in disallow[:20]],
                'sitemaps_declared': sitemap_urls[:5]
            }
            break

    # Try to fetch sitemap.xml
    sitemap_url = data.get('robots_txt', {}).get('sitemaps_declared', [None])
    sitemap_url = sitemap_url[0] if sitemap_url else f"{url_www}/sitemap.xml"

    if sitemap_url:
        stdout, _, rc = run_cmd(['curl', '-sL', '--max-time', str(timeout), sitemap_url])
        if rc == 0 and stdout and '<url>' in stdout.lower():
            urls_found = re.findall(r'<loc>([^<]+)</loc>', stdout)
            data['sitemap'] = {
                'url_count': len(urls_found),
                'sample_urls': urls_found[:15],
                'sections': list(set(
                    re.sub(r'https?://[^/]+/', '', u).split('/')[0]
                    for u in urls_found if '/' in re.sub(r'https?://[^/]+/', '', u)
                ))[:10]
            }

    if not data:
        return {"channel": "sitemap", "status": "error", "error": "no_robots_or_sitemap"}

    page_count = data.get('sitemap', {}).get('url_count', 0)
    sections = data.get('sitemap', {}).get('sections', [])

    return {
        "channel": "sitemap",
        "status": "complete",
        "source_tier": "T1",
        "title": f"Sitemap: {domain}",
        "source_url": sitemap_url or f"{url_www}/sitemap.xml",
        "data": data,
        "content_summary": f"Pages: {page_count}; Sections: {', '.join(sections[:5]) if sections else 'unknown'}",
        "relevance_score": 0.8
    }

# --- Channel: Tech Detection (from CSP + meta) ---
def do_tech():
    # Fetch full CSP header
    stdout, _, rc = run_cmd(['curl', '-sI', '-L', '--max-redirs', '3', url_www])
    csp = ''
    for line in (stdout or '').split('\n'):
        if line.lower().startswith('content-security-policy'):
            csp = line.split(':', 1)[1].strip()
            break

    # Fetch HTML head for meta tags and scripts
    html_stdout, _, _ = run_cmd(['curl', '-sL', '--max-time', str(timeout), '-r', '0-16384', url_www])

    detected = []
    detection_sources = {}

    # CSP-based detection
    csp_patterns = {
        'Google Tag Manager': 'googletagmanager.com',
        'Google Analytics': 'google-analytics.com',
        'Facebook Pixel': 'connect.facebook.net',
        'HubSpot': 'hubspot',
        'Intercom': 'intercom',
        'Segment': 'segment.com',
        'Mixpanel': 'mixpanel.com',
        'Hotjar': 'hotjar.com',
        'Sentry': 'sentry.io',
        'Stripe': 'stripe.com',
        'Cloudflare': 'cloudflare',
        'Webflow': 'website-files.com',
        'Sanity CMS': 'sanity.io',
        'Contentful': 'contentful.com',
        'Vercel': 'vercel',
        'Netlify': 'netlify',
        'YouTube': 'youtube.com',
        'Vimeo': 'vimeo.com',
        'Typeform': 'typeform.com',
        'Calendly': 'calendly.com',
        'Drift': 'drift.com',
        'Crisp': 'crisp.chat',
        'Amplitude': 'amplitude.com',
    }
    for tech, pattern in csp_patterns.items():
        if pattern in csp.lower():
            detected.append(tech)
            detection_sources[tech] = 'csp'

    # HTML-based detection
    html_lower = (html_stdout or '').lower()
    html_patterns = {
        'React': ('react', 'text/html'),
        'Next.js': ('_next/', 'text/html'),
        'Vue.js': ('vue.', 'text/html'),
        'Angular': ('ng-', 'text/html'),
        'WordPress': ('wp-content', 'text/html'),
        'Shopify': ('shopify', 'text/html'),
        'Squarespace': ('squarespace', 'text/html'),
        'Wix': ('wix.com', 'text/html'),
        'jQuery': ('jquery', 'text/html'),
        'Bootstrap': ('bootstrap', 'text/html'),
        'Tailwind CSS': ('tailwind', 'text/html'),
    }
    for tech, (pattern, _) in html_patterns.items():
        if tech not in detected and pattern in html_lower:
            detected.append(tech)
            detection_sources[tech] = 'html_inspection'

    # Generator meta tag
    gen_match = re.search(r'<meta\s+name=["\']generator["\']\s+content=["\']([^"\']+)', html_lower)
    if gen_match:
        gen = gen_match.group(1).strip()
        if gen and gen not in detected:
            detected.append(gen)
            detection_sources[gen] = 'meta_generator'

    return {
        "channel": "tech",
        "status": "complete",
        "source_tier": "T1",
        "title": f"Tech Stack: {domain}",
        "source_url": url_www,
        "data": {
            "detected": detected,
            "detection_sources": detection_sources,
            "detection_method": "csp_analysis+html_inspection+meta_tags"
        },
        "content_summary": f"Detected: {', '.join(detected[:8]) if detected else 'none identified'}",
        "relevance_score": 0.9
    }

# === Run channels ===
start_time = time.time()
findings = []
errors = []
channels_queried = []

mode_map = {
    'whois': [do_whois],
    'dns': [do_dns],
    'headers': [do_headers],
    'ssl': [do_ssl],
    'sitemap': [do_sitemap],
    'tech': [do_tech],
    'all': [do_whois, do_dns, do_headers, do_ssl, do_sitemap, do_tech],
}

channel_fns = mode_map.get(mode)
if not channel_fns:
    error_exit(f"invalid_mode: {mode}. Valid: all, whois, dns, headers, ssl, sitemap, tech")

for fn in channel_fns:
    try:
        result = fn()
        channel_name = result.get('channel', 'unknown')
        channels_queried.append(channel_name)
        if result.get('status') == 'error':
            errors.append({"channel": channel_name, "error": result.get('error', 'unknown')})
        else:
            findings.append(result)
    except Exception as e:
        errors.append({"channel": fn.__name__.replace('do_', ''), "error": str(e)})

duration_ms = int((time.time() - start_time) * 1000)

# === Build merged profile (for mode=all) ===
profile = {}
if mode == 'all':
    for f in findings:
        ch = f.get('channel')
        d = f.get('data', {})
        if ch == 'whois':
            profile['registration'] = d
        elif ch == 'dns':
            profile['dns_records'] = d.get('records', {})
            profile['infrastructure'] = d.get('inferences', {})
            profile.setdefault('infrastructure', {})['ip_addresses'] = d.get('records', {}).get('A', [])
        elif ch == 'headers':
            profile.setdefault('infrastructure', {})['web_server'] = d.get('headers', {}).get('server', 'unknown')
            profile['security'] = {
                'headers': d.get('security_headers', {}),
                'grade': d.get('security_grade', 'unknown')
            }
        elif ch == 'ssl':
            profile.setdefault('infrastructure', {})['ssl_issuer'] = d.get('issuer', 'unknown')
            profile.setdefault('infrastructure', {})['ssl_valid_until'] = d.get('valid_until', 'unknown')
        elif ch == 'sitemap':
            profile['content'] = {
                'page_count_estimate': d.get('sitemap', {}).get('url_count', 0),
                'sections': d.get('sitemap', {}).get('sections', []),
            }
        elif ch == 'tech':
            profile['technology'] = d

# === Output ===
status = 'complete'
if errors and findings:
    status = 'partial'
elif errors and not findings:
    status = 'error'

output = {
    "agent": "scout-domain",
    "status": status,
    "domain": domain,
    "findings": findings,
    "errors": errors,
    "metadata": {
        "items_total": len(findings) + len(errors),
        "items_returned": len(findings),
        "items_deduplicated": 0,
        "duration_ms": duration_ms,
        "channels_queried": channels_queried
    }
}

if profile:
    output["profile"] = profile

print(json.dumps(output, indent=2, default=str))
PYEOF
