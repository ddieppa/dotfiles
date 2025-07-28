# aliases/dotnet.ps1
Set-SafeAlias dn dotnet
function dnb { dotnet build @args }
function dnr { dotnet run @args }
function dnt { dotnet test @args }
