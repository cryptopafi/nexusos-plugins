#!/bin/bash
# CCP-004 mapping: Custom post-research hook (fires after research pipeline completion)
# post-research.sh — DELPHI PRO post-research hook
# Runs after each research session. Updates state, logs MCP usage.
set -euo pipefail

PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"

TOPIC="${1:-}"
DEPTH="${2:-auto}"
EPR="${3:-0}"
DURATION="${4:-0}"

# 1. Update state.json
export TOPIC DEPTH EPR DURATION PLUGIN_ROOT
python3 << 'PYEOF'
import json, os, datetime

state_path = os.path.join(os.environ['PLUGIN_ROOT'], 'resources', 'state.json')
try:
    with open(state_path) as f:
        state = json.load(f)

    depth = os.environ.get('DEPTH', 'D2')
    epr = int(os.environ.get('EPR', '0'))
    duration = int(os.environ.get('DURATION', '0'))

    state['total_runs'] += 1
    if depth in state['runs_by_depth']:
        state['runs_by_depth'][depth] += 1
        # Running average EPR
        runs = state['runs_by_depth'][depth]
        old_avg = state['avg_epr_by_depth'].get(depth, 0)
        state['avg_epr_by_depth'][depth] = round(((old_avg * (runs - 1)) + epr) / runs, 1)

    state['last_run'] = datetime.datetime.now().isoformat()

    # critic_stats: track D3/D4 runs and EPR>0 as proxy for critic usage
    cs = state.setdefault('critic_stats', {
        'd3_runs_total': 0, 'd3_runs_with_critic': 0,
        'd4_runs_total': 0, 'd4_runs_with_critic': 0,
        'compliance_rate': 0.0
    })
    if depth == 'D3':
        cs['d3_runs_total'] += 1
        if epr > 0:
            cs['d3_runs_with_critic'] += 1
    elif depth == 'D4':
        cs['d4_runs_total'] += 1
        if epr > 0:
            cs['d4_runs_with_critic'] += 1
    total_critic_runs = cs['d3_runs_total'] + cs['d4_runs_total']
    total_with_critic = cs['d3_runs_with_critic'] + cs['d4_runs_with_critic']
    cs['compliance_rate'] = round(total_with_critic / total_critic_runs, 2) if total_critic_runs > 0 else 0.0
    state['critic_stats'] = cs

    # channel_quotas: increment brave.used_this_month by estimated queries per depth
    brave_est = {'D1': 1, 'D2': 3, 'D3': 8, 'D4': 15}
    try:
        state['channel_quotas']['brave']['used_this_month'] += brave_est.get(depth, 3)
    except (KeyError, TypeError):
        pass

    tmp_path = state_path + '.tmp'
    with open(tmp_path, 'w') as f:
        json.dump(state, f, indent=2)
    os.rename(tmp_path, state_path)
except Exception as e:
    import sys
    print(f"[post-research] ERROR updating state.json: {e}", file=sys.stderr)
PYEOF

# 2. Log completion
echo "[DELPHI-PRO] Research complete: topic='${TOPIC}', depth=${DEPTH}, EPR=${EPR}, duration=${DURATION}s" >> ~/.nexus/logs/delphi.log 2>/dev/null || true

echo "post-research OK"
