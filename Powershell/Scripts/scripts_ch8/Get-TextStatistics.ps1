# -----------------------------------------------------------------------------
# Script: Get-TextStatistics.ps1
# Author: ed wilson, msft
# Date: 08/28/2013 10:44:48
# Keywords: function
# comments: understanding
# Windows PowerShell 4.0 Best Practices, Microsoft Press, 2013
# Chapter 8
# -----------------------------------------------------------------------------
Get-TextStatistics.ps1Function Get-TextStatistics($path)
{
 Get-Content -path $path |
 Measure-Object -line -character -word
}
