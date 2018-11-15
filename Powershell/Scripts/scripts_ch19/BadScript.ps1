# -----------------------------------------------------------------------------
# Script: BadScript.ps1
# Author: ed wilson, msft
# Date: 09/07/2013 16:18:52
# Keywords: Using Set-PSDebug
# comments: Stepping through code
# Windows PowerShell 4.0 Best Practices, Microsoft Press, 2013
# Chapter 19
# -----------------------------------------------------------------------------
Function AddOne([int]$num)
{
 $num+1
} #end function AddOne

Function AddTwo([int]$num)
{
 $num+2
} #end function AddTwo

Function SubOne([int]$num)
{
 $num-1
} #end function SubOne

Function TimesOne([int]$num)
{
  $num*2
} #end function TimesOne

Function TimesTwo([int]$num)
{
 $num*2
} #end function TimesTwo

Function DivideNum([int]$num)
{ 
 12/$num
} #end function DivideNum

# *** Entry Point to Script ***

$num = 0
SubOne($num) | DivideNum($num)
AddOne($num) | AddTwo($num)
