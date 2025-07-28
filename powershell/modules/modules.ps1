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
    Import-Module $availableModules -PassThru | Out-Null
}

# Install Oh My Posh using winget (not as a PowerShell module)
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
}
