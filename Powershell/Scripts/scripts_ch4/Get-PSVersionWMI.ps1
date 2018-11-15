# -----------------------------------------------------------------------------
# Script: Get-PSVersionWMI.ps1
# Author: ed wilson, msft
# Date: 08/24/2013 14:47:37
# Keywords: WMI
# comments: powershell version
# Windows PowerShell 4.0 Best Practices, Microsoft Press, 2013
# Chapter 4
# -----------------------------------------------------------------------------
$hklm = 2147483650
$key = "SOFTWARE\Microsoft\PowerShell\3\PowerShellEngine"
$value = "PowerShellVersion"
$wmi = [WMICLASS]"root\default:stdRegProv"
($wmi.GetStringValue($hklm,$key,$value)).svalue
