---
name: triage
description: "Bug triage: search Jira duplicates, create/skip. Trigger: 'triage', 'bug report', 'duplicate', '버그 트리아지', 'known issue'"
argument-hint: "<bug report, error message, or symptom description>"
---

# Triage — Bug Duplicate Detection

Search Jira for duplicate or related issues before creating new ones. Prevents duplicate tickets and connects related work.

## Tool Discovery

Load required MCP tools by exact name:

```
ToolSearch({ query: "select:mcp__atlassian__jira_search,mcp__atlassian__jira_get_issue" })
```

## Process

### Step 1: Extract Key Information

From the bug report, identify:
- **Error signature**: exact error message, exception type, error code
- **Component**: affected module, service, or file path
- **Symptoms**: observable behavior (crash, wrong output, performance)
- **Context**: when it occurs, what triggers it

### Step 2: Multi-Strategy Search

Run at least 3 parallel searches to maximize recall:

**Error-focused** (exact match):
```typescript
jira_search({
  jql: 'project = WAO AND text ~ "\\"exact error message\\"" ORDER BY updated DESC',
  limit: 5,
  fields: "summary,status,resolution,updated"
})
```

**Component-focused** (area match):
```typescript
jira_search({
  jql: 'project = WAO AND text ~ "component_name" AND type = Bug ORDER BY updated DESC',
  limit: 5,
  fields: "summary,status,resolution,updated"
})
```

**Symptom-focused** (behavioral match):
```typescript
jira_search({
  jql: 'project = WAO AND text ~ "symptom keywords" ORDER BY updated DESC',
  limit: 5,
  fields: "summary,status,resolution,updated"
})
```

### Step 3: Analyze Results

For each candidate, fetch full details if the summary looks relevant:

```typescript
jira_get_issue({
  issue_key: "WAO-XXX",
  fields: "summary,description,status,resolution,comment"
})
```

Score confidence:

| Confidence | Interpretation | Action |
|-----------|---------------|--------|
| >90% | Exact duplicate | Add comment to existing issue |
| 70-90% | Likely related | Present to user for decision |
| 40-70% | Possibly related | Mention as related, ask user |
| <40% | New issue | Create new issue |

**Regression check**: If a resolved issue matches, note it may be a regression. Check the fix version and resolution date.

### Step 4: Present Findings

Show the user:
- Search queries used and result counts
- Top candidates with key, summary, status, and similarity reasoning
- Recommendation (duplicate / related / new)

**Wait for user confirmation before taking any action.**

### Step 5: Execute Decision

**If duplicate** — add context to existing issue:
```
ToolSearch({ query: "select:mcp__atlassian__jira_add_comment" })
```

Add a comment with the new occurrence context, environment details, and any additional symptoms.

**If new issue** — create with full context:
```
ToolSearch({ query: "select:mcp__atlassian__jira_create_issue" })
```

Include error signature, reproduction steps, and links to any related issues found during search.

**If related** — create new issue and link:
```
ToolSearch({ query: "select:mcp__atlassian__jira_create_issue_link" })
```

## Additional Resources

- **`references/jira-mcp-tools.md`** — MCP tool signatures and JQL patterns
