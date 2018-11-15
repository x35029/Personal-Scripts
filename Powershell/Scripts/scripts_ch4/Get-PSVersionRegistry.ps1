# -----------------------------------------------------------------------------
# Script: Get-PSVersionRegistry.ps1
# Author: ed wilson, msft
# Date: 08/24/2013 13:52:50
# Keywords: Registry
# comments: powershell version
# Windows PowerShell 4.0 Best Practices, Microsoft Press, 2013
# Chapter 4
# -----------------------------------------------------------------------------
$path = "HKLM:\SOFTWARE\Microsoft\PowerShell\3\PowerShellEngine"
$psv = get-itemproperty -path $path
$psv.PowerShellVersion
