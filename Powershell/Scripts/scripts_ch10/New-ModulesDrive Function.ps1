# -----------------------------------------------------------------------------
# Script: New-ModulesDrive Function.ps1
# Author: ed wilson, msft
# Date: 09/07/2013 17:34:48
# Keywords: modules
# comments: installing
# Windows PowerShell 4.0 Best Practices, Microsoft Press, 2013
# Chapter 10
# -----------------------------------------------------------------------------
Function New-ModuleDrives
{
<#
    .SYNOPSIS
    Creates two PSDrives: myMods and sysMods
    .EXAMPLE
    New-ModuleDrives
    Creates two PSDrives: myMods and sysMods. These correspond 
    to the users' modules folder and the system modules folder respectively. 
#>
 $driveNames = "myMods","sysMods"

 For($i = 0 ; $i -le 1 ; $i++)
 {
  New-PSDrive -name $driveNames[$i] -PSProvider filesystem `
  -Root ($env:PSModulePath.split(";")[$i]) -scope Global |
  Out-Null
 } #end For
} #end New-ModuleDrives

Function Get-FileSystemDrives
{
<#
    .SYNOPSIS
    Displays global PS Drives that use the Filesystem provider
    .EXAMPLE
    Get-FileSystemDrives
    Displays global PS Drives that use the Filesystem provider
#>
 Get-PSDrive -PSProvider FileSystem -scope Global
} #end Get-FileSystemDrives

# *** EntryPoint to Script ***
New-ModuleDrives
Get-FileSystemDrives
