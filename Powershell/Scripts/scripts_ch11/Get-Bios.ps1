# -----------------------------------------------------------------------------
# Script: Get-Bios.ps1
# Author: ed wilson, msft
# Date: 09/06/2013 13:32:42
# Keywords: Input
# comments: Using 
# Windows PowerShell 4.0 Best Practices, Microsoft Press, 2013
# Chapter 11
# -----------------------------------------------------------------------------
Get-WmiObject -Class Win32_Bios -computername $args