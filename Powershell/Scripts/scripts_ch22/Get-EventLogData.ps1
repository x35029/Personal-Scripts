# -----------------------------------------------------------------------------
# Script: Get-EventLogData.ps1
# Author: ed wilson, msft
# Date: 09/07/2013 17:57:43
# Keywords: workflow
# comments: workflow
# Windows PowerShell 4.0 Best Practices, Microsoft Press, 2013
# Chapter 22
# -----------------------------------------------------------------------------
WorkFlow Get-EventLogData
{
 Parallel
 { 
   Get-EventLog -LogName application -Newest 1
   Get-EventLog -LogName system -Newest 1
   Get-EventLog -LogName 'Windows PowerShell' -Newest 1 } }