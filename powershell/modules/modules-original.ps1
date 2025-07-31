# Ensure TLS 1.2 for PowerShell Gallery compatibility
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Check and register PSGallery if needed
if (-not (Get-PSRepository -Name PSGallery -ErrorAction SilentlyContinue)) {
    Register-PSRepository -Default -ErrorAction SilentlyContinue
}

$required = @(
    'PSReadLine',
    'Terminal-Icons',
    'posh-git'
)

foreach ($m in $required) {
    if (-not (Get-Module -ListAvailable -Name $m)) {
        Write-Host "Installing $m ..." -Foreground Yellow
        try {
            Install-Module $m -Scope CurrentUser -Force -ErrorAction Stop
        } catch {
            Write-Warning "Failed to install $m : $($_.Exception.Message)"
        }
    }
}

# Import only successfully installed modules (skip PSReadLine as it's handled separately)
$availableModules = $required | Where-Object { 
    $_ -ne 'PSReadLine' -and (Get-Module -ListAvailable -Name $_) 
}
if ($availableModules) {
    foreach ($module in $availableModules) {
        $moduleTimer = [System.Diagnostics.Stopwatch]::StartNew()
        Write-Host "    Importing $module..." -ForegroundColor DarkGray
        try {
            Import-Module $module -Force -ErrorAction Stop
            Write-Host "    ✓ $module loaded ($($moduleTimer.ElapsedMilliseconds)ms)" -ForegroundColor DarkGreen
        } catch {
            Write-Host "    ✗ Failed to load $module : $($_.Exception.Message)" -ForegroundColor Red
        }
        $moduleTimer.Stop()
    }
}

# Install Oh My Posh using winget (not as a PowerShell module)
$ohMyPoshTimer = [System.Diagnostics.Stopwatch]::StartNew()
Write-Host "    Checking Oh My Posh..." -ForegroundColor DarkGray
if (-not (Get-Command oh-my-posh -ErrorAction SilentlyContinue)) {
    Write-Host "Installing Oh My Posh via winget..." -Foreground Yellow
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        try {
            winget install JanDeDobbeleer.OhMyPosh -s winget --accept-source-agreements --accept-package-agreements
        } catch {
            Write-Warning "Failed to install Oh My Posh via winget. Please install manually from https://ohmyposh.dev/docs/installation/windows"
        }
    } else {
        Write-Warning "winget not available. Please install Oh My Posh manually from https://ohmyposh.dev/docs/installation/windows"
    }
} else {
    Write-Host "    ✓ Oh My Posh already available ($($ohMyPoshTimer.ElapsedMilliseconds)ms)" -ForegroundColor DarkGreen
}
$ohMyPoshTimer.Stop()
