# -----------------------------------------------------------------------------
# Script: ConvertToMeters.ps1
# Author: ed wilson, msft
# Date: 08/28/2013 11:08:07
# Keywords: function
# comments: understanding
# Windows PowerShell 4.0 Best Practices, Microsoft Press, 2013
# Chapter 8
# -----------------------------------------------------------------------------
Function Script:ConvertToMeters($feet)
{
  "$feet feet equals $($feet*.31) meters"
} #end ConvertToMeters
$feet = 5
ConvertToMeters -Feet $feet
