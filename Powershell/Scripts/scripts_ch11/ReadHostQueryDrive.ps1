# -----------------------------------------------------------------------------
# Script: ReadHostQueryDrive.ps1
# Author: ed wilson, msft
# Date: 09/06/2013 15:18:17
# Keywords: Input
# comments: Prompting for input
# Windows PowerShell 4.0 Best Practices, Microsoft Press, 2013
# Chapter 11
# -----------------------------------------------------------------------------
$response = Read-Host "Type drive letter to query <c: / d:>"

Switch -regex($response) {
  "C" { Get-WmiObject -class Win32_Volume -filter "driveletter = 'c:'" }
  "D" { Get-WmiObject -class Win32_Volume -filter "driveletter = 'd:'" }
} #end switch
