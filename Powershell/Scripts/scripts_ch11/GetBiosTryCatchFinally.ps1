# -----------------------------------------------------------------------------
# Script: GetBiosTryCatchFinally.ps1
# Author: ed wilson, msft
# Date: 09/06/2013 13:39:45
# Keywords: Input
# comments: Using try Catch Finally
# Windows PowerShell 4.0 Best Practices, Microsoft Press, 2013
# Chapter 11
# -----------------------------------------------------------------------------
Try 
   { Get-WmiObject -class Win32_Bios -computer $args }
Catch [System.Management.Automation.ParameterBindingException]  
   { Write-Host -foregroundcolor cyan "Please enter computer name" }
Finally 
   { 'Cleaning up the $error object' ; $error.clear() }
