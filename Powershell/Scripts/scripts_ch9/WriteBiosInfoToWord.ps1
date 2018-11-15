# -----------------------------------------------------------------------------
# Script: WriteBiosInfoToWord.ps1
# Author: ed wilson, msft
# Date: 08/28/2013 13:45:51
# Keywords: help
# comments: Thirteen Rules for effective comments
# Windows PowerShell 4.0 Best Practices, Microsoft Press, 2013
# Chapter 9
# -----------------------------------------------------------------------------
#============================================================================
#  
# NAME: WriteBiosInfoToWord.ps1
# 
# AUTHOR: ed wilson , Microsoft 
# DATE  : 10/30/2008
# EMAIL: Scripter@Microsoft.com
# Version: 1.0
# 
# COMMENT: Uses the word.application object to create a new text document
# uses the get-wmiobject cmdlet to query wmi
# uses out-string to remove the "object nature" of the returned information
# uses foreach-object cmdlet to write the data to the word document.
# 
# Hey Scripting Guy! 11/11/2008
#============================================================================

$class = "Win32_Bios"
$path = "C:\fso\bios"

#The wdSaveFormat object must be saved as a reference type. 
[ref]$SaveFormat = "microsoft.office.interop.word.WdSaveFormat" -as [type]

$word = New-Object -ComObject word.application
$word.visible = $true
$doc = $word.documents.add()
$selection = $word.selection
$selection.typeText("This is the bios information")
$selection.TypeParagraph()

Get-WmiObject -class $class | 
Out-String |
ForEach-Object { $selection.typeText($_) }
$doc.saveas([ref] $path, [ref]$saveFormat::wdFormatDocument)
$word.quit()
