# -----------------------------------------------------------------------------
# Script: DemoTrapSystemException.ps1
# Author: ed wilson, msft
# Date: 08/28/2013 11:54:59
# Keywords: function
# comments: type constraint
# Windows PowerShell 4.0 Best Practices, Microsoft Press, 2013
# Chapter 8
# -----------------------------------------------------------------------------
Function My-Test([int]$myinput)
{
 
 "It worked"
} #End my-test function
# *** Entry Point to Script ***

Trap [SystemException] { "error trapped" ; continue }
My-Test -myinput "string"
"After the error"
