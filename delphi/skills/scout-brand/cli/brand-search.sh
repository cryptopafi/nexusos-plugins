#!/bin/bash
# brand-search.sh — Domain discovery for brand names via NameSilo + RDAP + Brave
# Part of scout-brand skill for DELPHI PRO
#
# Usage:
#   brand-search.sh --mode availability --domain nexusai.com
#   brand-search.sh --mode suggest --brand "NexusAI" --tlds "com,io,ai,co,app,dev"
#   brand-search.sh --mode suggest --domains "nexusai.com,nexus.ai,getnexusai.com"
#   brand-search.sh --mode recommend --brand "NexusAI" --budget 200
#
# Primary: NameSilo API (200 domains/request, returns pricing)
# Fallback: RDAP.org (HTTP 404 = available, 1 domain at a time)
# Trademark: Brave Search for USPTO/WIPO screening
#
# Environment variables (resolved via lib/resolve-key.sh):
#   NAMESILO_API_KEY — NameSilo domain availability API
#   BRAVE_SEARCH_API_KEY — Brave Search for trademark screening

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_DIR="$(cd "$SCRIPT_DIR/../../.." && pwd)"

# Source key resolver
source "$PLUGIN_DIR/lib/resolve-key.sh"

# === Argument parsing ===
MODE=""
DOMAIN=""
BRAND=""
TLDS=""
DOMAINS=""
BUDGET=""

while [[ $# -gt 0 ]]; do
  case $1 in
    --mode) MODE="$2"; shift 2 ;;
    --domain) DOMAIN="$2"; shift 2 ;;
    --brand) BRAND="$2"; shift 2 ;;
    --tlds) TLDS="$2"; shift 2 ;;
    --domains) DOMAINS="$2"; shift 2 ;;
    --budget) BUDGET="$2"; shift 2 ;;
    --help)
      cat <<'USAGE'
Usage: brand-search.sh --mode MODE [OPTIONS]

Modes:
  availability  Check if a single domain is available
    --domain DOMAIN         Domain to check (e.g., nexusai.com)

  suggest       Generate and check brand domain variants
    --brand BRAND           Brand name to generate variants for
    --tlds TLD_LIST         Comma-separated TLDs (default: com,io,ai,co,app,dev)
    --domains DOMAIN_LIST   OR provide explicit domain list (comma-separated)

  recommend     Full recommendation with budget breakdown
    --brand BRAND           Brand name
    --budget AMOUNT         Budget in USD (default: 200)
    --tlds TLD_LIST         Comma-separated TLDs (optional)

Environment (resolved via lib/resolve-key.sh):
  NAMESILO_API_KEY          NameSilo API key (primary)
  BRAVE_SEARCH_API_KEY      Brave Search API key (trademark screening)
USAGE
      exit 0 ;;
    *) echo "{\"status\": \"error\", \"error\": \"unknown_arg: $1\", \"agent\": \"scout-brand\"}" >&2; exit 1 ;;
  esac
done

# Resolve API keys
export NAMESILO_API_KEY=$(resolve_key "NAMESILO_API_KEY" 2>/dev/null || echo "")
export BRAVE_SEARCH_API_KEY=$(resolve_key "BRAVE_SEARCH_API_KEY" 2>/dev/null || echo "")

# Validate mode
if [[ -z "$MODE" ]]; then
  echo '{"status": "error", "error": "mode_required. Valid: availability, suggest, recommend", "agent": "scout-brand"}'
  exit 1
fi

# Export all vars for Python
export MODE DOMAIN BRAND TLDS DOMAINS BUDGET

python3 << 'PYEOF'
import json, sys, os, re, time, subprocess
from urllib.parse import quote

mode = os.environ.get('MODE', '')
domain_arg = os.environ.get('DOMAIN', '').strip()
brand_arg = os.environ.get('BRAND', '').strip()
tlds_arg = os.environ.get('TLDS', '').strip()
domains_arg = os.environ.get('DOMAINS', '').strip()
budget_arg = os.environ.get('BUDGET', '').strip()
namesilo_key = os.environ.get('NAMESILO_API_KEY', '').strip()
brave_key = os.environ.get('BRAVE_SEARCH_API_KEY', '').strip()

start_time = time.time()

def output_json(data):
    data.setdefault('agent', 'scout-brand')
    data.setdefault('status', 'complete')
    print(json.dumps(data, indent=2, default=str))
    sys.exit(0)

def error_exit(msg):
    output_json({"status": "error", "error": msg})

def run_cmd(cmd, timeout_secs=15):
    try:
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=timeout_secs)
        return result.stdout.strip(), result.returncode
    except subprocess.TimeoutExpired:
        return '', 1
    except FileNotFoundError:
        return '', 1

# ============================================================
# NameSilo bulk availability check (up to 200 domains/request)
# ============================================================
def namesilo_check(domain_list):
    """Check availability via NameSilo API. Returns dict: domain -> {available, price_usd, source}"""
    if not namesilo_key:
        return None  # Signal to use fallback

    results = {}
    # NameSilo accepts up to 200 comma-separated domains
    for batch_start in range(0, len(domain_list), 200):
        batch = domain_list[batch_start:batch_start + 200]
        domains_csv = ','.join(batch)
        url = f"https://www.namesilo.com/api/checkRegisterAvailability?version=1&type=json&key={namesilo_key}&domains={domains_csv}"

        stdout, rc = run_cmd(['curl', '-s', '--max-time', '20', url])
        if rc != 0 or not stdout:
            return None  # Signal fallback

        try:
            data = json.loads(stdout)
            reply = data.get('reply', {})
            code = reply.get('code')

            if str(code) not in ('300', '110'):
                # API error — signal fallback
                return None

            avail_data = reply.get('available', None)
            unavail_data = reply.get('unavailable', None)
            invalid_data = reply.get('invalid', None)

            # NameSilo response format varies wildly:
            # 1 result:  {"available": {"domain": "test.com", "price": 17.29}}
            # Multiple:  {"available": {"domain": [{"domain":"a.com","price":17}, ...]}}
            # Strings:   {"available": ["test.com"]} or {"available": "test.com"}
            # Flat list:  {"unavailable": ["x.com","y.com"]} or {"unavailable": "x.com"}
            # Dict list: {"unavailable": {"domain": ["x.com","y.com"]}}
            # Single dict with nested domain key that is itself a dict or list

            def _normalize_to_list(section):
                """Normalize any NameSilo response shape into a flat list of items (dicts or strings)."""
                if section is None:
                    return []
                if isinstance(section, str):
                    return [section]
                if isinstance(section, list):
                    return section
                if isinstance(section, dict):
                    # Dict with 'domain' key — the value could be a string, dict, or list
                    domain_val = section.get('domain')
                    if domain_val is None:
                        # No 'domain' key — treat whole dict as a single entry
                        return [section]
                    if isinstance(domain_val, str):
                        # {"domain": "test.com", "price": 17} — single entry as dict
                        return [section]
                    if isinstance(domain_val, dict):
                        # {"domain": {"domain": "test.com", "price": 17}} — unwrap
                        return [domain_val]
                    if isinstance(domain_val, list):
                        # {"domain": [{"domain":"a.com","price":17}, ...]} or {"domain": ["a.com","b.com"]}
                        return domain_val
                return []

            def _extract_domain_str(entry):
                """Extract domain string from an entry (dict or string)."""
                if isinstance(entry, str):
                    return entry.strip().lower()
                if isinstance(entry, dict):
                    d = entry.get('domain', '')
                    if isinstance(d, str):
                        return d.strip().lower()
                return ''

            def _extract_price(entry):
                """Extract price from an entry if present."""
                if isinstance(entry, dict):
                    p = entry.get('price')
                    if p is not None:
                        try:
                            return float(p)
                        except (ValueError, TypeError):
                            pass
                return None

            def parse_available_section(section):
                """Parse available section (has pricing info). Handles all NameSilo response shapes."""
                items = _normalize_to_list(section)
                for entry in items:
                    d = _extract_domain_str(entry)
                    if d:
                        results[d] = {"available": True, "price_usd": _extract_price(entry), "source": "namesilo"}

            def parse_unavailable_section(section):
                """Parse unavailable/invalid section. Handles all NameSilo response shapes."""
                items = _normalize_to_list(section)
                for entry in items:
                    d = _extract_domain_str(entry)
                    if d:
                        results[d] = {"available": False, "price_usd": None, "source": "namesilo"}

            parse_available_section(avail_data)
            parse_unavailable_section(unavail_data)
            parse_unavailable_section(invalid_data)

        except (json.JSONDecodeError, KeyError, TypeError):
            return None  # Signal fallback

    return results

# ============================================================
# RDAP fallback (1 domain at a time, slower)
# ============================================================
def rdap_check(domain_list, delay=0.5):
    """Check availability via RDAP.org. HTTP 404 = available."""
    results = {}
    for d in domain_list:
        url = f"https://rdap.org/domain/{d}"
        stdout, rc = run_cmd(['curl', '-s', '-L', '-o', '/dev/null', '-w', '%{http_code}', '--max-time', '10', url])
        http_code = stdout.strip()

        if http_code == '404':
            results[d.lower()] = {"available": True, "price_usd": None, "source": "rdap"}
        elif http_code == '200':
            results[d.lower()] = {"available": False, "price_usd": None, "source": "rdap"}
        else:
            results[d.lower()] = {"available": None, "price_usd": None, "source": "rdap", "note": f"http_{http_code}"}

        if len(domain_list) > 1 and delay > 0:
            time.sleep(delay)

    return results

# ============================================================
# Combined availability check with fallback
# ============================================================
def check_availability(domain_list):
    """Check domains via NameSilo (primary) with RDAP fallback."""
    results = namesilo_check(domain_list)

    if results is None:
        # NameSilo failed — fall back to RDAP
        results = rdap_check(domain_list)

    # Fill in any missing domains
    for d in domain_list:
        dl = d.lower()
        if dl not in results:
            # Try RDAP for individual missing domains
            single = rdap_check([d], delay=0)
            if single:
                results.update(single)
            else:
                results[dl] = {"available": None, "price_usd": None, "source": "unknown", "note": "check_failed"}

    return results

# ============================================================
# Brand name -> domain variant generation
# ============================================================
def split_camel_case(name):
    """Split camelCase/PascalCase into words: NexusAI -> ['nexus', 'ai']"""
    # Insert separator before uppercase letters that follow lowercase
    parts = re.sub(r'([a-z])([A-Z])', r'\1_\2', name)
    # Insert separator before sequences of uppercase followed by lowercase
    parts = re.sub(r'([A-Z]+)([A-Z][a-z])', r'\1_\2', parts)
    words = [w.lower() for w in re.split(r'[-_\s.]+', parts) if w]
    return words

def generate_abbreviation(words):
    """First letter of each word: ['nexus', 'ai'] -> 'nai'"""
    if len(words) < 2:
        return None
    abbr = ''.join(w[0] for w in words if w)
    return abbr if len(abbr) >= 2 else None

def generate_variants(brand, tlds):
    """Generate domain variants for a brand name."""
    brand_clean = re.sub(r'[^a-zA-Z0-9]', '', brand).lower()
    words = split_camel_case(brand)
    hyphenated = '-'.join(words)
    abbr = generate_abbreviation(words)

    variants = []
    seen = set()

    def add(d):
        dl = d.lower()
        if dl not in seen:
            seen.add(dl)
            variants.append(dl)

    # 1. Exact: brand.{tld}
    for tld in tlds:
        add(f"{brand_clean}.{tld}")

    # 2. Prefixed: get/try/use/my + brand + .com
    for prefix in ['get', 'try', 'use', 'my']:
        add(f"{prefix}{brand_clean}.com")

    # 3. Hyphenated: nexus-ai.{tld}
    if hyphenated != brand_clean:
        for tld in tlds:
            add(f"{hyphenated}.{tld}")

    # 4. Short/abbreviation
    if abbr and abbr != brand_clean:
        for tld in ['com', 'io', 'ai']:
            if tld in tlds:
                add(f"{abbr}.{tld}")

    return variants

# ============================================================
# Trademark risk screening via Brave Search
# ============================================================
def check_trademark(brand):
    """Search Brave for trademark conflicts on USPTO/WIPO."""
    if not brave_key:
        return {"risk_level": "unknown", "note": "no_brave_api_key", "conflicts": []}

    query = f'"{brand}" trademark site:uspto.gov OR site:wipo.int'
    url = f"https://api.search.brave.com/res/v1/web/search?q={quote(query)}&count=5"

    stdout, rc = run_cmd([
        'curl', '-s', '--max-time', '10',
        '-H', f'X-Subscription-Token: {brave_key}',
        '-H', 'Accept: application/json',
        url
    ])

    if rc != 0 or not stdout:
        return {"risk_level": "unknown", "note": "brave_search_failed", "conflicts": []}

    try:
        data = json.loads(stdout)
        results = data.get('web', {}).get('results', [])

        conflicts = []
        for r in results[:5]:
            title = r.get('title', '')
            url_res = r.get('url', '')
            desc = r.get('description', '')[:200]
            if 'trademark' in (title + desc).lower() or 'uspto.gov' in url_res or 'wipo.int' in url_res:
                conflicts.append({
                    "title": title[:150],
                    "url": url_res,
                    "snippet": desc
                })

        if len(conflicts) >= 3:
            risk_level = "high"
        elif len(conflicts) >= 1:
            risk_level = "medium"
        else:
            risk_level = "low"

        return {"risk_level": risk_level, "conflicts": conflicts, "query_used": query}

    except (json.JSONDecodeError, KeyError):
        return {"risk_level": "unknown", "note": "parse_error", "conflicts": []}

# ============================================================
# MODE: availability
# ============================================================
if mode == 'availability':
    if not domain_arg:
        error_exit("domain_required_for_availability_mode")

    # Normalize domain
    d = domain_arg.lower().strip()
    d = re.sub(r'^https?://', '', d)
    d = re.sub(r'^www\.', '', d)
    d = d.split('/')[0]

    if '.' not in d:
        error_exit("invalid_domain_format")

    results = check_availability([d])
    info = results.get(d, {"available": None, "source": "unknown"})

    output_json({
        "mode": "availability",
        "domain": d,
        "available": info.get("available"),
        "price_usd": info.get("price_usd"),
        "source": info.get("source", "unknown"),
        "note": info.get("note"),
        "metadata": {
            "duration_ms": int((time.time() - start_time) * 1000)
        }
    })

# ============================================================
# MODE: suggest
# ============================================================
elif mode == 'suggest':
    domain_list = []

    if domains_arg:
        # Manual list provided
        domain_list = [d.strip().lower() for d in domains_arg.split(',') if d.strip()]
    elif brand_arg:
        # Generate variants from brand
        tlds = [t.strip() for t in (tlds_arg or 'com,io,ai,co,app,dev').split(',') if t.strip()]
        domain_list = generate_variants(brand_arg, tlds)
    else:
        error_exit("brand_or_domains_required_for_suggest_mode")

    if not domain_list:
        error_exit("no_domains_generated")

    # Bulk check availability
    results = check_availability(domain_list)

    available = []
    taken = []
    for d in domain_list:
        info = results.get(d, {"available": None, "source": "unknown"})
        entry = {
            "domain": d,
            "available": info.get("available"),
            "price_usd": info.get("price_usd"),
            "source": info.get("source", "unknown")
        }
        if info.get("note"):
            entry["note"] = info["note"]

        if info.get("available") is True:
            available.append(entry)
        else:
            taken.append(entry)

    # Sort available by price (cheapest first), None prices at end
    available.sort(key=lambda x: (x.get("price_usd") is None, x.get("price_usd") or 9999))

    # Trademark check
    trademark = {"risk_level": "unknown", "conflicts": []}
    brand_for_tm = brand_arg or (domains_arg.split(',')[0].split('.')[0] if domains_arg else '')
    if brand_for_tm:
        trademark = check_trademark(brand_for_tm)

    output_json({
        "mode": "suggest",
        "brand": brand_arg or None,
        "variants_checked": len(domain_list),
        "available": available,
        "taken": taken,
        "trademark_risk": trademark,
        "metadata": {
            "duration_ms": int((time.time() - start_time) * 1000),
            "domains_checked": len(domain_list),
            "source": results.get(domain_list[0], {}).get("source", "unknown") if domain_list else "unknown"
        }
    })

# ============================================================
# MODE: recommend
# ============================================================
elif mode == 'recommend':
    if not brand_arg:
        error_exit("brand_required_for_recommend_mode")

    budget = float(budget_arg) if budget_arg else 200.0
    if budget <= 0:
        budget = 200.0
    tlds = [t.strip() for t in (tlds_arg or 'com,io,ai,co,app,dev').split(',') if t.strip()]

    # Generate variants and check availability
    domain_list = generate_variants(brand_arg, tlds)
    results = check_availability(domain_list)

    available = []
    taken = []
    for d in domain_list:
        info = results.get(d, {"available": None, "source": "unknown"})
        entry = {
            "domain": d,
            "available": info.get("available"),
            "price_usd": info.get("price_usd"),
            "source": info.get("source", "unknown")
        }
        if info.get("note"):
            entry["note"] = info["note"]
        if info.get("available") is True:
            available.append(entry)
        else:
            taken.append(entry)

    # Sort by relevance: exact match > prefix > hyphen > abbreviation
    brand_clean = re.sub(r'[^a-zA-Z0-9]', '', brand_arg).lower()
    words = split_camel_case(brand_arg)
    hyphenated = '-'.join(words)
    abbr = generate_abbreviation(words)

    def relevance_score(domain):
        name = domain.split('.')[0]
        tld = domain.split('.')[-1]

        # TLD priority
        tld_priority = {'com': 0, 'ai': 1, 'io': 2, 'co': 3, 'app': 4, 'dev': 5}.get(tld, 6)

        if name == brand_clean:
            return (0, tld_priority)  # Exact match — highest
        elif name in [f"get{brand_clean}", f"try{brand_clean}", f"use{brand_clean}", f"my{brand_clean}"]:
            return (1, tld_priority)  # Prefixed
        elif name == hyphenated:
            return (2, tld_priority)  # Hyphenated
        elif abbr and name == abbr:
            return (3, tld_priority)  # Abbreviation
        else:
            return (4, tld_priority)

    available.sort(key=lambda x: relevance_score(x['domain']))

    # Trademark check
    trademark = check_trademark(brand_arg)

    # Build recommendation
    # Determine must_protect TLDs
    must_protect_tlds = []
    for tld in ['com', 'ai', 'io']:
        exact_domain = f"{brand_clean}.{tld}"
        info = results.get(exact_domain, {})
        if info.get('available') is True:
            must_protect_tlds.append({
                "domain": exact_domain,
                "price_usd": info.get("price_usd"),
                "reason": f".{tld} is essential for brand protection"
            })
        elif info.get('available') is False:
            must_protect_tlds.append({
                "domain": exact_domain,
                "available": False,
                "reason": f".{tld} already taken — consider acquiring or monitoring"
            })

    # Budget breakdown
    budget_items = []
    remaining_budget = budget
    for entry in available:
        price = entry.get("price_usd")
        if price and remaining_budget >= price:
            budget_items.append({
                "domain": entry["domain"],
                "price_usd": price,
                "priority": "high" if relevance_score(entry["domain"])[0] <= 1 else "medium"
            })
            remaining_budget -= price

    total_cost = sum(item["price_usd"] for item in budget_items)

    # Registrar recommendation
    registrar_recommendation = (
        "Cloudflare Registrar for .com domains ($9.77/yr at-cost pricing, no markup). "
        "Porkbun for .ai domains (~$70-80/2yr, competitive rates). "
        "NameSilo for bulk registration (good prices, free WHOIS privacy)."
    )

    output_json({
        "mode": "recommend",
        "brand": brand_arg,
        "budget_usd": budget,
        "recommendation": {
            "best_available": available[:10],
            "must_protect": must_protect_tlds,
            "registrar_recommendation": registrar_recommendation,
            "budget_breakdown": {
                "items": budget_items,
                "total_cost": round(total_cost, 2),
                "remaining_budget": round(remaining_budget, 2),
                "domains_affordable": len(budget_items)
            },
            "trademark_risk": trademark
        },
        "available": available,
        "taken": taken,
        "metadata": {
            "domains_checked": len(domain_list),
            "duration_ms": int((time.time() - start_time) * 1000),
            "source": results.get(domain_list[0], {}).get("source", "unknown") if domain_list else "unknown"
        }
    })

else:
    error_exit(f"invalid_mode: {mode}. Valid: availability, suggest, recommend")
PYEOF
