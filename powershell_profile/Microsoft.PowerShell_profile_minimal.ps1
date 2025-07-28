# Minimal PowerShell Profile - Fixed encoding issues
# This version avoids Terminal-Icons on PowerShell 5.x and fixes encoding issues

# PowerShell Version Check
if ($PSVersionTable.PSVersion.Major -lt 7) {
    Write-Warning "PowerShell version is below 7. Some features may not work optimally."
}

# Oh My Posh
$env:POSH_THEMES_PATH = "$env:LOCALAPPDATA\Programs\oh-my-posh\themes"
if (Test-Path $env:POSH_THEMES_PATH) {
    $themeFile = Join-Path $env:POSH_THEMES_PATH "star.omp.json"
    if (Test-Path $themeFile) {
        oh-my-posh init pwsh --config $themeFile | Invoke-Expression
        Write-Host "[OK] Oh My Posh initialized" -ForegroundColor Green
    }
}

# PSReadLine
try {
    Set-PSReadLineOption -EditMode Windows
    Set-PSReadLineKeyHandler -Key Tab -Function Complete
    Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
    Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
    Write-Host "[OK] PSReadLine configured" -ForegroundColor Green
} catch {
    Write-Warning "PSReadLine configuration failed: $_"
}

# Terminal-Icons (only on PowerShell 7+)
if ($PSVersionTable.PSVersion.Major -ge 7) {
    if (Get-Module -ListAvailable -Name Terminal-Icons) {
        try {
            Import-Module Terminal-Icons -ErrorAction Stop
            Write-Host "[OK] Terminal Icons loaded" -ForegroundColor Green
        } catch {
            Write-Warning "Terminal-Icons failed to load: $_"
        }
    }
} else {
    Write-Host "[INFO] Terminal-Icons requires PowerShell 7+" -ForegroundColor Yellow
}

# Basic aliases
Set-Alias -Name g -Value git
Set-Alias -Name c -Value Clear-Host
Set-Alias -Name ll -Value Get-ChildItem

# Display welcome message
Write-Host ""
Write-Host "PowerShell Profile Loaded Successfully!" -ForegroundColor Cyan
Write-Host ""