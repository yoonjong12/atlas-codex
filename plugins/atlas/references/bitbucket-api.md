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
