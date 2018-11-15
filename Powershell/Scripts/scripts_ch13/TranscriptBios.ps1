# -----------------------------------------------------------------------------
# Script: TranscriptBios.ps1
# Author: ed wilson, msft
# Date: 09/06/2013 21:46:58
# Keywords: Use Start-Transcript
# comments: logging
# Windows PowerShell 4.0 Best Practices, Microsoft Press, 2013
# Chapter 13
# -----------------------------------------------------------------------------
Param(
 [Parameter(Mandatory=$true)]
 [string]$path,
 [string]$computer = $env:computername
)#end param

# *** Functions ***

Function Get-Bios($computer)
{
 "Calling function $($myInvocation.InvocationName)"
 Get-WmiObject -class win32_bios -computer $computer
}#end function Get-Bios

# *** Entry point to script ***

Start-Transcript -path $path
"Starting $($myInvocation.InvocationName) at $(Get-Date)"
 
Get-Bios -computer $computer
Stop-Transcript
