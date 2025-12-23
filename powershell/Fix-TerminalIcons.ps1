<#
.SYNOPSIS
    Fixes Terminal-Icons module by reinstalling it

.DESCRIPTION
    This script fixes the Terminal-Icons XML corruption error by:
    1. Checking if the Terminal-Icons module is loaded and unloading it
    2. Uninstalling all versions of Terminal-Icons
    3. Clearing the PowerShell module cache
    4. Reinstalling Terminal-Icons from PSGallery
    5. Verifying the installation

.EXAMPLE
    .\Fix-TerminalIcons.ps1
#>

[CmdletBinding()]
param()

Write-Host "`n=== Terminal-Icons Fix Utility ===" -ForegroundColor Cyan
Write-Host "This will reinstall the Terminal-Icons module to fix XML errors.`n" -ForegroundColor Gray

# Step 1: Check if module is currently loaded
Write-Host "[1/5] Checking if Terminal-Icons is currently loaded..." -ForegroundColor Yellow
$loadedModule = Get-Module -Name Terminal-Icons
if ($loadedModule) {
    Write-Host "    Removing loaded module..." -ForegroundColor Gray
    Remove-Module -Name Terminal-Icons -Force -ErrorAction SilentlyContinue
    Write-Host "    ✓ Module unloaded" -ForegroundColor Green
} else {
    Write-Host "    ✓ Module not currently loaded" -ForegroundColor Green
}

# Step 2: Uninstall all versions
Write-Host "`n[2/5] Uninstalling all versions of Terminal-Icons..." -ForegroundColor Yellow
$installedVersions = Get-InstalledModule -Name Terminal-Icons -AllVersions -ErrorAction SilentlyContinue
if ($installedVersions) {
    Write-Host "    Found $($installedVersions.Count) version(s) installed" -ForegroundColor Gray
    foreach ($version in $installedVersions) {
        Write-Host "    Uninstalling version $($version.Version)..." -ForegroundColor Gray
        Uninstall-Module -Name Terminal-Icons -RequiredVersion $version.Version -Force -ErrorAction SilentlyContinue
    }
    Write-Host "    ✓ All versions uninstalled" -ForegroundColor Green
} else {
    Write-Host "    ℹ No installed versions found" -ForegroundColor Gray
}

# Step 3: Clear PowerShell module cache
Write-Host "`n[3/5] Clearing PowerShell module cache..." -ForegroundColor Yellow
$modulePaths = @(
    "$env:USERPROFILE\Documents\PowerShell\Modules\Terminal-Icons",
    "$env:USERPROFILE\Documents\WindowsPowerShell\Modules\Terminal-Icons"
)

if ($env:OneDrive) {
    $modulePaths += @(
        "$env:OneDrive\Documents\PowerShell\Modules\Terminal-Icons",
        "$env:OneDrive\Documents\WindowsPowerShell\Modules\Terminal-Icons"
    )
}
foreach ($path in $modulePaths) {
    if (Test-Path $path) {
        Write-Host "    Removing $path..." -ForegroundColor Gray
        Remove-Item -Path $path -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "    ✓ Removed" -ForegroundColor Green
    }
}

Write-Host "    ✓ Cache cleared" -ForegroundColor Green

# Step 4: Reinstall Terminal-Icons
Write-Host "`n[4/5] Reinstalling Terminal-Icons from PSGallery..." -ForegroundColor Yellow
try {
    Install-Module -Name Terminal-Icons -Scope CurrentUser -Force -AllowClobber -ErrorAction Stop
    Write-Host "    ✓ Terminal-Icons reinstalled successfully" -ForegroundColor Green
} catch {
    Write-Host "    ✗ Installation failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "`nPlease try manually:" -ForegroundColor Yellow
    Write-Host "    Install-Module -Name Terminal-Icons -Scope CurrentUser -Force" -ForegroundColor Gray
    exit 1
}

# Step 5: Verify installation
Write-Host "`n[5/5] Verifying installation..." -ForegroundColor Yellow
try {
    Import-Module Terminal-Icons -DisableNameChecking -ErrorAction Stop
    if (Get-Module -Name Terminal-Icons) {
        Write-Host "    ✓ Terminal-Icons loaded successfully" -ForegroundColor Green

        # Show module info
        $module = Get-Module -Name Terminal-Icons
        Write-Host "`n    Module Information:" -ForegroundColor Cyan
        Write-Host "    Version: $($module.Version)" -ForegroundColor Gray
        Write-Host "    Path: $($module.ModuleBase)" -ForegroundColor Gray

        Write-Host "`n✓ Fix completed successfully!" -ForegroundColor Green
        Write-Host "Please restart your PowerShell session to apply changes.`n" -ForegroundColor Cyan
    } else {
        throw "Module did not load properly"
    }
} catch {
    Write-Host "    ✗ Verification failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "`nThe module was installed but failed to load." -ForegroundColor Yellow
    Write-Host "You may need to restart PowerShell and try again.`n" -ForegroundColor Yellow
    exit 1
}
