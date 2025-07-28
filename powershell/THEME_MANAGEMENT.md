# Oh My Posh Theme Management

This PowerShell profile includes comprehensive theme management functions for Oh My Posh, allowing you to easily switch between personal and built-in themes.

## Features

### 🎨 Interactive Theme Selection
- Browse and select from personal and built-in themes
- Visual indicators for theme types (📁 Personal, 🎨 Built-in)
- Persistent theme configuration across sessions

### 📁 Personal Theme Support
- Automatically detects themes in `dotfiles/powershell/prompt/` folder
- Personal themes take priority when names conflict with built-in themes
- Easy management of your custom themes

### 🔧 Advanced Options
- Filter by theme type (personal only, built-in only)
- Direct theme application by name
- Current theme information display
- Comprehensive help system

## Available Commands

| Command | Description |
|---------|-------------|
| `theme` | Interactive theme selector |
| `theme -List` | List all available themes |
| `theme -Personal` | Show only personal themes |
| `theme -BuiltIn` | Show only built-in themes |
| `theme -Name <name>` | Apply specific theme by name |
| `theme-current` | Show currently active theme |
| `theme-help` | Show help information |

## Usage Examples

### Interactive Selection
```powershell
# Browse and select from all themes
theme

# Select from personal themes only
theme -Personal

# Select from built-in themes only
theme -BuiltIn
```

### Direct Theme Application
```powershell
# Apply a specific theme by name
theme -Name "paradox"

# Apply a personal theme (takes priority if exists)
theme -Name "my-custom-theme"
```

### Information Commands
```powershell
# List all available themes
theme -List

# Show current active theme
theme-current

# Show help
theme-help
```

## Theme Types

### 📁 Personal Themes
- Located in: `dotfiles/powershell/prompt/`
- File format: `*.omp.json`
- Take priority when names conflict with built-in themes
- Managed through your dotfiles repository

### 🎨 Built-in Themes
- Located in: `$env:POSH_THEMES_PATH`
- Provided by Oh My Posh installation
- Automatically updated with Oh My Posh updates
- 120+ themes available

## Theme Detection

The `theme-current` command uses multiple detection methods to identify the active theme:

### Detection Priority
1. **Config file (.theme-config)** - Themes set via the theme management functions
2. **Environment variable (POSH_THEME)** - Automatically set by Oh My Posh
3. **Debug output detection** - Fallback method using Oh My Posh debug information

### Theme Types
- **📁 Personal** - Custom themes in your `dotfiles/powershell/prompt/` folder
- **🎨 Built-in** - Oh My Posh included themes from `$env:POSH_THEMES_PATH`
- **⚙️ Custom** - Themes from other locations

### When No Theme is Detected
If no theme configuration is found, it could mean:
- Oh My Posh is using a built-in default theme
- Theme is configured directly in your PowerShell profile
- Oh My Posh is not properly initialized

Use `oh-my-posh debug --plain` for detailed diagnostic information.

## Configuration

### Theme Persistence
The selected theme is saved to `.theme-config` file in your PowerShell profile directory and automatically loaded on profile startup.

### Multiple Detection Methods
The system can detect currently active themes even when not set through these functions, providing comprehensive theme information regardless of how the theme was configured.

### Profile Integration
The theme management is integrated into the PowerShell profile at:
- `dotfiles/powershell/aliases/theme.ps1` - Theme management functions
- `dotfiles/powershell/aliases/core.ps1` - Core utilities and alias management
- `dotfiles/powershell/Profile.ps1` - Auto-loading logic

## Implementation Details

### Best Practices (Microsoft Documentation)
- Uses proper PowerShell cmdlet structure with parameters
- Implements comprehensive help with `.SYNOPSIS` and `.DESCRIPTION`
- Follows PowerShell naming conventions
- Error handling for missing files and invalid themes

### Oh My Posh Integration
- Uses official Oh My Posh commands: `oh-my-posh init pwsh --config`
- Supports both theme names and full file paths
- Maintains compatibility with Oh My Posh updates
- Handles UTF-8 encoding issues properly

### User Experience
- Color-coded output for better readability
- Clear status messages and progress indicators
- Graceful error handling with helpful messages
- Consistent iconography (📁 for personal, 🎨 for built-in)

## Troubleshooting

### Theme Not Found
```powershell
# Check available themes
theme -List

# Check current theme
theme-current
```

### Theme Not Loading
```powershell
# Reload profile
. $PROFILE

# Or restart PowerShell session
```

### Missing Personal Themes
Ensure your custom themes are:
1. Located in `dotfiles/powershell/prompt/`
2. Named with `.omp.json` extension
3. Valid Oh My Posh JSON format

## Contributing

To add new personal themes:
1. Place `.omp.json` files in `dotfiles/powershell/prompt/`
2. Use `theme -Personal` to see your themes
3. Commit to your dotfiles repository

The theme management functions will automatically detect new themes without any configuration changes.
