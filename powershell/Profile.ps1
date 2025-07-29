# Prevent double execution of this profile
# This guard ensures the profile script is only loaded once per session.
# PowerShell can load the profile multiple times in scenarios such as nested sessions, reloading with `. $PROFILE`, or when invoked by other scripts.
# Without this check, duplicate imports, alias definitions, or event registrations could cause errors or unexpected behavior.
if ($global:__DOTFILES_PROFILE_LOADED) { return }
$global:__DOTFILES_PROFILE_LOADED = $true
# Dynamic Git-backed PowerShell profile
# Profile Performance Timer
$ProfileTimer = [System.Diagnostics.Stopwatch]::StartNew()
Write-Host "🔄 Loading PowerShell profile..." -ForegroundColor Cyan

# Find the dotfiles repository root
$RepoRoot = if ($MyInvocation.MyCommand.Path) {
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
function Join($child) { Join-Path -Path $RepoRoot -ChildPath $child }
Write-Host "  📁 Repository root: $RepoRoot ($($ProfileTimer.ElapsedMilliseconds)ms)" -ForegroundColor Gray

# 1. Modules -------------------------------------------------------
Write-Host "  📦 Loading modules..." -ForegroundColor Yellow
$ProfileTimer.Restart()
. (Join 'modules\modules.ps1')
Write-Host "  ✓ Modules loaded ($($ProfileTimer.ElapsedMilliseconds)ms)" -ForegroundColor Green

# 2. Aliases -------------------------------------------------------
Write-Host "  🔗 Loading core aliases..." -ForegroundColor Yellow
$ProfileTimer.Restart()
# Load core.ps1 first (contains Set-SafeAlias function)
. (Join 'aliases\core.ps1')
Write-Host "  ✓ Core aliases loaded ($($ProfileTimer.ElapsedMilliseconds)ms)" -ForegroundColor Green

Write-Host "  🔗 Loading additional aliases..." -ForegroundColor Yellow
$ProfileTimer.Restart()
# Load other alias files
Get-ChildItem (Join 'aliases') -Filter '*.ps1' |
    Where-Object { $_.Name -ne 'core.ps1' } |
    ForEach-Object { 
        Write-Host "    Loading $($_.Name)..." -ForegroundColor DarkGray
        . $_.FullName 
    }
Write-Host "  ✓ Additional aliases loaded ($($ProfileTimer.ElapsedMilliseconds)ms)" -ForegroundColor Green

# 3. PSReadLine bindings ------------------------------------------
Write-Host "  ⌨️  Loading PSReadLine bindings..." -ForegroundColor Yellow
$ProfileTimer.Restart()
. (Join 'psreadline\bindings.ps1')
Write-Host "  ✓ PSReadLine bindings loaded ($($ProfileTimer.ElapsedMilliseconds)ms)" -ForegroundColor Green

# 4. Prompt --------------------------------------------------------
Write-Host "  🎨 Loading Oh My Posh theme..." -ForegroundColor Yellow
$ProfileTimer.Restart()

# Look for theme configuration file first
$ThemeConfigFile = Join '.theme-config'
$SelectedThemeFile = $null

if (Test-Path $ThemeConfigFile) {
    $SelectedThemeFile = Get-Content $ThemeConfigFile -Raw | ForEach-Object { $_.Trim() }
    if ($SelectedThemeFile -and (Test-Path $SelectedThemeFile)) {
        Write-Host "  📝 Using configured theme: $(Split-Path $SelectedThemeFile -Leaf)" -ForegroundColor Gray
    } else {
        $SelectedThemeFile = $null
    }
}

# If no configured theme, look for any theme in prompt folder only
if (-not $SelectedThemeFile) {
    $ThemeFolder = Join 'prompt'
    if (Test-Path $ThemeFolder) {
        $AvailableThemes = Get-ChildItem -Path $ThemeFolder -Filter '*.omp.json' | Select-Object -First 1
        if ($AvailableThemes) {
            $SelectedThemeFile = $AvailableThemes.FullName
            Write-Host "  🎯 Using first available theme: $($AvailableThemes.Name) from prompt" -ForegroundColor Gray
        }
    }
}

# Final fallback to built-in theme
$Config = if ($SelectedThemeFile -and (Test-Path $SelectedThemeFile)) { 
    $SelectedThemeFile 
} else { 
    Write-Host "  ⚠️  No custom themes found, using built-in 'paradox'" -ForegroundColor Yellow
    'paradox' 
}

oh-my-posh init pwsh --config $Config | Invoke-Expression
Write-Host "  ✓ Oh My Posh theme loaded ($($ProfileTimer.ElapsedMilliseconds)ms)" -ForegroundColor Green

# 5. Lazy-load posh-git when entering a repo ----------------------
Write-Host "  🌿 Setting up posh-git lazy loading..." -ForegroundColor Yellow
$ProfileTimer.Restart()
Register-EngineEvent PowerShell.OnIdle -SupportEvent -Action {
    if (-not (Get-Module posh-git) -and (Test-Path .git)) {
        Import-Module posh-git -DisableNameChecking
    }
}
Write-Host "  ✓ Posh-git lazy loading configured ($($ProfileTimer.ElapsedMilliseconds)ms)" -ForegroundColor Green

# 6. Quality-of-Life ----------------------------------------------
Write-Host "  ⚡ Setting up quality-of-life functions..." -ForegroundColor Yellow
$ProfileTimer.Restart()
function reload { . $PROFILE }
Set-Alias rl reload

# Alias management shortcuts
function aliases { Show-CustomAliases }
function alias-check { Show-CustomAliases -ShowConflicts }
function alias-all { Show-CustomAliases -IncludeBuiltIn }
Write-Host "  ✓ Quality-of-life functions loaded ($($ProfileTimer.ElapsedMilliseconds)ms)" -ForegroundColor Green

# Profile loading complete
$ProfileTimer.Stop()
Write-Host "🚀 Profile loading complete! Total time: $($ProfileTimer.ElapsedMilliseconds)ms" -ForegroundColor Cyan
