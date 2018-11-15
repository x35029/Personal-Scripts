# -----------------------------------------------------------------------------
# Script: Test-ComputerPath.ps1
# Author: ed wilson, msft
# Date: 09/06/2013 16:37:13
# Keywords: Liimiting choices
# comments: test path
# Windows PowerShell 4.0 Best Practices, Microsoft Press, 2013
# Chapter 12
# -----------------------------------------------------------------------------
Param([string]$computer = "localhost")

Function Test-ComputerPath([string]$computer)
{
 Get-WmiObject -class win32_pingstatus -filter "address = '$computer'"
} #end Test-ComputerPath

# *** Entry Point to Script ***

if( (Test-ComputerPath -computer $computer).statusCode -eq 0 ) 
 {
  Get-WmiObject -class Win32_Bios -computer $computer
 }
Else
 {
  "Unable to reach $computer computer"
 }
