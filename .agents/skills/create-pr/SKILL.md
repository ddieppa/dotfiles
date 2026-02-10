---
name: create-pr
description: Create pull requests using gh CLI with standardized template. Use when user asks to "create a PR", "open a pull request", "submit for review", or "push changes". Extracts Jira ticket (MCA-XXX, PERF-XXX) from branch name and creates well-formatted PRs.
---

# Create Pull Request

**Requires**: GitHub CLI (`gh`) authenticated and available.

## Prerequisites

Before creating a PR, verify branch state running this [create-pr-ready script](scripts/check-pr-ready.ps1)

This checks for uncommitted changes and shows commits to be included. If there are uncommitted changes, commit them first before proceeding.

## Branch Naming Patterns

Branches follow: `{type}/{TICKET}-{description}` or `{type}/{TICKET}_{description}`

| Branch | Ticket | Title |
|--------|--------|-------|
| `fix/MCA-372-400-bad-request-errors-on-plantbatches-v-2` | MCA-372 | 400 bad request errors on plantbatches v2 |
| `feature/PERF-1126_Update_WebApiD8_to_Use_Multitenant_Auth` | PERF-1126 | Update WebApiD8 to Use Multitenant Auth |

**Parsing rules:**
1. Remove prefix (`fix/`, `feature/`, `bugfix/`, `hotfix/`)
2. Extract ticket (pattern: `MCA-\d+` or `PERF-\d+`)
3. Convert remaining `-` or `_` to spaces for title

## Process

### Step 1: Analyze Changes

```powershell
# See commits that will be in the PR
git log development..HEAD --oneline

# See the full diff
git diff development...HEAD --stat
```

Understand the scope and purpose of all changes before writing the description.

### Step 2: Write PR Content

Use template from [assets/pr-template.md](assets/pr-template.md).

| Placeholder | Source |
|-------------|--------|
| `{TICKET_URL}` | `https://metrc-tech.atlassian.net/browse/{ticket}` |
| `{DESCRIPTION}` | What the PR does and why |
| `{CHANGES}` | One bullet per logical change |
| `{TESTING}` | See [Testing section rules](#testing-section) |

**Conditional sections:**
- **Target Branch**: Include only if NOT targeting `development`
- **Screenshots**: Include only for UI changes

### Step 3: Create the PR

```powershell
gh pr create --base development --title "{TICKET} - {title}" --body $Body
```

After creation, output the PR link for quick access:

```powershell
gh pr view --json url -q .url
```

## Testing Section

Analyze commits to determine testing approach:

| Condition | Testing Content |
|-----------|-----------------|
| Commits include `*Test*.cs` or `*Tests*.cs` files | `Unit tests added/updated` or `Integration tests added/updated` |
| No test files in commits | `Manual testing performed` |
| User specifies manual testing details | Include their specific testing steps |

## PR Description Examples

### Feature PR

```markdown
## Ticket
https://metrc-tech.atlassian.net/browse/PERF-1126

## Description
Add multitenant authentication support to WebApiD8. This enables the API to 
handle requests from multiple tenants using a shared authentication flow.

## Changes
- Add TenantAuthMiddleware for request validation
- Update WebApiD8 configuration to support tenant context
- Add tenant resolution from JWT claims

## Testing
Unit tests added for TenantAuthMiddleware
```

### Bug Fix PR

```markdown
## Ticket
https://metrc-tech.atlassian.net/browse/MCA-372

## Description
Fix 400 Bad Request errors on plantbatches v2 growthphase endpoint. The 
endpoint was rejecting valid requests due to incorrect date format validation.

## Changes
- Fix date parsing in GrowthPhaseValidator
- Handle null growth phase gracefully

## Testing
Manual testing performed against staging environment
```

## Target Branches

| Branch | Use |
|--------|-----|
| `development` | Default |
| `version/hotfix/YYYYMMDD` | Hotfixes |
| `main` | Releases only |

## Guidelines

- **One PR per feature/fix** - Don't bundle unrelated changes
- **Keep PRs reviewable** - Smaller PRs get faster, better reviews
- **Explain the why** - Code shows what; description explains why