# OpenClaw Hooks Compatibility Note

## Status

The bash hook scripts in this directory (`pre-research.sh`, `post-research.sh`, `on-error.sh`, `pre-research-quota.sh`) are **not executed by the OpenClaw runtime**. OpenClaw does not support bash-based lifecycle hooks. These scripts exist for use in other execution contexts (direct Claude Code execution, cron-based SOC, etc.).

## Why

OpenClaw uses a declarative event model for hooks rather than executing arbitrary shell scripts. The `capabilities.hooks: false` flag in `openclaw.plugin.json` reflects this.

## Event Mapping

If you wish to replicate equivalent behavior in an OpenClaw-native environment, the following mapping applies:

| Bash script | OpenClaw event | Purpose |
|:---|:---|:---|
| `pre-research.sh` | `event: "before:skill:execute"` | Validate environment, check API keys, enforce depth limits |
| `post-research.sh` | `event: "after:skill:execute"` | Save results to state, update Cortex, send notifications |
| `on-error.sh` | `event: "error:skill:execute"` | Alert on failure, log error details, trigger fallback logic |
| `pre-research-quota.sh` | `event: "before:skill:execute"` | Quota check — verify cost budget before allowing research to proceed |

## What the Bash Scripts Actually Do

- **`pre-research.sh`**: Checks that required API keys are available in macOS Keychain (via `lib/resolve-key.sh`). Verifies depth parameter is valid (D1-D4). Writes session start to `resources/state.json`.
- **`pre-research-quota.sh`**: Reads current monthly spend from `resources/state.json`. Blocks execution if cost would exceed `max_cost_per_run` or monthly cap.
- **`post-research.sh`**: Appends run summary to `resources/state.json`. Triggers Cortex session log. Sends Telegram notification on D3/D4 completion.
- **`on-error.sh`**: Writes error details to `~/.nexus/logs/delphi-soc.log`. Sends Telegram alert. Marks run as `failed` in `state.json`.

## OpenClaw-Native Implementation Guide

To implement equivalent hooks in OpenClaw, declare them in your plugin manifest extension:

```json
{
  "hooks": [
    {
      "event": "before:skill:execute",
      "skill": "*",
      "action": "quota-check",
      "config": { "max_cost_usd": 8.0 }
    },
    {
      "event": "after:skill:execute",
      "skill": "*",
      "action": "state-update"
    },
    {
      "event": "error:skill:execute",
      "skill": "*",
      "action": "alert-and-log"
    }
  ]
}
```

The actual hook logic must be reimplemented as OpenClaw-native action handlers rather than shell scripts.
