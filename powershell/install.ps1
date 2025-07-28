<#
  Bootstrap script
  Creates symlink to live profile
  Auto-detects profile path, OneDrive redirection, and repo location.
#>

# 1. Identify where PowerShell wants the profile
$DestPath = $PROFILE.CurrentUserAllHosts           # respects OneDrive

# 2. Ensure parent folder exists
$DestDir = Split-Path $DestPath -Parent
New-Item -ItemType Directory -Path $DestDir -Force | Out-Null

# 3. Backup any old profile
if (Test-Path $DestPath -PathType Leaf) {
    Copy-Item $DestPath "$DestPath.bak" -Force
    Remove-Item $DestPath -Force
}

# 4. Link to the real profile using dynamic source
$SourcePath = Join-Path -Path $PSScriptRoot -ChildPath 'Profile.ps1'
New-Item -ItemType SymbolicLink -Path $DestPath -Target $SourcePath -Force   # admin not needed if Developer Mode on[8]

Write-Host "Profile linked → $DestPath" -ForegroundColor Green

