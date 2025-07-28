# Oh My Posh Themes

This folder contains custom Oh My Posh themes for your PowerShell profile.

## Available Themes

- **minimal.omp.json** - A clean, simple theme with basic information
- **paradox.omp.json** - A colorful powerline-style theme with diamond shapes
- **powerline.omp.json** - A classic powerline theme with segment separators
- **the-unnamed.personal.omp.json** - Your personal custom theme

## Using Themes

### During Installation
When you run `.\install.ps1`, you'll be prompted to select a theme from the available options.

### Changing Themes Later
To change your theme without re-running the full installation:

```powershell
.\install.ps1 -ThemeOnly
```

### Manual Theme Configuration
You can also manually set a theme by creating a `.theme-config` file in the powershell directory:

```powershell
# Set to use the minimal theme
echo "d:\dotfiles\powershell\propmt\minimal.omp.json" > .theme-config
```

### Adding Your Own Themes
1. Create a new `.omp.json` file in this folder
2. Use the [Oh My Posh documentation](https://ohmyposh.dev/docs/configuration/overview) for theme syntax
3. Run `.\install.ps1 -ThemeOnly` to select your new theme

## Theme Fallback Behavior
If no theme is configured or the configured theme file doesn't exist, the profile will:
1. Look for any `.omp.json` file in this folder
2. Fall back to the built-in 'paradox' theme

## Schema
All theme files should include the schema reference for IntelliSense support:
```json
{
  "$schema": "https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/schema.json",
  "version": 2,
  // ... rest of theme configuration
}
```
