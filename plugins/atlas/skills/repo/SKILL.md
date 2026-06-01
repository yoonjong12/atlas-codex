---
name: repo
description: "Explicit-only atlas skill. Invoke by name as atlas:repo, @repo, or a direct request for the repo skill."
disable-model-invocation: true
user-invocable: true
---

# Repo — Bitbucket Repository Operations

All operations are wrapped in `${PLUGIN_ROOT}/scripts/bb_repo.sh`. Invoke subcommands instead of writing curl. Repo is auto-detected from `git remote get-url origin`; override with `WORKSPACE=… REPO_SLUG=…` env.

## Prerequisites

`BITBUCKET_EMAIL` + `BITBUCKET_API_TOKEN` in env. If missing, use the setup skill.

## Subcommands

| Call | Purpose |
|------|---------|
| `bb_repo.sh info` | repo summary (full_name / language / main branch / updated / size / URL) |
| `bb_repo.sh branches` | recent 25 branches sorted by target date |
| `bb_repo.sh commits [branch]` | recent 10 commits on branch (default: main) |
| `bb_repo.sh src <branch> <path>` | raw file contents |
| `bb_repo.sh ls <branch> <dir>` | directory listing (D/F prefix) |
| `bb_repo.sh diff <source> <destination>` | unified diff between refs |
| `bb_repo.sh list [workspace]` | list repos in workspace (default: current) |
| `bb_repo.sh branch-create <name> <from_hash_or_branch>` | create branch via API |
| `bb_repo.sh branch-delete <name>` | delete branch via API |

## Clone

Cloning is a local `git` op, not a Bitbucket API op:

```bash
git clone git@bitbucket.org:${WORKSPACE}/${REPO_SLUG}.git
```

If the user asks to clone a repo you haven't detected yet, parse the URL first.

## URL Parsing

`https://bitbucket.org/mindai/pcr_skill_networking` → `WORKSPACE=mindai`, `REPO_SLUG=pcr_skill_networking`

## Escalation

For advanced ops (webhooks, permissions, deploy keys, LFS), hit the API directly — see `references/bitbucket-api.md`.
