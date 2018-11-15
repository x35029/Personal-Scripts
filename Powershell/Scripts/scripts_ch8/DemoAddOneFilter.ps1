# -----------------------------------------------------------------------------
# Script: DemoAddOneFilter.ps1
# Author: ed wilson, msft
# Date: 08/28/2013 12:08:37
# Keywords: function
# comments: Understanding Filters
# Windows PowerShell 4.0 Best Practices, Microsoft Press, 2013
# Chapter 8
# -----------------------------------------------------------------------------
Filter AddOne
{ 
 "add one filter"
  $_ + 1
}

1..5 | addOne
