# -----------------------------------------------------------------------------
# Script: MeasureAddOneR2Function.ps1
# Author: ed wilson, msft
# Date: 08/28/2013 12:10:06
# Keywords: function
# comments: Understanding Filters
# Windows PowerShell 4.0 Best Practices, Microsoft Press, 2013
# Chapter 8
# -----------------------------------------------------------------------------
Function AddOneR2
{ 
   Process { 
   "add one function r2"
   $_ + 1
  }
} #end AddOneR2

Measure-Command {1..50000 | addOneR2 }
