#!/bin/bash
# DELPHI-SOC — Self-Optimization Cycle runner
# Usage: delphi-soc.sh <phase> [options]
# Phases: ksl | ksl-burst | tool-scan | skill-optimize | research-scan | sol | epr-weekly | buffer-review
#
# ksl-burst options (delegated to ~/.nexus/ksl/ksl.sh --profile epr):
#   --experiments N    Max experiments (default: 20)
#   --cost-cap N       Max cost in USD (default: 3.00)
#   --pause N          Seconds between experiments (default: 30)
#   --stop-on-stable   Stop if 3 consecutive experiments show no improvement
#   --auto-apply       Auto-apply KEEP experiments to SKILL.md (with guard + rollback)
#   --skill-file PATH  Target SKILL.md (default: skills/scout-web/SKILL.md)

set -euo pipefail

PHASE="${1:-}"
shift || true
# NOTE: --dangerously-skip-permissions required for unattended SOC runs (security decision)
CLAUDE_BIN="${CLAUDE_BIN:-$(command -v claude 2>/dev/null || echo "$HOME/.local/bin/claude")}"

# Parse ksl-burst options
BURST_EXPERIMENTS=20
BURST_COST_CAP="3.00"
BURST_PAUSE=30
BURST_STOP_STABLE=true
AUTO_APPLY=false
SKILL_FILE=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --experiments) BURST_EXPERIMENTS="$2"; shift 2 ;;
    --cost-cap) BURST_COST_CAP="$2"; shift 2 ;;
    --depth) echo "WARN: --depth is deprecated (now in ksl-config.yaml epr profile)" >&2; shift 2 ;;
    --pause) BURST_PAUSE="$2"; shift 2 ;;
    --stop-on-stable) BURST_STOP_STABLE=true; shift ;;
    --no-stop-on-stable) BURST_STOP_STABLE=false; shift ;;
    --auto-apply) AUTO_APPLY=true; shift ;;
    --skill-file) SKILL_FILE="$2"; shift 2 ;;
    *) echo "WARN: unknown option '$1'" >&2; shift ;;
  esac
done
PLUGIN_ROOT="$HOME/.claude/plugins/delphi"
LOG_DIR="$HOME/.nexus/logs"
LOG_FILE="$LOG_DIR/delphi-soc.log"
LOCK_DIR="$HOME/.nexus/locks"
LOCK_FILE="$LOCK_DIR/delphi-soc-${PHASE}.lock"
STATE_FILE="$PLUGIN_ROOT/resources/state.json"

# S3: Default skill file if not specified
[[ -z "$SKILL_FILE" ]] && SKILL_FILE="$PLUGIN_ROOT/skills/scout-web/SKILL.md"

mkdir -p "$LOG_DIR" "$LOCK_DIR"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] [SOC:$PHASE] $*" >> "$LOG_FILE"; }

# retry_with_timeout — wrap command with retry (max 2 attempts, 300s total cap) (4E fix)
retry_with_timeout() {
    local _attempt=1 _rc=0
    while [ "$_attempt" -le 2 ]; do
        timeout 300 "$@" && return 0
        _rc=$?
        log "RETRY: attempt $_attempt failed (exit $_rc)"
        [ "$_attempt" -lt 2 ] && sleep 60
        _attempt=$((_attempt + 1))
    done
    log "RETRY: all 2 attempts failed"
    return $_rc
}


# PID lock — prevent concurrent runs of same phase
if [ -f "$LOCK_FILE" ]; then
    OLD_PID=$(cat "$LOCK_FILE" 2>/dev/null)
    if kill -0 "$OLD_PID" 2>/dev/null; then
        log "SKIP: phase $PHASE already running (PID $OLD_PID)"
        exit 0
    fi
    rm -f "$LOCK_FILE"
fi
echo $$ > "$LOCK_FILE"
trap 'rm -f "$LOCK_FILE"' EXIT

if [ -z "$PHASE" ]; then
    echo "Usage: delphi-soc.sh <phase> [options]"
    echo "Phases: ksl | ksl-burst | tool-scan | skill-optimize | research-scan | sol | epr-weekly | buffer-review"
    echo ""
    echo "ksl-burst options:"
    echo "  --experiments N    Max experiments (default: 20)"
    echo "  --cost-cap N       Max cost in USD (default: 3.00)"
    echo "  # --depth is deprecated (now in ksl-config.yaml epr profile)"
    echo "  --pause N          Seconds between experiments (default: 30)"
    echo "  --stop-on-stable   Stop if 3 consecutive no improvement (default: true)"
    echo "  --auto-apply       Auto-apply KEEP experiments to SKILL.md (guard + rollback)"
    echo "  --skill-file PATH  Target SKILL.md (default: skills/scout-web/SKILL.md)"
    exit 1
fi

if [ ! -x "$CLAUDE_BIN" ] && ! command -v claude &>/dev/null; then
    log "ERROR: claude CLI not found at $CLAUDE_BIN"
    exit 1
fi

log "START phase=$PHASE"

case "$PHASE" in
    ksl)
        # Faza 0: KSL — micro-experiments with binary EPR eval
        retry_with_timeout "$CLAUDE_BIN" --print --dangerously-skip-permissions \
            -p "You are DELPHI PRO SOC running KSL (Faza 0).
Read human-program.md at $PLUGIN_ROOT/resources/human-program.md for current focus.
Read state.json at $STATE_FILE for research history and baselines.
Pick a random topic from history. Apply ONE modification to ONE skill prompt.
Run a D2 research test. Compare EPR: if better, keep (git commit). If worse, revert.
Log result to state.json ksl section.
Max 5 experiments this run. Cost cap: \$1.00.
Never modify: agents/delphi.md, human-program.md, handoff contracts." \
            2>> "$LOG_FILE" >> "$LOG_FILE"
        ;;

    tool-scan)
        # Faza 1: Weekly tool discovery
        retry_with_timeout "$CLAUDE_BIN" --print --dangerously-skip-permissions \
            -p "You are DELPHI PRO SOC running Tool Scan (Faza 1).
Run /research 'new AI research tools MCP servers API changes last 7 days' at D2 depth.
Parse findings for actionable tool discoveries.
Check existing CLI tools health (run each with test query).
Check MCP tools still available.
Flag broken/deprecated tools.
Save report to $PLUGIN_ROOT/reports/tool-scan-$(date +%Y-%m-%d).json.
If changes found, note them for Quality Gate review." \
            2>> "$LOG_FILE" >> "$LOG_FILE"
        # 5A fix: stale EPR alert after tool scan
        _epr_updated=$(python3 -c "
import json, os, datetime
sf = os.path.expanduser('~/.nexus/ksl/state/ksl-state.json')
try:
    s = json.load(open(sf))
    updated = s.get('profiles', {}).get('epr', {}).get('last_updated', '')
    if not updated:
        print('STALE: epr.last_updated missing')
    else:
        age = (datetime.datetime.now(datetime.timezone.utc) - datetime.datetime.fromisoformat(updated.replace('Z','+00:00'))).days
        print('STALE:' + str(age) + 'd' if age > 7 else 'OK:' + str(age) + 'd')
except Exception as e:
    print('STALE:error:' + str(e))
" 2>/dev/null || echo "STALE:check_failed")
        if echo "$_epr_updated" | grep -q "^STALE"; then
            log "SENTINEL-NOTIFY: EPR burst stale — $_epr_updated"
        else
            log "EPR freshness: $_epr_updated"
        fi
        ;;

    skill-optimize)
        # Faza 2: Bi-weekly skill prompt optimization
        retry_with_timeout "$CLAUDE_BIN" --print --dangerously-skip-permissions \
            -p "You are DELPHI PRO SOC running Skill Optimize (Faza 2).
Load all SKILL.md files from $PLUGIN_ROOT/skills/.
Evaluate each with Skill Creator 3.0 criteria (format, description, boundaries, contract, reusability).
Only optimize skills scoring < 75 or with performance issues in state.json.
Apply max 3 PE techniques per skill. Preserve handoff contracts and frontmatter.
Save report to $PLUGIN_ROOT/reports/skill-optimize-$(date +%Y-%m-%d).json." \
            2>> "$LOG_FILE" >> "$LOG_FILE"
        ;;

    research-scan)
        # Faza 3: Bi-weekly research best practices discovery
        retry_with_timeout "$CLAUDE_BIN" --print --dangerously-skip-permissions \
            -p "You are DELPHI PRO SOC running Research Scan (Faza 3).
Run /research-deep 'AI research agent best practices prompt engineering techniques last 14 days' at D3 depth.
Classify findings: HIGH (architectural) / MEDIUM (optimization) / LOW (nice-to-have).
HIGH priority: flag for Pafi review, never auto-apply.
MEDIUM: add to optimization-buffer.md.
Save findings to Cortex (collection: research, tag: delphi-soc).
Save report to $PLUGIN_ROOT/reports/research-scan-$(date +%Y-%m-%d).json." \
            2>> "$LOG_FILE" >> "$LOG_FILE"
        ;;

    sol)
        # Faza 5: Weekly SOL on all prompts
        retry_with_timeout "$CLAUDE_BIN" --print --dangerously-skip-permissions \
            -p "You are DELPHI PRO SOC running SOL (Faza 5).
Scan all 20 DELPHI PRO prompts across $PLUGIN_ROOT.
Evaluate each on 5 dimensions (Opus-level assessment).
Apply PE techniques to weakest dimensions (Sonnet execution).
Auto-approve if delta >= +5, flag Pafi if < +5.
Save report to $PLUGIN_ROOT/reports/sol-$(date +%Y-%m-%d).json." \
            2>> "$LOG_FILE" >> "$LOG_FILE"
        ;;

    epr-weekly)
        # Faza 5.25: Weekly EPR scoring (pipeline-epr-delphi + pipeline-epr-mercury)
        # Runs real D2 pipeline, measures output quality, logs to ksl-state.json
        log "START EPR weekly: Delphi D2 pipeline"
        bash "${HOME}/.nexus/ksl/ksl-pipeline.sh" --profile pipeline-epr-delphi --max-iter 2 \
            2>> "$LOG_FILE" >> "$LOG_FILE" || log "WARN: Delphi EPR failed (exit $?)"

        log "START EPR weekly: Mercury discover-market pipeline"
        bash "${HOME}/.nexus/ksl/ksl-pipeline.sh" --profile pipeline-epr-mercury --max-iter 2 \
            2>> "$LOG_FILE" >> "$LOG_FILE" || log "WARN: Mercury EPR failed (exit $?)"

        log "EPR weekly complete. Results in ~/.nexus/ksl/state/ksl-state.json"

        # 5C fix: Delphi scouts batch (all 16 Delphi scout skills)
        log "START KSL Delphi scouts batch"
        bash "${HOME}/.nexus/ksl/ksl.sh" --profile nplf \
            --batch "${HOME}/.claude/plugins/delphi/skills/" \
            --max-skills=16 \
            2>> "$LOG_FILE" >> "$LOG_FILE" || log "WARN: Delphi scouts batch failed (exit $?)"
        log "Delphi scouts batch complete"
        ;;

    buffer-review)
        # Faza 5.5: Weekly buffer review
        retry_with_timeout "$CLAUDE_BIN" --print --dangerously-skip-permissions \
            -p "You are DELPHI PRO SOC running Buffer Review (Faza 5.5).
Read $PLUGIN_ROOT/resources/optimization-buffer.md.
List all pending proposals with context.
This is an informational run — log proposals to $PLUGIN_ROOT/reports/buffer-review-$(date +%Y-%m-%d).json.
Do NOT auto-apply any proposals. Pafi decides." \
            2>> "$LOG_FILE" >> "$LOG_FILE"
        ;;

    karpathy)
        # Daily karpathy EPR phase — delegate to ksl.sh --profile epr with conservative defaults (0D fix)
        log "START karpathy phase: delegating to KSL EPR burst (conservative)"
        retry_with_timeout "${HOME}/.nexus/ksl/ksl.sh" --profile epr --burst \
            --experiments=5 \
            --cost-cap=1.00 \
            --stop-on-stable \
            2>> "$LOG_FILE" >> "$LOG_FILE" || log "WARN: karpathy EPR burst failed (exit $?)"
        log "END karpathy phase"
        ;;

    ksl-burst|karpathy-burst)
        # Delegated to unified KSL Karpathy framework (2026-03-22)
        # Original inline code (~400 lines) replaced with exec to ~/.nexus/ksl/ksl.sh
        KSL_ARGS=(--profile epr --burst)
        [[ -n "$BURST_EXPERIMENTS" ]] && KSL_ARGS+=(--experiments "$BURST_EXPERIMENTS")
        [[ -n "$BURST_COST_CAP" ]] && KSL_ARGS+=(--cost-cap "$BURST_COST_CAP")
        [[ -n "$BURST_PAUSE" ]] && KSL_ARGS+=(--pause "$BURST_PAUSE")
        [[ "$BURST_STOP_STABLE" == "true" ]] && KSL_ARGS+=(--stop-on-stable)
        [[ "$AUTO_APPLY" == "true" ]] && KSL_ARGS+=(--auto-apply)
        [[ -n "$SKILL_FILE" ]] && KSL_ARGS+=(--skill-file "$SKILL_FILE")
        log "KSL DISPATCH: ${KSL_ARGS[*]}"
        exec "${HOME}/.nexus/ksl/ksl.sh" "${KSL_ARGS[@]}"
        # exec replaces process — code below is unreachable (kept ;; for case syntax)
        ;;

    *)
        log "ERROR: unknown phase '$PHASE'"
        echo "Unknown phase: $PHASE"
        exit 1
        ;;
esac

rc=$?
log "END phase=$PHASE exit=$rc"
