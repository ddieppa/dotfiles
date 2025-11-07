@echo off
setlocal enabledelayedexpansion

:: Set paths
set "CONFIG_DIR=%USERPROFILE%"
set "SCRIPT_DIR=%~dp0"

:: Copy main config
echo Installing main Git configuration...
copy /Y "%SCRIPT_DIR%\.gitconfig" "%CONFIG_DIR%\.gitconfig"

:: Copy .gitignore
echo Installing Git ignore file...
copy /Y "%SCRIPT_DIR%\.gitignore" "%CONFIG_DIR%\.gitignore"

:: Create work config if it doesn't exist
if not exist "%CONFIG_DIR%\.gitconfig-work" (
    echo Creating work Git configuration...
    copy /Y "%SCRIPT_DIR%\.gitconfig-template-work" "%CONFIG_DIR%\.gitconfig-work"
    echo Please update your work details in %CONFIG_DIR%\.gitconfig-work
)

:: Create personal config if it doesn't exist
if not exist "%CONFIG_DIR%\.gitconfig-personal" (
    echo Creating personal Git configuration...
    copy /Y "%SCRIPT_DIR%\.gitconfig-template-personal" "%CONFIG_DIR%\.gitconfig-personal"
    echo Please update your personal details in %CONFIG_DIR%\.gitconfig-personal
)

:: Verify .gitignore is referenced in main config
findstr /C:"excludesfile = ~/.gitignore" "%CONFIG_DIR%\.gitconfig" >nul
if errorlevel 1 (
    echo Adding .gitignore reference to Git config...
    echo [core]>> "%CONFIG_DIR%\.gitconfig"
    echo     excludesfile = ~/.gitignore>> "%CONFIG_DIR%\.gitconfig"
)

echo Git configuration installation complete!
echo Remember to update your personal and work configurations with your details.
pause