# -----------------------------------------------------------------------------
# Script: Get-EnabledBreakpointsFunction.ps1
# Author: ed wilson, msft
# Date: 09/07/2013 16:27:30
# Keywords: Debugging
# comments: Breakpoints
# Windows PowerShell 4.0 Best Practices, Microsoft Press, 2013
# Chapter 19
# -----------------------------------------------------------------------------
Function Get-EnabledBreakpoints
{
  Get-PSBreakpoint | 
  Format-Table -Property id, script, command, variable, enabled -AutoSize
}

# *** Entry Point to Script ***

Get-EnabledBreakpoints
