# -----------------------------------------------------------------------------
# Script: ScriptFolderConfig.ps1
# Author: ed wilson, msft
# Date: 09/08/2013 18:17:49
# Keywords: DSC
# comments: sample
# Windows PowerShell 4.0 Best Practices, Microsoft Press, 2013
# Chapter 23
# -----------------------------------------------------------------------------
#Requires -version 4.0

Configuration ScriptFolder
{
    node 'Server1'
    {
      File ScriptFiles
      {
        SourcePath = "\\dc1\Share\"
        DestinationPath = "C:\scripts"
        Ensure = "Present"
        Type = "Directory"
        Recurse = $true
      }
    }

}