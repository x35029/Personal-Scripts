# -----------------------------------------------------------------------------
# Script: AddOne6.ps1
# Author: ed wilson, msft
# Date: 09/06/2013 15:33:25
# Keywords: Output
# comments: OutPut from Functions
# Windows PowerShell 4.0 Best Practices, Microsoft Press, 2013
# Chapter 11
# -----------------------------------------------------------------------------
Function AddOne($int)
{
 ${Global:AddOne6.number} =  $int + 1 
}

AddOne(5)
${AddOne6.number} | get-member
'Display the value of ${AddOne6.number}: ' + ${AddOne6.number}
