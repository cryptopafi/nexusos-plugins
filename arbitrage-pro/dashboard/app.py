"""Arbitrage Pro Dashboard — FastAPI + HTMX + Tailwind"""

import hashlib
import hmac
import json
import secrets
import subprocess
import os
from datetime import datetime, timezone
from pathlib import Path

import yaml
from fastapi import Cookie, FastAPI, Form, Request, BackgroundTasks
from fastapi.responses import HTMLResponse, JSONResponse, RedirectResponse
from fastapi.staticfiles import StaticFiles
from fastapi.templating import Jinja2Templates

app = FastAPI(title="Arbitrage Pro", docs_url="/api/docs")

# ─── Password Protection ───────────────────────────────
DASHBOARD_PASSWORD = os.environ.get("ARB_PASSWORD", "ArbitragePro2026!")
SESSION_SECRET = os.environ.get("ARB_SESSION_SECRET", secrets.token_hex(32))


def make_token(password: str) -> str:
    return hmac.new(SESSION_SECRET.encode(), password.encode(), hashlib.sha256).hexdigest()


VALID_TOKEN = make_token(DASHBOARD_PASSWORD)

LOGIN_PAGE = """<!DOCTYPE html>
<html lang="en"><head>
<meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Arbitrage Pro | Login</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;600;700&display=swap" rel="stylesheet">
<style>
  * { margin: 0; padding: 0; box-sizing: border-box; }
  body { background: #0A0A0F; color: #f0f0f0; font-family: 'Inter', system-ui, sans-serif;
         display: flex; align-items: center; justify-content: center; min-height: 100vh; }
  .card { background: rgba(17,17,24,0.7); backdrop-filter: blur(12px); border: 1px solid rgba(255,255,255,0.06);
          border-radius: 16px; padding: 2.5rem; width: 360px; }
  h1 { font-size: 1.5rem; font-weight: 700; margin-bottom: 0.5rem; }
  .sub { color: #64748b; font-size: 0.875rem; margin-bottom: 1.5rem; }
  input { width: 100%%; padding: 0.75rem 1rem; background: rgba(255,255,255,0.05); border: 1px solid rgba(255,255,255,0.1);
          border-radius: 8px; color: #f0f0f0; font-size: 1rem; font-family: inherit; outline: none; }
  input:focus { border-color: #58a6ff; }
  button { width: 100%%; margin-top: 1rem; padding: 0.75rem; background: linear-gradient(135deg, #6366f1, #8b5cf6);
           border: none; border-radius: 8px; color: white; font-size: 1rem; font-weight: 600;
           cursor: pointer; transition: opacity 150ms; }
  button:hover { opacity: 0.9; }
  .err { color: #ef4444; font-size: 0.8rem; margin-top: 0.75rem; display: {err_display}; }
  .logo { width: 40px; height: 40px; background: linear-gradient(135deg, #6366f1, #8b5cf6);
          border-radius: 12px; display: flex; align-items: center; justify-content: center;
          font-weight: 700; font-size: 1.25rem; margin-bottom: 1.25rem; }
</style></head><body>
<div class="card">
  <div class="logo">A</div>
  <h1>Arbitrage Pro</h1>
  <div class="sub">Enter password to access the dashboard</div>
  <form method="POST" action="/login">
    <input type="password" name="password" placeholder="Password" autofocus>
    <button type="submit">Enter</button>
    <div class="err">Incorrect password</div>
  </form>
</div></body></html>"""


def check_auth(auth_token: str | None) -> bool:
    if not auth_token:
        return False
    return hmac.compare_digest(auth_token, VALID_TOKEN)


@app.get("/login", response_class=HTMLResponse)
async def login_page():
    return LOGIN_PAGE.replace("{err_display}", "none")


@app.post("/login")
async def login_submit(password: str = Form("")):
    if password == DASHBOARD_PASSWORD:
        response = RedirectResponse("/", status_code=302)
        response.set_cookie("arb_auth", make_token(password), httponly=True, max_age=86400 * 7)
        return response
    return HTMLResponse(LOGIN_PAGE.replace("{err_display}", "block"), status_code=401)

BASE_DIR = Path(__file__).parent
PLUGIN_DIR = BASE_DIR.parent
# On VPS, state/ is inside BASE_DIR; locally it's in PLUGIN_DIR
_env_state = os.environ.get("ARB_STATE_DIR", "")
if _env_state and Path(_env_state).is_dir():
    STATE_DIR = Path(_env_state)
elif (BASE_DIR / "state").is_dir():
    STATE_DIR = BASE_DIR / "state"
else:
    STATE_DIR = PLUGIN_DIR / "state"
SCRIPTS_DIR = BASE_DIR / "scripts" if (BASE_DIR / "scripts").is_dir() else PLUGIN_DIR / "scripts"

app.mount("/static", StaticFiles(directory=BASE_DIR / "static"), name="static")

templates = Jinja2Templates(directory=BASE_DIR / "templates")


# ─── Data Loaders ───────────────────────────────────────

def load_json(filename: str) -> list | dict:
    path = STATE_DIR / filename
    if not path.exists():
        return [] if filename.endswith(".json") else {}
    with open(path) as f:
        return json.load(f)


def load_yaml(filename: str) -> dict:
    path = STATE_DIR / filename
    if not path.exists():
        return {}
    with open(path) as f:
        return yaml.safe_load(f) or {}


def get_categories() -> dict:
    return load_yaml("category-intelligence.yaml")


def get_run_log() -> list:
    return load_json("run-log.json")


def get_deals() -> list:
    """Extract deals from run-log results (deals.json is empty at MVP)."""
    runs = get_run_log()
    deals = []
    for run in runs:
        for r in run.get("results", []):
            if r.get("verdict") in ("BUY", "WATCH"):
                deals.append({
                    "run_id": run.get("run_id"),
                    "timestamp": run.get("timestamp"),
                    "category": run.get("category", r.get("category", "mixed")),
                    "platform": ", ".join(run.get("platforms", [run.get("platform", "TWK")])),
                    **r,
                })
    return sorted(deals, key=lambda d: d.get("roi_pct", 0), reverse=True)


def get_lots_seen() -> list:
    return load_json("lots-seen.json")


def get_tool_matrix() -> dict:
    return load_json("tool-success-matrix.json")


# ─── KPI Computation ────────────────────────────────────

def compute_kpi() -> dict:
    runs = get_run_log()
    deals = get_deals()
    categories = get_categories()

    total_runs = len(runs)
    total_lots = sum(r.get("lots_scanned", r.get("categories_tested", 0)) for r in runs)
    buy_deals = [d for d in deals if d.get("verdict") == "BUY"]
    watch_deals = [d for d in deals if d.get("verdict") == "WATCH"]
    top_roi = max((d.get("roi_pct", 0) for d in deals), default=0)

    tier_counts = {
        "tier_1": len(categories.get("tier_1_profitable", {})),
        "tier_2": len(categories.get("tier_2_profitable", {})),
        "tier_3": len(categories.get("tier_3_marginal", {})),
        "tier_4": len(categories.get("tier_4_unprofitable", {})),
        "deferred": len(categories.get("deferred", {})),
    }
    total_categories = sum(tier_counts.values())

    return {
        "total_runs": total_runs,
        "total_lots": total_lots,
        "buy_count": len(buy_deals),
        "watch_count": len(watch_deals),
        "top_roi": round(top_roi, 1),
        "total_categories": total_categories,
        "tier_counts": tier_counts,
        "lots_tracked": len(get_lots_seen()),
    }


# ─── Category Helpers ───────────────────────────────────

def flatten_categories() -> list:
    """Flatten YAML tiers into a list of category dicts with tier info."""
    cats = get_categories()
    result = []
    tier_map = {
        "tier_1_profitable": {"tier": 1, "label": "Tier 1 — Profitable", "color": "green"},
        "tier_2_profitable": {"tier": 2, "label": "Tier 2 — Profitable", "color": "blue"},
        "tier_3_marginal": {"tier": 3, "label": "Tier 3 — Marginal", "color": "yellow"},
        "tier_4_unprofitable": {"tier": 4, "label": "Tier 4 — Unprofitable", "color": "red"},
        "deferred": {"tier": 5, "label": "Deferred", "color": "gray"},
    }
    for tier_key, meta in tier_map.items():
        tier_data = cats.get(tier_key, {})
        if isinstance(tier_data, dict):
            for name, data in tier_data.items():
                if isinstance(data, dict):
                    result.append({"name": name, **meta, **data})
                else:
                    result.append({"name": name, **meta, "status": data})
        elif isinstance(tier_data, list):
            for name in tier_data:
                result.append({"name": name, **meta})
    return result


# ─── Routes: Pages ──────────────────────────────────────

@app.get("/", response_class=HTMLResponse)
async def index(request: Request, arb_auth: str | None = Cookie(None)):
    if not check_auth(arb_auth):
        return RedirectResponse("/login", status_code=302)
    return templates.TemplateResponse(request, "base.html", {
        "kpi": compute_kpi(),
        "deals": get_deals(),
        "categories": flatten_categories(),
        "runs": get_run_log(),
        "now": datetime.now(timezone.utc).isoformat(),
    })


# ─── Routes: HTMX Partials ─────────────────────────────

@app.get("/partials/kpi", response_class=HTMLResponse)
async def partial_kpi(request: Request):
    return templates.TemplateResponse(request, "partials/kpi-bar.html", {
        "kpi": compute_kpi(),
    })


@app.get("/partials/deals", response_class=HTMLResponse)
async def partial_deals(request: Request):
    return templates.TemplateResponse(request, "partials/deals.html", {
        "deals": get_deals(),
    })


@app.get("/partials/categories", response_class=HTMLResponse)
async def partial_categories(request: Request):
    return templates.TemplateResponse(request, "partials/categories.html", {
        "categories": flatten_categories(),
    })


@app.get("/partials/history", response_class=HTMLResponse)
async def partial_history(request: Request):
    return templates.TemplateResponse(request, "partials/history.html", {
        "runs": get_run_log(),
    })


# ─── Routes: API (JSON) ────────────────────────────────

@app.get("/api/kpi")
async def api_kpi():
    return compute_kpi()


@app.get("/api/deals")
async def api_deals():
    return get_deals()


@app.get("/api/categories")
async def api_categories():
    return flatten_categories()


@app.get("/api/history")
async def api_history():
    return get_run_log()


@app.get("/api/lot/{lot_id}")
async def api_lot(lot_id: str, platform: str = "TWK"):
    """Live price check via GraphQL API (pure Python, no shell dependency)."""
    import urllib.request
    for plat in ([platform] if platform != "ALL" else ["TWK", "SPX", "VAVATO"]):
        try:
            q = json.dumps({
                "query": '{ lotDetails(displayId: "' + lot_id + '", locale: "en", platform: ' + plat + ') '
                         '{ lot { displayId title urlSlug currentBidAmount { cents currency } '
                         'visiblePlatforms } } }'
            })
            req = urllib.request.Request(
                GRAPHQL_URL,
                data=q.encode(),
                headers={"Content-Type": "application/json"},
            )
            with urllib.request.urlopen(req, timeout=10) as resp:
                data = json.loads(resp.read())
            lot_data = data.get("data", {}).get("lotDetails", {}).get("lot")
            if lot_data:
                bid = lot_data.get("currentBidAmount") or {}
                cents = bid.get("cents", 0)
                return {
                    "lot_id": lot_data.get("displayId", lot_id),
                    "title": lot_data.get("title", ""),
                    "current_bid_eur": cents / 100 if cents else 0,
                    "currency": bid.get("currency", "EUR"),
                    "platform": (lot_data.get("visiblePlatforms") or [plat])[0],
                }
        except Exception:
            continue
    return JSONResponse({"error": f"Lot {lot_id} not found on any platform"}, status_code=404)


@app.get("/api/tools")
async def api_tools():
    return get_tool_matrix()


GRAPHQL_URL = "https://storefront.tbauctions.com/storefront/graphql"
PLATFORM_DOMAINS = {
    "TWK": "www.troostwijkauctions.com",
    "SPX": "www.surplex.com",
    "VAVATO": "www.vavato.com",
    "BVA": "www.bfrench.com",
}


@app.get("/go/{lot_id}")
async def go_to_lot(lot_id: str):
    """Redirect to the correct auction page by fetching urlSlug from GraphQL."""
    import urllib.request
    query = json.dumps({
        "query": f'{{ lotDetails(displayId: "{lot_id}", locale: "en", platform: TWK) '
                 f'{{ lot {{ urlSlug visiblePlatforms }} }} }}'
    })
    for platform in ["TWK", "SPX"]:
        try:
            q = json.dumps({
                "query": f'{{ lotDetails(displayId: "{lot_id}", locale: "en", platform: {platform}) '
                         f'{{ lot {{ urlSlug visiblePlatforms }} }} }}'
            })
            req = urllib.request.Request(
                GRAPHQL_URL,
                data=q.encode(),
                headers={"Content-Type": "application/json"},
            )
            with urllib.request.urlopen(req, timeout=10) as resp:
                data = json.loads(resp.read())
            lot = data.get("data", {}).get("lotDetails", {}).get("lot")
            if lot and lot.get("urlSlug"):
                visible = lot.get("visiblePlatforms", [platform])
                domain = PLATFORM_DOMAINS.get(visible[0] if visible else platform, "www.surplex.com")
                return RedirectResponse(f"https://{domain}/en/l/{lot['urlSlug']}")
        except Exception:
            continue
    # Fallback: surplex search
    return RedirectResponse(f"https://www.surplex.com/en/search?q={lot_id}")


# ─── Hunt Trigger ───────────────────────────────────────

def run_hunt(category: str, region: str, min_margin: int):
    """Background task: run hunt pipeline via GraphQL search."""
    script = SCRIPTS_DIR / "troostwijk-graphql.sh"
    subprocess.run(
        ["bash", str(script), "--search", category, "TWK", "5"],
        capture_output=True, text=True, timeout=120,
    )


@app.post("/api/hunt")
async def api_hunt(
    background_tasks: BackgroundTasks,
    category: str = Form("compressors-industrial"),
    region: str = Form("all"),
    min_margin: int = Form(30),
):
    background_tasks.add_task(run_hunt, category, region, min_margin)
    return HTMLResponse(f"""
    <div class="glass-card p-4 border-l-2 border-l-[#22c55e]">
      <div class="flex items-center gap-2 mb-1">
        <div class="w-2 h-2 rounded-full bg-[#22c55e] pulse"></div>
        <span class="text-sm font-medium text-[#22c55e]">Hunt Dispatched</span>
      </div>
      <div class="text-xs text-[#94a3b8]">
        Category: <span class="font-mono">{category}</span> &middot;
        Platform: <span class="font-mono">{region}</span> &middot;
        Min ROI: <span class="font-mono">{min_margin}%</span>
      </div>
      <div class="text-xs text-[#64748b] mt-1">Scanning via GraphQL API... Results will appear in the Deals tab.</div>
    </div>
    """)


@app.post("/api/hunt/search")
async def api_hunt_search(
    background_tasks: BackgroundTasks,
    query: str = Form(""),
):
    """Free-text search across TWK + SPX via GraphQL."""
    if not query.strip():
        return HTMLResponse('<div class="text-sm text-[#ef4444]">Please enter a search term.</div>')
    background_tasks.add_task(run_hunt, query.strip(), "all", 0)
    return HTMLResponse(f"""
    <div class="glass-card p-4 border-l-2 border-l-[#58a6ff]">
      <div class="flex items-center gap-2 mb-1">
        <div class="w-2 h-2 rounded-full bg-[#58a6ff] pulse"></div>
        <span class="text-sm font-medium text-[#58a6ff]">Searching</span>
      </div>
      <div class="text-xs text-[#94a3b8]">
        Query: <span class="font-mono">"{query}"</span> &middot; Platforms: TWK + SPX
      </div>
      <div class="text-xs text-[#64748b] mt-1">Searching 80,000+ lots... Results will appear in the Deals tab.</div>
    </div>
    """)


# ─── Auto-Scan ─────────────────────────────────────────

autoscan_state = {"enabled": False, "last_run": None, "deals_found": 0}

@app.post("/api/autoscan")
async def api_autoscan_toggle(request: Request):
    body = await request.json()
    autoscan_state["enabled"] = body.get("enabled", False)
    return autoscan_state


@app.get("/api/autoscan")
async def api_autoscan_status():
    return autoscan_state


# ─── Telegram Alerts ───────────────────────────────────

def send_telegram_alert(category: str, lot_id: str, title: str, roi: float, max_bid: str, verdict: str, current_bid: str = ""):
    """Send deal alert via Telegram Bot API."""
    alert_script = SCRIPTS_DIR / "telegram-alert.sh"
    if alert_script.exists():
        subprocess.run(
            ["bash", str(alert_script), category, lot_id, title, str(roi), max_bid, verdict, current_bid],
            capture_output=True, text=True, timeout=60,
        )


@app.post("/api/alert")
async def api_send_alert(
    background_tasks: BackgroundTasks,
    category: str = Form(""),
    lot_id: str = Form(""),
    title: str = Form(""),
    roi: float = Form(0),
    max_bid: str = Form(""),
    verdict: str = Form("BUY"),
    current_bid: str = Form(""),
):
    """Manually trigger a Telegram alert for a deal."""
    background_tasks.add_task(send_telegram_alert, category, lot_id, title, roi, max_bid, verdict, current_bid)
    return {"status": "alert_queued", "category": category, "verdict": verdict}


@app.post("/api/alert/test")
async def api_test_alert(background_tasks: BackgroundTasks):
    """Send a test alert."""
    background_tasks.add_task(
        send_telegram_alert,
        "compressors-industrial", "A1-43994-1",
        "Atlas Copco GA 30 (1995)", 267.0, "200", "BUY", "100",
    )
    return {"status": "test_alert_queued"}


# ─── Health ─────────────────────────────────────────────

@app.get("/health")
async def health():
    return {
        "status": "ok",
        "state_files": {
            f.name: f.stat().st_size
            for f in STATE_DIR.iterdir()
            if f.is_file()
        },
        "timestamp": datetime.now(timezone.utc).isoformat(),
    }
