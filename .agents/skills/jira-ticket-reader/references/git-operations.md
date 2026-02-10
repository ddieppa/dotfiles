# Git Operations Reference

Git command patterns and best practices for the jira-ticket-reader skill.

## Branch Name Extraction

### Regex Pattern

Extract Jira ticket ID from branch name:

```regex
[A-Z]+-\d+
```

**Examples:**
- `fix/MCA-402-bug-fix` → `MCA-402`
- `feature/PERF-1126-optimization` → `PERF-1126`
- `hotfix/BUG-999-critical-fix` → `BUG-999`

### PowerShell Implementation

```powershell
# Get current branch
$branch = git branch --show-current

# Extract ticket ID
if ($branch -match '([A-Z]+-\d+)') {
    $ticketId = $matches[1]
    Write-Output "Found ticket: $ticketId"
} else {
    Write-Output "No ticket ID found in branch name"
}
```

### Bash Implementation

```bash
# Get current branch
branch=$(git branch --show-current)

# Extract ticket ID
if [[ $branch =~ ([A-Z]+-[0-9]+) ]]; then
    ticket_id="${BASH_REMATCH[1]}"
    echo "Found ticket: $ticket_id"
else
    echo "No ticket ID found in branch name"
fi
```

## Git Status Checks

### Verify Git Repository

```powershell
# Check if current directory is a git repository
try {
    git rev-parse --git-dir
    Write-Output "✅ Git repository found"
} catch {
    Write-Error "❌ Not a git repository"
    exit 1
}
```

### Check Git Installation

```powershell
# Verify git is installed and accessible
try {
    $version = git --version
    Write-Output "✅ Git installed: $version"
} catch {
    Write-Error "❌ Git not found. Please install Git CLI"
    exit 1
}
```

## Branch Information

### Get Current Branch

```powershell
# Get current branch name
$branch = git branch --show-current

# Alternative for older git versions
$branch = git rev-parse --abbrev-ref HEAD
```

### List All Branches

```powershell
# List local branches
git branch

# List remote branches
git branch -r

# List all branches
git branch -a
```

### Check if Branch Exists

```powershell
# Check if local branch exists
$branchExists = git branch --list "branch-name"

if ($branchExists) {
    Write-Output "Branch exists"
} else {
    Write-Output "Branch does not exist"
}
```

## Error Handling

### Common Git Errors

| Error | Cause | Solution |
|-------|-------|----------|
| `fatal: not a git repository` | Not in a git directory | Navigate to project root |
| `fatal: ambiguous argument 'HEAD'` | Empty repository | Initialize with first commit |
| `git: command not found` | Git not installed | Install Git CLI |
| `fatal: ref HEAD is not a symbolic ref` | Detached HEAD state | Checkout a branch |

### Safe Command Execution

```powershell
function Invoke-GitCommand {
    param(
        [string]$Command,
        [string]$ErrorMessage = "Git command failed"
    )
    
    try {
        $output = Invoke-Expression "git $Command" 2>&1
        
        if ($LASTEXITCODE -ne 0) {
            throw $ErrorMessage
        }
        
        return $output
    } catch {
        Write-Error "$ErrorMessage : $_"
        return $null
    }
}

# Usage
$branch = Invoke-GitCommand "branch --show-current" "Failed to get current branch"
```

## Best Practices

### 1. Always Verify Git State

Before any git operations:
- Check if in a git repository
- Verify git is installed
- Confirm current branch

### 2. Handle Edge Cases

- Empty repositories (no commits)
- Detached HEAD state
- Branches without ticket IDs
- Special characters in branch names

### 3. Cross-Platform Compatibility

**PowerShell (Windows):**
```powershell
$branch = git branch --show-current
```

**Bash (Unix/Mac):**
```bash
branch=$(git branch --show-current)
```

**Both:**
```powershell
# Works on both platforms
git rev-parse --abbrev-ref HEAD
```

### 4. Error Messages

Provide clear, actionable error messages:

```powershell
if (-not (Test-Path .git)) {
    Write-Error @"
❌ Not a git repository

This command must be run from within a git repository.

To fix:
1. Navigate to your project directory
2. Or initialize a new repository: git init
"@
    exit 1
}
```

## Integration with Jira Ticket Reader

### Workflow

1. **Validate Git Environment**
   ```powershell
   git --version
   git rev-parse --git-dir
   ```

2. **Get Current Branch**
   ```powershell
   $branch = git branch --show-current
   ```

3. **Extract Ticket ID**
   ```powershell
   if ($branch -match '([A-Z]+-\d+)') {
       $ticketId = $matches[1]
   }
   ```

4. **Fallback to User Input**
   ```powershell
   if (-not $ticketId) {
       Write-Output "No ticket ID found in branch name"
       # Proceed to query Jira or ask user
   }
   ```

### Complete Example

```powershell
# Complete ticket ID extraction with error handling
function Get-JiraTicketFromBranch {
    # Validate git installation
    try {
        $null = git --version
    } catch {
        throw "Git CLI not found. Please install Git."
    }
    
    # Validate git repository
    try {
        $null = git rev-parse --git-dir
    } catch {
        throw "Not a git repository. Navigate to project directory."
    }
    
    # Get current branch
    try {
        $branch = git branch --show-current
    } catch {
        throw "Failed to get current branch"
    }
    
    # Extract ticket ID
    if ($branch -match '([A-Z]+-\d+)') {
        $ticketId = $matches[1]
        Write-Output "✅ Found ticket ID: $ticketId"
        return $ticketId
    } else {
        Write-Output "⚠️  No ticket ID found in branch: $branch"
        return $null
    }
}

# Usage
$ticketId = Get-JiraTicketFromBranch

if ($ticketId) {
    # Proceed with Jira operations
} else {
    # Fallback to alternative methods
}
```

## Troubleshooting

### Issue: Branch name not found

**Symptoms:**
- `git branch --show-current` returns empty
- Command fails with error

**Causes:**
1. Detached HEAD state
2. Old git version (< 2.22)
3. No commits in repository

**Solutions:**
```powershell
# Try alternative method
$branch = git rev-parse --abbrev-ref HEAD

# Check for detached HEAD
if ($branch -eq "HEAD") {
    Write-Warning "In detached HEAD state"
    # Get commit hash instead
    $commit = git rev-parse --short HEAD
}
```

### Issue: Special characters in branch name

**Symptoms:**
- Regex doesn't match expected ticket ID
- Branch name contains spaces or special chars

**Solution:**
```powershell
# Escape special characters
$branch = $branch -replace '[^\w\-/]', ''

# More lenient regex
if ($branch -match '([A-Z]+[-_]\d+)') {
    $ticketId = $matches[1] -replace '_', '-'
}
```

### Issue: Multiple ticket IDs in branch

**Example:** `fix/MCA-402-MCA-403-combined-fix`

**Solution:**
```powershell
# Extract first match
if ($branch -match '([A-Z]+-\d+)') {
    $ticketId = $matches[1]
}

# Or extract all matches
$allTickets = [regex]::Matches($branch, '[A-Z]+-\d+') | 
    ForEach-Object { $_.Value }

if ($allTickets.Count -gt 1) {
    Write-Warning "Multiple tickets found: $($allTickets -join ', ')"
    # Ask user which one to use
}
```

## References

- [Git Documentation](https://git-scm.com/doc)
- [Git Branch Naming Best Practices](https://deepsource.io/blog/git-branch-naming-conventions/)
- [Jira MCP API Reference](jira-mcp.md)
