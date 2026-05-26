# atlas

Unified Atlassian access — Jira issues, Bitbucket pipelines, PRs, and repositories.

## Install

```bash
codex plugin marketplace add yoonjong12/atlas-codex
codex plugin add atlas@atlas
```

## Skills

| Skill | Description |
|-------|-------------|
| jira | Read, search, create, edit, comment, and transition Jira issues |
| pipeline | Check Bitbucket pipeline status, wait for completion, diagnose failures |
| pr | View PR details, diffs, comments, reviews; post comments and approve |
| repo | Bitbucket repository operations — clone, info, branches, commits, file contents |
| setup | Configure Atlassian credentials and verify connectivity |
| plugin-sync | Sync plugins from remote marketplace clones to local |
| triage | Triage bug reports by searching Jira for duplicates |

## Prerequisites

- **Jira**: MCP server (`mcp-atlassian`) configured with `JIRA_USERNAME` + `JIRA_API_TOKEN`
- **Bitbucket**: `BITBUCKET_EMAIL` + `BITBUCKET_API_TOKEN` environment variables

Run the `setup` skill for guided configuration.

## License

MIT
