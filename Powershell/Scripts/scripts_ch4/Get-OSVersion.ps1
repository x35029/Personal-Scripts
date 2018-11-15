# -----------------------------------------------------------------------------
# Script: Get-OSVersion.ps1
# Author: ed wilson, msft
# Date: 08/24/2013 21:18:22
# Keywords: Version
# comments: Operating System Requirements
# Windows PowerShell 4.0 Best Practices, Microsoft Press, 2013
# Chapter 4
# -----------------------------------------------------------------------------
Function Get-OsVersion
{
 [System.Environment]::OSVersion.Version
}

# *** entry point to script ***

$os = Get-OsVersion
if($os.major -ge 6 -and $os.Minor -ge 2)
 { "Windows 8 or greater detected" }
else
{ "Windows 8 or greater not detected" }
