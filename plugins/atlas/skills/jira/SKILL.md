---
name: jira
description: "Jira: read/search/create/edit/comment/transition. Trigger: issue key (e.g. WAO-123), '이슈', '스토리', '서브태스크', 'JQL', '상태변경', 'jira search'"
argument-hint: "<issue key, JQL query, or description>"
---

# Jira — Issue Access Layer

Read, search, create, edit, comment, and transition Jira issues via mcp-atlassian MCP.

## Tool Discovery

MCP tools are deferred. Load by exact name before first use:

```
ToolSearch({ query: "select:mcp__atlassian__jira_get_issue,mcp__atlassian__jira_search" })
```

Load write tools only when needed:

```
ToolSearch({ query: "select:mcp__atlassian__jira_create_issue,mcp__atlassian__jira_update_issue,mcp__atlassian__jira_add_comment,mcp__atlassian__jira_transition_issue,mcp__atlassian__jira_get_transitions" })
```

## Read Operations

### Single Issue Lookup

When the user provides an issue key (e.g., `WAO-372`):

```typescript
jira_get_issue({
  issue_key: "WAO-372",
  fields: "summary,description,status,assignee,subtasks,parent,priority"
})
```

Present results concisely: key, summary, status, assignee, and subtask list if any.

### Search with JQL

When the user asks to find or list issues:

```typescript
jira_search({
  jql: "project = WAO AND type = Story AND status != Done ORDER BY updated DESC",
  limit: 10,
  fields: "summary,status,assignee"
})
```

Translate natural language queries to JQL:
- "WAO 프로젝트 진행중인 스토리" → `project = WAO AND type = Story AND status = "In Progress"`
- "내 할당된 이슈" → `assignee = currentUser() AND status != Done`
- "이번주 생성된 이슈" → `project = WAO AND created >= startOfWeek()`
- "에러 핸들링 관련" → `project = WAO AND text ~ "error handling"`

For detailed JQL patterns, consult `references/jira-mcp-tools.md`.

### Hierarchy Navigation

To show an issue's full context (Epic → Story → Subtask):

1. Fetch the target issue with `parent` and `subtasks` fields
2. If it has a parent, fetch the parent for context
3. If it has subtasks, they are included in the response

## Write Operations

### Create Issue

```typescript
jira_create_issue({
  project_key: "WAO",
  issue_type: "Subtask",           // "Epic", "Story", "Subtask", "Task", "Bug"
  summary: "Issue title",
  description: "Description in markdown",
  assignee: "yoonjong@wisdomgraph.ai",
  additional_fields: {
    "parent": "WAO-372",           // required for Story under Epic, Subtask under Story
    "priority": {"name": "1"},
    "customfield_10025": "2026-04-13",  // Start date
    "duedate": "2026-04-20"
  }
})
```

### Edit Issue

```typescript
jira_update_issue({
  issue_key: "WAO-372",
  fields: { "summary": "Updated title" }
})
```

### Add Comment

```typescript
jira_add_comment({
  issue_key: "WAO-372",
  comment: "Comment text in markdown"
})
```

### Transition (Status Change)

Two-step process:

```typescript
// 1. Get available transitions
jira_get_transitions({
  issue_key: "WAO-372"
})
// Returns: [{id: 4, name: "BLOCKED"}, {id: 11, name: "해야 할 일"}, {id: 3, name: "Completed a task"}]

// 2. Execute transition using ID from step 1
jira_transition_issue({
  issue_key: "WAO-372",
  transition_id: "3"              // ID from jira_get_transitions result
})
```

### Link Issues

```typescript
jira_create_issue_link({
  type: "Blocks",
  inward_issue: "WAO-375",        // blocker
  outward_issue: "WAO-376"        // blocked
})
```

## Custom Field Resolution

Before using custom fields (story points, start date), read `~/.codex/atlas/fields.json`:

```bash
cat ~/.codex/atlas/fields.json
```

Use the resolved field ID instead of guessing. Example:
```typescript
// fields.json says: {"story_points": "customfield_10028"}
jira_update_issue({
  issue_key: "WAO-394",
  fields: "{\"customfield_10028\": 3}"
})
```

If the file doesn't exist, use atlas:setup first.

## Token Efficiency

- Request only needed fields via `fields` (comma-separated string)
- Use `limit` aggressively (5 for selection, 1 for latest)

## Additional Resources

- **`references/jira-mcp-tools.md`** — Full tool signatures, JQL patterns
