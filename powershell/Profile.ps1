# Dynamic Git-backed PowerShell profile
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

# 1. Modules -------------------------------------------------------
. (Join 'modules\modules.ps1')

# 2. Aliases -------------------------------------------------------
# Load core.ps1 first (contains Set-SafeAlias function)
. (Join 'aliases\core.ps1')

# Load other alias files
Get-ChildItem (Join 'aliases') -Filter '*.ps1' |
    Where-Object { $_.Name -ne 'core.ps1' } |
    ForEach-Object { . $_.FullName }

# 3. PSReadLine bindings ------------------------------------------
. (Join 'psreadline\bindings.ps1')

# 4. Prompt --------------------------------------------------------
$ThemeFile = Join 'prompt\night-owl.omp.json'
$Config    = if (Test-Path $ThemeFile) { $ThemeFile } else { 'paradox' }  # fallback
oh-my-posh init pwsh --config $Config | Invoke-Expression

# 5. Lazy-load posh-git when entering a repo ----------------------
Register-EngineEvent PowerShell.OnIdle -SupportEvent -Action {
    if (-not (Get-Module posh-git) -and (Test-Path .git)) {
        Import-Module posh-git -DisableNameChecking
    }
}

# 6. Quality-of-Life ----------------------------------------------
function reload { . $PROFILE }
Set-Alias rl reload

# Alias management shortcuts
function aliases { Show-CustomAliases }
function alias-check { Show-CustomAliases -ShowConflicts }
function alias-all { Show-CustomAliases -IncludeBuiltIn }
