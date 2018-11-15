# -----------------------------------------------------------------------------
# Script: OpenPasswordProtectedExcel.ps1
# Author: ed wilson, msft
# Date: 09/06/2013 15:15:57
# Keywords: Input
# comments: Connection Strings
# Windows PowerShell 4.0 Best Practices, Microsoft Press, 2013
# Chapter 11
# -----------------------------------------------------------------------------
$filename = "C:\fso\TestNumbersProtected.xls"
$updatelinks = 3
$readonly = $false
$format = 5
$password = "password"
$excel = New-Object -comobject Excel.Application
$excel.visible = $true
$excel.workbooks.open($fileName,$updatelinks,$readonly,$format,$password) |
Out-Null
