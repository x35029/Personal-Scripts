# -----------------------------------------------------------------------------
# Script: MandatoryParameter.ps1
# Author: ed wilson, msft
# Date: 09/06/2013 16:29:24
# Keywords: Handling missing parameters
# comments: Mandatory Parameter
# Windows PowerShell 4.0 Best Practices, Microsoft Press, 2013
# Chapter 12
# -----------------------------------------------------------------------------
#Requires –version 4.0
Param(
   [Parameter(Mandatory=$true)]
   [string]$drive,
   [string]$computerName = $env:computerName
) #end param

Function Get-DiskInformation($computerName,$drive)
{
 Get-WmiObject -class Win32_volume -computername $computername `
-filter "DriveLetter = '$drive'"
} #end function Get-BiosName

# *** Entry Point To Script ***

 Get-DiskInformation -computername $computerName -drive $drive
