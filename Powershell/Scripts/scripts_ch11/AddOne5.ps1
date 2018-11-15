# -----------------------------------------------------------------------------
# Script: AddOne5.ps1
# Author: ed wilson, msft
# Date: 09/06/2013 15:32:52
# Keywords: Output
# comments: OutPut from Functions
# Windows PowerShell 4.0 Best Practices, Microsoft Press, 2013
# Chapter 11
# -----------------------------------------------------------------------------
Function AddOne($int)
{
 $script:number =  $int + 1 
}

AddOne(5)
$script:number | get-member
'Display the value of $script:number: ' + $script:number
