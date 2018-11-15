# -----------------------------------------------------------------------------
# Script: GetDrivesCheckAllowedValue.ps1
# Author: ed wilson, msft
# Date: 09/06/2013 18:40:43
# Keywords: Out of Bounds Errors
# comments: Boundary Checking Function
# Windows PowerShell 4.0 Best Practices, Microsoft Press, 2013
# Chapter 12
# -----------------------------------------------------------------------------
Param(
   [Parameter(Mandatory=$true)]
   [string]$drive,
   [string]$computerName = $env:computerName
) #end param

Function Check-AllowedValue($drive, $computerName)
{
 Get-WmiObject -class Win32_Volume -computername $computerName| 
 ForEach-Object { $drives += @{ $_.DriveLetter = $_.DriveLetter } }
 $drives.contains($drive)
} #end function Check-AllowedValue

Function Get-DiskInformation($computerName,$drive)
{
 Get-WmiObject -class Win32_volume -computername $computername -filter "DriveLetter = '$drive'"
} #end function Get-BiosName

# *** Entry Point To Script ***

if(Check-AllowedValue -drive $drive -computername $computerName)
  {
   Get-DiskInformation -computername $computerName -drive $drive
  }
else
 {
  Write-Host -foregroundcolor yellow "$drive is not an allowed value:"
 }
