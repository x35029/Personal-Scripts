# -----------------------------------------------------------------------------
# Script: ScriptFolderVersionUnzip.ps1
# Author: ed wilson, msft
# Date: 09/08/2013 19:15:10
# Keywords: DSC configuration parameters
# comments: setting dependencies
# Windows PowerShell 4.0 Best Practices, Microsoft Press, 2013
# Chapter 23
# -----------------------------------------------------------------------------
#Requires -version 4.0

Configuration ScriptFolderVersionUnzip
{
 Param ($modulePath = ($env:PSModulePath -split ';' | 
    ?  {$_ -match 'Program Files'}),
    $Server = 'Server1')
    node $Server
    {
      File ScriptFiles
      {
        SourcePath = "\\dc1\Share\"
        DestinationPath = "C:\scripts"
        Ensure = "present"
        Type = "Directory"
        Recurse = $true
      }
      Registry AddScriptVersion
      {
        Key = "HKEY_Local_Machine\Software\ForScripting"
        ValueName = "ScriptsVersion"
        ValueData = "1.0"
        Ensure = "Present"
      }
      Archive ZippedModule
      {
        DependsOn = "[File]ScriptFiles"
        Path = "C:\scripts\PoshModules\PoshModules.zip"
        Destination = $modulePath
        Ensure = "Present"
      }
    }
}

ScriptFolderVersionUnZip -output C:\server1Config
Start-DscConfiguration -Path C:\server1Config -JobName Server1Config -Verbose