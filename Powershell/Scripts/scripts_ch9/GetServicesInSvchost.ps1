﻿# -----------------------------------------------------------------------------
# Script: GetServicesInSvchost.ps1
# Author: ed wilson, msft
# Date: 08/28/2013 17:45:15
# Keywords: help
# comments: Thirteen Rules for effective comments
# Windows PowerShell 4.0 Best Practices, Microsoft Press, 2013
# Chapter 9
# -----------------------------------------------------------------------------
# ------------------------------------------------------------------------
# NAME: GetServicesInSvchost.ps1
# AUTHOR: ed wilson, Microsoft
# DATE: 8/21/2008
#
# KEYWORDS: Get-WmiObject, Format-Table, 
# Foreach-Object
#
# COMMENTS: This script creates an array of WMI process
# objects and retrieves the handle of each process object.
# According to MSDN the handle is a process identifier. It
# is also the key of the Win32_Process class. The script
# then uses the handle which is the same as the processID
# property from the Win32_service class to retrieve the
# matches. 
#
# HSG 8/28/2008
# ------------------------------------------------------------------------

$aryPid = @(Get-WmiObject win32_process -Filter "name='svchost.exe'") | 
  Foreach-Object { $_.Handle } 

"There are " + $arypid.length + " instances of svchost.exe running"

foreach ($i in $aryPID) 
{ 
 Write-Host "Services running in ProcessID: $i" ; 
 Get-WmiObject win32_service -Filter " processID = $i" | 
 Format-Table name, state, startMode 
}
