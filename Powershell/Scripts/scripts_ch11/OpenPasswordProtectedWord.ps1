# -----------------------------------------------------------------------------
# Script: OpenPasswordProtectedWord.ps1
# Author: ed wilson, msft
# Date: 09/06/2013 15:17:13
# Keywords: Input
# comments: Connection Strings
# Windows PowerShell 4.0 Best Practices, Microsoft Press, 2013
# Chapter 11
# -----------------------------------------------------------------------------
#requires -version 2.0
Param(
  [Parameter(Mandatory=$true)]
  [string]$fileName,
  [Parameter(Mandatory=$true)]
  [string]$password
) 
Function Open-PasswordProtectedDocument($filename,$password)
{
 $Conversion= $false
 $readOnly = $false
 $addRecentFiles = $false
 $doc = New-Object -Comobject Word.Application
 $doc.visible = $true
 $doc.documents.open($filename,$Conversion,$readOnly,$addRecentFiles,$password) |  
 out-null
} #end function Open-PasswordProtectedDocument

# *** Entry Point to Script ***

Open-PasswordProtectedDocument -filename $filename -password $password
