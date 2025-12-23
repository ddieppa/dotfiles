Param(
    [string]$TargetDir = "."
)

Set-Location $TargetDir

git ls-files --cached --others --exclude-standard |
    Compress-Archive -DestinationPath "project_gitignored.zip" -Force
