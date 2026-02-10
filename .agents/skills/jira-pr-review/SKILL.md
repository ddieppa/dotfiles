---
name: jira-pr-review
description: Move a Jira ticket from "In Development" to "In Review" using pull request context, populate Resolution Details when required, verify the transition, and produce an MS Teams review message. Use when asked to "move ticket to review", "send to in review", "update Jira with PR", or "ready for code review". Do not use for starting work, QA/PM signoff flows, merge readiness, or multi-stage board automation.
---

# Jira PR Review Workflow

**Requires**: GitHub CLI (`gh`) authenticated and Atlassian MCP configured.

## Scope

- Handle only the board transition `In Development` -> `In Review`.
- Do not automate QA/PM/Ready-to-Merge transitions in this skill.

## Workflow

### 1) Resolve branch and PR context

```powershell
git branch --show-current
gh pr list --head "<branch-name>" --json number,title,url,baseRefName,headRefName
gh pr view <pr-number> --json number,title,url,body,baseRefName,headRefName,commits
```

Rules:
- If no PR exists for the branch, stop and ask the user to create or open the PR first.
- Use PR commit subjects as the source for Resolution Details. Do not rely on `git log development..HEAD`.

### 2) Resolve Jira key deterministically

Try in order:
1. Branch name (`[A-Z]+-\d+`)
2. PR title
3. PR body

If unresolved, ask the user for the ticket key.

### 3) Resolve Atlassian context by capability (intent first)

Capabilities to execute:
- Discover site/cloud context.
- Read Jira issue state and field name mapping.
- Read issue-type field metadata.
- Read available transitions.

Current MCP examples:
- `mcp__claude_ai_Atlassian__getAccessibleAtlassianResources`
- `mcp__claude_ai_Atlassian__getJiraIssue`
- `mcp__claude_ai_Atlassian__getJiraIssueTypeMetaWithFields`
- `mcp__claude_ai_Atlassian__getTransitionsForJiraIssue`

Issue read requirements:
- Use `expand: "names"` so field display names can be resolved to field keys.
- Use `fields: ["*all"]` so the `names` map includes custom fields for name-based matching.

Metadata read requirements:
- Use project key from `issue.fields.project.key`.
- Use issue type id from `issue.fields.issuetype.id`.

Rules:
- Prefer site URL `https://metrc-tech.atlassian.net` when multiple resources exist.
- If an Atlassian call fails with transient/auth errors, retry once before failing.
- If a mapped tool name is unavailable, use an equivalent tool by capability intent; if no safe equivalent exists, stop and report blocker.

### 4) Gate by current status before mutation

- If status is `In Development`: continue.
- If status is `In Review`: no-op success (already in target state).
- For any other status (`To Do`, `QA`, `QA Acceptance`, `PM Acceptance`, `Ready To Merge`, `Done`, `Cancelled`): stop and report blocker.

### 5) Resolve Resolution Details field ID dynamically

Field-name alias match order:
1. `Resolution Details`
2. `Resolution Detail`
3. `Resolution details`

Normalization rules before matching:
- Lowercase
- Trim leading/trailing whitespace
- Collapse internal whitespace to single spaces

Lookup order:
1. Match aliases against issue `names` map values (display names). If matched, use that key.
2. If unresolved, match aliases against issue-type metadata field `name`. Use `fieldId` (fallback to metadata `key` if `fieldId` missing).
3. If still unresolved, ask the user what to do next and include discovered field names from both sources.

Rules:
- Do not use hardcoded custom field IDs.
- Do not guess fallback field IDs.

### 6) Prepare and conditionally update Resolution Details from PR commits

Build one bullet per commit subject.

**CRITICAL**: the resolved Resolution Details field requires ADF, not plain text.

```json
{
  "type": "doc",
  "version": 1,
  "content": [
    {
      "type": "paragraph",
      "content": [{"type": "text", "text": "- <commit-subject>"}]
    }
  ]
}
```

Policy:
- Read the current value from the resolved field key.
- Treat as empty when value is `null`, missing, an empty string, or an ADF document with no non-whitespace text nodes.
- If empty: set the resolved field with commit bullets in ADF.
- If already populated: do not modify it.

Dynamic field update pattern:

```javascript
mcp__claude_ai_Atlassian__editJiraIssue({
  cloudId: "<cloud-id>",
  issueIdOrKey: "<jira-key>",
  fields: {
    [resolutionDetailsFieldId]: adfDoc
  }
})
```

### 7) Resolve and execute transition to In Review

Transition selection order:
1. Transition where `to.name == "In Review"`
2. Fallback transition named `Review Code` (case-insensitive)

If neither exists, stop and list available transitions.

Then call:
- `mcp__claude_ai_Atlassian__transitionJiraIssue`

### 8) Verify and output result

After transition, call:
- `mcp__claude_ai_Atlassian__getJiraIssue` (status + resolved Resolution Details field)

Verify:
- `status.name == "In Review"`

Generate Teams message:

`Review PR: [PR-TITLE](pr-link) for this ticket: [TICKET-NUMBER](jira-link)`

## Output Contract

### Success

Report:
- Jira key
- Final Jira status
- Resolved Resolution Details field id/key
- Resolution Details action: `updated` or `skipped (already populated)`
- Teams message text

### No-op

Report:
- Jira key
- Status already `In Review`
- Resolved Resolution Details field id/key (if resolved in run)
- Resolution Details action (if evaluated): `updated` or `skipped (already populated)`
- No transition executed
- Teams message text

### Failure

Report:
- Exact blocker (missing PR, unresolved ticket key, invalid status, missing transition, Resolution Details field name not found, API/auth error)
- Next action required from user

## References

- [Jira MCP Reference](references/jira-mcp.md) for tool call details, full ADF examples, and troubleshooting.

