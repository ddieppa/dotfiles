<#
  Bootstrap script
  Creates symlinks to live profile for both AllHosts and CurrentHost
  Auto-detects profile path, OneDrive redirection, and repo location.
#>

# Define both profile types we want to link
$ProfilePaths = @(
    @{ Name = "CurrentUserAllHosts"; Path = $PROFILE.CurrentUserAllHosts },
    @{ Name = "CurrentUserCurrentHost"; Path = $PROFILE.CurrentUserCurrentHost }
)

$SourcePath = Join-Path -Path $PSScriptRoot -ChildPath 'Profile.ps1'

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

