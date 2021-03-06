# -----------------------------------------------------------------------------
# Mod2ParseScriptCommands.ps1
# ed wilson, msft, 6/4/2010
# 
# uses the powershell tokenizer from [system.management.automation.psparser]
# .NET Framework class. The tokenize static method will return variables, as
# well as commands from a script. 
#
# WES-06-27-2010
# -----------------------------------------------------------------------------
$errors = $null
$logpath = "C:\a\commandlog.txt"
$path = "C:\data\PSExtras"
Get-ChildItem -Path $path -Filter *.ps1 -Recurse |
ForEach-Object { 
  $script = $_.fullname
  $scriptText = get-content -Path $script
  [system.management.automation.psparser]::Tokenize($scriptText, [ref]$errors) |
  Foreach-object -Begin { 
    "Processing $script" | Out-File -FilePath $logPath -Append } `
  -process { if($_.type -eq "command") 
    { "`t $($_.content)" | Out-File -FilePath $logpath -Append } }
}
#notepad $logpath