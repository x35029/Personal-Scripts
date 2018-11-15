# -----------------------------------------------------------------------------
# Script: Get-BiosInformation.ps1
# Author: ed wilson, msft
# Date: 09/06/2013 16:26:25
# Keywords: Defaults
# comments: Detecting Missing Values
# Windows PowerShell 4.0 Best Practices, Microsoft Press, 2013
# Chapter 12
# -----------------------------------------------------------------------------
Param(
  [string]$computerName
) #end param

Function Get-BiosInformation($computerName)
{
 Get-WmiObject -class Win32_Bios -computername $computername
} #end function Get-BiosName

# *** Entry Point To Script ***
If(-not($computerName)) { $computerName = $env:computerName }
Get-BiosInformation -computername $computername
