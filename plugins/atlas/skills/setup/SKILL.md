---
name: setup
description: "Configure Atlassian credentials. Trigger: 'atlas setup', 'configure atlassian', '설정', 'auth failed', '인증 실패'"
argument-hint: ""
---

# Setup — Atlassian Integration Configuration

Configure credentials for Bitbucket REST API and Jira MCP access, then verify connectivity.

## Prerequisites

The atlas plugin bundles `mcp-atlassian` (Jira only, 9 tools). Credentials are passed via shell environment variables.

| Service | Credential | Location | Purpose |
|---------|-----------|----------|---------|
| Jira MCP | `JIRA_URL` + `JIRA_USERNAME` + `JIRA_API_TOKEN` | `~/.zshrc` | Issue operations via mcp-atlassian |
| Bitbucket REST API | `BITBUCKET_EMAIL` + `BITBUCKET_API_TOKEN` | `~/.zshrc` | Pipeline, PR operations via curl |

Token types (all from https://id.atlassian.net/manage-profile/security/api-tokens):
- **Jira**: Unscoped API token (plain "API 토큰 만들기") — works with mcp-atlassian
- **Bitbucket**: Scoped API token → app: "Bitbucket", scopes: `read:repository:bitbucket`, `read:pullrequest:bitbucket`, `write:pullrequest:bitbucket`, `read:pipeline:bitbucket`

## Process

### Step 1: Check Jira credentials

```bash
echo "JIRA_URL: ${JIRA_URL:-(not set)}"
echo "JIRA_USERNAME: ${JIRA_USERNAME:-(not set)}"
echo "JIRA_API_TOKEN: ${JIRA_API_TOKEN:+(set)}${JIRA_API_TOKEN:-(not set)}"
```

If missing, guide the user to add to `~/.zshrc`:

```bash
export JIRA_URL="https://your-domain.atlassian.net"
export JIRA_USERNAME="user@example.com"
export JIRA_API_TOKEN="ATATT3x..."
```

Then: `source ~/.zshrc` and restart Codex CLI (`/exit` then relaunch).

### Step 2: Verify Jira Connectivity

After restart, test MCP connection:

```
ToolSearch({ query: "select:mcp__atlassian__jira_search" })
```

Then run a test query:

```typescript
jira_search({
  jql: "project = WAO AND type = Epic ORDER BY updated DESC",
  limit: 1,
  fields: "summary,status"
})
```

### Step 3: Check Bitbucket Credentials

Verify environment variables are set:

```bash
echo "BITBUCKET_EMAIL: ${BITBUCKET_EMAIL:-(not set)}"
echo "BITBUCKET_API_TOKEN: ${BITBUCKET_API_TOKEN:+(set)}"
```

If missing, guide the user:

1. Go to https://id.atlassian.net/manage-profile/security/api-tokens
2. Click "범위를 포함하여 API 토큰 만들기" (Create API token with scopes)
3. Select app: **Bitbucket**
4. Select scopes: `read:repository:bitbucket`, `read:pullrequest:bitbucket`, `write:pullrequest:bitbucket`, `read:pipeline:bitbucket`
5. Add to `~/.zshrc`:
   ```bash
   export BITBUCKET_EMAIL="user@example.com"
   export BITBUCKET_API_TOKEN="ATATT3x..."
   ```

### Step 4: Verify Bitbucket Connectivity

```bash
${PLUGIN_ROOT}/scripts/bb_auth.sh
```

Emits `OK: Bitbucket connected as <email>` on success. Failure modes:

- `200` → Connected
- `401` → Invalid credentials
- `403` → Missing scopes

### Step 5: Discover Custom Fields

After Jira connectivity is verified, discover and cache custom field IDs:

```bash
curl -s -u "${JIRA_USERNAME}:${JIRA_API_TOKEN}" \
  "${JIRA_URL}/rest/api/3/field" | python3 -c "
import sys, json, os
fields = json.load(sys.stdin)
mapping = {}
for f in fields:
    name = f.get('name','').lower()
    fid = f['id']
    if 'story point' in name and f.get('custom'):
        mapping.setdefault('story_points', fid)  # first match wins
    if name == 'story point estimate' and f.get('custom'):
        mapping['story_points'] = fid  # prefer 'estimate' variant
    if 'start date' in name and f.get('custom'):
        mapping.setdefault('start_date', fid)

mapping['_source'] = '${JIRA_URL}/rest/api/3/field'

os.makedirs(os.path.expanduser('~/.codex/atlas'), exist_ok=True)
with open(os.path.expanduser('~/.codex/atlas/fields.json'), 'w') as out:
    json.dump(mapping, out, indent=2)
print('Discovered fields:')
for k, v in mapping.items():
    if not k.startswith('_'):
        print(f'  {k}: {v}')
"
```

If `story_points` is not found, ask the user which field their project uses.

The mapping is stored at `~/.codex/atlas/fields.json` and referenced by all atlas + jira-planner skills.

### Step 6: Report Status

Present a summary table:

```
| Service    | Status      | Account           |
|------------|-------------|-------------------|
| Jira MCP   | Connected   | user@example.com  |
| Bitbucket  | Connected   | user@example.com  |
```

If any service is not connected, list the specific steps needed to fix it.
