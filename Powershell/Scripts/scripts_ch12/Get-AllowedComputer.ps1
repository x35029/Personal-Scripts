# -----------------------------------------------------------------------------
# Script: Get-AllowedComputer.ps1
# Author: ed wilson, msft
# Date: 09/06/2013 16:40:54
# Keywords: Liimiting choices
# comments: using -contains
# Windows PowerShell 4.0 Best Practices, Microsoft Press, 2013
# Chapter 12
# -----------------------------------------------------------------------------
Param([string]$computer = $env:computername)

Function Get-AllowedComputer([string]$computer)
{
 $servers = Get-Content -path c:\fso\servers.txt 
 $servers -contains $computer
} #end Get-AllowedComputer function

# *** Entry point to Script ***

if(Get-AllowedComputer -computer $computer)
 {
   Get-WmiObject -class Win32_Bios -computer $computer
 }
Else
 {
  "$computer is not an allowed computer"
 }
