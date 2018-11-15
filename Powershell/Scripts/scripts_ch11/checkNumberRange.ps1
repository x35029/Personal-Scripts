# -----------------------------------------------------------------------------
# Script: checkNumberRange.ps1
# Author: ed wilson, msft
# Date: 09/06/2013 14:47:25
# Keywords: Input
# comments: Validate Parameter Input
# Windows PowerShell 4.0 Best Practices, Microsoft Press, 2013
# Chapter 11
# -----------------------------------------------------------------------------
Param($number)

Function Check-Number($number)
{
 if($number -ge 1 -And $number -le 5)
  {  $true }
 Else
  { $false }
} #end check-number

Function Set-Number($number)
{
 $number * 2
} #end Set-Number

# *** Start of script ***
If(Check-Number($number))
  { Set-Number($number) }
Else
  { '$number is out of bounds' }
