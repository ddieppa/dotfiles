# Oh My Posh Theme Management Functions
# =====================================

# Oh My Posh Theme Management
function Set-OhMyPoshTheme {
    <#
    .SYNOPSIS
        Interactive theme selector for Oh My Posh themes
    
    .DESCRIPTION
        This function allows you to interactively select and apply Oh My Posh themes.
        It shows both personal themes (from your dotfiles prompt folder) and built-in themes.
        The selection is saved to a .theme-config file for persistence across sessions.
    
    .PARAMETER Name
        Optional. Directly specify a theme name to apply without interactive selection.
    
    .PARAMETER List
        Optional. List all available themes without applying any.
    
    .PARAMETER Personal
        Optional. Show only personal themes from the prompt folder.
    
    .PARAMETER BuiltIn
        Optional. Show only built-in Oh My Posh themes.
    
    .EXAMPLE
        Set-OhMyPoshTheme
        # Interactive theme selection
    
    .EXAMPLE
        Set-OhMyPoshTheme -Name "paradox"
        # Directly apply the paradox theme
    
    .EXAMPLE
        Set-OhMyPoshTheme -List
        # List all available themes
    
    .EXAMPLE
        Set-OhMyPoshTheme -Personal
        # Show only personal themes
    #>
    [CmdletBinding()]
    param(
        [string]$Name,
        [switch]$List,
        [switch]$Personal,
        [switch]$BuiltIn
    )
    
    # Get repository root
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
        Write-Error "Could not find dotfiles repository root"
        return
    }
    
    $promptFolder = Join-Path $repoRoot 'prompt'
    $themeConfigFile = Join-Path $repoRoot '.theme-config'
    
    # Get personal themes
    $personalThemes = @()
    if (Test-Path $promptFolder) {
        $personalThemes = Get-ChildItem -Path $promptFolder -Filter '*.omp.json' | 
            ForEach-Object { 
                [PSCustomObject]@{
                    Name = $_.BaseName
                    Path = $_.FullName
                    Type = 'Personal'
                }
            }
    }
    
    # Get built-in themes
    $builtInThemes = @()
    if ($env:POSH_THEMES_PATH -and (Test-Path $env:POSH_THEMES_PATH)) {
        $builtInThemes = Get-ChildItem -Path $env:POSH_THEMES_PATH -Filter '*.omp.json' | 
            ForEach-Object { 
                [PSCustomObject]@{
                    Name = $_.BaseName
                    Path = $_.FullName
                    Type = 'Built-in'
                }
            }
    }
    
    # Filter based on parameters
    $availableThemes = @()
    if ($Personal -and -not $BuiltIn) {
        $availableThemes = $personalThemes
    } elseif ($BuiltIn -and -not $Personal) {
        $availableThemes = $builtInThemes
    } else {
        $availableThemes = $personalThemes + $builtInThemes
    }
    
    # Sort themes
    $availableThemes = $availableThemes | Sort-Object Type, Name
    
    # Handle list parameter
    if ($List) {
        Write-Host "`n=== Available Oh My Posh Themes ===" -ForegroundColor Cyan
        
        if ($personalThemes.Count -gt 0) {
            Write-Host "`n📁 Personal Themes ($($personalThemes.Count)):" -ForegroundColor Yellow
            $personalThemes | ForEach-Object { Write-Host "  • $($_.Name)" -ForegroundColor Green }
        }
        
        if ($builtInThemes.Count -gt 0) {
            Write-Host "`n🎨 Built-in Themes ($($builtInThemes.Count)):" -ForegroundColor Yellow
            $builtInThemes | ForEach-Object { Write-Host "  • $($_.Name)" -ForegroundColor Cyan }
        }
        
        return
    }
    
    # Handle direct theme name
    if ($Name) {
        $selectedTheme = $availableThemes | Where-Object { $_.Name -eq $Name }
        if (-not $selectedTheme) {
            Write-Error "Theme '$Name' not found. Use -List to see available themes."
            return
        }
        
        # If multiple themes with same name exist, prefer personal theme
        if ($selectedTheme.Count -gt 1) {
            $personalMatch = $selectedTheme | Where-Object { $_.Type -eq 'Personal' }
            if ($personalMatch) {
                $selectedTheme = $personalMatch
                Write-Host "Multiple themes found with name '$Name'. Using personal theme." -ForegroundColor Yellow
            } else {
                $selectedTheme = $selectedTheme[0]
            }
        }
    } else {
        # Interactive selection
        Write-Host "`n🎨 Oh My Posh Theme Selector" -ForegroundColor Cyan
        Write-Host "=====================================`n" -ForegroundColor Cyan
        
        if ($availableThemes.Count -eq 0) {
            Write-Warning "No themes found."
            return
        }
        
        # Display themes with numbers
        for ($i = 0; $i -lt $availableThemes.Count; $i++) {
            $theme = $availableThemes[$i]
            $color = if ($theme.Type -eq 'Personal') { 'Green' } else { 'Cyan' }
            $symbol = if ($theme.Type -eq 'Personal') { '📁' } else { '🎨' }
            Write-Host ("{0,3}: {1} {2}" -f ($i + 1), $symbol, $theme.Name) -ForegroundColor $color
        }
        
        Write-Host "`n  0: Cancel" -ForegroundColor Red
        Write-Host "`nLegend: 📁 Personal themes | 🎨 Built-in themes" -ForegroundColor Gray
        
        # Get user selection
        do {
            $selection = Read-Host "`nSelect theme number (1-$($availableThemes.Count)) or 0 to cancel"
            $selectionNum = $null
            $validSelection = [int]::TryParse($selection, [ref]$selectionNum) -and 
                              $selectionNum -ge 0 -and $selectionNum -le $availableThemes.Count
            
            if (-not $validSelection) {
                Write-Warning "Please enter a valid number between 0 and $($availableThemes.Count)"
            }
        } while (-not $validSelection)
        
        if ($selectionNum -eq 0) {
            Write-Host "Theme selection cancelled." -ForegroundColor Yellow
            return
        }
        
        $selectedTheme = $availableThemes[$selectionNum - 1]
    }
    
    # Apply the theme
    try {
        Write-Host "`n🔄 Applying theme: $($selectedTheme.Name) ($($selectedTheme.Type))" -ForegroundColor Yellow
        
        # Save theme configuration
        Set-Content -Path $themeConfigFile -Value $selectedTheme.Path -Force
        Write-Host "✓ Theme configuration saved to: $themeConfigFile" -ForegroundColor Green
        
        # Apply theme immediately
        oh-my-posh init pwsh --config $selectedTheme.Path | Invoke-Expression
        Write-Host "✓ Theme applied successfully!" -ForegroundColor Green
        
        Write-Host "`n💡 Theme will be automatically loaded in new PowerShell sessions." -ForegroundColor Cyan
        Write-Host "💡 To see the full effect, consider starting a new PowerShell session." -ForegroundColor Cyan
        
    } catch {
        Write-Error "Failed to apply theme: $($_.Exception.Message)"
    }
}

# Function to show current theme
function Get-OhMyPoshTheme {
    <#
    .SYNOPSIS
        Shows the currently active Oh My Posh theme
    
    .DESCRIPTION
        Displays information about the currently active Oh My Posh theme,
        including its name, path, and type (Personal or Built-in).
    #>
    
    # Get repository root
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
        Write-Error "Could not find dotfiles repository root"
        return
    }
    
    $themeConfigFile = Join-Path $repoRoot '.theme-config'
    $promptFolder = Join-Path $repoRoot 'prompt'
    
    Write-Host "`n🎨 Current Oh My Posh Theme" -ForegroundColor Cyan
    Write-Host "==========================`n" -ForegroundColor Cyan
    
    $currentThemePath = $null
    $configSource = "Unknown"
    
    # Check our theme config file first
    if (Test-Path $themeConfigFile) {
        $currentThemePath = Get-Content $themeConfigFile -Raw | ForEach-Object { $_.Trim() }
        $configSource = "Config file (.theme-config)"
        
        if (-not (Test-Path $currentThemePath)) {
            $currentThemePath = $null
        }
    }
    
    # If no config file or path invalid, check POSH_THEME environment variable
    if (-not $currentThemePath -and $env:POSH_THEME) {
        $currentThemePath = $env:POSH_THEME
        $configSource = "Environment variable (POSH_THEME)"
        
        if (-not (Test-Path $currentThemePath)) {
            $currentThemePath = $null
        }
    }
    
    # If still no theme found, try to extract from oh-my-posh debug output
    if (-not $currentThemePath) {
        try {
            $debugOutput = oh-my-posh debug --plain 2>$null | Out-String
            if ($debugOutput -match "Config path:\s*(.+\.omp\.json)") {
                $currentThemePath = $matches[1].Trim()
                $configSource = "Detected from Oh My Posh debug"
                
                if (-not (Test-Path $currentThemePath)) {
                    $currentThemePath = $null
                }
            }
        } catch {
            # Debug command failed, continue without it
        }
    }
    
    if ($currentThemePath) {
        $themeName = [System.IO.Path]::GetFileNameWithoutExtension($currentThemePath)
        $themeType = if ($currentThemePath.StartsWith($promptFolder)) { 'Personal' } elseif ($env:POSH_THEMES_PATH -and $currentThemePath.StartsWith($env:POSH_THEMES_PATH)) { 'Built-in' } else { 'Custom' }
        $themeSymbol = switch ($themeType) {
            'Personal' { '📁' }
            'Built-in' { '🎨' }
            'Custom' { '⚙️' }
        }
        
        Write-Host "Theme:  $themeSymbol $themeName" -ForegroundColor Green
        Write-Host "Type:   $themeType" -ForegroundColor Gray
        Write-Host "Source: $configSource" -ForegroundColor Gray
        Write-Host "Path:   $currentThemePath" -ForegroundColor Gray
    } else {
        Write-Host "⚠️  No Oh My Posh theme configuration detected." -ForegroundColor Yellow
        Write-Host "This could mean:" -ForegroundColor Yellow
        Write-Host "  • Oh My Posh is using a built-in default theme" -ForegroundColor Gray
        Write-Host "  • Theme is configured directly in your PowerShell profile" -ForegroundColor Gray
        Write-Host "  • Oh My Posh is not properly initialized" -ForegroundColor Gray
        Write-Host "`nTry running 'oh-my-posh debug --plain' for more information." -ForegroundColor Cyan
    }
    
    Write-Host ""
}

# Function to show theme help
function Get-ThemeHelp {
    <#
    .SYNOPSIS
        Shows help for Oh My Posh theme management functions
    
    .DESCRIPTION
        Displays information about available theme management commands and their usage.
    #>
    
    Write-Host "`n🎨 Oh My Posh Theme Management" -ForegroundColor Cyan
    Write-Host "==============================`n" -ForegroundColor Cyan
    
    Write-Host "Available Commands:" -ForegroundColor Yellow
    Write-Host "  theme                    - Interactive theme selector" -ForegroundColor Green
    Write-Host "  theme -List              - List all available themes" -ForegroundColor Green
    Write-Host "  theme -Personal          - Show only personal themes" -ForegroundColor Green
    Write-Host "  theme -BuiltIn           - Show only built-in themes" -ForegroundColor Green
    Write-Host "  theme -Name <name>       - Apply specific theme by name" -ForegroundColor Green
    Write-Host "  theme-current            - Show currently active theme" -ForegroundColor Green
    Write-Host "  theme-help               - Show this help" -ForegroundColor Green
    
    Write-Host "`nExamples:" -ForegroundColor Yellow
    Write-Host "  theme                    # Interactive selection" -ForegroundColor Gray
    Write-Host "  theme -List              # List all themes" -ForegroundColor Gray
    Write-Host "  theme -Personal          # Show only personal themes" -ForegroundColor Gray
    Write-Host "  theme -Name paradox      # Apply paradox theme" -ForegroundColor Gray
    Write-Host "  theme-current            # Show current theme" -ForegroundColor Gray
    
    Write-Host "`nTheme Types:" -ForegroundColor Yellow
    Write-Host "  📁 Personal  - Custom themes in your dotfiles/powershell/prompt folder" -ForegroundColor Green
    Write-Host "  🎨 Built-in  - Oh My Posh included themes" -ForegroundColor Cyan
    Write-Host "  ⚙️  Custom    - Themes from other locations" -ForegroundColor Magenta
    
    Write-Host "`nDetection Sources:" -ForegroundColor Yellow
    Write-Host "  • Config file (.theme-config) - Themes set via this function" -ForegroundColor Gray
    Write-Host "  • Environment variable (POSH_THEME) - Set by Oh My Posh" -ForegroundColor Gray
    Write-Host "  • Debug output detection - Fallback method" -ForegroundColor Gray
    
    Write-Host "`nNotes:" -ForegroundColor Yellow
    Write-Host "  • Theme settings are saved to .theme-config file" -ForegroundColor Gray
    Write-Host "  • Personal themes take priority when names conflict" -ForegroundColor Gray
    Write-Host "  • Use 'reload' or start a new session to see full effect" -ForegroundColor Gray
    Write-Host "  • Run 'oh-my-posh debug --plain' for detailed theme info" -ForegroundColor Gray
    Write-Host ""
}

# Set up aliases for theme functions
if (Get-Command Set-SafeAlias -ErrorAction SilentlyContinue) {
    Set-SafeAlias theme Set-OhMyPoshTheme
    Set-SafeAlias theme-current Get-OhMyPoshTheme
    Set-SafeAlias theme-help Get-ThemeHelp
} else {
    # Fallback if Set-SafeAlias is not available
    Set-Alias theme Set-OhMyPoshTheme -Scope Global -Force
    Set-Alias theme-current Get-OhMyPoshTheme -Scope Global -Force
    Set-Alias theme-help Get-ThemeHelp -Scope Global -Force
}
