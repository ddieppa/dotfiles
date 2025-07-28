# PowerShell Dotfiles Repository - Complete Setup Guide

A modern, modular PowerShell-based dotfiles system for Windows 11 that rivals Oh My Zsh functionality. This repository provides a complete terminal customization solution with dynamic path handling, optional posh-git integration, modular alias management, and robust fallback mechanisms.

## 🚀 Features

- **Dynamic Path Resolution**: Works from any folder location - `D:\dotfiles\powershell`, `D:\github\ddieppa\dotfiles\powershell`, or anywhere else[1][2]
- **Modular Architecture**: Separate files for aliases, modules, PSReadLine settings, and Oh My Posh themes[3][4]
- **Per-App Alias Management**: Dedicated alias files for Git, .NET, Docker, Node.js, and VS Code Insiders[5][6]
- **Smart Fallbacks**: Automatic fallback to built-in Oh My Posh themes when custom themes aren't available[7][8]
- **OneDrive Compatibility**: Handles OneDrive Documents redirection seamlessly[9][10]
- **Optional posh-git**: Choose between Oh My Posh's built-in Git support or full posh-git functionality[11]
- **One-Command Setup**: Single installer script creates symbolic links and installs dependencies[12][13]

## 📁 Repository Structure

```
dotfiles/powershell/
├── Profile.ps1                    # Main orchestrator (symlinked to $PROFILE)
├── install.ps1                    # Bootstrap script
├── modules/
│   └── modules.ps1                # Module installer/loader
├── aliases/
│   ├── core.ps1                   # Basic shell aliases
│   ├── git.ps1                    # Git shortcuts
│   ├── dotnet.ps1                 # .NET CLI aliases
│   ├── docker.ps1                 # Docker & docker-compose
│   ├── node.ps1                   # Node.js & npm
│   └── vscode.ps1                 # VS Code Insiders integration
├── psreadline/
│   └── bindings.ps1               # Keyboard shortcuts & options
├── prompt/
│   └── night-owl.omp.json         # Custom Oh My Posh theme
└── utilities/                     # Optional helper functions
    └── helpers.ps1
```

## 🛠️ Installation

### Prerequisites

```powershell
# Set execution policy (one-time)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
```

### Quick Start

1. **Clone the repository** to any location:
   ```powershell
   git clone https://github.com/ddieppa/dotfiles D:\any\folder\dotfiles
   ```

2. **Run the installer**:
   ```powershell
   & D:\any\folder\dotfiles\powershell\install.ps1
   ```

3. **Restart PowerShell** to see your new environment.

The installer will:
- Install required modules (PSReadLine, Terminal-Icons, Oh My Posh)[14][11]
- Create a symbolic link from `$PROFILE.CurrentUserAllHosts` to your repo's `Profile.ps1`[12][13]
- Handle OneDrive Documents redirection automatically[9]
- Backup any existing profile safely

## 📝 Core Files

### Profile.ps1 (Main Orchestrator)

The heart of the system - a thin file that coordinates all components:

```powershell
# Dynamic Git-backed PowerShell profile
$RepoRoot = $PSScriptRoot
function Join($child) { Join-Path -Path $RepoRoot -ChildPath $child }

# 1. Modules
. (Join 'modules\modules.ps1')

# 2. Aliases (auto-load all *.ps1 files)
Get-ChildItem (Join 'aliases') -Filter '*.ps1' |
    ForEach-Object { . $_.FullName }

# 3. PSReadLine bindings
. (Join 'psreadline\bindings.ps1')

# 4. Prompt with fallback
$ThemeFile = Join 'prompt\night-owl.omp.json'
$Config = if (Test-Path $ThemeFile) { $ThemeFile } else { 'paradox' }
oh-my-posh init pwsh --config $Config | Invoke-Expression

# 5. Quality-of-life
function reload { . $PROFILE }
Set-Alias rl reload
```

**Key Features:**
- Uses `$PSScriptRoot` for dynamic path resolution[1][2]
- Fallback to built-in themes when custom themes are missing[7][8] 
- Auto-loads all alias files for easy expansion[4]

### install.ps1 (Bootstrap Script)

Handles setup and symbolic link creation:

```powershell
# 1. Identify where PowerShell wants the profile
$DestPath = $PROFILE.CurrentUserAllHosts  # respects OneDrive redirection

# 2. Ensure parent folder exists
$DestDir = Split-Path $DestPath -Parent
New-Item -ItemType Directory -Path $DestDir -Force | Out-Null

# 3. Backup any old profile
if (Test-Path $DestPath -PathType Leaf) {
    Copy-Item $DestPath "$DestPath.bak" -Force
    Remove-Item $DestPath -Force
}

# 4. Link to the real profile using dynamic source
$SourcePath = Join-Path -Path $PSScriptRoot -ChildPath 'Profile.ps1'
New-Item -ItemType SymbolicLink -Path $DestPath -Target $SourcePath -Force

Write-Host "Profile linked → $DestPath" -ForegroundColor Green
```

## 🎯 Alias Management

### Per-Application Approach

Instead of one massive alias file, we use dedicated files per tool:

**aliases/git.ps1**
```powershell
Set-Alias g   git
function gst { git status @args }
function gcm { git commit @args }
function gps { git push @args }
function gpl { git pull @args }
```

**aliases/dotnet.ps1**
```powershell
Set-Alias dn  dotnet
function dnb { dotnet build @args }
function dnr { dotnet run @args }
function dnt { dotnet test @args }
function dnp { dotnet pack @args }
```

**aliases/docker.ps1**
```powershell
Set-Alias d   docker
Set-Alias dc  docker-compose
function dcup { docker-compose up @args }
function dcdn { docker-compose down @args }
```

**aliases/node.ps1**
```powershell
Set-Alias np  npm
Set-Alias ni  'npm install'
Set-Alias nr  'npm run'
Set-Alias nrb 'npm run build'
Set-Alias nrt 'npm run test'
```

**aliases/vscode.ps1**
```powershell
# VS Code Insiders integration
Set-Alias code code-insiders
```

**Benefits:**
- Easy to maintain and version control[4]
- Clean separation of concerns[5]
- Simple to share specific alias sets with team members
- Auto-loaded by the main profile

## ⌨️ PSReadLine Configuration

Dedicated keyboard shortcuts and editing options in `psreadline/bindings.ps1`:

```powershell
Import-Module PSReadLine
Set-PSReadLineOption -PredictionSource History
Set-PSReadLineOption -HistorySaveStyle SaveIncrementally

# Key bindings
Set-PSReadLineKeyHandler -Key Ctrl+r -Function ReverseSearchHistory
Set-PSReadLineKeyHandler -Key Ctrl+l -Function ClearScreen
Set-PSReadLineKeyHandler -Key UpArrow   -Function HistorySearchBackward
Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward

# Word movement
Set-PSReadLineKeyHandler -Key Alt+b -Function BackwardWord
Set-PSReadLineKeyHandler -Key Alt+f -Function ForwardWord
```

**Included Shortcuts:**[14][15]
| Shortcut | Action | 
|----------|--------|
| Ctrl + R | Fuzzy reverse-history search |
| Ctrl + L | Clear & repaint screen |
| Alt + B/F | Move backward/forward by word |
| Up/Down | Prefix-aware history search |

## 🎨 Oh My Posh Integration

### Smart Theme Fallback

The profile includes intelligent fallback logic for themes:

```powershell
$ThemeFile = Join 'prompt\night-owl.omp.json'
$Config = if (Test-Path $ThemeFile) { $ThemeFile } else { 'paradox' }
oh-my-posh init pwsh --config $Config | Invoke-Expression
```

**Built-in Fallback Themes:**[8][16]
- `paradox` - Powerline arrows, colorful (requires Nerd Font)
- `jandedobbeleer` - Minimal left prompt with right-aligned info  
- `clean-detailed` - Compact, single-line
- `pwsh` - Simple, no special fonts required

### Do You Need posh-git?

**Oh My Posh Built-in vs posh-git Module:**

| Feature | Oh My Posh | posh-git | Recommendation |
|---------|------------|----------|----------------|
| Git status in prompt | ✅ Native | ✅ Yes | Either works |
| Tab completion | ❌ No | ✅ Extensive | Add posh-git for power users |
| Load time | Fast | +100-200ms | Skip for basic users |
| Memory usage | Low | Higher | Skip for basic users |

**For most users**: Oh My Posh's built-in Git support is sufficient.
**For Git power users**: Add posh-git for advanced tab completion.

## 🔧 Advanced Configuration

### Moving the Repository

The dynamic path system means you can move your dotfiles anywhere:

```powershell
# Works from any location
git clone https://github.com/ddieppa/dotfiles C:\Users\YourName\dotfiles
git clone https://github.com/ddieppa/dotfiles D:\projects\dotfiles  
git clone https://github.com/ddieppa/dotfiles E:\portable\dotfiles
```

Just re-run `install.ps1` after moving to update the symbolic link.

### OneDrive Integration

The system handles OneDrive Documents redirection automatically. Your `$PROFILE` might show:
```
C:\OneDrive\Documents\PowerShell\profile.ps1
```

The installer respects this and creates the symbolic link in the correct location[9][10].

### Adding New Aliases

1. Create a new file in `aliases/` (e.g., `aliases/azure.ps1`)
2. Add your aliases and functions
3. Restart PowerShell - they'll auto-load

### Custom Themes

1. Place `.omp.json` files in `prompt/`
2. Update the theme reference in `Profile.ps1`
3. Built-in fallback ensures the profile never breaks

## 🚀 Usage Examples

### Daily Workflow
```powershell
# Git workflow
gst              # git status
ga .             # git add .
gcm "Fix bug"    # git commit -m "Fix bug"
gps              # git push

# .NET development  
dnr              # dotnet run
dnb              # dotnet build
dnt              # dotnet test

# Docker operations
dcup -d          # docker-compose up -d
dcdn             # docker-compose down

# Node.js projects
ni               # npm install
nr start         # npm run start
nrb              # npm run build

# VS Code Insiders
code .           # Opens current directory in VS Code Insiders
```

### Profile Management
```powershell
rl               # Reload profile (alias for '. $PROFILE')
code $PROFILE    # Edit profile (opens VS Code Insiders)
```

## 🛡️ Troubleshooting

### Common Issues

| Problem | Cause | Solution |
|---------|-------|----------|
| "oh-my-posh not recognized" | Binary not on PATH | Re-run `winget install JanDeDobbeleer.OhMyPosh` |
| Custom theme ignored | File missing/wrong path | Check `$ThemeFile` path; fallback loads automatically |
| Aliases not loading | File not dot-sourced | Ensure `.ps1` extension; restart PowerShell |
| Symlink creation fails | Need admin rights | Enable Developer Mode or run as administrator |
| Profile path not found | Parent folder missing | Installer creates directory automatically |

### Performance Tips

1. **Antivirus Exclusions**: Add Oh My Posh binary path to Windows Defender exclusions[17]
2. **Module Loading**: Heavy modules (Az, AWS) should be lazy-loaded in functions[17][18]
3. **History Settings**: Use `SaveIncrementally` to prevent exit delays[14]

### Debugging

```powershell
# Check profile paths
$PROFILE | Select-Object *

# Verify modules are loaded
Get-Module PSReadLine, Terminal-Icons, posh-git

# Test Oh My Posh
oh-my-posh --version

# Check symbolic link
Get-Item $PROFILE.CurrentUserAllHosts | Select-Object Target
```

## 🔄 Updating

### Pull Latest Changes
```powershell
cd path\to\your\dotfiles
git pull
rl  # Reload profile
```

### Add New Machines
```powershell
git clone https://github.com/ddieppa/dotfiles D:\dotfiles
& D:\dotfiles\powershell\install.ps1
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Add your aliases, themes, or improvements
4. Test on multiple PowerShell versions
5. Submit a pull request

### Adding New Alias Categories

1. Create `aliases/your-tool.ps1`
2. Add aliases and functions for your tool
3. Document in this README
4. Test that auto-loading works

## 📚 Additional Resources

- [Oh My Posh Documentation](https://ohmyposh.dev/docs/)[19]
- [PSReadLine Module](https://github.com/PowerShell/PSReadLine)[11]
- [PowerShell Profile Best Practices](https://learn.microsoft.com/en-us/powershell/scripting/learn/shell/creating-profiles)[2]
- [Windows Terminal Customization](https://learn.microsoft.com/en-us/windows/terminal/tutorials/custom-prompt-setup)[6]

## 🔄 Version History

- **v2.0**: Modular architecture with per-app aliases
- **v1.5**: Dynamic path resolution
- **v1.0**: Basic profile with Oh My Posh integration

## 📄 License

MIT License - Feel free to use and modify for your needs.

**Ready to transform your PowerShell experience?** Clone this repository and run the installer to get started in under 2 minutes! 🚀

[1] https://lazyadmin.nl/powershell/powershell-profile/
[2] https://learn.microsoft.com/en-us/powershell/scripting/learn/shell/creating-profiles?view=powershell-7.5
[3] https://ohmyposh.dev/docs/installation/customize
[4] https://www.bowmanjd.com/dotfiles/dotfiles-2-bare-repo/
[5] https://powershellisfun.com/2023/07/13/powershell-profile/
[6] https://learn.microsoft.com/en-us/windows/terminal/tutorials/custom-prompt-setup
[7] https://ohmyposh.dev/docs/installation/prompt
[8] https://ohmyposh.dev/docs/themes
[9] https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_profiles?view=powershell-7.5
[10] https://stackoverflow.com/questions/74896830/how-can-i-change-powershells-profile-to-point-to-the-local-documents-folder-in
[11] https://github.com/PowerShell/PSReadLine
[12] https://mikefrobbins.com/2023/11/09/use-symlinks-to-version-control-your-powershell-profile-with-git/
[13] https://winaero.com/create-symbolic-link-windows-10-powershell/
[14] https://learn.microsoft.com/en-us/powershell/module/psreadline/set-psreadlineoption?view=powershell-7.5
[15] https://powershellisfun.com/2022/04/24/ps/
[16] https://ohmyposh.dev/docs/configuration/colors
[17] https://devblogs.microsoft.com/powershell/optimizing-your-profile/
[18] https://blog.inedo.com/powershell/modules-in-source-control/
[19] https://ohmyposh.dev/docs/
[20] https://github.com/ralish/PSDotFiles
[21] https://mohundro.com/blog/2024-08-03-how-i-manage-my-dotfiles/
[22] https://www.reddit.com/r/linuxquestions/comments/wuyusj/organizing_dotfiles_into_one_folder/
[23] https://www.youtube.com/watch?v=TRfhN0zI4Fs
[24] https://www.youtube.com/watch?v=OL9Mr4dzIWU
[25] https://github.com/jayharris/dotfiles-windows
[26] https://www.reddit.com/r/PowerShell/comments/10q61ie/what_do_you_folks_put_in_your_powershell_profile/
[27] https://ohmyposh.dev/docs/configuration/general
[28] https://www.powershellgallery.com/packages/PSWindowsDotfiles/1.0.3/Content/Functions%5CNew-Dotfiles.ps1
[29] https://scottmckendry.tech/the-ultimate-powershell-profile/
[30] https://ohmyposh.dev/docs/installation/windows
[31] https://learn-powershell.net/2013/07/16/creating-a-symbolic-link-using-powershell/
[32] https://www.techtarget.com/searchwindowsserver/tutorial/How-to-find-and-customize-your-PowerShell-profile
[33] https://www.youtube.com/watch?v=_VnONfOgP8M
[34] https://learn.microsoft.com/en-us/answers/questions/1163032/how-to-create-a-shortcut-to-a-folder-with-powershe
[35] https://www.hanselman.com/blog/you-should-be-customizing-your-powershell-prompt-with-psreadline
[36] https://github.com/PowerShell/PSReadLine/blob/master/PSReadLine/SamplePSReadLineProfile.ps1
[37] https://superuser.com/questions/1307360/how-do-you-create-a-new-symlink-in-windows-10-using-powershell-not-mklink-exe
[38] https://learn.microsoft.com/en-us/powershell/module/psreadline/about/about_psreadline?view=powershell-7.5
[39] https://www.youtube.com/watch?v=VeEdGTmCW5g
[40] https://stackoverflow.com/questions/75630199/creating-a-symbolic-link-using-powershell
[41] https://www.youtube.com/watch?v=Q11sSltuTE0
[42] https://www.anmalkov.com/blog/use-code-command-to-run-vscode-insiders
[43] https://forums.powershell.org/t/looking-for-some-best-practices-for-managing-large-powershell-scripts/25168
[44] https://stackoverflow.com/questions/62264109/how-to-open-visual-studio-code-insiders-from-the-command-line-in-windows/76149898
[45] https://github.com/JanDeDobbeleer/oh-my-posh/blob/main/themes/schema.json
[46] https://forums.powershell.org/t/powershell-module-best-practices/13290
[47] https://stackoverflow.com/questions/62264109/how-to-open-visual-studio-code-insiders-from-the-command-line-in-windows
[48] https://learn.microsoft.com/en-us/powershell/gallery/concepts/publishing-guidelines?view=powershellget-3.x
[49] https://code.visualstudio.com/docs/configure/command-line
[50] https://bash-it.readthedocs.io/en/latest/themes-list/oh-my-posh/
[51] https://www.scriptrunner.com/en/blog/5-best-practices
[52] https://code.visualstudio.com/docs/terminal/shell-integration
[53] https://www.reddit.com/r/PowerShell/comments/1e2pnpm/best_practices_in_creating_modules/
[54] https://github.com/microsoft/vscode/issues/161212
[55] https://whoisryosuke.com/blog/2022/leveling-up-windows-powershell-with-oh-my-posh
[56] https://www.youtube.com/watch?v=ZG3IYIaph38