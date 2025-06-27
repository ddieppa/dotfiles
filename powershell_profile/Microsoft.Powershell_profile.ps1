# =========================================================================
# PowerShell Profile
#
# Organizes the profile into logical sections for readability and
# maintainability. Includes performance optimizations and robust
# error handling.
# =========================================================================

# =========================================================================
# SECTION 1: ENVIRONMENT & PRE-CHECKS
# =========================================================================
# Ensure consistent UTF-8 output across PowerShell versions
if ($PSVersionTable.PSVersion.Major -ge 7) {
    [Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false)
}

# Check for minimum required PowerShell version
if ($PSVersionTable.PSVersion.Major -lt 7) {
    Write-Warning "⚠️ PowerShell version is below 7. Some features may not work optimally."
}

# Check execution policy to ensure scripts can run
if ((Get-ExecutionPolicy) -notin @("RemoteSigned", "Unrestricted")) {
    Write-Warning "⚠️ Execution policy is not set to RemoteSigned or higher. Some scripts may not run."
}


# =========================================================================
# SECTION 2: CONFIGURATION MANAGEMENT
# =========================================================================
# Centralized configuration for profile settings
$ProfileConfigPath = Join-Path (Split-Path $PROFILE -Parent) ".powershell-profile-config.json"

# Default settings if no config file is found
$DefaultConfig = @{
    OhMyPoshThemesPath = $env:POSH_THEMES_PATH
    OhMyPoshThemeName  = "mytheme.omp.json"
    EnablePredictiveText = $true
}

# Load configuration from file or create a default one
if (Test-Path $ProfileConfigPath) {
    try {
        $configContent = Get-Content $ProfileConfigPath -Raw | ConvertFrom-Json
        $global:Config = @{
            OhMyPoshThemesPath = $env:POSH_THEMES_PATH
            OhMyPoshThemeName  = $configContent.OhMyPoshThemeName
            EnablePredictiveText = $configContent.EnablePredictiveText
        }
    } catch {
        Write-Warning "⚠️ Error loading profile config, using defaults: $_"
        $global:Config = $DefaultConfig.Clone()
    }
} else {
    $global:Config = $DefaultConfig.Clone()
    try {
        $global:Config | ConvertTo-Json | Out-File -FilePath $ProfileConfigPath -Encoding UTF8
    } catch {
        Write-Warning "⚠️ Could not save profile config: $_"
    }
}


# =========================================================================
# SECTION 3: MODULE INITIALIZATION
# =========================================================================
# This block handles the loading of all PowerShell modules.
# Modules are not imported directly to leverage PowerShell's module autoloading for better performance.
# The configuration below ensures that the modules are ready to be used when called.

# --- Oh My Posh ---
# Must be initialized first to correctly render the prompt.
try {
    # Check if Oh My Posh command is available
    if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
        $themeFilePath = Join-Path $global:Config.OhMyPoshThemesPath $global:Config.OhMyPoshThemeName
        if ($global:Config.OhMyPoshThemesPath -and (Test-Path $themeFilePath)) {
            Invoke-Expression (&oh-my-posh init pwsh --config $themeFilePath)
            Write-Host "✅ Oh My Posh initialized with theme: $($global:Config.OhMyPoshThemeName)" -ForegroundColor Green
        } else {
            Write-Warning "⚠️ Oh My Posh theme file not found: $themeFilePath"
        }
    } else {
        Write-Warning "⚠️ Oh My Posh command not found. Please install it first."
    }
} catch {
    Write-Warning "⚠️ Oh My Posh initialization failed: $_"
}

# --- PSReadLine ---
# Provides an improved command-line editing experience.
try {
    if (Get-Module -ListAvailable -Name PSReadLine) {
        Set-PSReadLineOption -EditMode Windows
        # Enhanced Key Handlers
        Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
        Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
        Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
        Set-PSReadLineKeyHandler -Key "Ctrl+r" -Function ReverseHistorySearch
        Set-PSReadLineKeyHandler -Key "Ctrl+d" -Function ExitLine

        if ($global:Config.EnablePredictiveText) {
            Set-PSReadLineOption -PredictionSource History -PredictionViewStyle ListView
            Write-Host "✅ PSReadLine configured with predictive text" -ForegroundColor Green
        } else {
            Write-Host "✅ PSReadLine configured (predictive text disabled)" -ForegroundColor Green
        }
    } else {
        Write-Warning "⚠️ PSReadLine module not found. Command-line editing experience will be limited."
    }
} catch {
    if ($_.Exception.Message -like "*predictive text*") {
        Write-Host "✅ PSReadLine configured (predictive text disabled due to terminal compatibility)" -ForegroundColor Yellow
    } else {
        Write-Warning "⚠️ PSReadLine configuration failed: $_"
    }
}

# --- Terminal-Icons ---
# Adds file and folder icons to terminal commands like 'ls'.
try {
    if (Get-Module -ListAvailable -Name Terminal-Icons) {
        # The module will be auto-loaded on first use of a command like 'ls'
        Write-Host "✅ Terminal Icons is available and will auto-load" -ForegroundColor Green
    } else {
        Write-Warning "⚠️ Terminal-Icons module not installed. Run 'Install-ProfileModules' to install it."
    }
} catch {
    Write-Warning "⚠️ Terminal-Icons configuration failed: $_"
}

# --- PowerToys CommandNotFound ---
# Suggests WinGet packages if a command is not found.
try {
    if (Get-Module -ListAvailable -Name Microsoft.WinGet.CommandNotFound) {
        # This module also auto-loads when a command is not found.
        Write-Host "✅ PowerToys CommandNotFound module is available and will auto-load" -ForegroundColor Green
    }
} catch {
    Write-Warning "⚠️ PowerToys CommandNotFound module check failed: $_"
}

# General catch block for any unexpected errors during module loading
$errorMessage = "⚠️ A critical error occurred during module initialization: $_"
Write-Warning $errorMessage
# Log error to file for debugging
try {
    $logPath = Join-Path (Split-Path $PROFILE -Parent) "PowerShellProfileErrors.log"
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp - $errorMessage" | Out-File -FilePath $logPath -Append -Encoding UTF8 -ErrorAction SilentlyContinue
} catch {
    # If logging fails, just continue silently
}


# =========================================================================
# SECTION 4: CUSTOM ALIASES & FUNCTIONS
# =========================================================================

# --- General Aliases ---
Set-Alias -Name ll -Value Get-ChildItem
function la { Get-ChildItem -Force @args }
Set-Alias -Name c -Value Clear-Host
Set-Alias -Name which -Value Get-Command

# --- Git Aliases & Functions ---
Set-Alias -Name g -Value git
function gst { git status @args }
function gad { git add @args }
function gcm { git commit @args }
function gps { git push @args }
function gpl { git pull @args }
function gbr { git branch @args }
function gco { git checkout @args }
function gdf { git diff @args }
function glog { git log --oneline @args }

# --- .NET CLI Aliases & Functions ---
Set-Alias -Name dn -Value dotnet
function dnb { dotnet build @args }
function dnr { dotnet run @args }
function dnt { dotnet test @args }
function dnp { dotnet pack @args }
function dnpub { dotnet publish @args }
function dnres { dotnet restore @args }
function dnc { dotnet clean @args }
function dnnew { dotnet new @args }
function dnadd { dotnet add @args }
function dnrem { dotnet remove @args }
function dnlist { dotnet list @args }
function dnsln { dotnet sln @args }

# --- Profile Management Functions ---
function Edit-Profile {
    code-insiders $PROFILE
}

function Import-Profile {
    . $PROFILE
    Write-Host "✅ Profile reloaded" -ForegroundColor Green
}

function Install-ProfileModules {
    $modules = @(
        "OhMyPosh",
        "PSReadLine",
        "Terminal-Icons",
        "Microsoft.WinGet.CommandNotFound",
        "Microsoft.PowerShell.SecretManagement"
    )

    foreach ($module in $modules) {
        if (Get-Module -ListAvailable -Name $module) {
            Write-Host "✅ $module is already installed." -ForegroundColor Green
        } else {
            Write-Host "Installing $module..." -ForegroundColor Yellow
            try {
                Install-Module $module -Repository PSGallery -Force -Scope CurrentUser
                Write-Host "✅ Successfully installed $module." -ForegroundColor Green
            } catch {
                Write-Warning "⚠️ Failed to install $module: $_"
            }
        }
    }
    Write-Host "💡 Run 'Import-Profile' to apply changes" -ForegroundColor Yellow
}

# --- .NET Development Functions ---
function New-DotNetProject {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Name,
        [Parameter(Mandatory=$true)]
        [ValidateSet("console", "classlib", "web", "webapi", "mvc", "blazor", "worker", "test")]
        [string]$Template,
        [string]$Framework = "net8.0"
    )
    dotnet new $Template -n $Name -f $Framework
    Set-Location $Name
    Write-Host "✅ Created $Template project: $Name" -ForegroundColor Green
}

function Add-DotNetPackage {
    param(
        [Parameter(Mandatory=$true)]
        [string]$PackageName,
        [string]$Version
    )
    if ($Version) {
        dotnet add package $PackageName --version $Version
    } else {
        dotnet add package $PackageName
    }
    Write-Host "✅ Added package: $PackageName" -ForegroundColor Green
}

function Build-DotNetSolution {
    param(
        [string]$Configuration = "Debug",
        [switch]$NoBuild
    )
    if (-not $NoBuild) {
        dotnet build --configuration $Configuration
    }
    dotnet test --configuration $Configuration --no-build
    Write-Host "✅ Build and test completed" -ForegroundColor Green
}

function Open-ProjectInVSCode {
    param([string]$Path = ".")
    code-insiders $Path
}

# --- Secret Management Placeholder ---
# It's a best practice to avoid hardcoding secrets. Use the SecretManagement module.
# Example:
# if (Get-Module -ListAvailable -Name Microsoft.PowerShell.SecretManagement) {
#     # Register a vault if none is registered
#     if (-not (Get-SecretVault)) {
#         Register-SecretVault -Name LocalStore -ModuleName Microsoft.PowerShell.SecretStore -DefaultVault
#     }
#     # $apiKey = Get-Secret -Name "MyApiKey"
# }

# --- Diagnostic and Informational Functions ---
function Show-Aliases {
    Write-Host "=== .NET Development Shortcuts ===" -ForegroundColor Cyan
    Write-Host "dn       → dotnet" -ForegroundColor Green
    Write-Host "dnb      → dotnet build" -ForegroundColor Green
    Write-Host "dnr      → dotnet run" -ForegroundColor Green
    Write-Host "dnt      → dotnet test" -ForegroundColor Green
    Write-Host "dnp      → dotnet pack" -ForegroundColor Green
    Write-Host "dnpub    → dotnet publish" -ForegroundColor Green
    Write-Host "dnres    → dotnet restore" -ForegroundColor Green
    Write-Host "dnc      → dotnet clean" -ForegroundColor Green
    Write-Host "dnnew    → dotnet new" -ForegroundColor Green
    Write-Host "dnadd    → dotnet add" -ForegroundColor Green
    Write-Host "dnrem    → dotnet remove" -ForegroundColor Green
    Write-Host "dnlist   → dotnet list" -ForegroundColor Green
    Write-Host "dnsln    → dotnet sln" -ForegroundColor Green
    Write-Host ""
    Write-Host "=== Git Development Shortcuts ===" -ForegroundColor Yellow
    Write-Host "g        → git" -ForegroundColor Yellow
    Write-Host "gst      → git status" -ForegroundColor Yellow
    Write-Host "gad      → git add" -ForegroundColor Yellow
    Write-Host "gcm      → git commit" -ForegroundColor Yellow
    Write-Host "gps      → git push" -ForegroundColor Yellow
    Write-Host "gpl      → git pull" -ForegroundColor Yellow
    Write-Host "gbr      → git branch" -ForegroundColor Yellow
    Write-Host "gco      → git checkout" -ForegroundColor Yellow
    Write-Host "gdf      → git diff" -ForegroundColor Yellow
    Write-Host "glog     → git log --oneline" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "=== General Shortcuts ===" -ForegroundColor Cyan
    Write-Host "ll       → Get-ChildItem" -ForegroundColor Magenta
    Write-Host "la       → Get-ChildItem -Force" -ForegroundColor Magenta
    Write-Host "c        → Clear-Host" -ForegroundColor Magenta
    Write-Host "which    → Get-Command" -ForegroundColor Magenta
}

function Show-DotNetInfo {
    Write-Host "=== .NET Development Environment Info ===" -ForegroundColor Cyan
    Write-Host "Current Version:" -ForegroundColor Yellow
    dotnet --version
    Write-Host ""
    Write-Host "--- Installed SDKs ---" -ForegroundColor Yellow
    dotnet --list-sdks
    Write-Host ""
    Write-Host "--- Installed Runtimes ---" -ForegroundColor Yellow
    dotnet --list-runtimes
    Write-Host "=========================================" -ForegroundColor Cyan
}

function Test-ProfileEnvironment {
    Write-Host "=== PowerShell Profile Diagnostics ===" -ForegroundColor Cyan
    Write-Host "PowerShell Version: $($PSVersionTable.PSVersion)" -ForegroundColor Green
    Write-Host "Execution Policy: $(Get-ExecutionPolicy)" -ForegroundColor Green
    Write-Host "Profile Path: $PROFILE" -ForegroundColor Green
    Write-Host "Profile Exists: $(Test-Path $PROFILE)" -ForegroundColor Green
    Write-Host "Profile Directory: $(Split-Path $PROFILE -Parent)" -ForegroundColor Green
    
    Write-Host "`n=== Configuration Variables ===" -ForegroundColor Cyan
    Write-Host "Config File: $ProfileConfigPath" -ForegroundColor Gray
    Write-Host "Config File Exists: $(Test-Path $ProfileConfigPath)" -ForegroundColor Gray
    Write-Host "Oh My Posh Themes Path: $($global:Config.OhMyPoshThemesPath)" -ForegroundColor Yellow
    Write-Host "Oh My Posh Theme Name: $($global:Config.OhMyPoshThemeName)" -ForegroundColor Yellow
    Write-Host "Predictive Text Enabled: $($global:Config.EnablePredictiveText)" -ForegroundColor Yellow
    
    Write-Host "`n=== Oh My Posh Environment ===" -ForegroundColor Cyan
    if ($global:Config.OhMyPoshThemesPath) {
        Write-Host "Themes Path Exists: $(Test-Path $global:Config.OhMyPoshThemesPath)" -ForegroundColor Yellow
        $themeFile = Join-Path $global:Config.OhMyPoshThemesPath $global:Config.OhMyPoshThemeName
        Write-Host "Theme File Path: $themeFile" -ForegroundColor Yellow
        Write-Host "Theme File Exists: $(Test-Path $themeFile)" -ForegroundColor Yellow
        
        if (Test-Path $themeFile) {
            try {
                $null = Get-Content $themeFile -Raw | ConvertFrom-Json -ErrorAction Stop
                Write-Host "Theme JSON is valid: ✅" -ForegroundColor Green
            } catch {
                Write-Host "Theme JSON has errors: ❌ $_" -ForegroundColor Red
            }
        }
    }
    
    Write-Host "`n=== Module Status ===" -ForegroundColor Cyan
    $modules = @("Terminal-Icons", "Microsoft.WinGet.CommandNotFound", "PSReadLine")
    foreach ($module in $modules) {
        $available = Get-Module -ListAvailable -Name $module
        $loaded = Get-Module -Name $module
        Write-Host "$module - Available: $(if($available){'✅'}else{'❌'}) Loaded: $(if($loaded){'✅'}else{'❌'})" -ForegroundColor Green
    }
    
    Write-Host "`n=== Error Log ===" -ForegroundColor Cyan
    $logPath = Join-Path (Split-Path $PROFILE -Parent) "PowerShellProfileErrors.log"
    if (Test-Path $logPath) {
        Write-Host "Recent errors from: $logPath" -ForegroundColor Yellow
        Get-Content $logPath -Tail 5 | ForEach-Object { Write-Host "  $_" -ForegroundColor Red }
    } else {
        Write-Host "No error log found" -ForegroundColor Green
    }
    Write-Host "=========================================" -ForegroundColor Cyan
}

# --- Theme Management Functions ---
function Set-ProfileTheme {
    param(
        [Parameter(Mandatory=$true)]
        [string]$ThemeName
    )
    
    $themeFile = Join-Path $global:Config.OhMyPoshThemesPath "$ThemeName.omp.json"
    if (Test-Path $themeFile) {
        $global:Config.OhMyPoshThemeName = "$ThemeName.omp.json"
        
        try {
            $global:Config | ConvertTo-Json | Out-File -FilePath $ProfileConfigPath -Encoding UTF8
            Write-Host "✅ Theme set to: $ThemeName (saved to config)" -ForegroundColor Green
            Write-Host "💡 Run 'Import-Profile' to apply the new theme" -ForegroundColor Yellow
        } catch {
            Write-Warning "⚠️ Could not save theme setting: $_"
            Write-Host "✅ Theme set to: $ThemeName (session only)" -ForegroundColor Yellow
        }
    } else {
        Write-Warning "❌ Theme file not found: $themeFile"
        Write-Host "Available themes in $($global:Config.OhMyPoshThemesPath):" -ForegroundColor Yellow
        if (Test-Path $global:Config.OhMyPoshThemesPath) {
            Get-ChildItem $global:Config.OhMyPoshThemesPath -Name "*.omp.json" | ForEach-Object { 
                $themeName = $_ -replace '\.omp\.json$', ''
                Write-Host "  - $themeName" -ForegroundColor Cyan
            }
        }
    }
}

function Reset-ProfileConfig {
    param(
        [switch]$Force
    )
    
    if ($Force -or (Read-Host "Reset profile configuration to defaults? (y/N)") -eq 'y') {
        try {
            Remove-Item $ProfileConfigPath -Force -ErrorAction SilentlyContinue
            $global:Config = $DefaultConfig.Clone()
            $global:Config | ConvertTo-Json | Out-File -FilePath $ProfileConfigPath -Encoding UTF8
            Write-Host "✅ Profile configuration reset to defaults" -ForegroundColor Green
            Write-Host "💡 Run 'Import-Profile' to apply changes" -ForegroundColor Yellow
        } catch {
            Write-Warning "⚠️ Could not reset profile config: $_"
        }
    }
}

# =========================================================================
# SECTION 5: ARGUMENT COMPLETERS
# =========================================================================
# Tab completion for dotnet CLI
Register-ArgumentCompleter -Native -CommandName dotnet -ScriptBlock {
    param($commandName, $wordToComplete, $cursorPosition)
    dotnet complete --position $cursorPosition "$wordToComplete" | ForEach-Object {
        [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
    }
}

# =========================================================================
# SECTION 6: WELCOME MESSAGE
# =========================================================================
Write-Host ""
Write-Host "🚀 .NET Development Environment Ready!" -ForegroundColor Cyan
Write-Host "   Type 'Show-Aliases' to see available shortcuts" -ForegroundColor Gray
Write-Host "   Type 'Show-DotNetInfo' to see .NET installation details" -ForegroundColor Gray
Write-Host "   Type 'Test-ProfileEnvironment' to diagnose profile issues" -ForegroundColor Gray
Write-Host "   Type 'Install-ProfileModules' to install required modules" -ForegroundColor Gray
Write-Host "   Type 'Set-ProfileTheme <theme-name>' to change Oh My Posh theme" -ForegroundColor Gray
Write-Host "   Type 'Reset-ProfileConfig' to reset configuration to defaults" -ForegroundColor Gray
Write-Host "   Type 'Import-Profile' to reload this profile" -ForegroundColor Gray
Write-Host ""