---
name: jira-start-work
description: Start work on a Jira ticket by finding To Do tickets, creating a git branch, and transitioning to In Development. Use when user asks to "start work", "pick up a ticket", "begin a task", or "start a Jira ticket".
---

# Jira Start Work Workflow

**Requires**: Atlassian MCP server configured and Git CLI available.

## Purpose

Automates the process of starting work on a Jira ticket by:
1. Finding "To Do" tickets assigned to the current user
2. Creating a properly named git branch
3. Transitioning the ticket to "In Development" status

## Process

### Step 1: Get Atlassian Context

> [!IMPORTANT]
> **Retry Logic**: If any Atlassian call fails with an "Unauthorized" error, retry the call at least once more (minimum 2 attempts total). Authentication tokens may temporarily expire.

Actions:
- Call the Atlassian resource listing tool to get accessible sites.
- If multiple sites are returned, select the one with URL matching `metrc-tech.atlassian.net`.
- Call the user info tool to get the current user identity.

### Step 2: Find To Do Tickets (Primary)

Query for tickets assigned to the current user in "To Do" status:

```jql
assignee = currentUser() AND status = "To Do" ORDER BY priority DESC, created ASC
```

Fields to request:
- `key`, `summary`, `status`, `issuetype`, `priority`, `created`

### Step 3: Fallback to In Development (If No To Do)

If the "To Do" query returns zero results, query for tickets assigned to the current user in "In Development":

```jql
assignee = currentUser() AND status = "In Development" ORDER BY priority DESC, created ASC
```

### Step 4: Handle Ticket Selection

| Scenario | Action |
|----------|--------|
| **No tickets found** | Ask user which ticket they want to work on |
| **Multiple tickets** | List tickets as `KEY - Summary` and ask user to choose |
| **Single ticket** | Proceed with that ticket automatically |

### Step 5: Determine Branch Prefix

| Issue Type | Branch Prefix |
|------------|---------------|
| Bug | `fix/` |
| Story, Task, or other | `feature/` |

### Step 6: Create Branch Name

Format: `{prefix}/{TICKET}-{title-with-dashes}`

**Example transformations:**
- "MCA-372" + "400 Bad Request Errors" → `fix/MCA-372-400-bad-request-errors`
- "PERF-1126" + "Update WebApiD8" → `feature/PERF-1126-update-webapid8`

**Rules:**
1. Keep the ticket key uppercase
2. Convert title to lowercase
3. Replace non-alphanumeric with single hyphens
4. Trim leading/trailing hyphens and collapse repeats
5. Truncate if excessively long

### Step 7: Git Operations

Follow the cross-platform steps in `references/git.md`.

Short version (default base branch is `development`):

```bash
git status
git fetch --prune origin
git switch development
git pull --ff-only origin development
git switch -c "{branch-name}"
```

If `origin/development` does not exist, ask the user for the base branch and substitute it.

### Step 8: Transition Ticket to In Development

Actions:
- Fetch available transitions for the selected issue.
- If the issue is in **To Do**, select the transition labeled **Start Development** (case-insensitive) and execute it.
- If the issue is already **In Development**, skip the transition.
- If the label is not found, list the available transitions and ask the user which to use.

Workflow labels (from the current board):
- `Start Development` -> In Development
- `Review Code` -> In Review
- `Review Failed` -> In Development
- `A Failed, Back to Development` -> In Development
- `QA Signoff` -> QA Acceptance
- `PM Signoff` -> PM Acceptance
- `Ready to Merge Code` -> Ready to Merge
- `Code Complete/Cancelled` -> Done
- `Cancelled bug` -> Cancelled

### Step 9: Confirm Success

Report to user:
- ✅ Branch created: `{branch-name}`
- ✅ Ticket status: In Development
- 🔗 Jira link: `https://metrc-tech.atlassian.net/browse/{TICKET}`

### Step 10: Offer to Push Branch to Remote

After successful branch creation and ticket transition, **ask the user** if they want to push the newly created branch to remote:

> Would you like me to push the branch `{branch-name}` to remote?

If user confirms, run:

```bash
git push -u origin {branch-name}
```

This sets up tracking so future `git push` commands work without specifying the remote.

## Troubleshooting

| Error | Solution |
|-------|----------|
| No tickets in To Do | If none in "In Development", ask user for specific ticket key |
| Branch already exists | Checkout existing branch or create with suffix |
| Transition not available | Check current ticket status first |
| Git conflicts | Stash changes before switching branches |

## References

- [Jira MCP API Reference](references/jira-mcp.md) - Complete MCP tool documentation
- [Git Start Work Reference](references/git.md) - Cross-platform git steps and best practices
- [Jira Queries and Operations](references/jira-queries.md) - JQL patterns and Jira call examples
