# -----------------------------------------------------------------------------
# Script: StringArgs2.ps1
# Author: ed wilson, msft
# Date: 09/06/2013 13:37:25
# Keywords: Input
# comments: Using 
# Windows PowerShell 4.0 Best Practices, Microsoft Press, 2013
# Chapter 11
# -----------------------------------------------------------------------------
$args | Foreach-Object {
'The value of arg0 ' + $_[0] + ' the value of arg1 ' + $_[1]
}
