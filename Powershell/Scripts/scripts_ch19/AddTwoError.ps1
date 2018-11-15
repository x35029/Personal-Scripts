# -----------------------------------------------------------------------------
# Script: AddTwoError.ps1
# Author: ed wilson, msft
# Date: 09/07/2013 16:25:10
# Keywords: Using Set-StrictMode
# comments: Debugging
# Windows PowerShell 4.0 Best Practices, Microsoft Press, 2013
# Chapter 19
# -----------------------------------------------------------------------------
Function add-two ($a,$b)
{
 $a + $b
}

add-two(1,2)
