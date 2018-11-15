# -----------------------------------------------------------------------------
# Script: Get-VolumeWithCredentials.ps1
# Author: ed wilson, msft
# Date: 08/25/2013 19:49:04
# Keywords: cmdlet
# comments: CmdLet support
# Windows PowerShell 4.0 Best Practices, Microsoft Press, 2013
# Chapter 6
# -----------------------------------------------------------------------------
$cim = New-CimSession -Credential iammred\administrator -ComputerName client1
Get-Volume -CimSession $cim