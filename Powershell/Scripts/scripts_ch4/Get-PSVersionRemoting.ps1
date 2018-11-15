# -----------------------------------------------------------------------------
# Script: Get-PSVersionRemoting.ps1
# Author: ed wilson, msft
# Date: 08/24/2013 13:54:40
# Keywords: remoting
# comments: powershell version
# Windows PowerShell 4.0 Best Practices, Microsoft Press, 2013
# Chapter 4
# -----------------------------------------------------------------------------
Invoke-Command -ScriptBlock {$PSVersionTable.PSVersion} -ComputerName edlt, client1, server1