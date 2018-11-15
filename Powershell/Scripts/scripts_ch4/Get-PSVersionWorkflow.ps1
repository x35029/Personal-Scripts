# -----------------------------------------------------------------------------
# Script: Get-PSVersionWorkflow.ps1
# Author: ed wilson, msft
# Date: 08/24/2013 13:52:08
# Keywords: Workflow
# comments: powershell version
# Windows PowerShell 4.0 Best Practices, Microsoft Press, 2013
# Chapter 4
# -----------------------------------------------------------------------------
workflow Get-PSVersion
{
 InlineScript {$PSVersionTable.psversion}
}