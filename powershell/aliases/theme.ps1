# Helper function to get a list of themes from a folder, with caching
function Get-ThemeList {
    param(
        [string]$Folder,
        [string]$Type = "Personal",
        [switch]$ForceRefresh
    )
    if (-not $script:ThemeListCache) {
        $script:ThemeListCache = @{}
    }
    $cacheKey = "$Type|$Folder"
    if (-not $ForceRefresh -and $script:ThemeListCache.ContainsKey($cacheKey)) {
        return $script:ThemeListCache[$cacheKey]
    }
    $themes = @()
    if (Test-Path $Folder) {
        $themes = Get-ChildItem -Path $Folder -Filter '*.omp.json' | ForEach-Object {
            $cleanName = $_.Name -replace '\.omp\.json$', ''
            [PSCustomObject]@{
                Name = $cleanName
                Path = $_.FullName
                Type = $Type
            }
        } | Sort-Object Name
    }
    $script:ThemeListCache[$cacheKey] = $themes
    return $themes
}
# Oh My Posh Theme Management Functions
# =====================================

function Get-RepoRoot {
    <#
    .SYNOPSIS
        Finds the dotfiles repository root for PowerShell scripts
    .DESCRIPTION
        Returns the path to the dotfiles/powershell directory, or $null if not found.
    #>
    if (Get-Variable -Name 'RepoRoot' -ErrorAction SilentlyContinue) {
        return $RepoRoot
    } else {
        $possiblePaths = @(
            "D:\dotfiles\powershell",
            "C:\dotfiles\powershell",
            "$env:USERPROFILE\dotfiles\powershell",
            "$env:USERPROFILE\Documents\dotfiles\powershell"
        )
        return $possiblePaths | Where-Object { Test-Path $_ } | Select-Object -First 1
    }
}

# Helper function for interactive menu with pagination
function Show-InteractiveMenu {
    param(
        [string]$Title,
        [array]$Options,
        [string]$DisplayProperty = "Name",
        [switch]$ShowPagination
    )
    
    if ($Options.Count -eq 0) {
        return $null
    }
    
    $pageSize = 10
    $currentPage = 0
    $currentIndex = 0
    $totalPages = [Math]::Ceiling($Options.Count / [double]$pageSize)
    
    # Only display title if provided
    if ($Title) {
        Write-Host $Title -ForegroundColor White
        Write-Host ("-" * 40) -ForegroundColor DarkGray
        Write-Host ""
    }
    
    function Show-MenuPage {
        param($page, $selectedIndex)
        
        $startIndex = $page * $pageSize
        $endIndex = [Math]::Min($startIndex + $pageSize, $Options.Count) - 1
        
        # Save cursor position
        $cursorTop = [Console]::CursorTop

        # Display options for current page
        for ($i = $startIndex; $i -le $endIndex; $i++) {
            $option = $Options[$i]
            $displayText = if ($DisplayProperty -and $option.$DisplayProperty) { 
                $option.$DisplayProperty 
            } else { 
                $option.ToString() 
            }
            $symbol = if ($option.Symbol -and $option.Symbol.Trim()) { "$($option.Symbol) " } else { "" }
            
            if ($i -eq $selectedIndex) {
                # Clear the line first, then write the highlighted selection
                Write-Host ("  ● $symbol$displayText").PadRight(80) -ForegroundColor Magenta
            }
            else {
                # Clear the line first, then write the normal selection  
                Write-Host ("    $symbol$displayText").PadRight(80) -ForegroundColor White
            }
        }

        # Always output exactly $pageSize lines total to maintain consistent layout
        $displayedItems = $endIndex - $startIndex + 1
        $emptyLinesNeeded = $pageSize - $displayedItems
        for ($i = 0; $i -lt $emptyLinesNeeded; $i++) {
            Write-Host "".PadRight(80) # Clear remaining lines
        }

        # Show pagination info if needed
        if ($ShowPagination -and $totalPages -gt 1) {
            Write-Host ""
            Write-Host "  Page $($page + 1)/$totalPages" -ForegroundColor DarkGray
        }

        # Navigation hints
        Write-Host ""
        Write-Host "  Up/Down Navigate" -NoNewline -ForegroundColor DarkGray
        if ($ShowPagination -and $totalPages -gt 1) {
            Write-Host " | Left/Right Change page" -NoNewline -ForegroundColor DarkGray
        }
        Write-Host " | Enter Select | Esc Cancel" -ForegroundColor DarkGray

        # Store current bottom position for exit calculations
        $script:menuBottomPosition = [Console]::CursorTop

        # Return cursor to saved position for next update
        [Console]::SetCursorPosition(0, $cursorTop)
    }
    
    # Initial display
    Show-MenuPage -page $currentPage -selectedIndex $currentIndex
    
    # Navigation loop
    do {
        $key = [Console]::ReadKey($true)
        
        switch ($key.Key) {
            'UpArrow' {
                if ($currentIndex -gt 0) {
                    $currentIndex--
                    $newPage = [Math]::Floor($currentIndex / $pageSize)
                    if ($newPage -ne $currentPage) {
                        $currentPage = $newPage
                    }
                    Show-MenuPage -page $currentPage -selectedIndex $currentIndex
                }
            }
            'DownArrow' {
                if ($currentIndex -lt ($Options.Count - 1)) {
                    $currentIndex++
                    $newPage = [Math]::Floor($currentIndex / $pageSize)
                    if ($newPage -ne $currentPage) {
                        $currentPage = $newPage
                    }
                    Show-MenuPage -page $currentPage -selectedIndex $currentIndex
                }
            }
            'LeftArrow' {
                if ($ShowPagination -and $currentPage -gt 0) {
                    $currentPage--
                    $currentIndex = $currentPage * $pageSize
                    Show-MenuPage -page $currentPage -selectedIndex $currentIndex
                }
            }
            'RightArrow' {
                if ($ShowPagination -and $currentPage -lt ($totalPages - 1)) {
                    $currentPage++
                    $currentIndex = $currentPage * $pageSize
                    Show-MenuPage -page $currentPage -selectedIndex $currentIndex
                }
            }
            'PageUp' {
                if ($ShowPagination -and $currentPage -gt 0) {
                    $currentPage--
                    $currentIndex = $currentPage * $pageSize
                    Show-MenuPage -page $currentPage -selectedIndex $currentIndex
                }
            }
            'PageDown' {
                if ($ShowPagination -and $currentPage -lt ($totalPages - 1)) {
                    $currentPage++
                    $currentIndex = $currentPage * $pageSize
                    Show-MenuPage -page $currentPage -selectedIndex $currentIndex
                }
            }
            'Enter' {
                # Move cursor below menu before returning
                [Console]::SetCursorPosition(0, $script:menuBottomPosition + 1)
                return $Options[$currentIndex]
            }
            'Escape' {
                # Move cursor below menu before returning
                [Console]::SetCursorPosition(0, $script:menuBottomPosition + 1)
                return $null
            }
            'Q' {
                if ($key.KeyChar -eq 'q' -or $key.KeyChar -eq 'Q') {
                    # Move cursor below menu before returning
                    [Console]::SetCursorPosition(0, $script:menuBottomPosition + 1)
                    return $null
                }
            }
        }
    } while ($true)
}

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
    $repoRoot = Get-RepoRoot
    if (-not $repoRoot) {
        Write-Error "Could not find dotfiles repository root"
        return
    }
    $promptFolder = Join-Path $repoRoot 'prompt'
    $themeConfigFile = Join-Path $repoRoot '.theme-config'
    
    # Get personal themes (with caching)
    $personalThemes = Get-ThemeList -Folder $promptFolder -Type 'Personal'
    # Get built-in themes (with caching)
    $builtInThemes = @()
    if ($env:POSH_THEMES_PATH -and (Test-Path $env:POSH_THEMES_PATH)) {
        $builtInThemes = Get-ThemeList -Folder $env:POSH_THEMES_PATH -Type 'Built-in'
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
        # Interactive theme selection with enhanced UI
        Clear-Host
        
        # If no specific filter is provided, ask the user to choose
        if (-not $Personal -and -not $BuiltIn) {
            # Step 1: Select theme source
            Write-Host ""
            Write-Host " Select Theme Source" -ForegroundColor Black -BackgroundColor Blue
            Write-Host ""
            
            $sourceOptions = @(
                [PSCustomObject]@{ Name = "Personal themes"; Value = "personal"; Symbol = "" }
                [PSCustomObject]@{ Name = "Oh My Posh built-in themes"; Value = "builtin"; Symbol = "" }
                [PSCustomObject]@{ Name = "All themes"; Value = "all"; Symbol = "" }
            )
            
            $selectedSource = Show-InteractiveMenu -Options $sourceOptions -DisplayProperty "Name"
            if (-not $selectedSource) {
                Write-Host "`nTheme selection cancelled." -ForegroundColor Yellow
                return
            }
            
            # Filter themes based on selection
            if ($selectedSource.Value -eq "personal") {
                $availableThemes = $personalThemes
            } elseif ($selectedSource.Value -eq "builtin") {
                $availableThemes = $builtInThemes
            }
            # else use all themes (already set)
            
            # Re-sort after filtering
            $availableThemes = $availableThemes | Sort-Object Type, Name
            
            # Clear screen for theme selection
            Clear-Host
        }
        
        # Show title for theme selection
        Write-Host ""
        Write-Host " Select Theme" -ForegroundColor Black -BackgroundColor Blue
        Write-Host ""
        
        if ($availableThemes.Count -eq 0) {
            Write-Warning "No themes found in the selected source."
            return
        }
        
        # Convert themes to format expected by Show-InteractiveMenu
        $menuThemes = $availableThemes | ForEach-Object {
            # Clean up theme name by removing .omp extension if present
            $cleanName = $_.Name -replace '\.omp$', ''
            
            [PSCustomObject]@{
                Name = $cleanName
                Path = $_.Path
                Type = $_.Type
                Symbol = ""  # No symbol prefix
                DisplayName = $cleanName
            }
        }
        
        $selectedTheme = Show-InteractiveMenu -Options $menuThemes -DisplayProperty "Name" -ShowPagination
        
        if (-not $selectedTheme) {
            Write-Host "`nTheme selection cancelled." -ForegroundColor Yellow
            return
        }
        
        Write-Host "`n[OK] Selected: $($selectedTheme.Name)" -ForegroundColor Green
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
    $repoRoot = Get-RepoRoot
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
