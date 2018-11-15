# -----------------------------------------------------------------------------
# Script: get-biosArgsCheck1.ps1
# Author: ed wilson, msft
# Date: 09/06/2013 13:38:03
# Keywords: Input
# comments: Using 
# Windows PowerShell 4.0 Best Practices, Microsoft Press, 2013
# Chapter 11
# -----------------------------------------------------------------------------
If($args.count -eq 0) 
  {
   Write-Host -foregroundcolor Cyan "Please supply computer name"
   Exit
  } #end if
Get-WmiObject -Class Win32_Bios -computername $args
