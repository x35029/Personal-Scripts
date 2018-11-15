# -----------------------------------------------------------------------------
# Script: AddOne1.ps1
# Author: ed wilson, msft
# Date: 09/06/2013 15:30:47
# Keywords: Output
# comments: OutPut from Functions
# Windows PowerShell 4.0 Best Practices, Microsoft Press, 2013
# Chapter 11
# -----------------------------------------------------------------------------
Function AddOne($int)
{
 $int + 1 
}

$number = AddOne(5)
$number | get-member
'Display the value of $number: ' + $number
