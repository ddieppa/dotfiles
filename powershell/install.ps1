<#
  Bootstrap script
  Creates symlinks to live profile for both AllHosts and CurrentHost
  Auto-detects profile path, OneDrive redirection, and repo location.
  
  .PARAMETER ThemeOnly
  Only configure the Oh My Posh theme, skip profile linking
#>

param(
    [switch]$ThemeOnly
)

# Define both profile types we want to link
$ProfilePaths = @(
    @{ Name = "CurrentUserAllHosts"; Path = $PROFILE.CurrentUserAllHosts },
    @{ Name = "CurrentUserCurrentHost"; Path = $PROFILE.CurrentUserCurrentHost }
)

$SourcePath = Join-Path -Path $PSScriptRoot -ChildPath 'Profile.ps1'

# Function to select Oh My Posh theme
function Select-OhMyPoshTheme {
    # Try propmt folder first, then prompt folder for backward compatibility
    $ThemeFolders = @(
        (Join-Path -Path $PSScriptRoot -ChildPath 'propmt'),
        (Join-Path -Path $PSScriptRoot -ChildPath 'prompt')
    )
    
    $ThemeFolder = $ThemeFolders | Where-Object { Test-Path $_ } | Select-Object -First 1
    
    if (-not $ThemeFolder) {
        Write-Host "Theme folder not found. Looked in:" -ForegroundColor Red
        $ThemeFolders | ForEach-Object { Write-Host "  - $_" -ForegroundColor Gray }
        return $null
    }
    
    # Get all available themes
    $ThemeFiles = Get-ChildItem -Path $ThemeFolder -Filter '*.omp.json' | Sort-Object Name
    
    if ($ThemeFiles.Count -eq 0) {
        Write-Host "No Oh My Posh themes found in $ThemeFolder" -ForegroundColor Yellow
        return $null
    }
    
    Write-Host "`nAvailable Oh My Posh themes:" -ForegroundColor Cyan
    Write-Host "=============================" -ForegroundColor Cyan
    
    for ($i = 0; $i -lt $ThemeFiles.Count; $i++) {
        $themeName = [System.IO.Path]::GetFileNameWithoutExtension($ThemeFiles[$i].Name)
        Write-Host "  [$($i + 1)] $themeName" -ForegroundColor White
    }
    
    Write-Host "  [0] Skip theme selection (keep current)" -ForegroundColor Gray
    Write-Host ""
    
    do {
        $selection = Read-Host "Select a theme (1-$($ThemeFiles.Count) or 0 to skip)"
        
        if ($selection -eq '0') {
            Write-Host "Skipping theme selection." -ForegroundColor Yellow
            return $null
        }
        
        $selectionInt = 0
        if ([int]::TryParse($selection, [ref]$selectionInt) -and 
            $selectionInt -ge 1 -and $selectionInt -le $ThemeFiles.Count) {
            
            $selectedTheme = $ThemeFiles[$selectionInt - 1]
            Write-Host "Selected theme: $($selectedTheme.BaseName)" -ForegroundColor Green
            return $selectedTheme.FullName
        }
        
        Write-Host "Invalid selection. Please enter a number between 0 and $($ThemeFiles.Count)." -ForegroundColor Red
    } while ($true)
}

# Select Oh My Posh theme
$SelectedTheme = Select-OhMyPoshTheme

# Handle theme-only mode
if ($ThemeOnly) {
    Write-Host "🎨 Oh My Posh Theme Configuration" -ForegroundColor Cyan
    Write-Host "=================================" -ForegroundColor Cyan
    
    if ($SelectedTheme) {
        $ThemeConfigFile = Join-Path -Path $PSScriptRoot -ChildPath '.theme-config'
        try {
            $SelectedTheme | Out-File -FilePath $ThemeConfigFile -Encoding UTF8 -Force
            Write-Host "`n✓ Theme configuration updated: $(Split-Path $SelectedTheme -Leaf)" -ForegroundColor Green
            Write-Host "Restart your PowerShell session to apply the new theme." -ForegroundColor Cyan
        } catch {
            Write-Host "`n⚠️  Failed to save theme configuration: $($_.Exception.Message)" -ForegroundColor Yellow
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

# Save selected theme configuration
if ($SelectedTheme) {
    $ThemeConfigFile = Join-Path -Path $PSScriptRoot -ChildPath '.theme-config'
    try {
        $SelectedTheme | Out-File -FilePath $ThemeConfigFile -Encoding UTF8 -Force
        Write-Host "✓ Theme configuration saved: $(Split-Path $SelectedTheme -Leaf)" -ForegroundColor Green
    } catch {
        Write-Host "⚠️  Failed to save theme configuration: $($_.Exception.Message)" -ForegroundColor Yellow
    }
} else {
    Write-Host "ℹ️  No theme selected - profile will use default theme detection" -ForegroundColor Cyan
}

Write-Host "`n" -NoNewline
Write-Host "💡 Tip: " -ForegroundColor Yellow -NoNewline
Write-Host "You can change your theme later by running: " -NoNewline
Write-Host ".\install.ps1 -ThemeOnly" -ForegroundColor White

