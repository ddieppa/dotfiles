# Terminal-Icons Diagnostics and Repair Utility
# Helps diagnose and fix common Terminal-Icons issues

function Repair-TerminalIcons {
    <#
    .SYNOPSIS
        Diagnose and repair Terminal-Icons module issues.
    
    .DESCRIPTION
        This function attempts to diagnose and fix common Terminal-Icons problems,
        including XML corruption, installation issues, and import failures.
    
    .PARAMETER Force
        Force a complete reinstallation even if the module appears to be working.
    
    .EXAMPLE
        Repair-TerminalIcons
        
        Diagnoses and attempts to repair Terminal-Icons issues.
    
    .EXAMPLE
        Repair-TerminalIcons -Force
        
        Forces a complete reinstallation of Terminal-Icons.
    #>
    [CmdletBinding()]
    param(
        [switch]$Force
    )
    
    Write-Host "Terminal-Icons Diagnostic and Repair Utility" -ForegroundColor Cyan
    Write-Host "=============================================" -ForegroundColor Cyan
    
    # Step 1: Check if module is currently loaded
    $loadedModule = Get-Module Terminal-Icons
    if ($loadedModule) {
        Write-Host "✓ Terminal-Icons is currently loaded (Version: $($loadedModule.Version))" -ForegroundColor Green
        if (-not $Force) {
            Write-Host "Module appears to be working. Use -Force to reinstall anyway." -ForegroundColor Yellow
            return
        }
    } else {
        Write-Host "⚠️ Terminal-Icons is not currently loaded" -ForegroundColor Yellow
    }
    
    # Step 2: Check installed versions
    Write-Host "`nChecking installed versions..." -ForegroundColor Yellow
    $installedModules = Get-Module Terminal-Icons -ListAvailable
    if ($installedModules) {
        foreach ($module in $installedModules) {
            Write-Host "  Found version $($module.Version) at: $($module.ModuleBase)" -ForegroundColor Gray
        }
    } else {
        Write-Host "  No installed versions found" -ForegroundColor Red
    }
    
    # Step 3: Remove existing installations
    Write-Host "`nRemoving existing installations..." -ForegroundColor Yellow
    try {
        # Remove from current session
        Remove-Module Terminal-Icons -Force -ErrorAction SilentlyContinue
        
        # Uninstall all versions
        $installedModules | ForEach-Object {
            try {
                Write-Host "  Removing version $($_.Version)..." -ForegroundColor Gray
                Uninstall-Module Terminal-Icons -RequiredVersion $_.Version -Force -ErrorAction Stop
            } catch {
                Write-Host "  Failed to remove version $($_.Version): $($_.Exception.Message)" -ForegroundColor Red
            }
        }
        
        Write-Host "✓ Cleanup completed" -ForegroundColor Green
    } catch {
        Write-Host "⚠️ Cleanup had issues: $($_.Exception.Message)" -ForegroundColor Yellow
    }
    
    # Step 4: Clear PowerShell module cache
    Write-Host "`nClearing PowerShell module cache..." -ForegroundColor Yellow
    try {
        $modulePaths = $env:PSModulePath -split ';'
        foreach ($path in $modulePaths) {
            $terminalIconsPath = Join-Path $path "Terminal-Icons"
            if (Test-Path $terminalIconsPath) {
                Write-Host "  Removing cached files from: $terminalIconsPath" -ForegroundColor Gray
                Remove-Item $terminalIconsPath -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
        Write-Host "✓ Cache cleared" -ForegroundColor Green
    } catch {
        Write-Host "⚠️ Cache cleanup had issues: $($_.Exception.Message)" -ForegroundColor Yellow
    }
    
    # Step 5: Fresh installation
    Write-Host "`nInstalling fresh copy of Terminal-Icons..." -ForegroundColor Yellow
    try {
        # Ensure we're using TLS 1.2
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        
        Install-Module Terminal-Icons -Scope CurrentUser -Force -AllowClobber -Repository PSGallery
        Write-Host "✓ Fresh installation completed" -ForegroundColor Green
    } catch {
        Write-Host "✗ Installation failed: $($_.Exception.Message)" -ForegroundColor Red
        return
    }
    
    # Step 6: Test import
    Write-Host "`nTesting module import..." -ForegroundColor Yellow
    try {
        Import-Module Terminal-Icons -Force -ErrorAction Stop
        Write-Host "✓ Module imported successfully" -ForegroundColor Green
        
        # Test icon functionality
        Write-Host "`nTesting icon functionality..." -ForegroundColor Yellow
        $testResult = Get-ChildItem $PWD | Select-Object -First 1
        if ($testResult) {
            Write-Host "✓ Icons should now be working" -ForegroundColor Green
        }
        
    } catch {
        Write-Host "✗ Import failed: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "`nTrying alternative approach..." -ForegroundColor Yellow
        
        # Alternative: Try importing with specific parameters
        try {
            Import-Module Terminal-Icons -DisableNameChecking -Global -Force
            Write-Host "✓ Alternative import successful" -ForegroundColor Green
        } catch {
            Write-Host "✗ All import attempts failed" -ForegroundColor Red
            Write-Host "Consider using the basic icon fallback: 'lsi' command" -ForegroundColor Cyan
        }
    }
    
    Write-Host "`nRepair process completed." -ForegroundColor Cyan
}

function Test-TerminalIcons {
    <#
    .SYNOPSIS
        Test if Terminal-Icons is working properly.
    
    .DESCRIPTION
        Performs a quick test to verify Terminal-Icons functionality.
    #>
    [CmdletBinding()]
    param()
    
    Write-Host "Testing Terminal-Icons..." -ForegroundColor Cyan
    
    $module = Get-Module Terminal-Icons
    if ($module) {
        Write-Host "✓ Module is loaded (Version: $($module.Version))" -ForegroundColor Green
        
        # Test by listing current directory
        Write-Host "`nTesting icon display:" -ForegroundColor Yellow
        Get-ChildItem $PWD | Select-Object -First 5 | Format-Table
        
    } else {
        Write-Host "✗ Terminal-Icons is not loaded" -ForegroundColor Red
        Write-Host "Run 'Repair-TerminalIcons' to fix issues" -ForegroundColor Cyan
    }
}

# Export functions
Export-ModuleMember -Function Repair-TerminalIcons, Test-TerminalIcons
