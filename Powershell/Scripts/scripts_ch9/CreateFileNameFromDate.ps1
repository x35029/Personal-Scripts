# -----------------------------------------------------------------------------
# Script: CreateFileNameFromDate.ps1
# Author: ed wilson, msft
# Date: 08/28/2013 12:47:22
# Keywords: help
# comments: Adding Help Documentation
# Windows PowerShell 4.0 Best Practices, Microsoft Press, 2013
# Chapter 9
# -----------------------------------------------------------------------------
# ------------------------------------------------------------------------
# NAME: CreateFileNameFromDate.ps1
# AUTHOR: ed wilson, Microsoft
# DATE:12/15/2008
#
# KEYWORDS: .NET framework, io.path, get-date
# file, new-item, Standard Date and Time Format Strings
# regular expression, ref, pass by reference
#
# COMMENTS: This script creates an empty text file
# based upon the date-time stamp. Uses format string
# to specify a sortable date. Uses getInvalidFileNameChars
# method to get all the invalid characters that are not allowed
# in a file name. It assumes there is a folder named fso off the
# c:\ drive. If the folder does not exist, the script will fail. 
#
# ------------------------------------------------------------------------
Function GetFileName([ref]$fileName)
{
 $invalidChars = [io.path]::GetInvalidFileNamechars() 
 $date = Get-Date -format s
 $fileName.value = ($date.ToString() -replace "[$invalidChars]","-") + ".txt"
}

$fileName = $null
GetFileName([ref]$fileName)
new-item -path c:\fso -name $filename -itemtype file
