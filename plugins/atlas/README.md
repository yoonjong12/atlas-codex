# atlas

Unified Atlassian access layer for Codex CLI — Jira issues, Bitbucket pipelines, and PR management.

## Quick Start

```
atlas:setup
```

## Skills

| Skill | Command | Purpose |
|-------|---------|---------|
| **Setup** | `atlas:setup` | Configure Jira + Bitbucket credentials and verify connectivity |
| **Jira** | `atlas:jira` | Issue CRUD, JQL search, comments, transitions, links |
| **Triage** | `atlas:triage` | Bug duplicate detection + new issue creation |
| **Pipeline** | `atlas:pipeline` | Pipeline status, monitoring, failure diagnosis |
| **PR** | `atlas:pr` | PR details, diff, comments, reviews, description updates |
| **Repo** | `atlas:repo` | Clone, branches, commits, file contents, repo info |

## Prerequisites

| Service | Token Type | Scopes |
|---------|-----------|--------|
| Jira | Unscoped API token | None (plain token works) |
| Bitbucket | Scoped API token (app: Bitbucket) | `read:repository`, `read:pullrequest`, `write:pullrequest`, `read:pipeline` |

All tokens from: https://id.atlassian.net/manage-profile/security/api-tokens

## Install

```
codex plugin marketplace add yoonjong12/atlas-codex
codex plugin add atlas@atlas
```

## Architecture

- **Jira**: `sooperset/mcp-atlassian` local MCP server (no cloudId, fast)
- **Bitbucket**: Direct REST API via curl (PR description updates, pipeline logs)

## References

- `references/jira-mcp-tools.md` — Jira MCP tool signatures and JQL patterns
- `references/bitbucket-api.md` — Bitbucket Cloud REST API endpoints
