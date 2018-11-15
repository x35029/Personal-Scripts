# -----------------------------------------------------------------------------
# Script: ExportBiosToCSV.ps1
# Author: ed wilson, msft
# Date: 08/25/2013 18:37:29
# Keywords: cmdlet
# comments: CmdLet support
# Windows PowerShell 4.0 Best Practices, Microsoft Press, 2013
# Chapter 6
# -----------------------------------------------------------------------------
$path = "c:\fso\bios.csv"
Get-CimInstance -ClassName win32_bios |
Select-Object -property name, version |
Export-CSV -path $path –noTypeInformation
