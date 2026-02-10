---
name: jira-ticket-reader
description: Read Jira ticket and create task folder with info + starting prompt. Commands: /read-ticket, /task-info, /import-jira. Triggers: "read ticket", "get ticket info", "document ticket", "fetch jira issue", "import ticket", "load ticket details".
license: MIT
metadata:
  author: metrc-tech
  version: "1.5.0"
---

# Jira Ticket Reader

Extracts Jira ticket information from the current git branch, fetches complete ticket data, and creates a task folder with ticket documentation and a starting prompt for LLM-assisted development.

## How It Works

1. **Validate prerequisites** - Verify git repository and Jira connection
2. **Extract ticket ID** - From branch name (pattern: `[A-Z]+-\d+`) or query Jira
3. **Fetch ticket data** - Retrieve complete issue details with single API call
4. **Convert to Markdown** - Transform rich text format to readable documentation
5. **Generate files** - Create ticket documentation and starting prompt using templates
6. **Validate output** - Verify files created successfully
7. **Report success** - Confirm with file locations and links

## Usage

### Prerequisites

- Git repository with branch containing ticket ID
- Jira API access with read permissions
- Write access to local documentation directory

### Workflow

**1. Validate Environment**

- Check git is available and repository exists
- Verify Jira API connection is active
- Confirm current directory has write permissions

See [Git Operations](references/git-operations.md) for validation commands.

**2. Get Jira Connection**

- Retrieve available Jira instances
- Select appropriate cloud/server instance
- Extract connection identifier

See [Jira MCP API Reference](references/jira-mcp.md) for connection details.

**3. Determine Ticket ID**

**Option A: From Branch Name**

- Get current branch name
- Extract ticket ID using pattern: `[A-Z]+-\d+`
- Example: `fix/MCA-402-bug-fix` → `MCA-402`

**Option B: Query Jira**

- If no ticket in branch, query for assigned tickets in "In Development" status
- Present list to user if multiple tickets found
- Accept manual input if no tickets found

See [Git Operations](references/git-operations.md) for branch extraction.

**4. Fetch Complete Ticket Data**

- Request all relevant fields in single API call
- Include: summary, description, status, priority, type, labels, components, reporter, assignee, timestamps, comments, attachments
- Use field expansion for complete data

See [Jira MCP API Reference](references/jira-mcp.md) for API details.

**5. Convert Rich Text to Markdown**

- Parse structured document format (ADF)
- Apply conversion rules for all element types
- Handle nested structures and formatting marks
- Gracefully degrade unsupported elements

See [ADF Conversion Guide](references/adf-conversion.md) for conversion details and company-specific fields.

**6. Generate Documentation Files**

Create directory structure: `personal/tasks/{TICKET-ID}/`

**File 1: {TICKET-ID}.md** - Ticket information

- Streamlined ticket info with only relevant details
- Issue Details, Steps to Reproduce, Technical Context
- Comments (most recent first)
- Attachments list

See [Ticket Info Template](assets/output-ticket-info.md) for structure.

**File 2: {TICKET-ID}.prompt.md** - Starting prompt

- References the {TICKET-ID}.md file for full details
- Problem Statement, Objective, Constraints
- Request for AI assistance with structured approach

See [Prompt Template](assets/output-prompt.md) for structure.

**File 3: images/** - Downloaded attachments (CONDITIONAL)

- Only create if attachments were successfully downloaded
- Do NOT create folder if no attachments or download fails
- Reference downloaded images in {TICKET-ID}.md

See [Jira MCP Reference](references/jira-mcp.md) for attachment download details.

**7. Validate Files**

- Verify all files created
- Check file sizes are non-zero
- Confirm valid text encoding

**8. Report Results**

```
🔍 Ticket ID: {TICKET-ID}
✅ Ticket Info: personal/tasks/{TICKET-ID}/{TICKET-ID}.md
🚀 Starting Prompt: personal/tasks/{TICKET-ID}/{TICKET-ID}.prompt.md
�️ Images: personal/tasks/{TICKET-ID}/images/ (if attachments downloaded)
🔗 Jira: https://[instance]/browse/{TICKET-ID}
```

## Output

Creates task folder in `personal/tasks/{TICKET-ID}/`:

- **{TICKET-ID}.md** - Streamlined ticket information (Issue Details, Steps to Reproduce, Technical Context, Comments, Attachments)
- **{TICKET-ID}.prompt.md** - Starting prompt that references the ticket file, ready to begin development
- **images/** - Downloaded attachments (only if successfully retrieved)

## Error Handling

**Retry Strategy**:

- Retry failed API calls with exponential backoff
- Maximum 3 attempts per operation
- Backoff intervals: 1s, 2s, 4s
- Timeout: 30 seconds per attempt

**Common Issues**:
| Issue | Resolution |
|-------|------------|
| No ticket in branch | Query Jira or prompt user for ticket ID |
| Connection failed | Verify API credentials and retry |
| Ticket not found | Confirm ticket exists and user has access |
| Empty content | Check alternate fields; include comments |
| File creation failed | Verify directory permissions |

See [Troubleshooting Guide](references/troubleshooting.md) for detailed solutions.

## Document Format Conversion

Basic element mapping:

| Source Element | Target Format                     |
| -------------- | --------------------------------- |
| Paragraph      | Plain text with line breaks       |
| Heading (1-6)  | Markdown headings `#` to `######` |
| Bullet list    | Markdown list with `- `           |
| Numbered list  | Markdown list with `1. `          |
| Code block     | Fenced code blocks with language  |
| Bold text      | `**text**`                        |
| Italic text    | `*text*`                          |
| Inline code    | `` `text` ``                      |

**Fallback Handling**:

- Log warnings for unsupported elements
- Extract plain text when possible
- Add comments for skipped content
- Continue processing (never fail completely)

See [ADF Conversion Guide](references/adf-conversion.md) for complete conversion rules and company-specific examples.

## References

Load these resources on-demand for detailed implementation:

- **[Jira MCP API Reference](references/jira-mcp.md)** - Complete API documentation, connection setup, field specifications
- **[ADF Conversion Guide](references/adf-conversion.md)** - Convert Atlassian Document Format to Markdown, includes company-specific fields like `customfield_11828` (Resolution Details)
- **[Git Operations](references/git-operations.md)** - Platform-specific commands and branch extraction
- **[Troubleshooting Guide](references/troubleshooting.md)** - Common issues, error codes, and solutions
