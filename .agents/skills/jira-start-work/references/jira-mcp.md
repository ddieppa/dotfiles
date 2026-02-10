# MCP Reference

Complete reference for Atlassian Jira operations via MCP.

## Tool Mapping

| Action | MCP Tool |
| --- | --- |
| List accessible resources | `mcp_atlassian-mcp-server_getAccessibleAtlassianResources` |
| Get current user | `mcp_atlassian-mcp-server_atlassianUserInfo` |
| Search across Jira/Confluence | `mcp_atlassian-mcp-server_search` |
| Search issues (JQL) | `mcp_atlassian-mcp-server_searchJiraIssuesUsingJql` |
| Get issue | `mcp_atlassian-mcp-server_getJiraIssue` |
| Create issue | `mcp_atlassian-mcp-server_createJiraIssue` |
| Edit issue | `mcp_atlassian-mcp-server_editJiraIssue` |
| Get transitions | `mcp_atlassian-mcp-server_getTransitionsForJiraIssue` |
| Transition issue | `mcp_atlassian-mcp-server_transitionJiraIssue` |
| Add comment | `mcp_atlassian-mcp-server_addCommentToJiraIssue` |
| Add worklog | `mcp_atlassian-mcp-server_addWorklogToJiraIssue` |
| Lookup account ID | `mcp_atlassian-mcp-server_lookupJiraAccountId` |
| List projects | `mcp_atlassian-mcp-server_getVisibleJiraProjects` |
| Issue type metadata | `mcp_atlassian-mcp-server_getJiraProjectIssueTypesMetadata` |
| Issue type fields | `mcp_atlassian-mcp-server_getJiraIssueTypeMetaWithFields` |
| Remote issue links | `mcp_atlassian-mcp-server_getJiraIssueRemoteIssueLinks` |

If your MCP server exposes sprint tools, add their mappings here and align the examples in the Usage Patterns section.

## MCP Tool Reference

### Search Operations

#### `mcp_atlassian-mcp-server_search`
Unified search across Jira and Confluence using Rovo Search. Use this for general searches unless JQL/CQL is specifically needed.

**Parameters:**
- `query` (required): Search query string

**Example:**
```javascript
mcp_atlassian-mcp-server_search({
  query: "authentication bug"
})
```

#### `mcp_atlassian-mcp-server_searchJiraIssuesUsingJql`
Search Jira using JQL (Jira Query Language). ONLY use when JQL syntax is specifically needed.

**Parameters:**
- `cloudId` (required): Atlassian Cloud ID
- `jql` (required): JQL query string
- `maxResults`: Maximum results (default: 50, max: 100)
- `nextPageToken`: For pagination
- `fields`: Array of field names to return (default: summary, description, status, issuetype, priority, created)

**Example:**
```javascript
mcp_atlassian-mcp-server_searchJiraIssuesUsingJql({
  cloudId: "cloud-id",
  jql: "project = MCA AND status = 'In Progress'",
  fields: ["summary", "assignee", "customfield_11828"]
})
```

### Issue Operations

#### `mcp_atlassian-mcp-server_getJiraIssue`
Retrieve full issue details by ID or key.

**Parameters:**
- `cloudId` (required): Atlassian Cloud ID
- `issueIdOrKey` (required): Issue ID (numeric) or key (e.g., "MCA-372")
- `expand`: Additional data (e.g., "names", "transitions.fields", "changelog")
- `fields`: Array of specific fields to return

**Example:**
```javascript
mcp_atlassian-mcp-server_getJiraIssue({
  cloudId: "cloud-id",
  issueIdOrKey: "MCA-372",
  fields: ["status", "customfield_11828"]
})
```

#### `mcp_atlassian-mcp-server_createJiraIssue`
Create a new issue.

**Parameters:**
- `cloudId` (required): Atlassian Cloud ID
- `projectKey` (required): Target project key
- `issueTypeName` (required): Issue type (Story, Bug, Task, Epic, Subtask, etc.)
- `summary` (required): Issue title
- `description`: Detailed description (Markdown format)
- `assignee_account_id`: Account ID (use `lookupJiraAccountId` first)
- `parent`: Parent issue key/ID (for Subtasks)
- `additional_fields`: Object with custom fields

**Example:**
```javascript
mcp_atlassian-mcp-server_createJiraIssue({
  cloudId: "cloud-id",
  projectKey: "MCA",
  issueTypeName: "Bug",
  summary: "Fix authentication error",
  description: "Users cannot log in with OAuth",
  assignee_account_id: "712020:xxxxx"
})
```

#### `mcp_atlassian-mcp-server_editJiraIssue`
Update an existing issue.

**Parameters:**
- `cloudId` (required): Atlassian Cloud ID
- `issueIdOrKey` (required): Issue to update
- `fields` (required): Object with fields to update

**Example:**
```javascript
mcp_atlassian-mcp-server_editJiraIssue({
  cloudId: "cloud-id",
  issueIdOrKey: "MCA-372",
  fields: {
    "summary": "Updated summary",
    "customfield_11828": {
      "type": "doc",
      "version": 1,
      "content": [/* ADF content */]
    }
  }
})
```

**CRITICAL**: Custom text fields often require ADF format, not plain text. See [Custom Fields & ADF Format](#custom-fields--adf-format).

### Transition Operations

#### `mcp_atlassian-mcp-server_getTransitionsForJiraIssue`
Get available status transitions for an issue.

**Parameters:**
- `cloudId` (required): Atlassian Cloud ID
- `issueIdOrKey` (required): Issue key
- `expand`: Optional, use "transitions.fields" to get field requirements

**Returns:** List of available transitions with IDs, names, and metadata.

**Example:**
```javascript
mcp_atlassian-mcp-server_getTransitionsForJiraIssue({
  cloudId: "cloud-id",
  issueIdOrKey: "MCA-372",
  expand: "transitions.fields"
})
```

#### `mcp_atlassian-mcp-server_transitionJiraIssue`
Change issue status.

**Parameters:**
- `cloudId` (required): Atlassian Cloud ID
- `issueIdOrKey` (required): Issue key
- `transition` (required): Object with `id` property
- `fields`: Optional object with fields to set during transition

**Workflow:**
1. Get transitions: `getTransitionsForJiraIssue`
2. Find desired transition ID from results
3. Execute transition

**Example:**
```javascript
mcp_atlassian-mcp-server_transitionJiraIssue({
  cloudId: "cloud-id",
  issueIdOrKey: "MCA-372",
  transition: {"id": "8"}
})
```

**IMPORTANT**: Some transitions require specific fields to be populated BEFORE transitioning. If the transition fails with field validation errors, update the fields first using `editJiraIssue`, then transition without the fields parameter.

### Comment Operations

#### `mcp_atlassian-mcp-server_addCommentToJiraIssue`
Add a comment to an issue.

**Parameters:**
- `cloudId` (required): Atlassian Cloud ID
- `issueIdOrKey` (required): Issue key
- `commentBody` (required): Comment text (Markdown format)
- `commentVisibility`: Optional, restrict to group/role

**Example:**
```javascript
mcp_atlassian-mcp-server_addCommentToJiraIssue({
  cloudId: "cloud-id",
  issueIdOrKey: "MCA-372",
  commentBody: "Completed and ready for review"
})
```

### Worklog Operations

#### `mcp_atlassian-mcp-server_addWorklogToJiraIssue`
Log time spent on an issue.

**Parameters:**
- `cloudId` (required): Atlassian Cloud ID
- `issueIdOrKey` (required): Issue key
- `timeSpent` (required): Time string (e.g., "2h", "30m", "1d 4h")
- `visibility`: Optional, restrict to group/role

**Example:**
```javascript
mcp_atlassian-mcp-server_addWorklogToJiraIssue({
  cloudId: "cloud-id",
  issueIdOrKey: "MCA-372",
  timeSpent: "2h"
})
```

### User Operations

#### `mcp_atlassian-mcp-server_atlassianUserInfo`
Get current user info.

**Returns:** Account ID, display name, email, etc.

#### `mcp_atlassian-mcp-server_lookupJiraAccountId`
Find user account ID for assignments.

**Parameters:**
- `cloudId` (required): Atlassian Cloud ID
- `searchString` (required): Display name, email, or username

**Example:**
```javascript
mcp_atlassian-mcp-server_lookupJiraAccountId({
  cloudId: "cloud-id",
  searchString: "john.doe@example.com"
})
```

**Usage:** Always look up account IDs before assigning issues.

### Project Operations

#### `mcp_atlassian-mcp-server_getAccessibleAtlassianResources`
Get Cloud ID and available resources.

**Returns:** Array of accessible cloud instances with scopes.

**Example:**
```javascript
mcp_atlassian-mcp-server_getAccessibleAtlassianResources()
// Returns: [{"id": "cloud-id", "url": "https://yoursite.atlassian.net", ...}]
```

#### `mcp_atlassian-mcp-server_getVisibleJiraProjects`
List available Jira projects.

**Parameters:**
- `cloudId` (required): Atlassian Cloud ID
- `action`: Filter by permission (view, browse, edit, create) - default: "create"
- `searchString`: Filter by project name/key
- `maxResults`: Maximum results (default: 50, max: 50)
- `expandIssueTypes`: Include issue types (default: true)

**Example:**
```javascript
mcp_atlassian-mcp-server_getVisibleJiraProjects({
  cloudId: "cloud-id",
  action: "create"
})
```

#### `mcp_atlassian-mcp-server_getJiraProjectIssueTypesMetadata`
Get issue types and field metadata for a project.

**Parameters:**
- `cloudId` (required): Atlassian Cloud ID
- `projectIdOrKey` (required): Project key or ID
- `maxResults`: Maximum results (default: 50, max: 200)

**Example:**
```javascript
mcp_atlassian-mcp-server_getJiraProjectIssueTypesMetadata({
  cloudId: "cloud-id",
  projectIdOrKey: "MCA"
})
```

**Usage:** Call before creating issues to understand available issue types.

#### `mcp_atlassian-mcp-server_getJiraIssueTypeMetaWithFields`
Get detailed field metadata for a specific issue type.

**Parameters:**
- `cloudId` (required): Atlassian Cloud ID
- `projectIdOrKey` (required): Project key or ID
- `issueTypeId` (required): Issue type ID
- `maxResults`: Maximum results
- `startAt`: Pagination offset

**Returns:** Field definitions including required fields, schemas, allowed values, etc.

**Example:**
```javascript
mcp_atlassian-mcp-server_getJiraIssueTypeMetaWithFields({
  cloudId: "cloud-id",
  projectIdOrKey: "MCA",
  issueTypeId: "11260"
})
```

**Usage:** Call before creating issues to understand required fields and their formats.

#### `mcp_atlassian-mcp-server_getJiraIssueRemoteIssueLinks`
Get remote links (e.g., Confluence pages) for an issue.

**Parameters:**
- `cloudId` (required): Atlassian Cloud ID
- `issueIdOrKey` (required): Issue key
- `globalId`: Optional, filter by specific link

---

## Usage Patterns

### MCP Tool Calls

#### Searching Issues

```javascript
// Basic JQL search
const searchResult = mcp_atlassian-mcp-server_searchJiraIssuesUsingJql({
  cloudId: "cloud-id",
  jql: "project = PROJ AND sprint in openSprints()",
  maxResults: 50,
  fields: ["summary", "status", "assignee", "priority"]
});

// Parse response
const issues = JSON.parse(searchResult.content[0].text);
for (const issue of issues.issues) {
  console.log(`${issue.key}: ${issue.fields.summary}`);
}
```

#### Getting Issue Details

```javascript
// Get single issue with all fields
const issue = mcp_atlassian-mcp-server_getJiraIssue({
  cloudId: "cloud-id",
  issueIdOrKey: "PROJ-123",
  expand: "changelog,comments,transitions"
});

// Get issue with specific fields
const issuePartial = mcp_atlassian-mcp-server_getJiraIssue({
  cloudId: "cloud-id",
  issueIdOrKey: "PROJ-123",
  fields: ["summary", "description", "customfield_10001"]
});
```

#### Creating Issues

```javascript
// Create a bug
const newBug = mcp_atlassian-mcp-server_createJiraIssue({
  cloudId: "cloud-id",
  projectKey: "PROJ",
  issueTypeName: "Bug",
  summary: "Login fails with SSO enabled",
  description: "Users cannot log in when SSO is enabled.",
  assignee_account_id: "712020:xxxxx"
});
```

#### Updating Issues

```javascript
// Update issue fields
mcp_atlassian-mcp-server_editJiraIssue({
  cloudId: "cloud-id",
  issueIdOrKey: "PROJ-123",
  fields: {
    summary: "Updated summary",
    priority: { name: "Highest" },
    labels: ["urgent", "production"]
  }
});

// Add comment
mcp_atlassian-mcp-server_addCommentToJiraIssue({
  cloudId: "cloud-id",
  issueIdOrKey: "PROJ-123",
  commentBody: "Investigating this issue. Initial analysis suggests a race condition."
});

// Transition issue (use getTransitionsForJiraIssue to find the ID)
mcp_atlassian-mcp-server_transitionJiraIssue({
  cloudId: "cloud-id",
  issueIdOrKey: "PROJ-123",
  transition: {"id": "8"}
});
```

#### Sprint Operations (If Supported)

Tool names for sprint operations vary by MCP server. If your server provides sprint tools, map them in the Tool Mapping section and use the same pattern below.

```javascript
// Get active sprints
const sprints = jira_get_sprints({
  board_id: 42,
  state: "active"
});

// Move issue to sprint
jira_move_to_sprint({
  sprint_id: 123,
  issue_keys: ["PROJ-100", "PROJ-101", "PROJ-102"]
});

// Get sprint report
const report = jira_get_sprint_report({
  board_id: 42,
  sprint_id: 123
});
```

### Pagination Handling

```javascript
function getAllIssues(jql) {
  const allIssues = [];
  let nextPageToken = undefined;

  while (true) {
    const result = mcp_atlassian-mcp-server_searchJiraIssuesUsingJql({
      cloudId: "cloud-id",
      jql,
      maxResults: 100,
      nextPageToken,
      fields: ["summary", "status", "assignee"]
    });

    const response = JSON.parse(result.content[0].text);
    allIssues.push(...response.issues);

    if (!response.nextPageToken) {
      break;
    }

    nextPageToken = response.nextPageToken;
  }

  return allIssues;
}
```

### Bulk Operations

```javascript
function bulkUpdateLabels(jql, addLabels) {
  const issues = getAllIssues(jql);

  for (const issue of issues) {
    const existingLabels = issue.fields.labels || [];
    mcp_atlassian-mcp-server_editJiraIssue({
      cloudId: "cloud-id",
      issueIdOrKey: issue.key,
      fields: {
        labels: [...new Set([...existingLabels, ...addLabels])]
      }
    });

    // Respect rate limits
    delay(100);
  }
}

// Usage
bulkUpdateLabels(
  "project = PROJ AND sprint in openSprints() AND labels = backend",
  ["q4-priority", "needs-review"]
);
```

### Error Handling

```javascript
async function safeJiraCall(operation, retries = 3) {
  for (let attempt = 1; attempt <= retries; attempt++) {
    try {
      return await operation();
    } catch (error) {
      const status = error.response?.status;

      // Don't retry client errors (except rate limits)
      if (status >= 400 && status < 500 && status !== 429) {
        throw error;
      }

      // Rate limited - wait and retry
      if (status === 429) {
        const retryAfter = parseInt(error.response?.headers?.["retry-after"] || "60", 10);
        await delay(retryAfter * 1000);
        continue;
      }

      // Server error - exponential backoff
      if (attempt < retries) {
        const backoff = Math.pow(2, attempt) * 1000;
        await delay(backoff);
      } else {
        throw error;
      }
    }
  }

  throw new Error("Unexpected end of retry loop");
}
```

---

## Custom Fields & ADF Format

### Understanding Custom Fields

Custom fields are identified as `customfield_XXXXX` where XXXXX is a numeric ID. To find custom field IDs:

1. Get issue with `expand=names`:
```javascript
mcp_atlassian-mcp-server_getJiraIssue({
  cloudId: "cloud-id",
  issueIdOrKey: "MCA-372",
  expand: "names"
})
```

2. Check the `names` object in the response to map field names to IDs.

### ADF (Atlassian Document Format)

**CRITICAL**: Many custom text fields require ADF format, not plain text strings. This includes:
- Rich text fields
- Description fields in some configurations
- Custom text area fields
- **Resolution Details** and similar workflow-specific fields

#### Plain Text (Will Fail)
```javascript
{
  "customfield_11828": "Some text"
}
```

#### Correct ADF Format
```javascript
{
  "customfield_11828": {
    "type": "doc",
    "version": 1,
    "content": [
      {
        "type": "paragraph",
        "content": [
          {"type": "text", "text": "First line of text"}
        ]
      },
      {
        "type": "paragraph",
        "content": [
          {"type": "text", "text": "Second line of text"}
        ]
      }
    ]
  }
}
```

#### ADF with Formatting
```javascript
{
  "type": "doc",
  "version": 1,
  "content": [
    {
      "type": "paragraph",
      "content": [
        {"type": "text", "text": "Normal text "},
        {"type": "text", "text": "bold text", "marks": [{"type": "strong"}]},
        {"type": "text", "text": " and "},
        {"type": "text", "text": "italic text", "marks": [{"type": "em"}]}
      ]
    },
    {
      "type": "bulletList",
      "content": [
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{"type": "text", "text": "Bullet point 1"}]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{"type": "text", "text": "Bullet point 2"}]
            }
          ]
        }
      ]
    },
    {
      "type": "codeBlock",
      "attrs": {"language": "javascript"},
      "content": [
        {"type": "text", "text": "const example = 'code';"}
      ]
    }
  ]
}
```

### Common ADF Errors

| Error | Cause | Solution |
|-------|-------|----------|
| "Bad Request" (no details) | Plain text instead of ADF | Use ADF format |
| "Field cannot be set" | Wrong format or field not on screen | Check field requirements with metadata APIs |
| Validation error | Invalid ADF structure | Validate JSON structure |

### ADF Building Tips

1. **Start Simple**: Use basic paragraph structure first
2. **Multiple Lines**: Each line is a separate paragraph object
3. **Lists**: Use `bulletList` or `orderedList` with `listItem` children
4. **Formatting**: Add marks array to text objects (`strong`, `em`, `code`, `strike`, `underline`)
5. **Links**: Use `type: "text"` with `marks: [{"type": "link", "attrs": {"href": "url"}}]`

---

## JQL (Jira Query Language) Reference

### Basic Syntax

```
field operator value [AND|OR field operator value]
```

### Common Fields

| Field | Description | Example |
|-------|-------------|---------|
| `project` | Project key | `project = "MCA"` |
| `issuetype` | Issue type | `issuetype = Bug` |
| `status` | Issue status | `status = "In Progress"` |
| `assignee` | Assigned user | `assignee = currentUser()` |
| `reporter` | Issue creator | `reporter = "jobarksdale"` |
| `priority` | Priority level | `priority = High` |
| `labels` | Issue labels | `labels = "backend"` |
| `component` | Components | `component = "API"` |
| `created` | Creation date | `created >= -30d` |
| `updated` | Last update | `updated >= -7d` |
| `resolved` | Resolution date | `resolved >= startOfMonth()` |
| `sprint` | Sprint name/ID | `sprint in openSprints()` |
| `"Epic Link"` | Parent epic | `"Epic Link" = MCA-100` |
| `parent` | Parent issue | `parent = MCA-50` |
| `text` | Full-text search | `text ~ "authentication"` |
| `summary` | Title search | `summary ~ "login"` |
| `description` | Description search | `description ~ "OAuth"` |

### Operators

| Operator | Meaning | Example |
|----------|---------|---------|
| `=` | Exact match | `status = Done` |
| `!=` | Not equal | `status != Closed` |
| `~` | Contains (text) | `summary ~ "auth*"` |
| `!~` | Does not contain | `summary !~ "test"` |
| `>` `>=` `<` `<=` | Comparisons | `priority >= High` |
| `IN` | Multiple values | `status IN (Open, "In Progress")` |
| `NOT IN` | Exclude values | `status NOT IN (Done, Closed)` |
| `IS` | Null check | `assignee IS EMPTY` |
| `IS NOT` | Not null | `assignee IS NOT EMPTY` |
| `WAS` | Historical value | `status WAS "In Progress"` |
| `CHANGED` | Field changed | `status CHANGED` |

### Functions

| Function | Description | Example |
|----------|-------------|---------|
| `currentUser()` | Logged-in user | `assignee = currentUser()` |
| `now()` | Current timestamp | `created <= now()` |
| `startOfDay()` | Midnight today | `updated >= startOfDay()` |
| `startOfWeek()` | Start of week | `created >= startOfWeek()` |
| `startOfMonth()` | Start of month | `created >= startOfMonth()` |
| `endOfDay()` | End of today | `due <= endOfDay()` |
| `openSprints()` | Active sprints | `sprint in openSprints()` |
| `closedSprints()` | Completed sprints | `sprint in closedSprints()` |
| `linkedIssues()` | Linked issues | `issue in linkedIssues("MCA-123")` |

### Relative Dates

```jql
# Days
created >= -7d    # Last 7 days
updated >= -30d   # Last 30 days

# Weeks
created >= -2w    # Last 2 weeks

# Months
created >= -1M    # Last month

# Specific date
created >= "2024-01-01"
```

### Ordering

```jql
# Order by priority, highest first
project = MCA ORDER BY priority DESC

# Multiple sort fields
project = MCA ORDER BY status ASC, created DESC
```

### Complex Query Examples

```jql
# My open issues, high priority
assignee = currentUser() AND status NOT IN (Done, Closed) AND priority >= High

# Bugs created this week
issuetype = Bug AND created >= startOfWeek() ORDER BY priority DESC

# Epics in progress with stories
issuetype = Epic AND status = "In Progress" AND issueFunction in hasLinks("is parent of")

# Issues updated by me recently
updatedBy = currentUser() AND updated >= -7d ORDER BY updated DESC

# Blocked issues
status = Blocked OR "Flagged" = "Impediment"

# Issues linked to specific epic
"Epic Link" = MCA-100 AND status != Done

# Sprint backlog items
sprint in openSprints() AND status = "To Do" ORDER BY rank ASC

# Unassigned high-priority bugs
issuetype = Bug AND assignee IS EMPTY AND priority >= High

# Issues I'm watching
watcher = currentUser()

# Recently resolved by team
resolved >= -7d AND project = MCA ORDER BY resolved DESC

# Custom field queries
"Resolution Details" IS NOT EMPTY AND status = "In Review"
```

---

## Description Formatting

### Jira Markup (Wiki Style)

Used in some fields and older Jira instances:

```
h1. Heading 1
h2. Heading 2
h3. Heading 3

*bold text*
_italic text_
-strikethrough-
+underline+

{code:java}
public class Example {
    // code here
}
{code}

{quote}
Quoted text here
{quote}

* Bullet list
** Nested bullet
# Numbered list
## Nested number

[Link text|https://example.com]
[Issue link|MCA-123]

||Header 1||Header 2||
|Cell 1|Cell 2|

{panel:title=Panel Title}
Panel content here
{panel}
```

### Markdown Format

MCP tools support Markdown for descriptions and comments:

```markdown
# Heading 1
## Heading 2

**bold** and *italic*

- Bullet list
  - Nested item
1. Numbered list

[Link](https://example.com)

`inline code`

```javascript
code block
```

> Blockquote
```

---

## Error Handling

### Common Errors

| HTTP Code | Error | Cause | Resolution |
|-----------|-------|-------|------------|
| 400 | Bad Request | Invalid field values or format | Check field format (ADF vs plain text) |
| 401 | Unauthorized | Invalid credentials | Reconnect MCP server |
| 403 | Forbidden | Insufficient permissions | Check project/issue permissions |
| 404 | Not Found | Issue/project doesn't exist | Verify key is correct |
| 422 | Unprocessable | Validation failed | Check required fields and constraints |

### Specific Error Messages

#### "Field 'customfield_XXXXX' cannot be set. It is not on the appropriate screen, or unknown."

**Causes:**
1. Field requires ADF format but you provided plain text
2. Field is not available on the current screen (create/edit/transition)
3. Field doesn't exist or you lack permission

**Solutions:**
1. Convert plain text to ADF format
2. For transitions: Update field separately using `editJiraIssue` before transitioning
3. Verify field ID using `getJiraIssue` with `expand=names`

#### "Please enter resolution details on how this bug has been 'fixed'"

**Cause:** Workflow validator requires a specific field to be populated before transition.

**Solution:** Update the field using `editJiraIssue` BEFORE calling `transitionJiraIssue`.

### Transition Metadata Quirk

**Important Discovery**: The `getTransitionsForJiraIssue` API may return:
- `hasScreen: false`
- `fields: {}`

This suggests no fields are required, but **workflow validators** can still enforce field requirements. If a transition fails with field validation errors:

1. The field is required by a validator (not visible in API metadata)
2. Update the field separately using `editJiraIssue`
3. Then perform the transition without the fields parameter

### Authentication Issues

If MCP tools return authentication errors:
1. Check connection status
2. Reconnect the Atlassian MCP server if needed
3. Verify API token permissions in Atlassian account settings

### Field Validation

Before creating/editing issues:
1. Get metadata: `getJiraIssueTypeMetaWithFields` or `getJiraProjectIssueTypesMetadata`
2. Check required fields and their schemas
3. Look up user account IDs for assignee fields (`lookupJiraAccountId`)
4. Verify custom field IDs using `expand=names`
5. Determine if fields need ADF format (type: "doc")

---

## Common Workflows

### Get Cloud ID

Always start by getting your Cloud ID:

```javascript
const resources = mcp_atlassian-mcp-server_getAccessibleAtlassianResources();
const cloudId = resources[0].id; // Use the appropriate resource
```

### Move Ticket to "In Review" with Resolution Details

```javascript
// 1. Get cloud ID
const cloudId = "your-cloud-id";

// 2. Populate Resolution Details FIRST (ADF format required)
mcp_atlassian-mcp-server_editJiraIssue({
  cloudId: cloudId,
  issueIdOrKey: "MCA-372",
  fields: {
    "customfield_11828": {
      "type": "doc",
      "version": 1,
      "content": [
        {
          "type": "paragraph",
          "content": [{"type": "text", "text": "- Fixed authentication bug"}]
        },
        {
          "type": "paragraph",
          "content": [{"type": "text", "text": "- Added validation"}]
        }
      ]
    }
  }
});

// 3. Get available transitions
const transitions = mcp_atlassian-mcp-server_getTransitionsForJiraIssue({
  cloudId: cloudId,
  issueIdOrKey: "MCA-372"
});
// Find transition ID for "In Review" (e.g., ID 8)

// 4. Execute transition
mcp_atlassian-mcp-server_transitionJiraIssue({
  cloudId: cloudId,
  issueIdOrKey: "MCA-372",
  transition: {"id": "8"}
});

// 5. Verify
const issue = mcp_atlassian-mcp-server_getJiraIssue({
  cloudId: cloudId,
  issueIdOrKey: "MCA-372",
  fields: ["status", "customfield_11828"]
});
```

### Create and Assign Issue

```javascript
// 1. Look up user account ID
const users = mcp_atlassian-mcp-server_lookupJiraAccountId({
  cloudId: cloudId,
  searchString: "john.doe@example.com"
});
const accountId = users[0].accountId;

// 2. Create issue with assignment
mcp_atlassian-mcp-server_createJiraIssue({
  cloudId: cloudId,
  projectKey: "MCA",
  issueTypeName: "Task",
  summary: "Implement feature X",
  description: "## Details\n\nImplementation details here...",
  assignee_account_id: accountId
});
```

### List My In-Progress Issues

```javascript
mcp_atlassian-mcp-server_searchJiraIssuesUsingJql({
  cloudId: cloudId,
  jql: "assignee = currentUser() AND status = 'In Progress' ORDER BY updated DESC",
  fields: ["summary", "status", "priority", "updated"]
});
```

### Get Project Info Before Creating

```javascript
// 1. List available projects
const projects = mcp_atlassian-mcp-server_getVisibleJiraProjects({
  cloudId: cloudId,
  action: "create"
});

// 2. Get issue types for project
const metadata = mcp_atlassian-mcp-server_getJiraProjectIssueTypesMetadata({
  cloudId: cloudId,
  projectIdOrKey: "MCA"
});

// 3. Get detailed field requirements for specific issue type
const fieldMeta = mcp_atlassian-mcp-server_getJiraIssueTypeMetaWithFields({
  cloudId: cloudId,
  projectIdOrKey: "MCA",
  issueTypeId: "11260" // Bug type
});

// 4. Create issue with correct type and required fields
mcp_atlassian-mcp-server_createJiraIssue({
  cloudId: cloudId,
  projectKey: "MCA",
  issueTypeName: "Bug",
  summary: "Issue summary",
  description: "Issue description"
  // Add other required fields as identified in fieldMeta
});
```

### Update Multiple Fields

```javascript
mcp_atlassian-mcp-server_editJiraIssue({
  cloudId: cloudId,
  issueIdOrKey: "MCA-372",
  fields: {
    "summary": "Updated summary",
    "description": "Updated description content",
    "priority": {"name": "High"},
    "labels": ["bug", "urgent"],
    "customfield_11828": {
      "type": "doc",
      "version": 1,
      "content": [
        {"type": "paragraph", "content": [{"type": "text", "text": "Custom field value"}]}
      ]
    }
  }
});
```

### Add Comment with Worklog

```javascript
// 1. Add comment
mcp_atlassian-mcp-server_addCommentToJiraIssue({
  cloudId: cloudId,
  issueIdOrKey: "MCA-372",
  commentBody: "Completed implementation and testing"
});

// 2. Log time spent
mcp_atlassian-mcp-server_addWorklogToJiraIssue({
  cloudId: cloudId,
  issueIdOrKey: "MCA-372",
  timeSpent: "3h 30m"
});
```

---

## Best Practices

### 1. Always Get Cloud ID First
```javascript
const resources = mcp_atlassian-mcp-server_getAccessibleAtlassianResources();
const cloudId = resources.find(r => r.url.includes("yoursite")).id;
```

### 2. Verify Issue Exists Before Operations
```javascript
try {
  const issue = mcp_atlassian-mcp-server_getJiraIssue({
    cloudId: cloudId,
    issueIdOrKey: "MCA-372"
  });
} catch (error) {
  // Handle 404 - issue not found
}
```

### 3. Check Field Requirements Before Creating
Don't assume field names - always check metadata:
```javascript
const meta = mcp_atlassian-mcp-server_getJiraIssueTypeMetaWithFields({
  cloudId: cloudId,
  projectIdOrKey: "MCA",
  issueTypeId: "11260"
});
// Review required fields and their schemas
```

### 4. Use ADF for Text Fields
When in doubt, use ADF format for custom text fields:
```javascript
{
  "customfield_XXXXX": {
    "type": "doc",
    "version": 1,
    "content": [
      {"type": "paragraph", "content": [{"type": "text", "text": "Your text"}]}
    ]
  }
}
```

### 5. Separate Field Updates from Transitions
If a transition requires specific fields:
1. Update fields first using `editJiraIssue`
2. Then perform transition using `transitionJiraIssue` (without fields)

This avoids "field cannot be set" errors.

### 6. Handle Pagination
For large result sets, use pagination:
```javascript
let allIssues = [];
let nextPageToken = null;

do {
  const result = mcp_atlassian-mcp-server_searchJiraIssuesUsingJql({
    cloudId: cloudId,
    jql: "project = MCA",
    maxResults: 100,
    nextPageToken: nextPageToken
  });
  
  allIssues = allIssues.concat(result.issues);
  nextPageToken = result.nextPageToken;
} while (nextPageToken);
```

### 7. Look Up Custom Field IDs
Don't hardcode custom field IDs - discover them:
```javascript
const issue = mcp_atlassian-mcp-server_getJiraIssue({
  cloudId: cloudId,
  issueIdOrKey: "MCA-372",
  expand: "names"
});
// Check issue.names to map human-readable names to customfield_XXXXX
```

### 8. Validate Transitions Before Executing
```javascript
const transitions = mcp_atlassian-mcp-server_getTransitionsForJiraIssue({
  cloudId: cloudId,
  issueIdOrKey: "MCA-372"
});

const reviewTransition = transitions.transitions.find(t => 
  t.name === "Review Code" || t.to.name === "In Review"
);

if (reviewTransition) {
  // Execute transition
} else {
  // Transition not available
}
```

---

## Troubleshooting Checklist

- [ ] Have you called `getAccessibleAtlassianResources` to get Cloud ID?
- [ ] Are you using the correct issue key format (PROJECT-123)?
- [ ] For custom fields, are you using ADF format instead of plain text?
- [ ] Have you checked field requirements using metadata APIs?
- [ ] For transitions, did you populate required fields BEFORE transitioning?
- [ ] For assignee fields, did you look up the account ID first?
- [ ] Are you handling pagination for large result sets?
- [ ] Have you verified the issue/project exists before operations?
- [ ] Are you checking transition availability before executing?
- [ ] Have you reviewed error messages for specific field validation issues?
