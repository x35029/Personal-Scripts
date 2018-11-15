# -----------------------------------------------------------------------------
# Script: DemoAddOneFunction.ps1
# Author: ed wilson, msft
# Date: 08/28/2013 12:09:07
# Keywords: function
# comments: Understanding Filters
# Windows PowerShell 4.0 Best Practices, Microsoft Press, 2013
# Chapter 8
# -----------------------------------------------------------------------------
Function AddOne
{  
  "Add One Function"
  While ($input.moveNext())
   {
     $input.current + 1
   }
}

1..5 | addOne
