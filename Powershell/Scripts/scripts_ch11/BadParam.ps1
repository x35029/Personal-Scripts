# -----------------------------------------------------------------------------
# Script: BadParam.ps1
# Author: ed wilson, msft
# Date: 09/06/2013 13:44:29
# Keywords: Input
# comments: Using Param Statement
# Windows PowerShell 4.0 Best Practices, Microsoft Press, 2013
# Chapter 11
# -----------------------------------------------------------------------------
Write-Host "Param not in first position"
Param($computer = "localhost")
Get-WmiObject -Class Win32_Bios -computername $computer
