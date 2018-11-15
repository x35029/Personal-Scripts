# -----------------------------------------------------------------------------
# Script: Get-BiosInformationDefaultParam.ps1
# Author: ed wilson, msft
# Date: 09/06/2013 16:27:05
# Keywords: Defaults
# comments: Detecting Missing Values
# Windows PowerShell 4.0 Best Practices, Microsoft Press, 2013
# Chapter 12
# -----------------------------------------------------------------------------
Param(
  [string]$computerName = $env:computername
) #end param

Function Get-BiosInformation($computerName)
{
 Get-WmiObject -class Win32_Bios -computername $computername
} #end function Get-BiosName

# *** Entry Point To Script ***

Get-BiosInformation -computername $computername
