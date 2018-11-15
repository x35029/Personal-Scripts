# -----------------------------------------------------------------------------
# Script: BusinessLogicDemo.ps1
# Author: ed wilson, msft
# Date: 08/28/2013 11:57:34
# Keywords: function
# comments: Business Logic
# Windows PowerShell 4.0 Best Practices, Microsoft Press, 2013
# Chapter 8
# -----------------------------------------------------------------------------
Function Get-Discount
{
 Param ([double]$rate,[int]$total)
 $rate * $total 
} #end Get-Discount

 $rate = .05
$total = 100
$discount = Get-Discount -rate $rate -total $total
"Total: $total"
"Discount: $discount"
"Your Total: $($total-$discount)"

