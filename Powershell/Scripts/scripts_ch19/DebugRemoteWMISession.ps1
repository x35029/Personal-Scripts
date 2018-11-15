# -----------------------------------------------------------------------------
# Script: DebugRemoteWMISession.ps1
# Author: ed wilson, msft
# Date: 09/07/2013 16:30:28
# Keywords: Debugging
# comments: Errors
# Windows PowerShell 4.0 Best Practices, Microsoft Press, 2013
# Chapter 19
# -----------------------------------------------------------------------------
$oldDebugPreference = $DebugPreference
$DebugPreference = "continue"
$credential = Get-Credential
$cn = Read-Host -Prompt "enter a computer name"
Write-Debug "user name: $($credential.UserName)"
Write-Debug "password: $($credential.GetNetworkCredential().Password)"
Write-Debug "$cn is up: 
  $(Test-Connection -Computername $cn -Count 1 -BufferSize 16 -quiet)"
Get-WmiObject win32_bios -cn $cn -Credential $credential
$DebugPreference = $oldDebugPreference
