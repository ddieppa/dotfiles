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

# Import theme management functions
. $PSScriptRoot\aliases\theme.ps1

# Define both profile types we want to link
$ProfilePaths = @(
    @{ Name = "CurrentUserAllHosts"; Path = $PROFILE.CurrentUserAllHosts },
    @{ Name = "CurrentUserCurrentHost"; Path = $PROFILE.CurrentUserCurrentHost }
)

$SourcePath = Join-Path -Path $PSScriptRoot -ChildPath 'Profile.ps1'

# Function to select Oh My Posh theme using the imported functions
function Select-OhMyPoshTheme {
    # Clear screen for better UI experience if not disabled
    if (-not $NoClearScreen) {
        Clear-Host
    }

    # Use the imported theme selection logic
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

    # Get themes based on selection using the imported functions
    $repoRoot = Get-RepoRoot
    if (-not $repoRoot) {
        Write-Error "Could not find dotfiles repository root"
        return $null
    }
    
    $themes = @()
    if ($selectedSource.Value -eq "personal") {
        $promptFolder = Join-Path $repoRoot 'prompt'
        $themes = Get-ThemeList -Folder $promptFolder -Type 'Personal'
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

