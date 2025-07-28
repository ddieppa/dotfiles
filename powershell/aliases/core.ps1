# Safe alias function (reusable across alias files)
function Set-SafeAlias {
    param(
        [string]$Name,
        [string]$Value,
        [switch]$Verbose
    )
    
    $existingAlias = Get-Alias -Name $Name -ErrorAction SilentlyContinue
    if ($existingAlias) {
        if ($existingAlias.Options -match 'ReadOnly|Constant') {
            if ($Verbose) { Write-Warning "Alias '$Name' is read-only. Forcing override..." }
            Set-Alias -Name $Name -Value $Value -Force -Scope Global -ErrorAction SilentlyContinue
        } else {
            if ($Verbose) { Write-Host "Updating existing alias '$Name'" -ForegroundColor Yellow }
            Set-Alias -Name $Name -Value $Value -Scope Global
        }
    } else {
        if ($Verbose) { Write-Host "Creating new alias '$Name'" -ForegroundColor Green }
        Set-Alias -Name $Name -Value $Value -Scope Global
    }
}

# Function to check all custom aliases and their status
function Show-CustomAliases {
    param(
        [switch]$IncludeBuiltIn,
        [switch]$ShowConflicts
    )
    
    Write-Host "`n=== Custom Aliases Status ===" -ForegroundColor Cyan

    # Dynamically find all alias names from all .ps1 files in the aliases directory
    # Use the global $RepoRoot variable if available, otherwise try to find it
    $repoRoot = if (Get-Variable -Name 'RepoRoot' -ErrorAction SilentlyContinue) { 
        $RepoRoot 
    } else { 
        # Fallback: try to find the dotfiles directory
        $possiblePaths = @(
            "D:\dotfiles\powershell",
            "C:\dotfiles\powershell",
            "$env:USERPROFILE\dotfiles\powershell",
            "$env:USERPROFILE\Documents\dotfiles\powershell"
        )
        $possiblePaths | Where-Object { Test-Path $_ } | Select-Object -First 1
    }
    
    if (-not $repoRoot) {
        Write-Host "  Could not find dotfiles repository root" -ForegroundColor Red
        return
    }
    
    $aliasesDir = Join-Path $repoRoot 'aliases'
    if (-not (Test-Path $aliasesDir)) {
        Write-Host "  Aliases directory not found: $aliasesDir" -ForegroundColor Red
        return
    }
    
    $aliasFiles = Get-ChildItem -Path $aliasesDir -Filter '*.ps1' -ErrorAction SilentlyContinue
    $aliasNames = @()
    foreach ($file in $aliasFiles) {
        $content = Get-Content $file.FullName -Raw
        
        # Match Set-SafeAlias and Set-Alias calls - match the first parameter after the command
        $aliasMatches = [regex]::Matches($content, '(?m)^\s*Set-(?:Safe)?Alias\s+([^\s]+)')
        foreach ($m in $aliasMatches) {
            $aliasName = $m.Groups[1].Value.Trim("'", '"')
            if ($aliasName -and $aliasName -notmatch '^-') {
                $aliasNames += $aliasName
            }
        }
        
        # Match function definitions
        $functionMatches = [regex]::Matches($content, '(?m)^\s*function\s+([^\s{]+)')
        foreach ($m in $functionMatches) {
            $functionName = $m.Groups[1].Value.Trim()
            if ($functionName -and $functionName -notmatch '^(Set-SafeAlias|Show-CustomAliases|Reset-CustomAliases|Get-AliasConflicts)$') {
                $aliasNames += $functionName
            }
        }
    }
    $aliasNames = $aliasNames | Sort-Object -Unique
    $conflicts = @()

    if ($aliasNames.Count -eq 0) {
        Write-Host "  No aliases found in $aliasesDir" -ForegroundColor Yellow
        return
    }

    foreach ($aliasName in $aliasNames) {
        # Check if it's an alias first
        $alias = Get-Alias -Name $aliasName -ErrorAction SilentlyContinue
        if ($alias) {
            $status = if ($alias.Options -match 'ReadOnly') { 'ReadOnly' }
                     elseif ($alias.Options -match 'Constant') { 'Constant' }
                     else { 'Normal' }

            $color = switch ($status) {
                'ReadOnly' { 'Yellow' }
                'Constant' { 'Red' }
                'Normal' { 'Green' }
            }

            Write-Host "  $aliasName -> $($alias.Definition) [Alias-$status]" -ForegroundColor $color

            if ($status -ne 'Normal') {
                $conflicts += $aliasName
            }
        } else {
            # Check if it's a function
            $function = Get-Command -Name $aliasName -CommandType Function -ErrorAction SilentlyContinue
            if ($function) {
                Write-Host "  $aliasName -> $($function.Definition.Split("`n")[0].Trim()) [Function]" -ForegroundColor Cyan
            } else {
                Write-Host "  $aliasName -> NOT FOUND" -ForegroundColor Red
            }
        }
    }

    if ($ShowConflicts -and $conflicts.Count -gt 0) {
        Write-Host "`n=== Conflicted Aliases ===" -ForegroundColor Red
        foreach ($conflict in $conflicts) {
            $alias = Get-Alias -Name $conflict -ErrorAction SilentlyContinue
            if ([string]::IsNullOrWhiteSpace($alias.Source)) {
                # Built-in alias - show descriptive message
                Write-Host "  $conflict is a built-in alias for $($alias.Definition)" -ForegroundColor Red
            } else {
                # Module or script alias - show source
                Write-Host "  $conflict is $($alias.Options) - Source: $($alias.Source) -> $($alias.Definition)" -ForegroundColor Red
            }
        }
    }

    if ($IncludeBuiltIn) {
        Write-Host "`n=== All Aliases ===" -ForegroundColor Magenta
        Get-Alias | Sort-Object Name | Format-Table Name, Definition, Options -AutoSize
    }
}

# Function to reset/remove custom aliases
function Reset-CustomAliases {
    param([switch]$Force)
    
    $customAliases = @('ll', 'la', 'np', 'ni', 'nr', 'nrb', 'nrt')
    
    if (-not $Force) {
        $response = Read-Host "This will remove all custom aliases. Continue? (y/N)"
        if ($response -ne 'y' -and $response -ne 'Y') {
            Write-Host "Operation cancelled." -ForegroundColor Yellow
            return
        }
    }
    
    foreach ($aliasName in $customAliases) {
        try {
            Remove-Alias -Name $aliasName -Force -ErrorAction SilentlyContinue
            Write-Host "Removed alias: $aliasName" -ForegroundColor Green
        } catch {
            Write-Warning "Could not remove alias: $aliasName"
        }
    }
}

# Core aliases
Set-SafeAlias ll Get-ChildItem
Set-SafeAlias la 'Get-ChildItem -Force'

# Utility functions
function which { Get-Command -Name $args }
function Get-AliasConflicts { Show-CustomAliases -ShowConflicts }
