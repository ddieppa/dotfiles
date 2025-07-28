# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a Windows PowerShell dotfiles repository that provides a comprehensive terminal customization solution with modular architecture, dynamic path handling, and Oh My Posh integration. The system is designed to work from any location and automatically handles OneDrive Documents redirection.

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
alias-check

# Show all aliases (including built-in)
alias-all
```

## Architecture

### Core Structure

The repository follows a modular architecture centered around `powershell/Profile.ps1`:

1. **Dynamic Path Resolution**: Uses `$PSScriptRoot` to work from any location, with fallback paths for common locations.

2. **Module Loading** (`modules/modules.ps1`): 
   - Installs required PowerShell modules: PSReadLine, Terminal-Icons, posh-git
   - Installs Oh My Posh via winget (not as a PowerShell module)
   - Handles module import with performance tracking

3. **Alias System** (`aliases/`):
   - `core.ps1` - Loaded first, contains `Set-SafeAlias` function and alias management utilities
   - Per-application alias files (git.ps1, dotnet.ps1, node.ps1, vscode.ps1, theme.ps1)
   - Auto-loaded by profile with conflict detection

4. **Enhanced Theme System**:
   - Interactive theme selector with keyboard navigation and pagination
   - Two-step selection: source (Personal/Built-in) then specific theme
   - Visual indicators with background highlighting for selected items
   - Themes stored in `prompt/` directory for personal themes
   - Configuration persisted in `.theme-config` file
   - Intelligent fallback to built-in themes
   - Comprehensive theme management functions in `aliases/theme.ps1`

5. **Profile Linking**:
   - Creates symbolic links for both `$PROFILE.CurrentUserAllHosts` and `$PROFILE.CurrentUserCurrentHost`
   - Ensures profile loads correctly in all PowerShell hosts

### Key Implementation Details

- **Performance Monitoring**: Profile loading includes detailed timing information for troubleshooting
- **Lazy Loading**: posh-git is loaded only when entering a Git repository
- **Error Handling**: Graceful fallbacks for missing modules, themes, or configurations
- **Conflict Prevention**: Custom `Set-SafeAlias` function prevents overwriting existing commands

### Theme Detection Priority

1. `.theme-config` file (themes set via management functions)
2. Environment variable `POSH_THEME` (set by Oh My Posh)
3. Debug output detection (fallback method)

## Development Notes

- Always test profile changes with `reload` command before committing
- When adding new alias files, ensure they don't conflict with existing commands
- Theme files must be valid Oh My Posh JSON format with `.omp.json` extension
- The installer handles both standard and OneDrive-redirected Documents folders
- Interactive theme selector requires a proper console environment for keyboard input
- The `Show-InteractiveMenu` function provides reusable UI components for other features