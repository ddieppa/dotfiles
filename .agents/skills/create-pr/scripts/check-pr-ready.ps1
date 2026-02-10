<#
.SYNOPSIS
    Check if branch is ready for PR creation.
.DESCRIPTION
    Verifies no uncommitted changes and shows PR context.
.PARAMETER Target
    Target branch. Defaults to "development".
.EXAMPLE
    .\check-pr-ready.ps1
    .\check-pr-ready.ps1 -Target "main"
#>

param(
    [string]$Target = "development"
)

$HasErrors = $false

Write-Host "=== Pre-flight Checks ===" -ForegroundColor Cyan
Write-Host ""

# Ensure we're in a git repository
$InRepo = git rev-parse --is-inside-work-tree 2>$null
if ($LASTEXITCODE -ne 0 -or $InRepo -ne "true") {
    Write-Host "[FAIL] Not inside a git repository." -ForegroundColor Red
    exit 1
}

function Resolve-TargetRef {
    param(
        [string]$TargetBranch
    )

    $LocalRef = "refs/heads/$TargetBranch"
    $RemoteRef = "refs/remotes/origin/$TargetBranch"

    git show-ref --verify $LocalRef 2>$null | Out-Null
    if ($LASTEXITCODE -eq 0) {
        return $TargetBranch
    }

    git show-ref --verify $RemoteRef 2>$null | Out-Null
    if ($LASTEXITCODE -eq 0) {
        return "origin/$TargetBranch"
    }

    git fetch origin $TargetBranch 2>$null | Out-Null
    git show-ref --verify $RemoteRef 2>$null | Out-Null
    if ($LASTEXITCODE -eq 0) {
        return "origin/$TargetBranch"
    }

    return $null
}

# Check for uncommitted changes
$Status = git status --porcelain
if ($Status) {
    Write-Host "[FAIL] Uncommitted changes detected:" -ForegroundColor Red
    Write-Host $Status
    Write-Host ""
    Write-Host "Commit or stash changes before creating PR." -ForegroundColor Yellow
    $HasErrors = $true
} else {
    Write-Host "[OK] Working directory clean" -ForegroundColor Green
}

# Resolve target ref (local or origin)
$TargetRef = Resolve-TargetRef -TargetBranch $Target
if (-not $TargetRef) {
    Write-Host "[FAIL] Target branch '$Target' not found locally or on origin." -ForegroundColor Red
    $HasErrors = $true
}

# Check if branch has commits ahead of target
$Commits = $null
if ($TargetRef) {
    $Commits = git log "$TargetRef..HEAD" --oneline 2>$null
}

if (-not $Commits) {
    Write-Host "[FAIL] No commits ahead of $Target" -ForegroundColor Red
    $HasErrors = $true
} else {
    $CommitCount = ($Commits | Measure-Object -Line).Lines
    Write-Host "[OK] $CommitCount commit(s) ahead of $Target" -ForegroundColor Green
}

Write-Host ""

if ($HasErrors) {
    Write-Host "=== Fix issues above before creating PR ===" -ForegroundColor Red
    exit 1
}

# Show context
$Branch = git branch --show-current

$Ticket = $null
if ($Branch -match '(MCA-\d+|PERF-\d+)') {
    $Ticket = $Matches[1]
}

$Title = $Branch -replace '^(fix|feature|bugfix|hotfix)/', ''
$Title = $Title -replace "^$Ticket[-_]?", ''
$Title = $Title -replace '[-_]', ' '
$Title = (Get-Culture).TextInfo.ToTitleCase($Title.Trim().ToLower())

Write-Host "=== PR Context ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Branch:  $Branch"
Write-Host "Ticket:  $(if ($Ticket) { $Ticket } else { '(none found)' })"
Write-Host "Title:   $(if ($Ticket) { "$Ticket - $Title" } else { $Title })"
Write-Host "Target:  $Target"
Write-Host ""

Write-Host "=== Commits ===" -ForegroundColor Cyan
Write-Host $Commits
Write-Host ""

Write-Host "=== Changed Files ===" -ForegroundColor Cyan
if ($TargetRef) {
    git diff "$TargetRef" --stat 2>$null
}
Write-Host ""

# Check for test files
Write-Host "=== Test Files ===" -ForegroundColor Cyan
$TestFiles = @()
if ($TargetRef) {
    $TestFiles = git diff "$TargetRef" --name-only 2>$null | Where-Object { $_ -match 'Test.*\.cs$|Tests.*\.cs$' }
}
if ($TestFiles) {
    Write-Host "Tests added/modified:" -ForegroundColor Green
    $TestFiles | ForEach-Object { Write-Host "  $_" }
} else {
    Write-Host "(No test files in changes - use manual testing)" -ForegroundColor Yellow
}