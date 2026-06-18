# atlas

Unified Atlassian access layer for Codex CLI — Jira issues, Bitbucket pipelines, PRs, and repositories.

## Install

```bash
codex plugin marketplace add yoonjong12/atlas-codex
codex plugin add atlas@atlas
```

## Quick Start

```text
atlas:setup
```

## Skills

| Skill | Purpose |
|-------|---------|
| `atlas:setup` | Configure Jira + Bitbucket credentials and verify connectivity |
| `atlas:jira` | Issue CRUD, JQL search, comments, transitions, links |
| `atlas:triage` | Bug duplicate detection + new issue creation |
| `atlas:pipeline` | Pipeline status, monitoring, failure diagnosis |
| `atlas:pr` | PR details, diff, comments, reviews, description updates |
| `atlas:repo` | Clone, branches, commits, file contents, repo info |
| `atlas:plugin-sync` | Sync plugins from marketplace clones to local cache |

## Prerequisites

| Service | Token Type | Scopes |
|---------|------------|--------|
| Jira | Unscoped API token | None |
| Bitbucket | Scoped API token, app: Bitbucket | `read:repository`, `read:pullrequest`, `write:pullrequest`, `read:pipeline` |

All tokens come from https://id.atlassian.net/manage-profile/security/api-tokens.

## Architecture

- **Jira**: `sooperset/mcp-atlassian` local MCP server.
- **Bitbucket**: Direct REST API via curl for PRs, pipelines, and repo operations.

## License

MIT
