# -----------------------------------------------------------------------------
# Script: Get-PSVersionRegRead.ps1
# Author: ed wilson, msft
# Date: 08/24/2013 14:55:05
# Keywords: Registry, COM
# comments: powershell version
# Windows PowerShell 4.0 Best Practices, Microsoft Press, 2013
# Chapter 4
# -----------------------------------------------------------------------------
$path = "HKLM\SOFTWARE\Microsoft\PowerShell\3\PowerShellEngine"
$WshShell = New-Object -ComObject Wscript.Shell
$WshShell.RegRead("$path\PowerShellVersion")
