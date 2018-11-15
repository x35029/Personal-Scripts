# -----------------------------------------------------------------------------
# Script: Get-BiosArray2.ps1
# Author: ed wilson, msft
# Date: 09/06/2013 13:36:23
# Keywords: Input
# comments: Using 
# Windows PowerShell 4.0 Best Practices, Microsoft Press, 2013
# Chapter 11
# -----------------------------------------------------------------------------
$args | Foreach-Object {
Get-WmiObject -Class Win32_Bios -computername $_
}  
