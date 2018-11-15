# -----------------------------------------------------------------------------
# Script: Get-TextStatisticsCallChildFunction-DoesNOTWork-MissingClosingBracket.ps1
# Author: ed wilson, msft
# Date: 08/28/2013 11:03:02
# Keywords: function
# comments: understanding
# Windows PowerShell 4.0 Best Practices, Microsoft Press, 2013
# Chapter 8
# -----------------------------------------------------------------------------
Function Get-TextStatistics($path)
{
 Get-Content -path $path |
 Measure-Object -line -character -word
 Write-Path
# Here is where the missing bracket goes

Function Write-Path()
{
 "Inside Write-Path the `$path variable is equal to $path"
}
Get-TextStatistics("C:\fso\test.txt")
Outside the Get-TextStatistics function `$path is equal to $path"
