# -----------------------------------------------------------------------------
# Script: FilterHasMessage.ps1
# Author: ed wilson, msft
# Date: 08/28/2013 12:10:36
# Keywords: function
# comments: Understanding Filters
# Windows PowerShell 4.0 Best Practices, Microsoft Press, 2013
# Chapter 8
# -----------------------------------------------------------------------------
Filter HasMessage
{
 $_ |
 Where-Object { $_.message }
} #end HasMessage

Get-WinEvent -LogName Application | HasMessage | Measure-Object
