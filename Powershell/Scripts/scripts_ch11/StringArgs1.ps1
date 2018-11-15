# -----------------------------------------------------------------------------
# Script: StringArgs1.ps1
# Author: ed wilson, msft
# Date: 09/06/2013 13:36:56
# Keywords: Input
# comments: Using 
# Windows PowerShell 4.0 Best Practices, Microsoft Press, 2013
# Chapter 11
# -----------------------------------------------------------------------------
$args | Foreach-Object {
'The value of arg0 ' + $_ + ' the value of arg1 ' + $_ 
}
