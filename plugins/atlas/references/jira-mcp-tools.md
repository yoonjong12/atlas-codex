# Jira MCP Tool Reference (mcp-atlassian)

Tool reference for `sooperset/mcp-atlassian` MCP server, registered as `atlassian` in `~/.claude.json`.

## Tool Discovery

All tools are deferred. Load by exact name before first use:

```
ToolSearch({ query: "select:mcp__atlassian__jira_get_issue,mcp__atlassian__jira_search" })
ToolSearch({ query: "select:mcp__atlassian__jira_create_issue,mcp__atlassian__jira_update_issue" })
ToolSearch({ query: "select:mcp__atlassian__jira_add_comment,mcp__atlassian__jira_transition_issue,mcp__atlassian__jira_get_transitions" })
ToolSearch({ query: "select:mcp__atlassian__jira_create_issue_link,mcp__atlassian__jira_get_user_profile" })
```

## Read Operations

### jira_get_issue

```typescript
jira_get_issue({
  issue_key: "WAO-372",
  fields: "summary,description,status,assignee,subtasks,parent,priority"
})
```

### jira_search

```typescript
jira_search({
  jql: "project = WAO AND type = Story AND status != Done ORDER BY updated DESC",
  limit: 10,
  fields: "summary,status,assignee"
})
```

### jira_get_user_profile

```typescript
jira_get_user_profile({
  user_identifier: "yoonjong@wisdomgraph.ai"
})
```

## Write Operations

### jira_create_issue

```typescript
jira_create_issue({
  project_key: "WAO",
  issue_type: "Subtask",        // "Epic", "Story", "Subtask", "Task", "Bug"
  summary: "Issue title",
  description: "Description in markdown",
  assignee: "yoonjong@wisdomgraph.ai",
  additional_fields: {
    "parent": "WAO-372",        // string, NOT {"key": "WAO-372"}
    "priority": {"name": "1"},
    "customfield_10025": "2026-04-13",  // Start date
    "duedate": "2026-04-20"
  }
})
```

**Note**: Use `"Subtask"` not `"Sub-task"` for issue_type.

### jira_update_issue

```typescript
jira_update_issue({
  issue_key: "WAO-372",
  fields: {
    "summary": "Updated title",
    "description": "Updated description"
  }
})
```

### jira_add_comment

```typescript
jira_add_comment({
  issue_key: "WAO-372",
  comment: "Comment text in markdown"
})
```

### jira_get_transitions

```typescript
jira_get_transitions({
  issue_key: "WAO-372"
})
// Returns: [{id: 4, name: "BLOCKED"}, {id: 11, name: "해야 할 일"}, {id: 3, name: "Completed a task"}]
```

### jira_transition_issue

```typescript
jira_transition_issue({
  issue_key: "WAO-372",
  transition_id: "3",            // ID from jira_get_transitions
  comment: "Status changed"      // optional
})
```

### jira_create_issue_link

```typescript
jira_create_issue_link({
  type: "Blocks",
  inward_issue: "WAO-375",      // blocker
  outward_issue: "WAO-376"      // blocked by inward
})
```

## Common JQL Patterns

```jql
# Active epics
project = WAO AND type = Epic AND status IN (Open, "In Progress") ORDER BY updated DESC

# Stories under epic
parent = WAO-180 AND type = Story

# Subtasks under story
parent = WAO-372 AND type = Subtask

# My incomplete tasks
assignee = currentUser() AND status != Done AND resolution = Unresolved

# Recent issues
project = WAO AND created >= -7d ORDER BY created DESC

# By text search
project = WAO AND text ~ "error handling"

# By sprint
project = WAO AND sprint in openSprints()
```

## Token Efficiency

1. **Selective fields**: Only request needed fields (comma-separated string)
   ```typescript
   fields: "summary,status"
   ```

2. **Limit results**: Use `limit` aggressively
   ```typescript
   limit: 5   // for selection lists
   limit: 1   // for "latest" queries
   ```
