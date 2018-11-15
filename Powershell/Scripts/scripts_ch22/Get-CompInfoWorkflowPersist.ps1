# -----------------------------------------------------------------------------
# Script: Get-CompInfoWorkflowPersist.ps1
# Author: ed wilson, msft
# Date: 09/07/2013 17:57:11
# Keywords: workflow
# comments: workflow
# Windows PowerShell 4.0 Best Practices, Microsoft Press, 2013
# Chapter 22
# -----------------------------------------------------------------------------
workflow Get-CompInfo
{
  Get-process -PSPersist $true
  Get-Disk 
  Get-service -PSPersist $true
}