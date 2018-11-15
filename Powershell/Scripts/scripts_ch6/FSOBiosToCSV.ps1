# -----------------------------------------------------------------------------
# Script: FSOBiosToCSV.ps1
# Author: ed wilson, msft
# Date: 08/25/2013 18:39:45
# Keywords: cmdlet
# comments: CmdLet support
# Windows PowerShell 4.0 Best Practices, Microsoft Press, 2013
# Chapter 6
# -----------------------------------------------------------------------------
$path = "c:\fso\bios1.csv"
$bios = Get-CimInstance -ClassName win32_bios
$csv = "Name,Version`r`n"
$csv +=$bios.name + "," + $bios.version
$fso = new-object -comobject scripting.filesystemobject
$file = $fso.CreateTextFile($path,$true)
$file.write($csv)
$file.close()
