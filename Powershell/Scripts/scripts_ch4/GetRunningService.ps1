# -----------------------------------------------------------------------------
# Script: GetRunningService.ps1
# Author: ed wilson, msft
# Date: 08/24/2013 21:24:34
# Keywords: Service
# comments: Application Requirements
# Windows PowerShell 4.0 Best Practices, Microsoft Press, 2013
# Chapter 4
# -----------------------------------------------------------------------------
$serviceName = "ZuneBusEnum"
if(
   Get-Service | 
   Where-Object { $_.status -eq 'running' -AND $_.name -eq $serviceName }
  )
 {
  "$serviceName is running"
 } #end if
ELSE
 {
  "$serviceName is not running"
 } #end else
