# -----------------------------------------------------------------------------
# Script: My-Function.ps1
# Author: ed wilson, msft
# Date: 09/07/2013 16:31:32
# Keywords: Debugging
# comments: Errors
# Windows PowerShell 4.0 Best Practices, Microsoft Press, 2013
# Chapter 19
# -----------------------------------------------------------------------------
Function my-function
{
 Param(
  [int]$a,
  [int]$b)
  "$a plus $b equals four"
} 
