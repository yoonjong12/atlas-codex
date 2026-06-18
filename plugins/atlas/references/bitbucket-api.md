# Bitbucket Cloud REST API Reference

Base URL: `https://api.bitbucket.org`

## Authentication

All requests require Basic auth:

```bash
curl -s -u "${BITBUCKET_EMAIL}:${BITBUCKET_API_TOKEN}" \
  "https://api.bitbucket.org/2.0/repositories/{workspace}/{repo_slug}/..."
```

## Repo Detection

Extract workspace and repo slug from git remote:

```bash
REMOTE_URL=$(git remote get-url origin)
# SSH: git@bitbucket.org:workspace/repo.git
# HTTPS: https://bitbucket.org/workspace/repo.git
WORKSPACE=$(echo "$REMOTE_URL" | sed -E 's#.*bitbucket.org[:/]([^/]+)/.*#\1#')
REPO_SLUG=$(echo "$REMOTE_URL" | sed -E 's#.*bitbucket.org[:/][^/]+/([^.]+).*#\1#')
```

## Pipeline API

### Get Latest Pipeline

```bash
curl -s -u "${BITBUCKET_EMAIL}:${BITBUCKET_API_TOKEN}" \
  "https://api.bitbucket.org/2.0/repositories/${WORKSPACE}/${REPO_SLUG}/pipelines/?sort=-created_on&pagelen=1"
```

Response fields: `.values[0].uuid`, `.values[0].state.name`, `.values[0].target.commit.hash`

States: `PENDING`, `RUNNING`, `COMPLETED`
Result (when COMPLETED): `.values[0].state.result.name` → `SUCCESSFUL`, `FAILED`, `STOPPED`

### Get Pipeline Steps

```bash
curl -s -u "${BITBUCKET_EMAIL}:${BITBUCKET_API_TOKEN}" \
  "https://api.bitbucket.org/2.0/repositories/${WORKSPACE}/${REPO_SLUG}/pipelines/${PIPELINE_UUID}/steps/"
```

Response: `.values[]` with `.name`, `.state.name`, `.state.result.name`

### Get Step Logs

```bash
curl -s -L -u "${BITBUCKET_EMAIL}:${BITBUCKET_API_TOKEN}" \
  -H "Range: bytes=0-999999" \
  "https://api.bitbucket.org/2.0/repositories/${WORKSPACE}/${REPO_SLUG}/pipelines/${PIPELINE_UUID}/steps/${STEP_UUID}/log" \
  | strings | grep -i -E "(error|fail|exception|traceback)" | tail -50
```

**Notes:**
- Log endpoint returns binary data — pipe through `strings` to extract text
- Use `-L` flag to follow 307 redirects
- Use `Range` header to limit download size

## Pull Request API

### Create PR

```bash
curl -s -u "${BITBUCKET_EMAIL}:${BITBUCKET_API_TOKEN}" \
  -X POST \
  -H "Content-Type: application/json" \
  -d '{
    "title": "PR title",
    "description": "Markdown description",
    "source": {"branch": {"name": "feature-branch"}},
    "destination": {"branch": {"name": "main"}},
    "close_source_branch": true
  }' \
  "https://api.bitbucket.org/2.0/repositories/${WORKSPACE}/${REPO_SLUG}/pullrequests"
```

### Get PR Details

```bash
curl -s -u "${BITBUCKET_EMAIL}:${BITBUCKET_API_TOKEN}" \
  "https://api.bitbucket.org/2.0/repositories/${WORKSPACE}/${REPO_SLUG}/pullrequests/${PR_ID}"
```

Response fields: `.title`, `.description`, `.state`, `.author.display_name`, `.source.branch.name`, `.destination.branch.name`, `.created_on`, `.updated_on`

### Get PR Diff

```bash
curl -s -u "${BITBUCKET_EMAIL}:${BITBUCKET_API_TOKEN}" \
  "https://api.bitbucket.org/2.0/repositories/${WORKSPACE}/${REPO_SLUG}/pullrequests/${PR_ID}/diff"
```

Returns unified diff format.

### List PRs

```bash
# Open PRs
curl -s -u "${BITBUCKET_EMAIL}:${BITBUCKET_API_TOKEN}" \
  "https://api.bitbucket.org/2.0/repositories/${WORKSPACE}/${REPO_SLUG}/pullrequests?state=OPEN&pagelen=10"

# Merged PRs
curl -s -u "${BITBUCKET_EMAIL}:${BITBUCKET_API_TOKEN}" \
  "https://api.bitbucket.org/2.0/repositories/${WORKSPACE}/${REPO_SLUG}/pullrequests?state=MERGED&pagelen=10"
```

### Get PR Comments

```bash
curl -s -u "${BITBUCKET_EMAIL}:${BITBUCKET_API_TOKEN}" \
  "https://api.bitbucket.org/2.0/repositories/${WORKSPACE}/${REPO_SLUG}/pullrequests/${PR_ID}/comments?pagelen=100"
```

Response: `.values[]` with `.content.raw`, `.user.display_name`, `.created_on`, `.inline` (for inline comments: `.inline.path`, `.inline.from`, `.inline.to`)

### Update PR Title or Description

```bash
curl -s -u "${BITBUCKET_EMAIL}:${BITBUCKET_API_TOKEN}" \
  -X PUT \
  -H "Content-Type: application/json" \
  -d '{"description": "Updated markdown description"}' \
  "https://api.bitbucket.org/2.0/repositories/${WORKSPACE}/${REPO_SLUG}/pullrequests/${PR_ID}"
```

### Get PR Activity (Reviews)

```bash
curl -s -u "${BITBUCKET_EMAIL}:${BITBUCKET_API_TOKEN}" \
  "https://api.bitbucket.org/2.0/repositories/${WORKSPACE}/${REPO_SLUG}/pullrequests/${PR_ID}/activity?pagelen=50"
```

Response: `.values[]` with `.approval`, `.update`, `.comment` entries

### Post PR Comment

```bash
# General comment
curl -s -u "${BITBUCKET_EMAIL}:${BITBUCKET_API_TOKEN}" \
  -X POST \
  -H "Content-Type: application/json" \
  -d '{"content": {"raw": "Comment text in markdown"}}' \
  "https://api.bitbucket.org/2.0/repositories/${WORKSPACE}/${REPO_SLUG}/pullrequests/${PR_ID}/comments"

# Inline comment on specific file/line
curl -s -u "${BITBUCKET_EMAIL}:${BITBUCKET_API_TOKEN}" \
  -X POST \
  -H "Content-Type: application/json" \
  -d '{
    "content": {"raw": "Comment on this line"},
    "inline": {"path": "src/main.py", "to": 42}
  }' \
  "https://api.bitbucket.org/2.0/repositories/${WORKSPACE}/${REPO_SLUG}/pullrequests/${PR_ID}/comments"
```

### Reply to Comment Thread

**`bb_pr.sh comment` posts a top-level comment. To reply inside a reviewer's thread, include `"parent": {"id": <comment_id>}`.**

```bash
# 1. Find the parent comment ID from the comments list
curl -s -u "${BITBUCKET_EMAIL}:${BITBUCKET_API_TOKEN}" \
  "https://api.bitbucket.org/2.0/repositories/${WORKSPACE}/${REPO_SLUG}/pullrequests/${PR_ID}/comments?pagelen=100" \
  | python3 -c "
import sys, json
for c in json.load(sys.stdin)['values']:
    pid = c.get('parent', {}).get('id', '')
    print(c['id'], c['user']['display_name'], repr(c['content']['raw'][:60]), '| parent:', pid)
"

# 2. Post a reply nested under the reviewer's comment
curl -s -u "${BITBUCKET_EMAIL}:${BITBUCKET_API_TOKEN}" \
  -X POST \
  -H "Content-Type: application/json" \
  -d "{\"content\": {\"raw\": \"$(cat /tmp/reply.md | python3 -c 'import sys; print(sys.stdin.read().replace("\\\\", "\\\\\\\\").replace("\"", "\\\\\"").replace(chr(10), "\\\\n"))')\"}, \"parent\": {\"id\": ${PARENT_COMMENT_ID}}}" \
  "https://api.bitbucket.org/2.0/repositories/${WORKSPACE}/${REPO_SLUG}/pullrequests/${PR_ID}/comments"
```

For long reply bodies, write the JSON payload to a file to avoid shell escaping issues:

```bash
python3 -c "
import json, sys
body = open('/tmp/reply.md').read()
print(json.dumps({'content': {'raw': body}, 'parent': {'id': ${PARENT_COMMENT_ID}}}))
" > /tmp/reply-payload.json

curl -s -u "${BITBUCKET_EMAIL}:${BITBUCKET_API_TOKEN}" \
  -X POST \
  -H "Content-Type: application/json" \
  -d @/tmp/reply-payload.json \
  "https://api.bitbucket.org/2.0/repositories/${WORKSPACE}/${REPO_SLUG}/pullrequests/${PR_ID}/comments"
```

Response: comment object with `.id` (the new reply's ID). Verify `.parent.id` matches the intended parent.

### Delete PR Comment

```bash
curl -s -u "${BITBUCKET_EMAIL}:${BITBUCKET_API_TOKEN}" \
  -X DELETE \
  "https://api.bitbucket.org/2.0/repositories/${WORKSPACE}/${REPO_SLUG}/pullrequests/${PR_ID}/comments/${COMMENT_ID}"
```

Returns HTTP 204 on success. Use this to remove a mistakenly posted general comment before re-posting as a thread reply.

### Approve/Unapprove PR

```bash
# Approve
curl -s -u "${BITBUCKET_EMAIL}:${BITBUCKET_API_TOKEN}" \
  -X POST \
  "https://api.bitbucket.org/2.0/repositories/${WORKSPACE}/${REPO_SLUG}/pullrequests/${PR_ID}/approve"

# Unapprove
curl -s -u "${BITBUCKET_EMAIL}:${BITBUCKET_API_TOKEN}" \
  -X DELETE \
  "https://api.bitbucket.org/2.0/repositories/${WORKSPACE}/${REPO_SLUG}/pullrequests/${PR_ID}/approve"
```

### Merge PR

```bash
curl -s -u "${BITBUCKET_EMAIL}:${BITBUCKET_API_TOKEN}" \
  -X POST \
  -H "Content-Type: application/json" \
  -d '{"close_source_branch": true, "message": "Merge message"}' \
  "https://api.bitbucket.org/2.0/repositories/${WORKSPACE}/${REPO_SLUG}/pullrequests/${PR_ID}/merge"
```

## Pagination

Bitbucket API uses cursor-based pagination:

```json
{
  "pagelen": 10,
  "page": 1,
  "next": "https://api.bitbucket.org/2.0/...?page=2",
  "values": [...]
}
```

Follow `.next` URL for additional pages. Omit `page` parameter to start from the beginning.
