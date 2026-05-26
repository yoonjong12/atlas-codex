# atlas bb_*.sh scripts

Static Bitbucket Cloud REST wrappers invoked by the `atlas:*` skills (pr, pipeline, repo, setup). Replaces per-call curl composition with parameterized subcommands.

## Scripts

- `_lib.sh` — shared helpers: auth check, repo auto-detection, curl wrapper
- `bb_auth.sh` — verify `BITBUCKET_EMAIL` + `BITBUCKET_API_TOKEN`
- `bb_pr.sh <sub> [args]` — get/diff/comments/activity/list/find-by-branch/comment/inline/update/approve
- `bb_pipeline.sh <sub> [args]` — latest/get/steps/log/wait
- `bb_repo.sh <sub> [args]` — info/branches/commits/src/ls/diff/list/branch-create/branch-delete

Run `<script>` with no args for subcommand help.

## Env

Required (in `~/.zshrc` or current shell):

```bash
export BITBUCKET_EMAIL="you@example.com"
export BITBUCKET_API_TOKEN="ATATT..."
```

Optional override for repo detection (skips `git remote` parse):

```bash
WORKSPACE=mindai REPO_SLUG=pcr_skill_networking bb_pr.sh list
```

## Plugin Update Recovery

The `atlas` plugin cache at `~/.claude/plugins/cache/atlas/atlas/<version>/skills/` holds SKILL.md files rewritten to call these scripts. On plugin upgrade (e.g. 0.2.1 → 0.2.2), the new version directory will ship upstream SKILL.md that reverts to inline curl.

Re-apply after update:

```bash
# 1. diff old (rewritten) vs new (upstream) SKILLs
diff -r ~/.claude/plugins/cache/atlas/atlas/0.2.1/skills \
        ~/.claude/plugins/cache/atlas/atlas/<new>/skills

# 2. re-apply by asking Claude: "refactor new atlas SKILL.md to use bb_*.sh"
```

Scripts in this directory are user-owned; plugin upgrades do not touch them.

## Allowlist

`~/.claude/settings.json` contains:

```json
"Bash(~/.claude/atlas/scripts/bb_auth.sh:*)",
"Bash(~/.claude/atlas/scripts/bb_pr.sh:*)",
"Bash(~/.claude/atlas/scripts/bb_pipeline.sh:*)",
"Bash(~/.claude/atlas/scripts/bb_repo.sh:*)"
```

→ no permission prompts for these script invocations.
