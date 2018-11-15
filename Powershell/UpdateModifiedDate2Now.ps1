$ErrorActionPreference = "SilentlyContinue"
Get-ChildItem -Path $env:homeshare,$env:userprofile,"\\mysite.na.xom.com\personal\$env:userdomain`_$env:username" -Recurse | ForEach-Object { $_.LastWriteTime = Get-Date }
exit