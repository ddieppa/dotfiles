<#
  Bootstrap script
  Creates symlinks to live profile for both AllHosts and CurrentHost
  Auto-detects profile path, OneDrive redirection, and repo location.
  
  .PARAMETER ThemeOnly
  Only configure the Oh My Posh theme, skip profile linking
#>

param(
    [switch]$ThemeOnly,
    [switch]$NoClearScreen = $false
)

# Define both profile types we want to link
$ProfilePaths = @(
    @{ Name = "CurrentUserAllHosts"; Path = $PROFILE.CurrentUserAllHosts },
    @{ Name = "CurrentUserCurrentHost"; Path = $PROFILE.CurrentUserCurrentHost }
)

$SourcePath = Join-Path -Path $PSScriptRoot -ChildPath 'Profile.ps1'


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
            $cleanName = $_.BaseName -replace '\.omp$', ''
            [PSCustomObject]@{
                Name = $cleanName
                Path = $_.FullName
                Symbol = ""
                Type = $Type
            }
        } | Sort-Object Name
    }
    $script:ThemeListCache[$cacheKey] = $themes
    return $themes
}

# Function to select Oh My Posh theme
function Select-OhMyPoshTheme {
    # Clear screen for better UI experience if not disabled
    if (-not $NoClearScreen) {
        Clear-Host
    }

    # Title
    Write-Host ""
    Write-Host " Select Theme" -ForegroundColor Black -BackgroundColor Blue
    Write-Host ""

    # Step 1: Select theme source
    $sourceOptions = @(
        [PSCustomObject]@{ Name = "Personal themes"; Value = "personal"; Symbol = "" }
        [PSCustomObject]@{ Name = "Oh My Posh built-in themes"; Value = "builtin"; Symbol = "" }
    )

    $selectedSource = Show-InteractiveMenu -Options $sourceOptions -DisplayProperty "Name"
    if (-not $selectedSource) {
        Write-Host "`nTheme selection cancelled." -ForegroundColor Yellow
        return $null
    }

    # Get themes based on selection
    $themes = @()
    if ($selectedSource.Value -eq "personal") {
        $ThemeFolder = Join-Path -Path $PSScriptRoot -ChildPath 'prompt'
        $themes = Get-ThemeList -Folder $ThemeFolder -Type 'Personal'
    } else {
        if ($env:POSH_THEMES_PATH -and (Test-Path $env:POSH_THEMES_PATH)) {
            $themes = Get-ThemeList -Folder $env:POSH_THEMES_PATH -Type 'Built-in'
        }
    }

    if ($themes.Count -eq 0) {
        Write-Host "`nNo themes found in the selected source." -ForegroundColor Yellow
        return $null
    }

    # Step 2: Select specific theme
    Clear-Host
    Write-Host ""
    Write-Host " Select Theme" -ForegroundColor Black -BackgroundColor Blue
    Write-Host ""

    $selectedTheme = Show-InteractiveMenu -Options $themes -DisplayProperty "Name" -ShowPagination
    if (-not $selectedTheme) {
        Write-Host "`nTheme selection cancelled." -ForegroundColor Yellow
        return $null
    }

    Write-Host "`n[OK] Selected theme: $($selectedTheme.Name)" -ForegroundColor Green
    return $selectedTheme.Path
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
    $totalPages = [Math]::Ceiling($Options.Count / $pageSize)
    
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
            $relativeIndex = $i - $startIndex
            
            if ($i -eq $selectedIndex) {
                # Highlighted selection
                Write-Host "  " -NoNewline
                Write-Host "  ● $symbol$displayText" -ForegroundColor Magenta
            }
            else {
                Write-Host "     $symbol$displayText" -ForegroundColor White
            }
        }
        
        # Add empty lines to maintain consistent height
        $displayedItems = $endIndex - $startIndex + 1
        for ($i = $displayedItems; $i -lt $pageSize; $i++) {
            Write-Host ""
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
                [Console]::SetCursorPosition(0, [Console]::CursorTop + $pageSize + 5)
                return $Options[$currentIndex]
            }
            'Escape' {
                # Move cursor below menu before returning
                [Console]::SetCursorPosition(0, [Console]::CursorTop + $pageSize + 5)
                return $null
            }
            'Q' {
                if ($key.KeyChar -eq 'q' -or $key.KeyChar -eq 'Q') {
                    # Move cursor below menu before returning
                    [Console]::SetCursorPosition(0, [Console]::CursorTop + $pageSize + 5)
                    return $null
                }
            }
        }
    } while ($true)
}

# Handle theme-only mode
if ($ThemeOnly) {
    Write-Host "Theme Configuration" -ForegroundColor Cyan
    Write-Host "==================" -ForegroundColor Cyan
    
    $SelectedTheme = Select-OhMyPoshTheme
    
    if ($SelectedTheme) {
        $ThemeConfigFile = Join-Path -Path $PSScriptRoot -ChildPath '.theme-config'
        try {
            $SelectedTheme | Out-File -FilePath $ThemeConfigFile -Encoding UTF8 -Force
            Write-Host "`n[OK] Theme configuration updated: $(Split-Path $SelectedTheme -Leaf)" -ForegroundColor Green
            Write-Host "Restart your PowerShell session to apply the new theme." -ForegroundColor Cyan
        } catch {
            Write-Host "`n[!] Failed to save theme configuration: $($_.Exception.Message)" -ForegroundColor Yellow
        }
    } else {
        Write-Host "`nNo changes made to theme configuration." -ForegroundColor Gray
    }
    
    return
}

# Full installation mode
Write-Host "`n🚀 PowerShell Profile Setup" -ForegroundColor Cyan
Write-Host "============================" -ForegroundColor Cyan

foreach ($ProfileInfo in $ProfilePaths) {
    $DestPath = $ProfileInfo.Path
    $ProfileName = $ProfileInfo.Name
    
    Write-Host "Setting up $ProfileName profile..." -ForegroundColor Cyan
    
    # 1. Ensure parent folder exists
    $DestDir = Split-Path $DestPath -Parent
    New-Item -ItemType Directory -Path $DestDir -Force | Out-Null
    
    # 2. Backup any existing profile
    if (Test-Path $DestPath -PathType Leaf) {
        $BackupPath = "$DestPath.bak"
        Write-Host "  Backing up existing profile to $BackupPath" -ForegroundColor Yellow
        Copy-Item $DestPath $BackupPath -Force
        Remove-Item $DestPath -Force
    }
    
    # 3. Create symlink
    try {
        New-Item -ItemType SymbolicLink -Path $DestPath -Target $SourcePath -Force | Out-Null
        Write-Host "  ✓ Profile linked → $DestPath" -ForegroundColor Green
    } catch {
        Write-Host "  ✗ Failed to create symlink: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "    You may need to run as Administrator or enable Developer Mode" -ForegroundColor Yellow
    }
}

Write-Host "`nProfile setup complete!" -ForegroundColor Green
Write-Host "Both AllHosts and CurrentHost profiles now point to your dotfiles." -ForegroundColor Cyan

# Select Oh My Posh theme for full installation
$SelectedTheme = Select-OhMyPoshTheme

# Save selected theme configuration
if ($SelectedTheme) {
    $ThemeConfigFile = Join-Path -Path $PSScriptRoot -ChildPath '.theme-config'
    try {
        $SelectedTheme | Out-File -FilePath $ThemeConfigFile -Encoding UTF8 -Force
        Write-Host "[OK] Theme configuration saved: $(Split-Path $SelectedTheme -Leaf)" -ForegroundColor Green
    } catch {
        Write-Host "[!] Failed to save theme configuration: $($_.Exception.Message)" -ForegroundColor Yellow
    }
} else {
    Write-Host "[i] No theme selected - profile will use default theme detection" -ForegroundColor Cyan
}

Write-Host "`n" -NoNewline
Write-Host "Tip: " -ForegroundColor Yellow -NoNewline
Write-Host "You can change your theme later by running: " -NoNewline
Write-Host ".\install.ps1 -ThemeOnly" -ForegroundColor White

