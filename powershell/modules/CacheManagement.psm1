# PowerShell Profile Cache Management Utilities
# Provides functions to manage, inspect, and optimize the profile cache

#Requires -Version 5.1

function Get-ProfileCacheStats {
    <#
    .SYNOPSIS
        Display current profile cache statistics and health information.
    
    .DESCRIPTION
        Shows detailed information about the current state of the profile cache,
        including entry counts, memory usage estimates, and cache hit ratios.
    
    .EXAMPLE
        Get-ProfileCacheStats
        
        Displays cache statistics in a formatted table.
    #>
    [CmdletBinding()]
    param()
    
    if (-not $Global:__ProfileCache) {
        Write-Warning "Profile cache is not initialized"
        return
    }
    
    $stats = @{
        PathTestEntries = $Global:__ProfileCache.PathTests.Count
        CommandTestEntries = $Global:__ProfileCache.CommandTests.Count
        ModuleAvailabilityEntries = $Global:__ProfileCache.ModuleAvailability.Count
        TotalEntries = 0
        OldestEntry = $null
        NewestEntry = $null
        CacheAge = $null
    }
    
    # Calculate total entries
    $stats.TotalEntries = $stats.PathTestEntries + $stats.CommandTestEntries + $stats.ModuleAvailabilityEntries
    
    # Find oldest and newest entries
    $allEntries = @()
    $allEntries += $Global:__ProfileCache.PathTests.Values
    $allEntries += $Global:__ProfileCache.CommandTests.Values
    $allEntries += $Global:__ProfileCache.ModuleAvailability.Values
    
    if ($allEntries.Count -gt 0) {
        $stats.OldestEntry = ($allEntries | Sort-Object Time | Select-Object -First 1).Time
        $stats.NewestEntry = ($allEntries | Sort-Object Time | Select-Object -Last 1).Time
        $stats.CacheAge = (Get-Date) - $stats.OldestEntry
    }
    
    # Display formatted output
    Write-Host "Profile Cache Statistics" -ForegroundColor Cyan
    Write-Host "========================" -ForegroundColor Cyan
    Write-Host "Path Tests: $($stats.PathTestEntries)" -ForegroundColor Green
    Write-Host "Command Tests: $($stats.CommandTestEntries)" -ForegroundColor Green
    Write-Host "Module Availability: $($stats.ModuleAvailabilityEntries)" -ForegroundColor Green
    Write-Host "Total Entries: $($stats.TotalEntries)" -ForegroundColor Yellow
    
    if ($stats.OldestEntry) {
        Write-Host "Cache Age: $($stats.CacheAge.TotalMinutes.ToString('F1')) minutes" -ForegroundColor Gray
        Write-Host "Oldest Entry: $($stats.OldestEntry.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor Gray
        Write-Host "Newest Entry: $($stats.NewestEntry.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor Gray
    }
}

function Clear-ProfileCache {
    <#
    .SYNOPSIS
        Clear all or specific parts of the profile cache.
    
    .DESCRIPTION
        Removes cached entries to free memory or force fresh data retrieval.
        Can target specific cache types or clear everything.
    
    .PARAMETER CacheType
        Specific cache type to clear. Valid values: PathTests, CommandTests, ModuleAvailability, All
    
    .PARAMETER OlderThan
        Clear entries older than the specified timespan (e.g., "30m", "1h", "2d")
    
    .EXAMPLE
        Clear-ProfileCache -CacheType All
        
        Clears all cache entries.
    
    .EXAMPLE
        Clear-ProfileCache -CacheType PathTests -OlderThan "1h"
        
        Clears path test entries older than 1 hour.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter()]
        [ValidateSet('PathTests', 'CommandTests', 'ModuleAvailability', 'All')]
        [string]$CacheType = 'All',
        
        [Parameter()]
        [string]$OlderThan
    )
    
    if (-not $Global:__ProfileCache) {
        Write-Warning "Profile cache is not initialized"
        return
    }
    
    $cutoffTime = $null
    if ($OlderThan) {
        try {
            $cutoffTime = (Get-Date) - [TimeSpan]::Parse($OlderThan)
        } catch {
            Write-Error "Invalid time format: $OlderThan. Use format like '30m', '1h', '2d'"
            return
        }
    }
    
    $cachesToClear = if ($CacheType -eq 'All') {
        @('PathTests', 'CommandTests', 'ModuleAvailability')
    } else {
        @($CacheType)
    }
    
    foreach ($cache in $cachesToClear) {
        if ($Global:__ProfileCache.ContainsKey($cache)) {
            $cacheObj = $Global:__ProfileCache[$cache]
            $beforeCount = $cacheObj.Count
            
            if ($cutoffTime) {
                # Clear only old entries
                $keysToRemove = $cacheObj.Keys | Where-Object {
                    $cacheObj[$_].Time -lt $cutoffTime
                }
                
                if ($PSCmdlet.ShouldProcess("$($keysToRemove.Count) entries from $cache cache", "Remove")) {
                    $keysToRemove | ForEach-Object { $cacheObj.Remove($_) }
                    $afterCount = $cacheObj.Count
                    Write-Host "Cleared $($beforeCount - $afterCount) old entries from $cache cache" -ForegroundColor Green
                }
            } else {
                # Clear all entries
                if ($PSCmdlet.ShouldProcess("All $beforeCount entries from $cache cache", "Remove")) {
                    $cacheObj.Clear()
                    Write-Host "Cleared all $beforeCount entries from $cache cache" -ForegroundColor Green
                }
            }
        }
    }
}

function Get-ProfileCacheEntries {
    <#
    .SYNOPSIS
        List specific entries in the profile cache for inspection.
    
    .DESCRIPTION
        Shows detailed information about cached entries, useful for debugging
        and understanding cache behavior.
    
    .PARAMETER CacheType
        Type of cache to inspect. Valid values: PathTests, CommandTests, ModuleAvailability
    
    .PARAMETER Pattern
        Filter entries by key pattern (supports wildcards)
    
    .EXAMPLE
        Get-ProfileCacheEntries -CacheType PathTests
        
        Shows all path test cache entries.
    
    .EXAMPLE
        Get-ProfileCacheEntries -CacheType CommandTests -Pattern "*git*"
        
        Shows command test entries with "git" in the key.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('PathTests', 'CommandTests', 'ModuleAvailability')]
        [string]$CacheType,
        
        [Parameter()]
        [string]$Pattern = '*'
    )
    
    if (-not $Global:__ProfileCache -or -not $Global:__ProfileCache.ContainsKey($CacheType)) {
        Write-Warning "Cache type '$CacheType' not found or not initialized"
        return
    }
    
    $cache = $Global:__ProfileCache[$CacheType]
    $entries = $cache.Keys | Where-Object { $_ -like $Pattern } | ForEach-Object {
        [PSCustomObject]@{
            Key = $_
            Result = $cache[$_].Result
            CachedTime = $cache[$_].Time
            Age = (Get-Date) - $cache[$_].Time
        }
    } | Sort-Object CachedTime -Descending
    
    if ($entries) {
        $entries | Format-Table -AutoSize
    } else {
        Write-Host "No entries found matching pattern '$Pattern' in $CacheType cache" -ForegroundColor Yellow
    }
}

function Optimize-ProfileCache {
    <#
    .SYNOPSIS
        Optimize the profile cache by removing stale entries and defragmenting.
    
    .DESCRIPTION
        Performs maintenance on the profile cache to improve performance and reduce memory usage.
        Removes expired entries and reorganizes cache structures.
    
    .PARAMETER MaxAge
        Maximum age for cache entries (default: 1 hour)
    
    .PARAMETER Verbose
        Show detailed optimization information
    
    .EXAMPLE
        Optimize-ProfileCache
        
        Performs standard cache optimization.
    
    .EXAMPLE
        Optimize-ProfileCache -MaxAge "30m" -Verbose
        
        Optimizes cache with 30-minute max age and shows details.
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [TimeSpan]$MaxAge = [TimeSpan]::FromHours(1),
        
        [Parameter()]
        [switch]$Force
    )
    
    if (-not $Global:__ProfileCache) {
        Write-Warning "Profile cache is not initialized"
        return
    }
    
    Write-Host "Optimizing profile cache..." -ForegroundColor Cyan
    
    $cutoffTime = (Get-Date) - $MaxAge
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
                Write-Verbose "Removed $removed expired entries from $cacheType cache"
            }
        }
    }
    
    # Update last cache time
    $Global:__ProfileCache.LastCacheTime = Get-Date
    
    Write-Host "✓ Cache optimization complete. Removed $totalRemoved expired entries." -ForegroundColor Green
    
    if ($VerbosePreference -eq 'Continue') {
        Get-ProfileCacheStats
    }
}

# Export all functions
Export-ModuleMember -Function Get-ProfileCacheStats, Clear-ProfileCache, Get-ProfileCacheEntries, Optimize-ProfileCache
