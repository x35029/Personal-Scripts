# -----------------------------------------------------------------------------
# Script: Get-BiosArgsTrap1.ps1
# Author: ed wilson, msft
# Date: 09/06/2013 13:39:05
# Keywords: Input
# comments: Using Trap
# Windows PowerShell 4.0 Best Practices, Microsoft Press, 2013
# Chapter 11
# -----------------------------------------------------------------------------
Trap [System.Management.Automation.ParameterBindingException] 
  { 
    Write-Host -foregroundcolor cyan "Supply a computer name"
    Exit
  }

Get-WmiObject -Class Win32_Bios -computername $args
