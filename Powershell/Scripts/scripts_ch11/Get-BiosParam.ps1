# -----------------------------------------------------------------------------
# Script: Get-BiosParam.ps1
# Author: ed wilson, msft
# Date: 09/06/2013 13:51:07
# Keywords: Input
# comments: Using Param Statement
# Windows PowerShell 4.0 Best Practices, Microsoft Press, 2013
# Chapter 11
# -----------------------------------------------------------------------------
Param($computer = "localhost")
Get-WmiObject -Class Win32_Bios -computername $computer
