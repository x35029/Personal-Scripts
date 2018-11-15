# -----------------------------------------------------------------------------
# Script: GetRunningProcess.ps1
# Author: ed wilson, msft
# Date: 08/24/2013 21:28:02
# Keywords: process
# comments: Application Requirements
# Windows PowerShell 4.0 Best Practices, Microsoft Press, 2013
# Chapter 4
# -----------------------------------------------------------------------------
$processName = "iexplore"
if(
   Get-Process | Where ProcessName -eq $processName 
  )
 {
  "$processName is running"
 } #end if
ELSE 
 {
  "$processName is not running"
 } #end else
