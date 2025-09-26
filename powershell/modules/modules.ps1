# Optimized module loading with caching and lazy loading
# Based on Microsoft PowerShell performance best practices

#Requires -Version 5.1

# Ensure TLS 1.2 for PowerShell Gallery compatibility
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Performance optimization: Cache module availability checks
if (-not $Global:__ProfileCache) {
    $Global:__ProfileCache = @{
        ModuleAvailability = @{}
        PathTests = @{}
        CommandTests = @{}
        LastCacheTime = (Get-Date)
    }
}

function Test-ModuleAvailable {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ModuleName,
        [int]$CacheTimeoutMinutes = 15
    )
    
    $cacheKey = "Module_$ModuleName"
    $cache = $Global:__ProfileCache.ModuleAvailability
    
    if ($cache.ContainsKey($cacheKey)) {
        $cachedResult = $cache[$cacheKey]
        if ((Get-Date) - $cachedResult.Time -lt [TimeSpan]::FromMinutes($CacheTimeoutMinutes)) {
            return $cachedResult.Result
        }
    }
    
    $result = [bool](Get-Module -ListAvailable -Name $ModuleName -ErrorAction SilentlyContinue)
    $cache[$cacheKey] = @{ Result = $result; Time = Get-Date }
    return $result
}

function Install-ModuleIfMissing {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ModuleName,
        [string]$Repository = 'PSGallery'
    )
    
    if (-not (Test-ModuleAvailable -ModuleName $ModuleName)) {
        Write-Host "    Installing $ModuleName..." -ForegroundColor Yellow
        try {
            # Use -AllowClobber to handle potential conflicts more gracefully
            Install-Module $ModuleName -Scope CurrentUser -Force -AllowClobber -Repository $Repository -ErrorAction Stop
            
            # Update cache after successful installation
            $Global:__ProfileCache.ModuleAvailability["Module_$ModuleName"] = @{ Result = $true; Time = Get-Date }
            
            Write-Host "    ✓ $ModuleName installed successfully" -ForegroundColor Green
            return $true
        } catch {
            Write-Warning "Failed to install $ModuleName : $($_.Exception.Message)"
            return $false
        }
    }
    return $true
}

function Import-ModuleWithTimer {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ModuleName,
        [switch]$Force
    )
    
    if (Test-ModuleAvailable -ModuleName $ModuleName) {
        $moduleTimer = [System.Diagnostics.Stopwatch]::StartNew()
        Write-Host "    Importing $ModuleName..." -ForegroundColor DarkGray
        try {
            $importParams = @{
                Name = $ModuleName
                DisableNameChecking = $true
                ErrorAction = 'Stop'
            }
            if ($Force) { $importParams.Force = $true }
            
            Import-Module @importParams
            Write-Host "    ✓ $ModuleName loaded ($($moduleTimer.ElapsedMilliseconds)ms)" -ForegroundColor DarkGreen
            return $true
        } catch {
            Write-Host "    ✗ Failed to load $ModuleName : $($_.Exception.Message)" -ForegroundColor Red
            return $false
        } finally {
            $moduleTimer.Stop()
        }
    } else {
        Write-Host "    ✗ $ModuleName not available" -ForegroundColor Red
        return $false
    }
}

# Check and register PSGallery if needed (with caching)
$psGalleryKey = "PSGallery_Available"
if (-not $Global:__ProfileCache.ContainsKey($psGalleryKey) -or 
    ((Get-Date) - $Global:__ProfileCache[$psGalleryKey].Time -gt [TimeSpan]::FromMinutes(60))) {
    
    $psGalleryExists = [bool](Get-PSRepository -Name PSGallery -ErrorAction SilentlyContinue)
    if (-not $psGalleryExists) {
        try {
            Register-PSRepository -Default -ErrorAction SilentlyContinue
            $psGalleryExists = $true
        } catch {
            Write-Warning "Failed to register PSGallery repository"
            $psGalleryExists = $false
        }
    }
    $Global:__ProfileCache[$psGalleryKey] = @{ Result = $psGalleryExists; Time = Get-Date }
}

# Define required modules with lazy loading strategy
$requiredModules = @{
    # Essential modules - load immediately
    Immediate = @(
        'Terminal-Icons'  # Now working properly after fresh install
    )
    # Git-related modules - load on demand
    OnDemand = @(
        'posh-git'
    )
    # Editor/readline modules - handled separately
    Special = @(
        'PSReadLine'  # This is typically pre-loaded in PowerShell 5.1+
    )
}

# Install missing modules
Write-Host "    Checking required modules..." -ForegroundColor DarkGray
foreach ($category in $requiredModules.Keys) {
    foreach ($moduleName in $requiredModules[$category]) {
        Install-ModuleIfMissing -ModuleName $moduleName | Out-Null
    }
}

# Import immediate modules with better error handling
foreach ($moduleName in $requiredModules.Immediate) {
    try {
        # Special handling for Terminal-Icons which can have XML issues
        if ($moduleName -eq 'Terminal-Icons') {
            Write-Host "    Importing Terminal-Icons..." -ForegroundColor DarkGray
            $moduleTimer = [System.Diagnostics.Stopwatch]::StartNew()
            try {
                Import-Module Terminal-Icons -DisableNameChecking -Force -ErrorAction Stop 2>$null
                if (Get-Module Terminal-Icons) {
                    Write-Host "    ✓ Terminal-Icons loaded ($($moduleTimer.ElapsedMilliseconds)ms)" -ForegroundColor DarkGreen
                } else {
                    throw "Module failed to load properly"
                }
            } catch {
                Write-Host "    ✗ Terminal-Icons failed to load: $($_.Exception.Message)" -ForegroundColor Red
                Write-Host "    📁 Setting up basic icon fallback..." -ForegroundColor Yellow
                # Create a basic icon fallback function
                function global:Get-ChildItemPretty {
                    [CmdletBinding()]
                    param(
                        [Parameter(ValueFromPipeline = $true, Position = 0)]
                        [string]$Path = ".",
                        [switch]$Force,
                        [switch]$Recurse
                    )
                    $params = @{ Path = $Path }
                    if ($Force) { $params.Force = $true }
                    if ($Recurse) { $params.Recurse = $true }
                    Get-ChildItem @params | ForEach-Object {
                        $icon = if ($_.PSIsContainer) { "📁" }
                               elseif ($_.Extension -eq ".ps1") { "📜" }
                               elseif ($_.Extension -in @(".txt", ".md", ".log")) { "📄" }
                               elseif ($_.Extension -in @(".jpg", ".png", ".gif", ".bmp")) { "🖼️" }
                               elseif ($_.Extension -in @(".mp3", ".wav", ".mp4", ".avi")) { "🎵" }
                               elseif ($_.Extension -in @(".zip", ".rar", ".7z")) { "📦" }
                               elseif ($_.Extension -in @(".exe", ".msi")) { "⚙️" }
                               else { "📄" }
                        [PSCustomObject]@{
                            Icon = $icon
                            Name = $_.Name
                            Length = if ($_.PSIsContainer) { "" } else { $_.Length }
                            LastWriteTime = $_.LastWriteTime
                            FullName = $_.FullName
                        }
                    }
                }
                Set-Alias -Name lsi -Value Get-ChildItemPretty -Scope Global -ErrorAction SilentlyContinue
                Write-Host "    ✓ Basic icon fallback configured (use 'lsi' for icons)" -ForegroundColor Green
            }
            $moduleTimer.Stop()
        } else {
            Import-ModuleWithTimer -ModuleName $moduleName | Out-Null
        }
    } catch {
        Write-Warning "Failed to process module $moduleName : $_"
    }
}

# Always ensure icon fallback is available
if (-not (Get-Alias lsi -ErrorAction SilentlyContinue)) {
    Write-Host "    Ensuring icon fallback is available..." -ForegroundColor DarkGray
    function global:Get-ChildItemPretty {
        [CmdletBinding()]
        param(
            [Parameter(ValueFromPipeline = $true, Position = 0)]
            [string]$Path = ".",
            [switch]$Force,
            [switch]$Recurse
        )
        $params = @{ Path = $Path }
        if ($Force) { $params.Force = $true }
        if ($Recurse) { $params.Recurse = $true }
        Get-ChildItem @params | ForEach-Object {
            $icon = if ($_.PSIsContainer) { "📁" }
                   elseif ($_.Extension -eq ".ps1") { "📜" }
                   elseif ($_.Extension -in @(".txt", ".md", ".log")) { "📄" }
                   elseif ($_.Extension -in @(".jpg", ".png", ".gif", ".bmp")) { "🖼️" }
                   elseif ($_.Extension -in @(".mp3", ".wav", ".mp4", ".avi")) { "🎵" }
                   elseif ($_.Extension -in @(".zip", ".rar", ".7z")) { "📦" }
                   elseif ($_.Extension -in @(".exe", ".msi")) { "⚙️" }
                   else { "📄" }
            [PSCustomObject]@{
                Icon = $icon
                Name = $_.Name
                Length = if ($_.PSIsContainer) { "" } else { $_.Length }
                LastWriteTime = $_.LastWriteTime
                FullName = $_.FullName
            }
        }
    }
    Set-Alias -Name lsi -Value Get-ChildItemPretty -Scope Global -ErrorAction SilentlyContinue
    Write-Host "    ✓ Icon fallback ready (use 'lsi' for icons)" -ForegroundColor Green
}

# Set up lazy loading for on-demand modules
if (Test-ModuleAvailable -ModuleName 'posh-git') {
    $Global:__PoshGitAutoLoad = $true
    Write-Host "    ✓ posh-git configured for lazy loading" -ForegroundColor DarkGreen
}

# Handle Oh My Posh installation (not a PowerShell module)
$ohMyPoshTimer = [System.Diagnostics.Stopwatch]::StartNew()
Write-Host "    Checking Oh My Posh..." -ForegroundColor DarkGray

# Cache Oh My Posh availability check
$ohMyPoshKey = "OhMyPosh_Available"
if (-not $Global:__ProfileCache.ContainsKey($ohMyPoshKey) -or 
    ((Get-Date) - $Global:__ProfileCache[$ohMyPoshKey].Time -gt [TimeSpan]::FromMinutes(30))) {
    
    $ohMyPoshAvailable = [bool](Get-Command oh-my-posh -ErrorAction SilentlyContinue)
    $Global:__ProfileCache[$ohMyPoshKey] = @{ Result = $ohMyPoshAvailable; Time = Get-Date }
} else {
    $ohMyPoshAvailable = $Global:__ProfileCache[$ohMyPoshKey].Result
}

if (-not $ohMyPoshAvailable) {
    Write-Host "    Installing Oh My Posh via winget..." -ForegroundColor Yellow
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        try {
            $wingetProcess = Start-Process winget -ArgumentList "install JanDeDobbeleer.OhMyPosh -s winget --accept-source-agreements --accept-package-agreements" -Wait -PassThru -NoNewWindow
            if ($wingetProcess.ExitCode -eq 0) {
                Write-Host "    ✓ Oh My Posh installed successfully" -ForegroundColor Green
                # Update cache
                $Global:__ProfileCache[$ohMyPoshKey] = @{ Result = $true; Time = Get-Date }
            } else {
                Write-Warning "Oh My Posh installation failed (winget exit code: $($wingetProcess.ExitCode))"
            }
        } catch {
            Write-Warning "Failed to install Oh My Posh via winget: $_"
            Write-Host "    Please install manually from https://ohmyposh.dev/docs/installation/windows" -ForegroundColor Yellow
        }
    } else {
        Write-Warning "winget not available. Please install Oh My Posh manually from https://ohmyposh.dev/docs/installation/windows"
    }
} else {
    Write-Host "    ✓ Oh My Posh already available ($($ohMyPoshTimer.ElapsedMilliseconds)ms)" -ForegroundColor DarkGreen
}
$ohMyPoshTimer.Stop()

# Note: Export-ModuleMember is not used here since this is a script (.ps1), not a module (.psm1)
# The functions are already available in the global scope where this script is dot-sourced
