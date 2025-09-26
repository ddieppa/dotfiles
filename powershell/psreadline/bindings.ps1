# $RepoRoot\psreadline\bindings.ps1
# Import PSReadLine only if not already loaded
if (-not (Get-Module PSReadLine)) {
    Import-Module PSReadLine
}

# Configure PSReadLine with fallback for environments without virtual terminal support
try {
    # Try to enable prediction features if virtual terminal is supported
    Set-PSReadLineOption -PredictionSource History -ErrorAction Stop
    Set-PSReadLineOption -HistorySaveStyle SaveIncrementally
} catch {
    # Fallback for environments without virtual terminal support (like VS Code PowerShell extension)
    Write-Verbose "Virtual terminal processing not available, using basic PSReadLine configuration"
    Set-PSReadLineOption -PredictionSource None
    Set-PSReadLineOption -HistorySaveStyle SaveIncrementally
}

# Key bindings
Set-PSReadLineKeyHandler -Key Ctrl+r -Function ReverseSearchHistory
Set-PSReadLineKeyHandler -Key Ctrl+l -Function ClearScreen
Set-PSReadLineKeyHandler -Key UpArrow   -Function HistorySearchBackward
Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward

# Word movement
Set-PSReadLineKeyHandler -Key Alt+b -Function BackwardWord
Set-PSReadLineKeyHandler -Key Alt+f -Function ForwardWord

