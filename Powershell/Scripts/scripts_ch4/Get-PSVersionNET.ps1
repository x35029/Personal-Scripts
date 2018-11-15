# -----------------------------------------------------------------------------
# Script: Get-PSVersionNET.ps1
# Author: ed wilson, msft
# Date: 08/24/2013 14:49:27
# Keywords: .NET
# comments: powershell version
# Windows PowerShell 4.0 Best Practices, Microsoft Press, 2013
# Chapter 4
# -----------------------------------------------------------------------------
$hklm = "HKEY_LOCAL_MACHINE"
$key = "SOFTWARE\Microsoft\PowerShell\3\PowerShellEngine"
$value = "PowerShellVersion"
[Microsoft.Win32.Registry]::GetValue("$hklm\$key",$value,$null)
