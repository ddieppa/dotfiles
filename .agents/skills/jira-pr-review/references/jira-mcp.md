# Jira MCP Reference (`jira-pr-review`)

Focused reference for moving a ticket from `In Development` to `In Review`.

## Table of Contents

- [Quick Capability Sequence](#quick-capability-sequence)
- [Capability-to-Tool Mapping](#capability-to-tool-mapping)
- [Board Scope](#board-scope)
- [Resolution Details Field Discovery](#resolution-details-field-discovery)
- [Resolution Details (ADF)](#resolution-details-adf)
- [Transition Resolution Rules](#transition-resolution-rules)
- [Common Errors and Fixes](#common-errors-and-fixes)
- [Verification Checklist](#verification-checklist)

## Quick Capability Sequence

1. Discover site/cloud context.
2. Read issue with `expand: "names"` for field-name mapping.
3. Read issue-type field metadata.
4. Read available transitions.
5. Optional: update Resolution Details when discovered field is empty.
6. Transition to `In Review`.
7. Verify final status and Resolution Details behavior.

Retry Atlassian calls one time on transient/authorization errors before failing.

## Capability-to-Tool Mapping

| Capability | Current MCP Tool |
|---|---|
| DiscoverSite | `mcp__claude_ai_Atlassian__getAccessibleAtlassianResources` |
| ReadIssue | `mcp__claude_ai_Atlassian__getJiraIssue` |
| ReadIssueTypeFields | `mcp__claude_ai_Atlassian__getJiraIssueTypeMetaWithFields` |
| ListTransitions | `mcp__claude_ai_Atlassian__getTransitionsForJiraIssue` |
| UpdateIssue | `mcp__claude_ai_Atlassian__editJiraIssue` |
| TransitionIssue | `mcp__claude_ai_Atlassian__transitionJiraIssue` |
| VerifyIssue | `mcp__claude_ai_Atlassian__getJiraIssue` |

Compatibility guidance:
- If a mapped call is unavailable, use an equivalent operation by capability intent.
- If no safe equivalent exists, fail fast and report the missing capability.

## Board Scope

This skill handles only:
- `In Development` -> `In Review`

This skill does not automate:
- `In Review` -> `QA`
- `QA` -> `QA Acceptance`
- `QA Acceptance` -> `PM Acceptance`
- `PM Acceptance` -> `Ready To Merge`
- `Ready To Merge` -> `Done`

## Resolution Details Field Discovery

Selection rule:
- If multiple Atlassian resources are returned, select `https://metrc-tech.atlassian.net`.

Alias match order:
1. `Resolution Details`
2. `Resolution Detail`
3. `Resolution details`

Normalization rules:
- Lowercase
- Trim leading/trailing whitespace
- Collapse internal whitespace to single spaces

### Read-only discovery calls

Get issue state and names map:

```javascript
mcp__claude_ai_Atlassian__getJiraIssue({
  cloudId: "<cloud-id>",
  issueIdOrKey: "MCA-372",
  expand: "names",
  fields: ["*all"]
})
```

Get issue-type metadata:

```javascript
mcp__claude_ai_Atlassian__getJiraIssueTypeMetaWithFields({
  cloudId: "<cloud-id>",
  projectIdOrKey: "<issue.fields.project.key>",
  issueTypeId: "<issue.fields.issuetype.id>",
  maxResults: 200
})
```

Resolution algorithm:
1. Try alias match against `issue.names` values. If matched, use that field key.
2. If unresolved, try alias match against metadata field `name`; use metadata `fieldId` (fallback to metadata `key`).
3. If still unresolved, ask the user what to do next and include discovered field names from both lookups.

Rules:
- Do not use hardcoded custom field IDs.
- Do not guess fallback field IDs.
- `getJiraIssue` with narrow `fields` only returns a partial `names` map; use `fields: ["*all"]` for reliable name discovery.

## Resolution Details (ADF)

Rules:
- Write to the discovered Resolution Details field id/key.
- Must use ADF document format.
- Plain text values fail for this field.
- For this skill: write only when field is empty.

Plain text example (invalid):

```json
{"<resolutionDetailsFieldId>": "Fixed issue"}
```

Valid dynamic update example:

```javascript
mcp__claude_ai_Atlassian__editJiraIssue({
  cloudId: "<cloud-id>",
  issueIdOrKey: "MCA-372",
  fields: {
    [resolutionDetailsFieldId]: {
      type: "doc",
      version: 1,
      content: [
        {
          type: "paragraph",
          content: [{ type: "text", text: "- Commit subject one" }]
        },
        {
          type: "paragraph",
          content: [{ type: "text", text: "- Commit subject two" }]
        }
      ]
    }
  }
})
```

## Transition Resolution Rules

Resolve transition in this order:
1. Transition with `to.name == "In Review"`
2. Fallback transition with `name == "Review Code"` (case-insensitive)

If neither exists:
- Do not transition.
- Return blocker with available transition names and IDs.

## Common Errors and Fixes

| Error | Cause | Fix |
|---|---|---|
| `Resolution Details field name not found` | Alias match failed in both names and metadata | Ask user what to do next; include discovered field names from issue names and metadata. |
| `Field '<resolved-field-id>' cannot be set` | Non-ADF payload or field not editable in current context | Send ADF object (`type: doc`, `version: 1`, `content`) and verify field editability. |
| `Please enter resolution details` | Workflow validator requires field | If discovered field is empty, update it before transition. |
| Transition to `In Review` unavailable | Wrong current status or workflow path | List available transitions and stop with blocker. |
| 401/Unauthorized or transient API failure | Session/token hiccup | Retry the call once, then fail with re-auth guidance. |

## Verification Checklist

Before mutation:
- PR exists for current branch.
- Jira key resolved.
- Atlassian site/cloud resolved.
- Issue fetched with `expand: "names"`.
- Issue-type metadata fetched.
- Resolution Details field id/key resolved by field name lookup (or user asked what to do if not found).
- Transitions fetched.

After mutation:
- Status is `In Review`.
- Report resolved Resolution Details field id/key.
- Report whether Resolution Details were updated or skipped.
- Output Teams message:

`Review PR: [PR-TITLE](https://github.com/ORG/REPO/pull/123) for this ticket: [TICKET-NUMBER](https://YOUR-DOMAIN.atlassian.net/browse/TICKET-NUMBER)`
