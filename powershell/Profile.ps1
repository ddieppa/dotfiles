# --- PowerShell Profile ---
# Performance-optimized with conditional loading and error guards

# Prevent double initialization when both profile types load the same script.
if ($global:DotfilesProfileLoaded) { return }
$global:DotfilesProfileLoaded = $true

#region Module Loading (with guards)
if (Get-Module -ListAvailable Terminal-Icons) {
    Import-Module -Name Terminal-Icons
}

if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
    oh-my-posh init pwsh --config peru | Invoke-Expression
}
#endregion

#region Smart Navigation (Zoxide)
if (Get-Command zoxide -ErrorAction SilentlyContinue) {
    Invoke-Expression (& { (zoxide init powershell --cmd z --hook prompt | Out-String) })
}
#endregion

#region PSReadLine Configuration
$canUsePredictions = $false
try {
    $canUsePredictions = (
        [Environment]::UserInteractive -and
        -not [Console]::IsInputRedirected -and
        -not [Console]::IsOutputRedirected -and
        $Host.UI.SupportsVirtualTerminal
    )
} catch {
    $canUsePredictions = $false
}

if ($canUsePredictions) {
    Set-PSReadLineOption -PredictionSource History
    Set-PSReadLineOption -PredictionViewStyle ListView
}
#endregion

#region Deep History Search (fzf)
if (Get-Module -ListAvailable PSFzf) {
    Import-Module PSFzf
    Set-PsFzfOption -HistoryDefault
}
#endregion

#region .NET Developer Functions
function dni {
    Write-Host "`n--- .NET SDKs ---" -ForegroundColor Cyan
    dotnet --list-sdks
    Write-Host "`n--- .NET Runtimes ---" -ForegroundColor Cyan
    dotnet --list-runtimes
    Write-Host ""
}

# Or keep as functions if you need argument handling
function dnt { dotnet test @args }
function dnw { dotnet watch @args }
function dnc { dotnet clean }
function dnref { dotnet restore }
function dnsln { dotnet sln list }
function dnfeat { dotnet new list }
function dnew { dotnet new @args }
function dnb { dotnet build @args }
function dnr { dotnet run @args }
#endregion

#region VS Code Aliases
function vsc { if ($args.Count -eq 0) { code . } else { code @args } }
function vsci { if ($args.Count -eq 0) { code-insiders . } else { code-insiders @args } }
#endregion

#region Quick Navigation (Fixed)
function .. { Set-Location .. }
function ... { Set-Location ../.. }
function .... { Set-Location ../../.. }
#endregion

#region AI TUI Tools
function gcp { copilot @args }
function cc { claude @args }
function gem { gemini @args }
function oc { opencode @args }
function cx { codex @args }

# Quick reference for AI tools
function Show-AiHelp {
    Write-Host "AI Tools:" -ForegroundColor Cyan
    Write-Host "  gcp  - GitHub Copilot CLI"
    Write-Host "  cc   - Claude Code"
    Write-Host "  gem  - Gemini CLI"
    Write-Host "  oc   - OpenCode"
    Write-Host "  cx   - Codex"
}
Set-Alias -Name ai-help -Value Show-AiHelp
#endregion

#region Utilities
function Update-Profile { . $PROFILE }
Set-Alias -Name reload-profile -Value Update-Profile

# Profile load time measurement (useful for optimization)
function measure-profile {
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    . $PROFILE
    $sw.Stop()
    Write-Host "Profile loaded in $($sw.ElapsedMilliseconds)ms" -ForegroundColor Green
}
#endregion
