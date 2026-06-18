---
name: pipeline
description: "Bitbucket CI: status/wait/diagnose. Trigger: 'pipeline', 'CI', 'build', '파이프라인', 'build failed', 'CI 결과'"
argument-hint: ""
---

# Pipeline — Bitbucket CI Status

All operations are wrapped in `${PLUGIN_ROOT}/scripts/bb_pipeline.sh`. Invoke subcommands instead of writing curl. Repo is auto-detected from `git remote get-url origin`.

## Prerequisites

`BITBUCKET_EMAIL` + `BITBUCKET_API_TOKEN` in env. If missing, use atlas:setup.

## Subcommands

| Call | Purpose |
|------|---------|
| `bb_pipeline.sh latest [branch]` | latest pipeline for branch (default: current). Returns `uuid state result commit branch`. |
| `bb_pipeline.sh get <uuid>` | pipeline details |
| `bb_pipeline.sh steps <uuid>` | step table: name / state / result / duration / step_uuid |
| `bb_pipeline.sh log <uuid> <step_uuid>` | raw step log output |
| `bb_pipeline.sh wait <uuid> [interval=75]` | block until `COMPLETED`, print final state (use `run_in_background: true`) |

## Process

1. `bb_pipeline.sh latest` → grab `uuid`, `state`, `commit`.
2. If the returned `commit` does not match `git rev-parse HEAD`, inform the user — pipeline is for a different commit.
3. If `state` is `PENDING` or `RUNNING`, run `bb_pipeline.sh wait <uuid>` in background.
4. On `COMPLETED`, if `result != SUCCESSFUL`: `bb_pipeline.sh steps <uuid>` → find failed step → `bb_pipeline.sh log <uuid> <step_uuid>` → diagnose.

## Output Handling

For `log`, scan the tail first (failures surface at the end). Quote exact error strings when reporting.

## Escalation

For commit-range filtering, trigger-on-demand runs, or variable inspection, hit the API directly — see `references/bitbucket-api.md`.
