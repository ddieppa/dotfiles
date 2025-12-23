# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a Windows PowerShell dotfiles repository that provides a comprehensive terminal customization solution with modular architecture, dynamic path handling, and Oh My Posh integration. The system is designed to work from any location and automatically handles OneDrive Documents redirection.

### Key Features
- Advanced performance caching system for fast profile loading
- Modular alias system with conflict detection
- Interactive theme selector with keyboard navigation
- Lazy loading for git integration (posh-git)
- Profile optimization with JIT compilation support
- Comprehensive error handling and graceful fallbacks

## Common Commands

### Installation and Setup
```powershell
# Initial installation - creates symbolic links and installs dependencies
& D:\dotfiles\powershell\install.ps1

# Change Oh My Posh theme without full reinstallation
.\install.ps1 -ThemeOnly
```

### Profile Management
```powershell
# Reload profile after changes
rl  # or reload

# Edit profile in VS Code Insiders
code $PROFILE
```

### Theme Management
```powershell
# Interactive theme selector with enhanced UI
theme

# Interactive theme selector with specific filters
theme -Personal    # Personal themes only
theme -BuiltIn     # Built-in themes only

# List all available themes
theme -List

# Show current theme
theme-current

# Apply specific theme directly
theme -Name "paradox"

# Show theme help
theme-help
```

### Alias Management
```powershell
# Show custom aliases
aliases

# Check for alias conflicts
alias-check   # or Test-Alias

# Show all aliases (including built-in)
alias-all     # or Get-AllAliases

# Get alias conflicts
Get-AliasConflicts

# Available utility commands
which <command>   # Find command location
ll                # List files (Get-ChildItem)
la                # List all files including hidden
```

### Performance Monitoring
```powershell
# View profile performance statistics
perf              # or Get-ProfilePerformance

# Optimize profile cache
optimize          # or Optimize-ProfileCache

# Optimize with custom timeout (removes entries older than N minutes)
Optimize-ProfileCache -MaxAgeMinutes 30
```

## Architecture

### Core Structure

The repository follows a modular architecture centered around `powershell/Profile.ps1`:

1. **Double-Execution Prevention**:
   - Profile uses a guard variable to prevent duplicate loading in nested sessions
   - Prevents duplicate imports, alias definitions, and event registrations

2. **Performance Caching System** (`Profile.ps1:26-71`):
   - Global `$__ProfileCache` hashtable for caching module availability, path tests, and command tests
   - `Test-CachedPath` function: Caches file system tests with 5-minute timeout
   - `Test-CachedCommand` function: Caches command existence checks with 10-minute timeout
   - JIT compilation optimization via `System.Runtime.ProfileOptimization`
   - Automatic cache cleanup removes entries older than 30 minutes

3. **Dynamic Path Resolution** (`Profile.ps1:84-135`):
   - Uses `$PSScriptRoot` with symlink target resolution
   - Searches common locations: D:\dotfiles, C:\dotfiles, %USERPROFILE%\dotfiles
   - Results cached for 30 minutes
   - Fallback to hardcoded path if all else fails

4. **Module Loading** (`modules/modules.ps1`):
   - Installs required PowerShell modules: PSReadLine, Terminal-Icons, posh-git
   - Installs Oh My Posh via winget (not as a PowerShell module)
   - Handles module import with performance tracking
   - Conditional loading based on command availability

5. **Alias System** (`aliases/`):
   - `core.ps1` - Loaded first, contains `Set-SafeAlias` function and alias management utilities
   - Per-application alias files (git.ps1, dotnet.ps1, node.ps1, vscode.ps1, theme.ps1)
   - Auto-loaded by profile with conflict detection
   - `Show-CustomAliases` function dynamically discovers aliases from all .ps1 files
   - Supports read-only alias override with force option

6. **Enhanced Theme System** (`aliases/theme.ps1`):
   - Interactive theme selector with keyboard navigation and pagination
   - `Show-InteractiveMenu` function: Reusable UI component with page navigation
   - Two-step selection: source (Personal/Built-in) then specific theme
   - Visual indicators with background highlighting for selected items
   - Themes stored in `prompt/` directory for personal themes
   - Configuration persisted in `.theme-config` file
   - Theme list caching for improved performance
   - Intelligent fallback to built-in themes

7. **PSReadLine Bindings** (`psreadline/bindings.ps1`):
   - Custom key bindings for enhanced editing experience
   - Only loaded if PSReadLine module is available

8. **Lazy Loading for posh-git** (`Profile.ps1:344-405`):
   - Loads posh-git only when entering a Git repository
   - Uses PowerShell engine events (`PowerShell.OnIdle`)
   - Triggers on location changes via `LocationChangedAction`
   - Git repository detection results cached for 2 minutes
   - Prevents redundant module imports

9. **Profile Linking** (`install.ps1`):
   - Creates symbolic links for both `$PROFILE.CurrentUserAllHosts` and `$PROFILE.CurrentUserCurrentHost`
   - Ensures profile loads correctly in all PowerShell hosts
   - Supports `-ThemeOnly` flag for theme-only configuration

### Key Implementation Details

- **Performance Monitoring**:
  - Profile loading includes detailed timing information for each component
  - `Get-ProfilePerformance` (alias: `perf`) shows comprehensive performance report
  - Tracks cache hit rates and module load times
  - Provides optimization suggestions based on cache statistics

- **Lazy Loading**:
  - posh-git is loaded only when entering a Git repository
  - Triggered by PowerShell.OnIdle events and location changes
  - Reduces initial profile load time significantly

- **Error Handling**:
  - Graceful fallbacks for missing modules, themes, or configurations
  - All major operations wrapped in try-catch blocks
  - Warnings displayed but don't halt profile loading
  - Automatic fallback to built-in 'paradox' theme if custom themes unavailable

- **Conflict Prevention**:
  - Custom `Set-SafeAlias` function prevents overwriting existing commands
  - Supports force override for read-only aliases
  - `Show-CustomAliases -ShowConflicts` identifies conflicting aliases
  - Detailed conflict information including source and options

- **UTF-8 Encoding**:
  - Console output encoding set to UTF-8 (65001) for emoji support
  - Ensures proper display of Oh My Posh themes with special characters

### Theme Detection Priority

The profile loads themes in the following order (first found wins):

1. **`.theme-config` file** - Full path to theme file written by `theme` command or `install.ps1`
2. **First theme in `prompt/` folder** - Automatically selects first `.omp.json` file found
3. **Built-in 'paradox' theme** - Final fallback if no custom themes available

Theme configuration file location: `powershell/.theme-config`

## Development Notes

### Best Practices
- Always test profile changes with `reload` (or `rl`) command before committing
- Use `perf` command to monitor performance impact of changes
- Run `optimize` periodically to clean up old cache entries
- When adding new alias files, ensure they don't conflict with existing commands using `alias-check`

### Code Structure Guidelines
- All paths should use `Test-CachedPath` instead of `Test-Path` for better performance
- Command existence checks should use `Test-CachedCommand` instead of `Get-Command`
- New alias files must be placed in `powershell/aliases/` and use `Set-SafeAlias` function
- Theme files must be valid Oh My Posh JSON format with `.omp.json` extension
- Personal themes go in `powershell/prompt/` directory

### System Requirements
- PowerShell 5.1 or later (profile includes version check)
- The installer handles both standard and OneDrive-redirected Documents folders
- Interactive theme selector requires a proper console environment for keyboard input
- Oh My Posh must be installed via winget (not as PowerShell module)

### Reusable Components
- `Show-InteractiveMenu` function: Reusable UI component for keyboard-driven selection menus
  - Supports pagination (10 items per page)
  - Navigation: Arrow keys, PgUp/PgDown, Home/End, Esc to cancel
  - Returns selected object or $null if cancelled
- `Test-CachedPath` and `Test-CachedCommand`: Performance-optimized existence checks
- `Set-SafeAlias`: Conflict-safe alias creation with force override support

### File Locations
- Profile source: `powershell/Profile.ps1`
- Profile symlinks: `$PROFILE.CurrentUserAllHosts` and `$PROFILE.CurrentUserCurrentHost`
- Themes: `powershell/prompt/*.omp.json`
- Theme config: `powershell/.theme-config`
- Modules: `powershell/modules/modules.ps1`
- Aliases: `powershell/aliases/*.ps1`
- PSReadLine: `powershell/psreadline/bindings.ps1`

### Performance Optimization
- Global cache entries are automatically cleared after 30 minutes
- Path tests cached for 5 minutes
- Command tests cached for 10 minutes
- Theme configuration cached for 15 minutes
- Git repository checks cached for 2 minutes
- Use `Optimize-ProfileCache -MaxAgeMinutes N` to customize cleanup threshold

### Troubleshooting
- **Profile doesn't load**: Check if symlinks exist with `Get-Item $PROFILE | Select-Object Target`
- **Themes don't work**: Verify Oh My Posh installed with `oh-my-posh --version`
- **Performance is slow**: Run `perf` to see cache statistics and optimization suggestions
- **Aliases conflict**: Run `alias-check` to identify conflicts
- **Cache issues**: Run `optimize` to clear stale entries
- **Terminal-Icons XML error**: The profile will attempt to auto-fix on next reload. If it persists, run:
  ```powershell
  .\powershell\Fix-TerminalIcons.ps1
  ```
  Or manually:
  ```powershell
  Uninstall-Module Terminal-Icons -AllVersions -Force
  Install-Module Terminal-Icons -Scope CurrentUser -Force
  ```

## Available Aliases

### Core Aliases (`aliases/core.ps1`)
```powershell
ll                    # Get-ChildItem
la                    # Get-ChildItem -Force (show hidden files)
which <command>       # Get-Command -Name (find command location)
```

### Git Aliases (`aliases/git.ps1`)
```powershell
g                     # git
gst                   # git status
gcm                   # git commit
gps                   # git push
```

### .NET Aliases (`aliases/dotnet.ps1`)
```powershell
dn                    # dotnet
dnb                   # dotnet build
dnr                   # dotnet run
dnt                   # dotnet test
```

### Node/NPM Aliases (`aliases/node.ps1`)
```powershell
np                    # npm
ni                    # npm install
nr                    # npm run
nrb                   # npm run build
nrt                   # npm run test
```

### VS Code Aliases (`aliases/vscode.ps1`)
```powershell
code                  # code-insiders (VS Code Insiders)
```

### Theme Management Aliases (`aliases/theme.ps1`)
```powershell
theme                 # Interactive theme selector
theme -Personal       # Show personal themes only
theme -BuiltIn        # Show built-in themes only
theme -List           # List all themes
theme -Name <name>    # Apply specific theme
theme-current         # Show current theme
theme-help            # Show theme help
```

### Quality of Life Functions (`Profile.ps1`)
```powershell
reload / rl           # Reload PowerShell profile
aliases               # Show custom aliases
Test-Alias            # Show alias conflicts
Get-AllAliases        # Show all aliases (including built-in)
Get-AliasConflicts    # Show conflicting aliases
perf                  # Get-ProfilePerformance
optimize              # Optimize-ProfileCache
```

## Available Personal Themes

The repository includes several custom Oh My Posh themes in `powershell/prompt/`:
- amro.omp.json
- cloud-context.omp.json
- di4am0nd.omp.json
- minimal.omp.json
- paradox.omp.json
- powerline.omp.json
- robbyrussell.omp.json
- space.omp.json
- spaceship.omp.json
- star.omp.json
- the-unnamed.personal.omp.json

Use the interactive `theme` command to preview and select themes.

## Repository Structure

```
dotfiles/
├── powershell/                    # PowerShell configuration (this folder)
│   ├── Profile.ps1               # Main profile script with caching and performance optimizations
│   ├── install.ps1               # Installation script for creating symlinks and theme setup
│   ├── .theme-config             # Current theme configuration (generated)
│   ├── aliases/                  # Modular alias system
│   │   ├── core.ps1             # Core aliases and Set-SafeAlias function
│   │   ├── git.ps1              # Git shortcuts
│   │   ├── dotnet.ps1           # .NET CLI shortcuts
│   │   ├── node.ps1             # Node/NPM shortcuts
│   │   ├── vscode.ps1           # VS Code integration
│   │   └── theme.ps1            # Theme management functions
│   ├── modules/                  # PowerShell module management
│   │   ├── modules.ps1          # Main module loader (active)
│   │   ├── modules-optimized.ps1 # Optimized variant
│   │   └── modules-original.ps1  # Original implementation
│   ├── prompt/                   # Personal Oh My Posh themes
│   │   ├── *.omp.json           # Custom theme files
│   │   └── README.md            # Theme documentation
│   ├── psreadline/              # PSReadLine configuration
│   │   └── bindings.ps1         # Custom key bindings
│   └── docs/                     # Documentation
│       ├── Performance-Optimization-Guide.md
│       └── Terminal-Icons-Issues.md
├── git/                          # Git configuration
├── windows_terminal/             # Windows Terminal settings
├── bash/                         # Bash configuration
├── zsh/                          # Zsh configuration
├── CLAUDE.md                     # This file - guidance for Claude Code
└── README.md                     # Repository overview
```

## Related Documentation

- `powershell/README.md` - Detailed PowerShell setup guide
- `powershell/docs/Performance-Optimization-Guide.md` - Performance tuning tips
- `powershell/docs/Terminal-Icons-Issues.md` - Troubleshooting Terminal-Icons
- `powershell/prompt/README.md` - Theme customization guide