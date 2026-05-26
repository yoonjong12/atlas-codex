---
name: pr
description: "Access Bitbucket Cloud pull requests — view details, diffs, comments, reviews, post comments, and approve. This skill should be used when the user asks about a PR, wants to read PR comments or reviews, check a PR diff, post a comment, or approve a PR. Trigger on: 'PR', 'pull request', 'PR comments', 'review', 'PR 확인', 'PR 코멘트', '리뷰 확인', 'PR diff', '풀리퀘스트', 'PR에 코멘트 달아', 'approve PR', '승인'"
---

# PR — Bitbucket Pull Request Access

All operations are wrapped in `${CODEX_PLUGIN_ROOT}/scripts/bb_pr.sh`. Invoke subcommands instead of writing curl. Repo (workspace/slug) is auto-detected from `git remote get-url origin`; override with `WORKSPACE=… REPO_SLUG=…` env.

## Prerequisites

`BITBUCKET_EMAIL` + `BITBUCKET_API_TOKEN` in env. If missing, use the setup skill.

## Subcommands

| Call | Purpose |
|------|---------|
| `bb_pr.sh get <pr_id>` | PR details (title/state/branches/dates/URL/description) |
| `bb_pr.sh diff <pr_id>` | unified diff |
| `bb_pr.sh comments <pr_id>` | all comments, grouped: General + Inline per file |
| `bb_pr.sh activity <pr_id>` | approvals / updates / comment activity |
| `bb_pr.sh list [state]` | list PRs (default `OPEN`; also `MERGED`, `DECLINED`, `SUPERSEDED`) |
| `bb_pr.sh find-by-branch [branch]` | open PR for branch (default: current) |
| `bb_pr.sh comment <pr_id> <body>` | post general comment (body in markdown) |
| `bb_pr.sh inline <pr_id> <path> <line> <body>` | post inline comment on `path:line` |
| `bb_pr.sh update <pr_id> title\|description <value>` | update title or description |
| `bb_pr.sh approve <pr_id>` | approve PR |

## Input Handling

If user provides a URL (`https://bitbucket.org/<ws>/<repo>/pull-requests/60`), extract `60` and pass as `<pr_id>`.

If user omits PR ID, first try `bb_pr.sh find-by-branch` using the current branch.

## Output Handling

Scripts print structured, concise output. Present it as-is for read ops. For `diff`, summarize changed files and key modifications rather than dumping raw diff.

## Escalation

For edge cases not covered by subcommands (unusual filters, paginated bulk ops), fall back to direct `curl` against `https://api.bitbucket.org/2.0/repositories/${WORKSPACE}/${REPO_SLUG}/…` — see `references/bitbucket-api.md` for endpoints.
