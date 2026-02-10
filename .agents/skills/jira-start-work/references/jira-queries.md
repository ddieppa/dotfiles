# Jira Queries and Operations

---

## JQL Fundamentals

### Basic Query Structure

```
field OPERATOR value [AND|OR field OPERATOR value]
```

### Common Operators

| Operator | Description | Example |
|----------|-------------|---------|
| `=` | Exact match | `project = "PROJ"` |
| `!=` | Not equal | `status != Done` |
| `~` | Contains (text search) | `summary ~ "login bug"` |
| `!~` | Does not contain | `description !~ "test"` |
| `>`, `<`, `>=`, `<=` | Comparison | `created >= -7d` |
| `IN` | Multiple values | `status IN (Open, "In Progress")` |
| `NOT IN` | Exclude values | `assignee NOT IN (john, jane)` |
| `IS` | Null check | `assignee IS EMPTY` |
| `IS NOT` | Not null | `resolution IS NOT EMPTY` |
| `WAS` | Historical state | `status WAS "In Progress"` |
| `CHANGED` | Field changed | `status CHANGED FROM Open` |

### Field Reference

**Standard Fields:**
```jql
project = PROJ
issuetype = Bug
status = "In Progress"
priority = High
assignee = currentUser()
reporter = "john.doe"
resolution = Unresolved
labels = backend
component = "API"
fixVersion = "2.0"
affectsVersion = "1.5"
```

**Date Fields:**
```jql
created >= -30d                    -- Last 30 days
updated >= "2024-01-01"           -- Since specific date
due <= endOfWeek()                 -- Due this week
resolved >= startOfMonth()         -- Resolved this month
```

**Text Search:**
```jql
summary ~ "authentication"         -- Summary contains
description ~ "error AND login"    -- Description search
text ~ "payment failed"            -- All text fields
comment ~ "blocked"                -- Comment contains
```

## Essential JQL Patterns

### Sprint and Backlog Queries

```jql
-- Current sprint issues
sprint in openSprints() AND project = PROJ

-- Backlog items
sprint IS EMPTY AND resolution IS EMPTY AND project = PROJ

-- Sprint completion
sprint = "Sprint 23" AND status = Done

-- Spillover from last sprint
sprint in closedSprints() AND resolution IS EMPTY

-- Ready for sprint planning
status = "Ready for Dev" AND sprint IS EMPTY
```

### Bug Tracking

```jql
-- Open bugs by priority
issuetype = Bug AND resolution IS EMPTY ORDER BY priority DESC

-- Critical production bugs
issuetype = Bug AND priority IN (Highest, High)
  AND labels = production AND resolution IS EMPTY

-- Bugs created this week
issuetype = Bug AND created >= startOfWeek()

-- Bugs without reproduction steps
issuetype = Bug AND "Reproduction Steps" IS EMPTY
  AND resolution IS EMPTY

-- Regression bugs
issuetype = Bug AND labels = regression AND fixVersion = "2.0"
```

### Team Workload

```jql
-- My open issues
assignee = currentUser() AND resolution IS EMPTY

-- Unassigned high priority
assignee IS EMPTY AND priority IN (Highest, High)
  AND resolution IS EMPTY

-- Team member workload
assignee = "jane.smith" AND sprint in openSprints()

-- Blocked issues
status = Blocked OR labels = blocked

-- Stale issues (no update in 14 days)
updated <= -14d AND resolution IS EMPTY
```

### Release Management

```jql
-- Release candidates
fixVersion = "2.0" AND status = "Ready for Release"

-- Missing fix version
resolution = Done AND fixVersion IS EMPTY AND updated >= -30d

-- Release blockers
fixVersion = "2.0" AND priority = Blocker AND resolution IS EMPTY

-- Changelog items
fixVersion = "2.0" AND resolution = Done ORDER BY issuetype
```

## Common Anti-Patterns

**Avoid:**
```jql
-- Too broad (slow, may timeout)
project IS NOT EMPTY

-- Missing quotes for multi-word values
status = In Progress  -- WRONG
status = "In Progress"  -- CORRECT

-- Case sensitivity issues
assignee = John  -- May fail
assignee = "john.doe@company.com"  -- CORRECT

-- Inefficient ordering
ORDER BY created  -- Missing direction
ORDER BY created DESC  -- CORRECT
```

## Related References

- `common-workflows.md` - End-to-end workflow patterns
- `authentication-patterns.md` - Credential setup for API calls
- `confluence-operations.md` - Linking Jira issues to Confluence pages
