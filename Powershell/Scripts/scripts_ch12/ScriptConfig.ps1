# -----------------------------------------------------------------------------
# Script: ScriptConfig.ps1
# Author: ed wilson, msft
# Date: 09/06/2013 17:40:26
# Keywords: Using Requires
# comments: admin rights
# Windows PowerShell 4.0 Best Practices, Microsoft Press, 2013
# Chapter 12
# -----------------------------------------------------------------------------
#Requires -version 4.0
#Requires -RunAsAdministrator
$webNode = 'Server1'

Configuration ScriptFolder
{
    node $webNode
    {
      File ScriptFiles
      {
        SourcePath = "\\dc1\Share\"
        DestinationPath = "C:\scripts"
        Ensure = "present"
        Type = "Directory"
        Recurse = $true
      }
    }

}