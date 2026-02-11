<#
.SYNOPSIS
Creates project-level links for AI tooling from shared `.agents` content.

.DESCRIPTION
Interactive by default:
 - Prompts for project root (defaults to current directory)
 - Shows a multi-select checklist of tools
 - Previews planned actions before applying (one action per source item per tool)

Non-interactive mode:
 - Requires -NonInteractive -ProjectRoot -Tools

.EXAMPLE
.\Link-SharedSkills.ps1

.EXAMPLE
.\Link-SharedSkills.ps1 -NonInteractive -ProjectRoot D:\src\work\metrc\metrc.webapp -Tools copilot-cli,gemini-cli
#>

[CmdletBinding()]
param(
    [string]$ProjectRoot,
    [Alias('SkillsSource')]
    [string]$AgentsSource = 'D:\dotfiles\.agents',
    [ValidateSet('copilot-cli', 'gemini-cli', 'cursor', 'antigravity', 'windsurf', 'vscode', 'claude', 'codex', 'opencode')]
    [string[]]$Tools,
    [ValidateSet('BackupReplace', 'Skip', 'ForceReplace')]
    [string]$ConflictPolicy = 'BackupReplace',
    [ValidateSet('SymlinkThenJunction', 'SymlinkOnly', 'JunctionOnly')]
    [string]$LinkStrategy = 'SymlinkThenJunction',
    [switch]$NonInteractive
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function New-ToolCatalog {
    [CmdletBinding()]
    param()

    @(
        [PSCustomObject]@{
            Key = 'copilot-cli'
            Label = 'GitHub Copilot CLI'
            RelativeDestination = '.github'
            CommandName = 'copilot'
        }
        [PSCustomObject]@{
            Key = 'gemini-cli'
            Label = 'Gemini CLI'
            RelativeDestination = '.gemini'
            CommandName = 'gemini'
        }
        [PSCustomObject]@{
            Key = 'cursor'
            Label = 'Cursor'
            RelativeDestination = '.cursor'
            CommandName = 'n/a'
        }
        [PSCustomObject]@{
            Key = 'antigravity'
            Label = 'Antigravity'
            RelativeDestination = '.agent'
            CommandName = 'n/a'
        }
        [PSCustomObject]@{
            Key = 'windsurf'
            Label = 'Windsurf'
            RelativeDestination = '.windsurf'
            CommandName = 'n/a'
        }
        [PSCustomObject]@{
            Key = 'vscode'
            Label = 'VS Code'
            RelativeDestination = '.vscode'
            CommandName = 'n/a'
        }
        [PSCustomObject]@{
            Key = 'claude'
            Label = 'Claude Code'
            RelativeDestination = '.claude'
            CommandName = 'n/a'
        }
        [PSCustomObject]@{
            Key = 'codex'
            Label = 'OpenAI Codex'
            RelativeDestination = '.codex'
            CommandName = 'n/a'
        }
        [PSCustomObject]@{
            Key = 'opencode'
            Label = 'OpenCode'
            RelativeDestination = '.opencode'
            CommandName = 'n/a'
        }
    )
}

function Get-Style {
    [CmdletBinding()]
    param()

    $hasStyle = $false
    try {
        $null = $PSStyle.Foreground.BrightCyan
        $hasStyle = $true
    } catch {
        $hasStyle = $false
    }

    if ($hasStyle) {
        return @{
            Reset = $PSStyle.Reset
            Title = $PSStyle.Foreground.BrightCyan
            Accent = $PSStyle.Foreground.BrightBlue
            Success = $PSStyle.Foreground.BrightGreen
            Warning = $PSStyle.Foreground.BrightYellow
            Error = $PSStyle.Foreground.BrightRed
            Muted = $PSStyle.Foreground.BrightBlack
            Selected = $PSStyle.Foreground.BrightMagenta
        }
    }

    return @{
        Reset = ''
        Title = ''
        Accent = ''
        Success = ''
        Warning = ''
        Error = ''
        Muted = ''
        Selected = ''
    }
}

function Write-Banner {
    [CmdletBinding()]
    param(
        [hashtable]$Style
    )

    Clear-Host
    Write-Host "$($Style.Title)Shared Agents Link Manager$($Style.Reset)"
    Write-Host "$($Style.Muted)--------------------------------$($Style.Reset)"
    Write-Host "$($Style.Muted)Create project-scoped links to centralized .agents content$($Style.Reset)"
    Write-Host ''
}

function Normalize-Path {
    [CmdletBinding()]
    param(
        [AllowNull()]
        [string]$Path
    )

    if ([string]::IsNullOrWhiteSpace($Path)) {
        return $null
    }

    try {
        $full = [System.IO.Path]::GetFullPath($Path)
    } catch {
        $full = $Path
    }

    return $full.TrimEnd('\', '/')
}

function Test-SamePath {
    [CmdletBinding()]
    param(
        [AllowNull()][string]$Left,
        [AllowNull()][string]$Right
    )

    if ([string]::IsNullOrWhiteSpace($Left) -or [string]::IsNullOrWhiteSpace($Right)) {
        return $false
    }

    return [string]::Equals(
        (Normalize-Path -Path $Left),
        (Normalize-Path -Path $Right),
        [System.StringComparison]::OrdinalIgnoreCase
    )
}

function Resolve-LinkTarget {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [System.IO.FileSystemInfo]$Item
    )

    $rawTarget = $null
    try {
        $rawTarget = $Item.Target
    } catch {
        $rawTarget = $null
    }

    if ($rawTarget -is [System.Array]) {
        $rawTarget = $rawTarget | Select-Object -First 1
    }

    if ([string]::IsNullOrWhiteSpace($rawTarget)) {
        return $null
    }

    if ([System.IO.Path]::IsPathRooted($rawTarget)) {
        return Normalize-Path -Path $rawTarget
    }

    $parent = Split-Path -Path $Item.FullName -Parent
    $combined = Join-Path -Path $parent -ChildPath $rawTarget
    return Normalize-Path -Path $combined
}

function Get-DestinationState {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$DestinationPath,
        [Parameter(Mandatory)]
        [string]$SourcePath
    )

    $result = [PSCustomObject]@{
        Exists = $false
        IsDirectory = $false
        IsReparsePoint = $false
        LinkType = 'None'
        CurrentTarget = $null
        State = 'Missing'
    }

    if (-not (Test-Path -LiteralPath $DestinationPath)) {
        return $result
    }

    $item = Get-Item -LiteralPath $DestinationPath -Force
    $isReparse = [bool]($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint)
    $isDir = [bool]$item.PSIsContainer
    $target = $null
    $linkType = 'None'

    if ($isReparse) {
        $target = Resolve-LinkTarget -Item $item
        if ($item.LinkType) {
            $linkType = [string]$item.LinkType
        } else {
            $linkType = 'ReparsePoint'
        }
    }

    $state = 'ExistingPath'
    if ($isReparse -and (Test-SamePath -Left $target -Right $SourcePath)) {
        $state = 'AlreadyLinked'
    } elseif ($isReparse) {
        $state = 'ExistingLinkDifferentTarget'
    } elseif (-not $isDir) {
        $state = 'ExistingFile'
    } else {
        $state = 'ExistingDirectory'
    }

    [PSCustomObject]@{
        Exists = $true
        IsDirectory = $isDir
        IsReparsePoint = $isReparse
        LinkType = $linkType
        CurrentTarget = $target
        State = $state
    }
}

function Get-PlannedAction {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [pscustomobject]$DestinationState,
        [Parameter(Mandatory)]
        [ValidateSet('BackupReplace', 'Skip', 'ForceReplace')]
        [string]$Policy
    )

    if ($DestinationState.State -eq 'Missing') {
        return 'CreateLink'
    }

    if ($DestinationState.State -eq 'AlreadyLinked') {
        return 'NoChangeAlreadyLinked'
    }

    switch ($Policy) {
        'Skip' { return 'SkipExisting' }
        'BackupReplace' { return 'BackupThenReplace' }
        'ForceReplace' { return 'ReplaceExisting' }
    }

    return 'ReplaceExisting'
}

function New-LinkPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$DestinationPath,
        [Parameter(Mandatory)][string]$SourcePath,
        [Parameter(Mandatory)][bool]$SourceIsDirectory,
        [Parameter(Mandatory)]
        [ValidateSet('SymlinkThenJunction', 'SymlinkOnly', 'JunctionOnly')]
        [string]$Strategy
    )

    $parent = Split-Path -Path $DestinationPath -Parent
    if (-not (Test-Path -LiteralPath $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }

    if ($Strategy -eq 'JunctionOnly') {
        if (-not $SourceIsDirectory) {
            throw "JunctionOnly is not supported for file targets: $SourcePath"
        }
        New-Item -ItemType Junction -Path $DestinationPath -Target $SourcePath -Force | Out-Null
        return 'Junction'
    }

    if ($Strategy -eq 'SymlinkOnly') {
        New-Item -ItemType SymbolicLink -Path $DestinationPath -Target $SourcePath -Force | Out-Null
        return 'SymbolicLink'
    }

    try {
        New-Item -ItemType SymbolicLink -Path $DestinationPath -Target $SourcePath -Force | Out-Null
        return 'SymbolicLink'
    } catch {
        if (-not $SourceIsDirectory) {
            throw
        }
        New-Item -ItemType Junction -Path $DestinationPath -Target $SourcePath -Force | Out-Null
        return 'Junction'
    }
}

function New-BackupPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$OriginalPath
    )

    $timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
    $candidate = "$OriginalPath.bak-$timestamp"
    $counter = 1
    while (Test-Path -LiteralPath $candidate) {
        $candidate = "$OriginalPath.bak-$timestamp-$counter"
        $counter++
    }
    return $candidate
}

function Read-ProjectRoot {
    [CmdletBinding()]
    param(
        [hashtable]$Style
    )

    $defaultRoot = (Get-Location).Path
    while ($true) {
        Write-Host "$($Style.Accent)Project root$($Style.Reset) [$defaultRoot]:" -NoNewline
        $inputValue = Read-Host
        $candidate = if ([string]::IsNullOrWhiteSpace($inputValue)) { $defaultRoot } else { $inputValue.Trim() }

        try {
            $full = Normalize-Path -Path $candidate
        } catch {
            Write-Host "$($Style.Error)Invalid path syntax.$($Style.Reset)"
            continue
        }

        if (Test-Path -LiteralPath $full -PathType Container) {
            return $full
        }

        Write-Host "$($Style.Warning)Path not found or not a directory: $full$($Style.Reset)"
    }
}

function Show-MultiSelectTools {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][array]$ToolCatalog,
        [Parameter(Mandatory)][hashtable]$Style
    )

    $index = 0
    $selected = @{}
    foreach ($tool in $ToolCatalog) {
        $selected[$tool.Key] = $false
    }

    while ($true) {
        Write-Banner -Style $Style
        Write-Host "$($Style.Accent)Select tools (multi-select)$($Style.Reset)"
        Write-Host "$($Style.Muted)Use Up/Down, Space toggle, A toggle all, Enter confirm, Esc cancel.$($Style.Reset)"
        Write-Host ''

        for ($i = 0; $i -lt $ToolCatalog.Count; $i++) {
            $tool = $ToolCatalog[$i]
            $isCurrent = ($i -eq $index)
            $isSelected = $selected[$tool.Key]
            $marker = if ($isSelected) { '[x]' } else { '[ ]' }
            $line = '{0} {1,-16} ({2}) -> {3}' -f $marker, $tool.Label, $tool.Key, $tool.RelativeDestination

            if ($isCurrent) {
                Write-Host "$($Style.Selected)> $line$($Style.Reset)"
            } else {
                Write-Host "  $line"
            }
        }

        $selectedCount = @($selected.GetEnumerator() | Where-Object { $_.Value }).Count
        Write-Host ''
        Write-Host "$($Style.Accent)Selected:$($Style.Reset) $selectedCount"

        $key = [System.Console]::ReadKey($true)
        switch ($key.Key) {
            'UpArrow' {
                if ($index -gt 0) { $index-- }
            }
            'DownArrow' {
                if ($index -lt ($ToolCatalog.Count - 1)) { $index++ }
            }
            'Spacebar' {
                $currentKey = $ToolCatalog[$index].Key
                $selected[$currentKey] = -not $selected[$currentKey]
            }
            'A' {
                $allSelected = (@($selected.Values | Where-Object { -not $_ }).Count -eq 0)
                foreach ($tool in $ToolCatalog) {
                    $selected[$tool.Key] = -not $allSelected
                }
            }
            'Enter' {
                $final = @($ToolCatalog | Where-Object { $selected[$_.Key] } | ForEach-Object { $_.Key })
                if ($final.Count -gt 0) {
                    return $final
                }
            }
            'Escape' {
                return $null
            }
        }
    }
}

function BuildPlannedActions {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ResolvedProjectRoot,
        [Parameter(Mandatory)][string]$ResolvedSource,
        [Parameter(Mandatory)][string[]]$SelectedTools,
        [Parameter(Mandatory)][array]$ToolCatalog,
        [Parameter(Mandatory)][array]$SourceEntries,
        [Parameter(Mandatory)][string]$Policy
    )

    $toolByKey = @{}
    foreach ($item in $ToolCatalog) {
        $toolByKey[$item.Key] = $item
    }

    $actions = @()
    foreach ($toolKey in $SelectedTools) {
        $tool = $toolByKey[$toolKey]
        $toolRoot = Normalize-Path -Path (Join-Path -Path $ResolvedProjectRoot -ChildPath $tool.RelativeDestination)
        foreach ($sourceEntry in $SourceEntries) {
            $sourcePath = Normalize-Path -Path $sourceEntry.FullName
            $destPath = Normalize-Path -Path (Join-Path -Path $toolRoot -ChildPath $sourceEntry.Name)
            $state = Get-DestinationState -DestinationPath $destPath -SourcePath $sourcePath
            $planned = Get-PlannedAction -DestinationState $state -Policy $Policy

            $actions += [PSCustomObject]@{
                SelectedAs = $tool.Key
                ToolLabel = $tool.Label
                SourceItem = $sourceEntry.Name
                SourcePath = $sourcePath
                SourceIsDirectory = [bool]$sourceEntry.PSIsContainer
                DestinationPath = $destPath
                EffectiveDestination = ($tool.RelativeDestination + '\' + $sourceEntry.Name)
                CurrentState = $state.State
                PlannedAction = $planned
                CurrentTarget = $state.CurrentTarget
                LinkType = $state.LinkType
                Exists = $state.Exists
            }
        }
    }

    return $actions | Sort-Object DestinationPath
}

function Show-Preview {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][array]$Actions,
        [Parameter(Mandatory)][hashtable]$Style
    )

    Write-Banner -Style $Style
    Write-Host "$($Style.Accent)Planned actions$($Style.Reset)"
    Write-Host ''

    $preview = $Actions | Select-Object `
        SelectedAs, `
        SourceItem, `
        EffectiveDestination, `
        CurrentState, `
        PlannedAction, `
        DestinationPath

    $preview | Format-Table -AutoSize | Out-String | Write-Host
}

function Read-Confirmation {
    [CmdletBinding()]
    param(
        [hashtable]$Style
    )

    Write-Host "$($Style.Accent)Apply these actions? (Y/N)$($Style.Reset): " -NoNewline
    $answer = Read-Host
    return ($answer -match '^(y|yes)$')
}

function Invoke-Actions {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][array]$Actions,
        [Parameter(Mandatory)]
        [ValidateSet('BackupReplace', 'Skip', 'ForceReplace')]
        [string]$Policy,
        [Parameter(Mandatory)]
        [ValidateSet('SymlinkThenJunction', 'SymlinkOnly', 'JunctionOnly')]
        [string]$Strategy
    )

    $results = @()
    foreach ($action in $Actions) {
        $status = 'Unknown'
        $linkKind = $null
        $backupPath = $null
        $message = $null

        try {
            $state = Get-DestinationState -DestinationPath $action.DestinationPath -SourcePath $action.SourcePath

            if ($state.State -eq 'AlreadyLinked') {
                $status = 'AlreadyLinked'
            } elseif ($state.Exists -and $Policy -eq 'Skip') {
                $status = 'Skipped'
                $message = 'Destination exists and policy is Skip.'
            } else {
                if ($state.Exists) {
                    if ($Policy -eq 'BackupReplace') {
                        $backupPath = New-BackupPath -OriginalPath $action.DestinationPath
                        Move-Item -LiteralPath $action.DestinationPath -Destination $backupPath -Force
                    } else {
                        Remove-Item -LiteralPath $action.DestinationPath -Recurse -Force
                    }
                }

                $linkKind = New-LinkPath -DestinationPath $action.DestinationPath -SourcePath $action.SourcePath -SourceIsDirectory $action.SourceIsDirectory -Strategy $Strategy
                if ($backupPath) {
                    $status = "BackedUpAndCreated$linkKind"
                } else {
                    $status = "Created$linkKind"
                }
            }
        } catch {
            $status = 'Failed'
            $message = $_.Exception.Message
        }

        $results += [PSCustomObject]@{
            SelectedAs = $action.SelectedAs
            SourceItem = $action.SourceItem
            EffectiveDestination = $action.EffectiveDestination
            DestinationPath = $action.DestinationPath
            SourcePath = $action.SourcePath
            Status = $status
            BackupPath = $backupPath
            LinkType = $linkKind
            Message = $message
        }
    }

    return $results
}

function Show-Results {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][array]$Results,
        [Parameter(Mandatory)][hashtable]$Style
    )

    Write-Host ''
    Write-Host "$($Style.Accent)Execution results$($Style.Reset)"
    Write-Host "$($Style.Muted)-----------------$($Style.Reset)"

    $table = $Results | Select-Object SelectedAs, SourceItem, EffectiveDestination, Status, DestinationPath
    $table | Format-Table -AutoSize | Out-String | Write-Host

    $summary = $Results | Group-Object -Property Status | Sort-Object Name
    Write-Host "$($Style.Accent)Summary$($Style.Reset)"
    foreach ($group in $summary) {
        $color = if ($group.Name -eq 'Failed') { $Style.Error } elseif ($group.Name -like '*Created*' -or $group.Name -eq 'AlreadyLinked' -or $group.Name -eq 'Skipped') { $Style.Success } else { $Style.Muted }
        Write-Host "$color$($group.Name): $($group.Count)$($Style.Reset)"
    }
}

$style = Get-Style
$toolCatalog = New-ToolCatalog
$toolKeys = @($toolCatalog | ForEach-Object { $_.Key })

$resolvedSource = Normalize-Path -Path $AgentsSource
if (-not (Test-Path -LiteralPath $resolvedSource -PathType Container)) {
    throw "Agents source does not exist or is not a directory: $resolvedSource"
}

$sourceEntries = @(Get-ChildItem -LiteralPath $resolvedSource -Force | Sort-Object Name)
if ($sourceEntries.Count -eq 0) {
    throw "Agents source is empty. Nothing to link: $resolvedSource"
}

if ($NonInteractive) {
    if (-not $ProjectRoot) {
        throw 'Non-interactive mode requires -ProjectRoot.'
    }
    if (-not $Tools -or $Tools.Count -eq 0) {
        throw 'Non-interactive mode requires at least one -Tools value.'
    }
}

if (-not $ProjectRoot) {
    $ProjectRoot = Read-ProjectRoot -Style $style
}

$resolvedProjectRoot = Normalize-Path -Path $ProjectRoot
if (-not (Test-Path -LiteralPath $resolvedProjectRoot -PathType Container)) {
    throw "Project root does not exist or is not a directory: $resolvedProjectRoot"
}

$selectedTools = @()
if ($Tools -and $Tools.Count -gt 0) {
    $selectedTools = @($Tools)
} else {
    $selectedTools = Show-MultiSelectTools -ToolCatalog $toolCatalog -Style $style
    if (-not $selectedTools -or $selectedTools.Count -eq 0) {
        Write-Host "$($style.Warning)No tools selected. Nothing to do.$($style.Reset)"
        exit 0
    }
}

# Keep the first occurrence of each tool key so repeated CLI values do not create repeated actions.
$seenTools = New-Object System.Collections.Generic.HashSet[string]([System.StringComparer]::OrdinalIgnoreCase)
$uniqueSelectedTools = New-Object System.Collections.Generic.List[string]
foreach ($toolKey in $selectedTools) {
    if ($seenTools.Add($toolKey)) {
        $uniqueSelectedTools.Add($toolKey) | Out-Null
    }
}
$selectedTools = @($uniqueSelectedTools)

$unknownTools = @($selectedTools | Where-Object { $toolKeys -notcontains $_ })
if ($unknownTools.Count -gt 0) {
    throw "Unknown tool key(s): $($unknownTools -join ', ')"
}

$actions = BuildPlannedActions `
    -ResolvedProjectRoot $resolvedProjectRoot `
    -ResolvedSource $resolvedSource `
    -SelectedTools $selectedTools `
    -ToolCatalog $toolCatalog `
    -SourceEntries $sourceEntries `
    -Policy $ConflictPolicy

if (-not $NonInteractive) {
    Show-Preview -Actions $actions -Style $style
    if (-not (Read-Confirmation -Style $style)) {
        Write-Host "$($style.Warning)Cancelled. No changes were made.$($style.Reset)"
        exit 0
    }
}

$results = Invoke-Actions -Actions $actions -Policy $ConflictPolicy -Strategy $LinkStrategy
Show-Results -Results $results -Style $style

$hasFailure = @($results | Where-Object { $_.Status -eq 'Failed' }).Count -gt 0
if ($hasFailure) {
    exit 1
}

exit 0
