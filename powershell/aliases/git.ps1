# aliases/git.ps1
Set-SafeAlias g git
function gst { git status @args }
function gcm { git commit @args }
function gps { git push @args }
