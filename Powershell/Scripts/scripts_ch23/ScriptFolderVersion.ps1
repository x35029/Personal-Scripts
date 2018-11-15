# -----------------------------------------------------------------------------
# Script: ScriptFolderVersion.ps1
# Author: ed wilson, msft
# Date: 09/08/2013 19:03:45
# Keywords: DSC
# comments: sample
# Windows PowerShell 4.0 Best Practices, Microsoft Press, 2013
# Chapter 23
# -----------------------------------------------------------------------------
#Requires -Version 4.0

Configuration ScriptFolderVersion
{
 Param ($server = 'server1') 
    node $server
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
      
    }
}

ScriptFolderVersion 
