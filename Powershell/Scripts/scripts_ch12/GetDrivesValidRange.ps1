# -----------------------------------------------------------------------------
# Script: GetDrivesValidRange.ps1
# Author: ed wilson, msft
# Date: 09/06/2013 18:42:26
# Keywords: Out Of Bounds Errors
# comments: Placing Limits
# Windows PowerShell 4.0 Best Practices, Microsoft Press, 2013
# Chapter 12
# -----------------------------------------------------------------------------
Param(
   [Parameter(Mandatory=$true)]
   [ValidateRange("c","f")]
   [string]$drive,
   [string]$computerName = $env:computerName
) #end param

Function Get-DiskInformation($computerName,$drive)
{
 Get-WmiObject -class Win32_volume -computername $computername `
 -filter "DriveLetter = '$drive`:'"
} #end function Get-BiosName

# *** Entry Point To Script ***

Get-DiskInformation -computername $computerName -drive $drive
