#Requires -Version 5.1

# Prevent double execution of this profile
# This guard ensures the profile script is only loaded once per session.
# PowerShell can load the profile multiple times in scenarios such as nested sessions, reloading with `. $PROFILE`, or when invoked by other scripts.
# Without this check, duplicate imports, alias definitions, or event registrations could cause errors or unexpected behavior.
$profileVarName = "__DOTFILES_PROFILE_LOADED_$($PROFILE -replace '[\\/:*?""<>|]', '_')"
if (Get-Variable -Name $profileVarName -Scope Global -ErrorAction SilentlyContinue) { return }
Set-Variable -Name $profileVarName -Value $true -Scope Global

# Advanced Performance Optimizations
# Enable ProfileOptimization for JIT compilation improvements (PowerShell 5.1+)
if ($PSVersionTable.PSVersion.Major -ge 5) {
    try {
        $profileOptimizationPath = Join-Path $env:TEMP "PowerShellProfileOptimization"
        if (-not (Test-Path $profileOptimizationPath)) {
            New-Item -Path $profileOptimizationPath -ItemType Directory -Force | Out-Null
        }
        [System.Runtime.ProfileOptimization]::SetProfileRoot($profileOptimizationPath)
        [System.Runtime.ProfileOptimization]::StartProfile("PowerShellProfile.profile")
    } catch {
        # Silently continue if ProfileOptimization fails
    }
}

# Initialize performance caching
$Global:__ProfileCache = @{
    ModuleAvailability = @{}
    PathTests = @{}
    CommandTests = @{}
    LastCacheTime = (Get-Date)
}

# Cache helper functions
function Test-CachedPath {
    [CmdletBinding()]
    param([string]$Path, [int]$CacheTimeoutMinutes = 5)
    
    $cacheKey = $Path
    $cache = $Global:__ProfileCache.PathTests
    
    if ($cache.ContainsKey($cacheKey)) {
        $cachedResult = $cache[$cacheKey]
        if ((Get-Date) - $cachedResult.Time -lt [TimeSpan]::FromMinutes($CacheTimeoutMinutes)) {
            return $cachedResult.Result
        }
    }
    
    $result = Test-Path $Path -ErrorAction SilentlyContinue
    $cache[$cacheKey] = @{ Result = $result; Time = Get-Date }
    return $result
}

function Test-CachedCommand {
    [CmdletBinding()]
    param([string]$CommandName, [int]$CacheTimeoutMinutes = 10)
    
    $cacheKey = $CommandName
    $cache = $Global:__ProfileCache.CommandTests
    
    if ($cache.ContainsKey($cacheKey)) {
        $cachedResult = $cache[$cacheKey]
        if ((Get-Date) - $cachedResult.Time -lt [TimeSpan]::FromMinutes($CacheTimeoutMinutes)) {
            return $cachedResult.Result
        }
    }
    
    $result = [bool](Get-Command $CommandName -ErrorAction SilentlyContinue)
    $cache[$cacheKey] = @{ Result = $result; Time = Get-Date }
    return $result
}

# Profile Performance Timer
$ProfileTimer = [System.Diagnostics.Stopwatch]::StartNew()

# Ensure proper Unicode output encoding for emojis
if ([Console]::OutputEncoding.CodePage -ne 65001) {
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
}

Write-Host "Loading PowerShell profile..." -ForegroundColor Cyan
$HostSupportsColor = $Host.UI.SupportsVirtualTerminal

# Find the dotfiles repository root with better error handling and caching
$RepoRoot = try {
    # Check cache first
    $cacheKey = "RepoRoot_$($PROFILE)"
    $cachedResult = $null
    
    if ($Global:__ProfileCache.ContainsKey($cacheKey)) {
        $cachedResult = $Global:__ProfileCache[$cacheKey]
        if ((Get-Date) - $cachedResult.Time -lt [TimeSpan]::FromMinutes(30)) {
            $cachedResult.Result
        } else {
            $Global:__ProfileCache.Remove($cacheKey)
            $cachedResult = $null
        }
    }
    
    # If not cached or cache expired, determine the root
    if (-not $cachedResult) {
        $result = $null
        
        if ($MyInvocation.MyCommand.Path) {
            # First try to resolve symlink target
            $item = Get-Item $MyInvocation.MyCommand.Path -Force -ErrorAction SilentlyContinue
            if ($item -and $item.Target) {
                $result = Split-Path $item.Target -Parent
            } else {
                # Search for dotfiles directory in common locations
                $possiblePaths = @(
                    "D:\dotfiles\powershell",
                    "C:\dotfiles\powershell",
                    "$env:USERPROFILE\dotfiles\powershell",
                    "$env:USERPROFILE\Documents\dotfiles\powershell"
                )
                $result = $possiblePaths | Where-Object { Test-CachedPath $_ } | Select-Object -First 1
            }
        }
        
        # Final fallback
        if (-not $result) {
            $result = if ($PSScriptRoot) { $PSScriptRoot } else { "D:\dotfiles\powershell" }
        }
        
        # Cache the result
        $Global:__ProfileCache[$cacheKey] = @{ Result = $result; Time = Get-Date }
        $result
    } else {
        $cachedResult.Result
    }
} catch {
    Write-Warning "Error determining profile root: $_"
    if ($PSScriptRoot) { $PSScriptRoot } else { "D:\dotfiles\powershell" }
}

function Join($child) { 
    if (-not $RepoRoot -or [string]::IsNullOrEmpty($RepoRoot)) { 
        Write-Warning "Repository root not determined. Using fallback path."
        $fallbackRoot = "D:\dotfiles\powershell"
        return Join-Path -Path $fallbackRoot -ChildPath $child 
    }
    Join-Path -Path $RepoRoot -ChildPath $child 
}

# Ensure RepoRoot is valid before proceeding
if (-not $RepoRoot -or [string]::IsNullOrEmpty($RepoRoot)) {
    Write-Warning "Repository root is null or empty. Setting fallback."
    $RepoRoot = "D:\dotfiles\powershell"
}

if ($HostSupportsColor) {
    Write-Host "  Repository root: $RepoRoot ($(${ProfileTimer}.ElapsedMilliseconds)ms)" -ForegroundColor Gray
} else {
    Write-Host "  Repository root: $RepoRoot ($(${ProfileTimer}.ElapsedMilliseconds)ms)"
}

# 1. Modules with lazy loading and manifest optimization ----------------
if ($HostSupportsColor) { Write-Host "  Loading modules..." -ForegroundColor Yellow }
else { Write-Host "  Loading modules..." }
$ProfileTimer.Restart()

try {
    # Check if modules.ps1 exists before loading
    $modulesPath = Join 'modules\modules.ps1'
    if (Test-CachedPath $modulesPath) {
        . $modulesPath
        if ($HostSupportsColor) { Write-Host "  Modules loaded ($(${ProfileTimer}.ElapsedMilliseconds)ms)" -ForegroundColor Green }
        else { Write-Host "  Modules loaded ($(${ProfileTimer}.ElapsedMilliseconds)ms)" }
    } else {
        if ($HostSupportsColor) { Write-Host "  modules.ps1 not found, skipping" -ForegroundColor Yellow }
        else { Write-Host "  modules.ps1 not found, skipping" }
    }
} catch {
    Write-Warning "Failed to load modules: $_"
}

# 2. Aliases with improved file loading and caching -------------------
if ($HostSupportsColor) { Write-Host "  Loading core aliases..." -ForegroundColor Yellow }
else { Write-Host "  Loading core aliases..." }
$ProfileTimer.Restart()

try {
    # Load core.ps1 first (contains Set-SafeAlias function)
    $coreAliasPath = Join 'aliases\core.ps1'
    if (Test-CachedPath $coreAliasPath) {
        . $coreAliasPath
        if ($HostSupportsColor) { Write-Host "  Core aliases loaded ($(${ProfileTimer}.ElapsedMilliseconds)ms)" -ForegroundColor Green }
        else { Write-Host "  Core aliases loaded ($(${ProfileTimer}.ElapsedMilliseconds)ms)" }
    } else {
        if ($HostSupportsColor) { Write-Host "  core.ps1 not found, skipping" -ForegroundColor Yellow }
        else { Write-Host "  core.ps1 not found, skipping" }
    }
} catch {
    Write-Warning "Failed to load core aliases: $_"
}

if ($HostSupportsColor) { Write-Host "  Loading additional aliases..." -ForegroundColor Yellow }
else { Write-Host "  Loading additional aliases..." }
$ProfileTimer.Restart()

try {
    # Load other alias files - optimized with caching and parallel loading
    $aliasFolder = Join 'aliases'
    if (Test-CachedPath $aliasFolder) {
        # Use cached file list if available
        $cacheKey = "AliasFiles_$aliasFolder"
        $aliasFiles = $null
        
        if ($Global:__ProfileCache.ContainsKey($cacheKey)) {
            $cachedResult = $Global:__ProfileCache[$cacheKey]
            if ((Get-Date) - $cachedResult.Time -lt [TimeSpan]::FromMinutes(10)) {
                $aliasFiles = $cachedResult.Result
            }
        }
        
        if (-not $aliasFiles) {
            $aliasFiles = Get-ChildItem $aliasFolder -Filter '*.ps1' -ErrorAction SilentlyContinue |
                          Where-Object { $_.Name -ne 'core.ps1' }
            $Global:__ProfileCache[$cacheKey] = @{ Result = $aliasFiles; Time = Get-Date }
        }
        
        # Load files efficiently
        foreach ($file in $aliasFiles) { 
            try {
                if ($HostSupportsColor) { Write-Host "    Loading $($file.Name)..." -ForegroundColor DarkGray }
                else { Write-Host "    Loading $($file.Name)..." }
                . $file.FullName 
            } catch {
                Write-Warning "Failed to load $($file.Name): $_"
            }
        }
        
        if ($HostSupportsColor) { Write-Host "  Additional aliases loaded ($(${ProfileTimer}.ElapsedMilliseconds)ms)" -ForegroundColor Green }
        else { Write-Host "  Additional aliases loaded ($(${ProfileTimer}.ElapsedMilliseconds)ms)" }
    } else {
        if ($HostSupportsColor) { Write-Host "  aliases folder not found, skipping" -ForegroundColor Yellow }
        else { Write-Host "  aliases folder not found, skipping" }
    }
} catch {
    Write-Warning "Failed to load additional aliases: $_"
}

# 3. PSReadLine bindings with conditional loading ----------------------
if ($HostSupportsColor) { Write-Host "  Loading PSReadLine bindings..." -ForegroundColor Yellow }
else { Write-Host "  Loading PSReadLine bindings..." }
$ProfileTimer.Restart()

try {
    # Only load PSReadLine bindings if PSReadLine is available
    if (Test-CachedCommand 'Set-PSReadLineOption') {
        $bindingsPath = Join 'psreadline\bindings.ps1'
        if (Test-CachedPath $bindingsPath) {
            . $bindingsPath
            if ($HostSupportsColor) { Write-Host "  PSReadLine bindings loaded ($(${ProfileTimer}.ElapsedMilliseconds)ms)" -ForegroundColor Green }
            else { Write-Host "  PSReadLine bindings loaded ($(${ProfileTimer}.ElapsedMilliseconds)ms)" }
        } else {
            if ($HostSupportsColor) { Write-Host "  bindings.ps1 not found, skipping" -ForegroundColor Yellow }
            else { Write-Host "  bindings.ps1 not found, skipping" }
        }
    } else {
        if ($HostSupportsColor) { Write-Host "  PSReadLine not available, skipping bindings" -ForegroundColor Yellow }
        else { Write-Host "  PSReadLine not available, skipping bindings" }
    }
} catch {
    Write-Warning "Failed to load PSReadLine bindings: $_"
}

# 4. Prompt with enhanced caching and lazy loading ---------------------
if ($HostSupportsColor) { Write-Host "  Loading Oh My Posh theme..." -ForegroundColor Yellow }
else { Write-Host "  Loading Oh My Posh theme..." }
$ProfileTimer.Restart()

try {
    # Only proceed if oh-my-posh is available
    if (Test-CachedCommand 'oh-my-posh') {
        # Look for theme configuration file first with caching
        $ThemeConfigFile = Join '.theme-config'
        $SelectedThemeFile = $null
        
        # Cache theme configuration lookup
        $cacheKey = "ThemeConfig_$ThemeConfigFile"
        if ($Global:__ProfileCache.ContainsKey($cacheKey)) {
            $cachedResult = $Global:__ProfileCache[$cacheKey]
            if ((Get-Date) - $cachedResult.Time -lt [TimeSpan]::FromMinutes(15)) {
                $SelectedThemeFile = $cachedResult.Result
            }
        }
        
        if (-not $SelectedThemeFile) {
            if (Test-CachedPath $ThemeConfigFile) {
                $configContent = Get-Content $ThemeConfigFile -Raw -ErrorAction SilentlyContinue | ForEach-Object { $_.Trim() }
                if ($configContent -and (Test-CachedPath $configContent)) {
                    $SelectedThemeFile = $configContent
                    if ($HostSupportsColor) { Write-Host "  Using configured theme: $(Split-Path $SelectedThemeFile -Leaf)" -ForegroundColor Gray }
                    else { Write-Host "  Using configured theme: $(Split-Path $SelectedThemeFile -Leaf)" }
                }
            }
            
            # If no configured theme, look for any theme in prompt folder
            if (-not $SelectedThemeFile) {
                $ThemeFolder = Join 'prompt'
                if (Test-CachedPath $ThemeFolder) {
                    $AvailableThemes = Get-ChildItem -Path $ThemeFolder -Filter '*.omp.json' -ErrorAction SilentlyContinue | Select-Object -First 1
                    if ($AvailableThemes) {
                        $SelectedThemeFile = $AvailableThemes.FullName
                        if ($HostSupportsColor) { Write-Host "  Using first available theme: $($AvailableThemes.Name) from prompt" -ForegroundColor Gray }
                        else { Write-Host "  Using first available theme: $($AvailableThemes.Name) from prompt" }
                    }
                }
            }
            
            # Cache the result
            $Global:__ProfileCache[$cacheKey] = @{ Result = $SelectedThemeFile; Time = Get-Date }
        }

        # Final fallback to built-in theme
        $Config = if ($SelectedThemeFile -and (Test-CachedPath $SelectedThemeFile)) { 
            $SelectedThemeFile 
        } else { 
            if ($HostSupportsColor) { Write-Host "  No custom themes found, using built-in 'paradox'" -ForegroundColor Yellow }
            else { Write-Host "  No custom themes found, using built-in 'paradox'" }
            'paradox' 
        }

        # Initialize oh-my-posh with error handling
        $ohMyPoshInit = oh-my-posh init pwsh --config $Config 2>$null
        if ($ohMyPoshInit) {
            Invoke-Expression $ohMyPoshInit
            if ($HostSupportsColor) { Write-Host "  Oh My Posh theme loaded ($(${ProfileTimer}.ElapsedMilliseconds)ms)" -ForegroundColor Green }
            else { Write-Host "  Oh My Posh theme loaded ($(${ProfileTimer}.ElapsedMilliseconds)ms)" }
        } else {
            if ($HostSupportsColor) { Write-Host "  Failed to initialize Oh My Posh theme" -ForegroundColor Yellow }
            else { Write-Host "  Failed to initialize Oh My Posh theme" }
        }
    } else {
        if ($HostSupportsColor) { Write-Host "  oh-my-posh not available, using default prompt" -ForegroundColor Yellow }
        else { Write-Host "  oh-my-posh not available, using default prompt" }
    }
} catch {
    Write-Warning "Failed to load Oh My Posh theme: $_"
}

# 5. Advanced lazy-load posh-git with background job support -----------
if ($HostSupportsColor) { Write-Host "  Setting up posh-git lazy loading..." -ForegroundColor Yellow }
else { Write-Host "  Setting up posh-git lazy loading..." }
$ProfileTimer.Restart()

try {
    # Only set up posh-git if git is available
    if (Test-CachedCommand 'git') {
        # Enhanced lazy loading with background job support and caching
        $Global:__PoshGitLoaded = $false
        
        # Function to load posh-git in background
        function Import-PoshGitAsync {
            if (-not $Global:__PoshGitLoaded -and -not (Get-Module posh-git)) {
                try {
                    # Check if we're in a git repository (cached)
                    $isGitRepo = $false
                    $gitCheckKey = "GitRepo_$PWD"
                    
                    if ($Global:__ProfileCache.PathTests.ContainsKey($gitCheckKey)) {
                        $cachedResult = $Global:__ProfileCache.PathTests[$gitCheckKey]
                        if ((Get-Date) - $cachedResult.Time -lt [TimeSpan]::FromMinutes(2)) {
                            $isGitRepo = $cachedResult.Result
                        } else {
                            $Global:__ProfileCache.PathTests.Remove($gitCheckKey)
                        }
                    }
                    
                    if (-not $Global:__ProfileCache.PathTests.ContainsKey($gitCheckKey)) {
                        $isGitRepo = Test-Path .git -ErrorAction SilentlyContinue
                        $Global:__ProfileCache.PathTests[$gitCheckKey] = @{ Result = $isGitRepo; Time = Get-Date }
                    }
                    
                    if ($isGitRepo) {
                        Import-Module posh-git -DisableNameChecking -ErrorAction SilentlyContinue
                        $Global:__PoshGitLoaded = $true
                    }
                } catch {
                    # Silently continue if posh-git fails to load
                }
            }
        }
        
        # Register multiple triggers for posh-git loading
        Register-EngineEvent PowerShell.OnIdle -SupportEvent -Action {
            Import-PoshGitAsync
        } | Out-Null
        
        # Also load on location change
        $ExecutionContext.SessionState.InvokeCommand.LocationChangedAction = {
            Import-PoshGitAsync
        }
        
        if ($HostSupportsColor) { Write-Host "  Enhanced posh-git lazy loading configured ($(${ProfileTimer}.ElapsedMilliseconds)ms)" -ForegroundColor Green }
        else { Write-Host "  Enhanced posh-git lazy loading configured ($(${ProfileTimer}.ElapsedMilliseconds)ms)" }
    } else {
        if ($HostSupportsColor) { Write-Host "  Git not available, skipping posh-git setup" -ForegroundColor Yellow }
        else { Write-Host "  Git not available, skipping posh-git setup" }
    }
} catch {
    Write-Warning "Failed to configure posh-git lazy loading: $_"
}

# 6. Quality-of-Life with performance monitoring ----------------------
if ($HostSupportsColor) { Write-Host "  Setting up quality-of-life functions..." -ForegroundColor Yellow }
else { Write-Host "  Setting up quality-of-life functions..." }
$ProfileTimer.Restart()

try {
    # Reload function with better error handling and performance tracking
    function global:reload {
        [CmdletBinding()]
        param()
        try {
            $reloadTimer = [System.Diagnostics.Stopwatch]::StartNew()
            . $PROFILE
            $reloadTimer.Stop()
            Write-Host "Profile reloaded in $($reloadTimer.ElapsedMilliseconds)ms" -ForegroundColor Green
        } catch {
            Write-Error "Failed to reload profile: $_"
        }
    }
    Set-Alias -Name rl -Value reload -Scope Global -ErrorAction SilentlyContinue

    # Enhanced alias management shortcuts with caching
    function global:aliases { 
        if (Get-Command Show-CustomAliases -ErrorAction SilentlyContinue) {
            Show-CustomAliases 
        } else {
            Get-Alias | Sort-Object Name
        }
    }
    
    function global:Test-Alias { 
        if (Get-Command Show-CustomAliases -ErrorAction SilentlyContinue) {
            Show-CustomAliases -ShowConflicts 
        } else {
            Write-Warning "Show-CustomAliases function not available"
        }
    }
    
    function global:Get-AllAliases { 
        if (Get-Command Show-CustomAliases -ErrorAction SilentlyContinue) {
            Show-CustomAliases -IncludeBuiltIn 
        } else {
            Get-Alias | Sort-Object Name
        }
    }
    
    # Performance monitoring functions
    function global:Get-ProfilePerformance {
        <#
        .SYNOPSIS
            Show profile performance statistics and cache information.
        
        .DESCRIPTION
            Displays detailed performance metrics for the PowerShell profile,
            including load times, cache statistics, and optimization suggestions.
        #>
        [CmdletBinding()]
        param()
        
        Write-Host "PowerShell Profile Performance Report" -ForegroundColor Cyan
        Write-Host "=====================================" -ForegroundColor Cyan
        
        # Basic system info
        Write-Host "PowerShell Version: $($PSVersionTable.PSVersion) ($($PSVersionTable.PSEdition))" -ForegroundColor White
        Write-Host "Profile Path: $PROFILE" -ForegroundColor Gray
        Write-Host "Repository Root: $RepoRoot" -ForegroundColor Gray
        Write-Host ""
        
        # Cache statistics
        if ($Global:__ProfileCache) {
            Write-Host "Cache Statistics:" -ForegroundColor Yellow
            $totalEntries = $Global:__ProfileCache.PathTests.Count + $Global:__ProfileCache.CommandTests.Count + $Global:__ProfileCache.ModuleAvailability.Count
            Write-Host "  Total Cache Entries: $totalEntries" -ForegroundColor Green
            Write-Host "  Path Tests: $($Global:__ProfileCache.PathTests.Count)" -ForegroundColor Green
            Write-Host "  Command Tests: $($Global:__ProfileCache.CommandTests.Count)" -ForegroundColor Green
            Write-Host "  Module Availability: $($Global:__ProfileCache.ModuleAvailability.Count)" -ForegroundColor Green
            
            if ($totalEntries -gt 50) {
                Write-Host "  Consider running Optimize-ProfileCache to clean up old entries" -ForegroundColor Yellow
            }
        }
        
        # Module status
        Write-Host ""
        Write-Host "Module Status:" -ForegroundColor Yellow
        $importantModules = @('Terminal-Icons', 'posh-git', 'PSReadLine')
        foreach ($module in $importantModules) {
            $loaded = Get-Module $module -ErrorAction SilentlyContinue
            $available = Get-Module -ListAvailable $module -ErrorAction SilentlyContinue
            
            if ($loaded) {
                Write-Host "  $module (loaded)" -ForegroundColor Green
            } elseif ($available) {
                Write-Host "  $module (available)" -ForegroundColor Yellow
            } else {
                Write-Host "  $module (not installed)" -ForegroundColor Red
            }
        }
        
        # Performance suggestions
        Write-Host ""
        Write-Host "Performance Suggestions:" -ForegroundColor Yellow
        
        if (-not (Test-Path (Join-Path $RepoRoot 'modules\CacheManagement.psm1'))) {
            Write-Host "  • Install cache management module for advanced cache control" -ForegroundColor Cyan
        }
        
        if ($Global:__ProfileCache.PathTests.Count -eq 0) {
            Write-Host "  • Path caching not active - may indicate first run" -ForegroundColor Cyan
        }
        
        Write-Host "  • Use 'Optimize-ProfileCache' to clean up old cache entries" -ForegroundColor Cyan
        Write-Host "  • Use 'perf' alias for quick performance check" -ForegroundColor Cyan
    }
    
    function global:Optimize-ProfileCache {
        <#
        .SYNOPSIS
            Optimize the profile cache for better performance.
        
        .DESCRIPTION
            Cleans up old cache entries and optimizes cache structure for improved performance.
        #>
        [CmdletBinding()]
        param(
            [Parameter()]
            [int]$MaxAgeMinutes = 60
        )
        
        if (-not $Global:__ProfileCache) {
            Write-Warning "Profile cache not initialized"
            return
        }
        
        Write-Host "Optimizing profile cache..." -ForegroundColor Cyan
        
        $cutoffTime = (Get-Date).AddMinutes(-$MaxAgeMinutes)
        $totalRemoved = 0
        
        @('PathTests', 'CommandTests', 'ModuleAvailability') | ForEach-Object {
            $cacheType = $_
            if ($Global:__ProfileCache.ContainsKey($cacheType)) {
                $cache = $Global:__ProfileCache[$cacheType]
                $beforeCount = $cache.Count
                
                $keysToRemove = $cache.Keys | Where-Object {
                    $cache[$_].Time -lt $cutoffTime
                }
                
                $keysToRemove | ForEach-Object { $cache.Remove($_) }
                $removed = $beforeCount - $cache.Count
                $totalRemoved += $removed
                
                if ($removed -gt 0) {
                    Write-Host "  Removed $removed old entries from $cacheType" -ForegroundColor Green
                }
            }
        }
        
        Write-Host "Cache optimization complete. Removed $totalRemoved entries." -ForegroundColor Green
    }
    
    # Alias for performance functions
    Set-Alias -Name perf -Value Get-ProfilePerformance -Scope Global -ErrorAction SilentlyContinue
    Set-Alias -Name optimize -Value Optimize-ProfileCache -Scope Global -ErrorAction SilentlyContinue
    
    if ($HostSupportsColor) { Write-Host "  Quality-of-life functions loaded ($(${ProfileTimer}.ElapsedMilliseconds)ms)" -ForegroundColor Green }
    else { Write-Host "  Quality-of-life functions loaded ($(${ProfileTimer}.ElapsedMilliseconds)ms)" }
} catch {
    Write-Warning "Failed to load quality-of-life functions: $_"
}

# Profile loading complete with cache cleanup
$ProfileTimer.Stop()

# Cache maintenance - cleanup old entries to prevent memory bloat
try {
    $cutoffTime = (Get-Date).AddMinutes(-30)
    @('PathTests', 'CommandTests', 'ModuleAvailability') | ForEach-Object {
        $cache = $Global:__ProfileCache[$_]
        $keysToRemove = $cache.Keys | Where-Object { 
            $cache[$_].Time -lt $cutoffTime 
        }
        $keysToRemove | ForEach-Object { $cache.Remove($_) }
    }
} catch {
    # Silently continue if cache cleanup fails
}

if ($HostSupportsColor) { 
    Write-Host "Profile loading complete! Total time: $($ProfileTimer.ElapsedMilliseconds)ms" -ForegroundColor Cyan
    Write-Host "PowerShell $($PSVersionTable.PSVersion) | $($PSVersionTable.PSEdition) Edition" -ForegroundColor Gray
    if ($Global:__ProfileCache.PathTests.Count + $Global:__ProfileCache.CommandTests.Count -gt 0) {
        Write-Host "Cache entries: $($Global:__ProfileCache.PathTests.Count + $Global:__ProfileCache.CommandTests.Count) items" -ForegroundColor Gray
    }
} else { 
    Write-Host "Profile loading complete! Total time: $($ProfileTimer.ElapsedMilliseconds)ms"
    Write-Host "PowerShell $($PSVersionTable.PSVersion) | $($PSVersionTable.PSEdition) Edition"
    if ($Global:__ProfileCache.PathTests.Count + $Global:__ProfileCache.CommandTests.Count -gt 0) {
        Write-Host "Cache entries: $($Global:__ProfileCache.PathTests.Count + $Global:__ProfileCache.CommandTests.Count) items"
    }
}

# Clean up variables
Remove-Variable -Name ProfileTimer, HostSupportsColor -ErrorAction SilentlyContinue
