# -----------------------------------------------------------------------------
# Script: ParseScriptCommands.ps1
# Author: ed wilson, msft
# Date: 09/08/2013 14:44:40
# Keywords: documentation
# comments: AST
# Windows PowerShell 4.0 Best Practices, Microsoft Press, 2013
# Chapter 14
# -----------------------------------------------------------------------------
$errors = $null
$logpath = "C:\fso\commandlog.txt"
$path = 'C:\ScriptFolder'
Get-ChildItem -Path $path -Include *.ps1 -Recurse |
ForEach-Object { 
  $script = $_.fullname
  $scriptText = get-content -Path $script
  [system.management.automation.psparser]::Tokenize($scriptText, [ref]$errors) |
  Foreach-object -Begin { 
    "Processing $script" | Out-File -FilePath $logPath -Append } `
  -process { if($_.type -eq "command") 
    { "`t $($_.content)" | Out-File -FilePath $logpath -Append } }
}
notepad $logpath