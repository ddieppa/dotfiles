# Git Configuration

This directory contains Git configuration templates and installation scripts for managing multiple Git identities and settings across different environments.

## Directory Structure

```
git/
├── .gitconfig                   # Main config template
├── .gitconfig-template-work     # Template for work config
├── .gitconfig-template-personal # Template for personal config
├── install.bat                  # Installation script
└── README.md                    # This file
```

## Features

- Separate configurations for work and personal projects
- Automatically switches Git identity based on repository location
- Uses Windows Credential Manager for secure credential storage
- Configures VS Code Insiders as default editor
- Sets up sensible defaults for Git operations
- Maintains Windows-specific settings

## Installation

1. Clone this repository:
   ```bash
   git clone <repository-url> D:/personal/github/dotfiles
   ```

2. Run the installation script:
   ```bash
   D:\personal\github\dotfiles\git\install.bat
   ```

3. Update your personal and work configurations in:
   - `%USERPROFILE%\.gitconfig-work`
   - `%USERPROFILE%\.gitconfig-personal`

## Configuration Details

### Main Config (`~/.gitconfig`)
- Sets `main` as default branch
- Configures VS Code Insiders as default editor
- Sets up Windows-specific line ending handling
- Includes work/personal configs based on repository location
- Configures credential helper and other Git defaults

### Work Config (`~/.gitconfig-work`)
- Work email and name
- Work-specific SSH key configuration
- Additional work-specific settings

### Personal Config (`~/.gitconfig-personal`)
- Personal email and name
- Personal SSH key configuration
- Additional personal settings

## Directory-Based Configuration

The configuration automatically switches between work and personal settings based on the repository location:

- `D:/work/**` → Uses work configuration
- `D:/personal/**` → Uses personal configuration

## Customization

1. Work Configuration:
   ```ini
   # ~/.gitconfig-work
   [user]
       name = Your Work Name
       email = your.work@company.com
   
   [core]
       sshCommand = "C:/Users/YourUsername/.ssh/id_work"
   ```

2. Personal Configuration:
   ```ini
   # ~/.gitconfig-personal
   [user]
       name = Your Personal Name
       email = your.personal@email.com
   
   [core]
       sshCommand = "C:/Users/YourUsername/.ssh/id_personal"
   ```

## Verification

To verify your configuration:

```bash
# Check all settings
git config --list --show-origin

# Test work configuration
cd D:\work\some-project
git config user.email  # Should show work email

# Test personal configuration
cd D:\personal\some-project
git config user.email  # Should show personal email
```

## Security Notes

- The template files don't contain actual credentials
- Sensitive information is stored only in local configuration files
- SSH keys and credentials are managed separately
- Uses Windows Credential Manager for secure credential storage

## Maintenance

- Update templates as needed for new Git settings
- Keep local configurations backed up separately
- Review and update SSH key configurations periodically
- Check Git documentation for new features and security updates

## Troubleshooting

1. **Wrong Identity Used**: 
   - Verify repository location matches configured paths
   - Check local repository Git config
   - Ensure no overriding local configurations

2. **SSH Key Issues**:
   - Verify SSH key paths in configurations
   - Ensure keys have correct permissions
   - Test SSH connection with `ssh -T git@github.com`

3. **Line Ending Issues**:
   - Check `core.autocrlf` setting
   - Review `.gitattributes` in repositories
   - Verify file encodings in editor

## Additional Resources

- [Git Documentation](https://git-scm.com/docs)
- [Git Config Documentation](https://git-scm.com/docs/git-config)
- [GitHub SSH Setup Guide](https://docs.github.com/en/authentication/connecting-to-github-with-ssh)