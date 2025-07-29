#Requires -Version 5.1

# Prevent double execution of this profile
# This guard ensures the profile script is only loaded once per session.
# PowerShell can load the profile multiple times in scenarios such as nested sessions, reloading with `. $PROFILE`, or when invoked by other scripts.
# Without this check, duplicate imports, alias definitions, or event registrations could cause errors or unexpected behavior.
$profileVarName = "__DOTFILES_PROFILE_LOADED_$($PROFILE -replace '[\\/:*?""<>|]', '_')"
if (Get-Variable -Name $profileVarName -Scope Global -ErrorAction SilentlyContinue) { return }
Set-Variable -Name $profileVarName -Value $true -Scope Global
# Dynamic Git-backed PowerShell profile
# Profile Performance Timer
$ProfileTimer = [System.Diagnostics.Stopwatch]::StartNew()

# Ensure proper Unicode output encoding for emojis
if ([Console]::OutputEncoding.CodePage -ne 65001) {
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
}

Write-Host "🔄 Loading PowerShell profile..." -ForegroundColor Cyan
$HostSupportsColor = $Host.UI.SupportsVirtualTerminal

# Find the dotfiles repository root with better error handling
$RepoRoot = try {
    if ($MyInvocation.MyCommand.Path) {
        # First try to resolve symlink target
        $item = Get-Item $MyInvocation.MyCommand.Path -Force -ErrorAction SilentlyContinue
        if ($item -and $item.Target) {
            Split-Path $item.Target -Parent
        } else {
            # Search for dotfiles directory in common locations
            $possiblePaths = @(
                "D:\dotfiles\powershell",
                "C:\dotfiles\powershell",
                "$env:USERPROFILE\dotfiles\powershell",
                "$env:USERPROFILE\Documents\dotfiles\powershell"
            )
            $foundPath = $possiblePaths | Where-Object { Test-Path $_ } | Select-Object -First 1
            if ($foundPath) {
                $foundPath
            } else {
                $PSScriptRoot
            }
        }
    } else {
        $PSScriptRoot
    }
} catch {
    Write-Warning "Error determining profile root: $_"
    $PSScriptRoot
}

function Join($child) { 
    if (-not $RepoRoot) { throw "Repository root not determined" }
    Join-Path -Path $RepoRoot -ChildPath $child 
}

if ($HostSupportsColor) {
    Write-Host "  📁 Repository root: $RepoRoot ($($ProfileTimer.ElapsedMilliseconds)ms)" -ForegroundColor Gray
} else {
    Write-Host "  Repository root: $RepoRoot ($($ProfileTimer.ElapsedMilliseconds)ms)"
}

# 1. Modules -------------------------------------------------------
if ($HostSupportsColor) { Write-Host "  📦 Loading modules..." -ForegroundColor Yellow }
else { Write-Host "  Loading modules..." }
$ProfileTimer.Restart()

try {
    . (Join 'modules\modules.ps1')
    if ($HostSupportsColor) { Write-Host "  ✓ Modules loaded ($($ProfileTimer.ElapsedMilliseconds)ms)" -ForegroundColor Green }
    else { Write-Host "  Modules loaded ($($ProfileTimer.ElapsedMilliseconds)ms)" }
} catch {
    Write-Warning "Failed to load modules: $_"
}

# 2. Aliases -------------------------------------------------------
if ($HostSupportsColor) { Write-Host "  🔗 Loading core aliases..." -ForegroundColor Yellow }
else { Write-Host "  Loading core aliases..." }
$ProfileTimer.Restart()

try {
    # Load core.ps1 first (contains Set-SafeAlias function)
    . (Join 'aliases\core.ps1')
    if ($HostSupportsColor) { Write-Host "  ✓ Core aliases loaded ($($ProfileTimer.ElapsedMilliseconds)ms)" -ForegroundColor Green }
    else { Write-Host "  Core aliases loaded ($($ProfileTimer.ElapsedMilliseconds)ms)" }
} catch {
    Write-Warning "Failed to load core aliases: $_"
}

if ($HostSupportsColor) { Write-Host "  🔗 Loading additional aliases..." -ForegroundColor Yellow }
else { Write-Host "  Loading additional aliases..." }
$ProfileTimer.Restart()

try {
    # Load other alias files - more efficient approach
    $aliasFiles = Get-ChildItem (Join 'aliases') -Filter '*.ps1' -ErrorAction SilentlyContinue |
                  Where-Object { $_.Name -ne 'core.ps1' }
    
    foreach ($file in $aliasFiles) { 
        try {
            if ($HostSupportsColor) { Write-Host "    Loading $($file.Name)..." -ForegroundColor DarkGray }
            else { Write-Host "    Loading $($file.Name)..." }
            . $file.FullName 
        } catch {
            Write-Warning "Failed to load $($file.Name): $_"
        }
    }
    
    if ($HostSupportsColor) { Write-Host "  ✓ Additional aliases loaded ($($ProfileTimer.ElapsedMilliseconds)ms)" -ForegroundColor Green }
    else { Write-Host "  Additional aliases loaded ($($ProfileTimer.ElapsedMilliseconds)ms)" }
} catch {
    Write-Warning "Failed to load additional aliases: $_"
}

# 3. PSReadLine bindings ------------------------------------------
if ($HostSupportsColor) { Write-Host "  ⌨️  Loading PSReadLine bindings..." -ForegroundColor Yellow }
else { Write-Host "  Loading PSReadLine bindings..." }
$ProfileTimer.Restart()

try {
    . (Join 'psreadline\bindings.ps1')
    if ($HostSupportsColor) { Write-Host "  ✓ PSReadLine bindings loaded ($($ProfileTimer.ElapsedMilliseconds)ms)" -ForegroundColor Green }
    else { Write-Host "  PSReadLine bindings loaded ($($ProfileTimer.ElapsedMilliseconds)ms)" }
} catch {
    Write-Warning "Failed to load PSReadLine bindings: $_"
}

# 4. Prompt --------------------------------------------------------
if ($HostSupportsColor) { Write-Host "  🎨 Loading Oh My Posh theme..." -ForegroundColor Yellow }
else { Write-Host "  Loading Oh My Posh theme..." }
$ProfileTimer.Restart()

try {
    # Look for theme configuration file first
    $ThemeConfigFile = Join '.theme-config'
    $SelectedThemeFile = $null

    if (Test-Path $ThemeConfigFile) {
        $SelectedThemeFile = Get-Content $ThemeConfigFile -Raw -ErrorAction SilentlyContinue | ForEach-Object { $_.Trim() }
        if ($SelectedThemeFile -and (Test-Path $SelectedThemeFile)) {
            if ($HostSupportsColor) { Write-Host "  📝 Using configured theme: $(Split-Path $SelectedThemeFile -Leaf)" -ForegroundColor Gray }
            else { Write-Host "  Using configured theme: $(Split-Path $SelectedThemeFile -Leaf)" }
        } else {
            $SelectedThemeFile = $null
        }
    }

    # If no configured theme, look for any theme in prompt folder only
    if (-not $SelectedThemeFile) {
        $ThemeFolder = Join 'prompt'
        if (Test-Path $ThemeFolder) {
            $AvailableThemes = Get-ChildItem -Path $ThemeFolder -Filter '*.omp.json' -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($AvailableThemes) {
                $SelectedThemeFile = $AvailableThemes.FullName
                if ($HostSupportsColor) { Write-Host "  🎯 Using first available theme: $($AvailableThemes.Name) from prompt" -ForegroundColor Gray }
                else { Write-Host "  Using first available theme: $($AvailableThemes.Name) from prompt" }
            }
        }
    }

    # Final fallback to built-in theme
    $Config = if ($SelectedThemeFile -and (Test-Path $SelectedThemeFile)) { 
        $SelectedThemeFile 
    } else { 
        if ($HostSupportsColor) { Write-Host "  ⚠️  No custom themes found, using built-in 'paradox'" -ForegroundColor Yellow }
        else { Write-Host "  No custom themes found, using built-in 'paradox'" }
        'paradox' 
    }

    oh-my-posh init pwsh --config $Config | Invoke-Expression
    if ($HostSupportsColor) { Write-Host "  ✓ Oh My Posh theme loaded ($($ProfileTimer.ElapsedMilliseconds)ms)" -ForegroundColor Green }
    else { Write-Host "  Oh My Posh theme loaded ($($ProfileTimer.ElapsedMilliseconds)ms)" }
} catch {
    Write-Warning "Failed to load Oh My Posh theme: $_"
}

# 5. Lazy-load posh-git when entering a repo ----------------------
if ($HostSupportsColor) { Write-Host "  🌿 Setting up posh-git lazy loading..." -ForegroundColor Yellow }
else { Write-Host "  Setting up posh-git lazy loading..." }
$ProfileTimer.Restart()

try {
    # More efficient lazy loading with proper error handling
    Register-EngineEvent PowerShell.OnIdle -SupportEvent -Action {
        try {
            if (-not (Get-Module posh-git) -and (Test-Path .git -ErrorAction SilentlyContinue)) {
                Import-Module posh-git -DisableNameChecking -ErrorAction SilentlyContinue
            }
        } catch {
            # Silently continue if posh-git fails to load
        }
    } | Out-Null
    
    if ($HostSupportsColor) { Write-Host "  ✓ Posh-git lazy loading configured ($($ProfileTimer.ElapsedMilliseconds)ms)" -ForegroundColor Green }
    else { Write-Host "  Posh-git lazy loading configured ($($ProfileTimer.ElapsedMilliseconds)ms)" }
} catch {
    Write-Warning "Failed to configure posh-git lazy loading: $_"
}

# 6. Quality-of-Life ----------------------------------------------
if ($HostSupportsColor) { Write-Host "  ⚡ Setting up quality-of-life functions..." -ForegroundColor Yellow }
else { Write-Host "  Setting up quality-of-life functions..." }
$ProfileTimer.Restart()

try {
    # Reload function with better error handling
    function global:reload {
        [CmdletBinding()]
        param()
        try {
            . $PROFILE
        } catch {
            Write-Error "Failed to reload profile: $_"
        }
    }
    Set-Alias -Name rl -Value reload -Scope Global -ErrorAction SilentlyContinue

    # Alias management shortcuts with error handling
    function global:aliases { 
        if (Get-Command Show-CustomAliases -ErrorAction SilentlyContinue) {
            Show-CustomAliases 
        } else {
            Get-Alias | Sort-Object Name
        }
    }
    
    function global:Test-Alias { 
        if (Get-Command Show-CustomAliases -ErrorAction SilentlyContinue) {
            Show-CustomAliases -ShowConflicts 
        } else {
            Write-Warning "Show-CustomAliases function not available"
        }
    }
    
    function global:Get-AllAliases { 
        if (Get-Command Show-CustomAliases -ErrorAction SilentlyContinue) {
            Show-CustomAliases -IncludeBuiltIn 
        } else {
            Get-Alias | Sort-Object Name
        }
    }
    
    if ($HostSupportsColor) { Write-Host "  ✓ Quality-of-life functions loaded ($($ProfileTimer.ElapsedMilliseconds)ms)" -ForegroundColor Green }
    else { Write-Host "  Quality-of-life functions loaded ($($ProfileTimer.ElapsedMilliseconds)ms)" }
} catch {
    Write-Warning "Failed to load quality-of-life functions: $_"
}

# Profile loading complete
$ProfileTimer.Stop()
if ($HostSupportsColor) { 
    Write-Host "🚀 Profile loading complete! Total time: $($ProfileTimer.ElapsedMilliseconds)ms" -ForegroundColor Cyan
    Write-Host "PowerShell $($PSVersionTable.PSVersion) | $($PSVersionTable.PSEdition) Edition" -ForegroundColor Gray
} else { 
    Write-Host "Profile loading complete! Total time: $($ProfileTimer.ElapsedMilliseconds)ms"
    Write-Host "PowerShell $($PSVersionTable.PSVersion) | $($PSVersionTable.PSEdition) Edition"
}

# Clean up variables
Remove-Variable -Name ProfileTimer, HostSupportsColor -ErrorAction SilentlyContinue
