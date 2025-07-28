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
$ThemeFile = Join 'prompt\night-owl.omp.json'
$Config    = if (Test-Path $ThemeFile) { $ThemeFile } else { 'paradox' }  # fallback
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
