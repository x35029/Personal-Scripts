# -----------------------------------------------------------------------------
# Script: get-biosArgsCheck2.ps1
# Author: ed wilson, msft
# Date: 09/06/2013 13:38:31
# Keywords: Input
# comments: Using 
# Windows PowerShell 4.0 Best Practices, Microsoft Press, 2013
# Chapter 11
# -----------------------------------------------------------------------------
If(!$args.count) 
  {
   Throw "Please supply computer name"
  } #end if
Get-WmiObject -Class Win32_Bios -computername $args
