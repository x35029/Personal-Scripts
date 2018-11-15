# -----------------------------------------------------------------------------
# Script: Get-WindowsEdition.ps1
# Author: ed wilson, msft
# Date: 09/07/2013 13:11:02
# Keywords: Version number
# comments: Version
# Windows PowerShell 4.0 Best Practices, Microsoft Press, 2013
# Chapter 17
# -----------------------------------------------------------------------------
<#
   .Synopsis
    Gets the version of Windows that is installed on the local computer
   .Description
    Gets the version of Windows that is installed on the local computer. This 
    is information such as Windows 7 Enterprise.
   .Example
    Get-WindowsEdition.ps1
    Displays version of windows on local computer. 
   .Inputs
    none
   .OutPuts
    [string]
   .Notes
    NAME:  Get-WindowsEdition.ps1
    AUTHOR: Ed Wilson 
    LASTEDIT: 9/20/2013
    VERSION: 1.2.0 Added Help tags
             1.1.1 4/2/1009 Added link to http://www.ScriptingGuys.com
             1.1.0 4/1/2009 Modified to use regex pattern
    KEYWORDS: Windows PowerShell Best Practices
   .Link
     Http://www.ScriptingGuys.com
#Requires -Version 4.0
#>


$strPattern = "version"
$text = net config workstation

switch -regex ($text) 
{
  $strPattern { Write-Host $switch.current }
}
