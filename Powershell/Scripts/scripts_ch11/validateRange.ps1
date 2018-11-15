# -----------------------------------------------------------------------------
# Script: validateRange.ps1
# Author: ed wilson, msft
# Date: 09/06/2013 14:49:08
# Keywords: Input
# comments: Validate Parameter INput
# Windows PowerShell 4.0 Best Practices, Microsoft Press, 2013
# Chapter 11
# -----------------------------------------------------------------------------
#requires -version 4.0
Param( 
      [ValidateRange(1,5)]
      $number
     )

Function Set-Number($number)
{
 $number * 2
} #end Set-Number

# *** Entry point to script ***
Set-Number($number)
