# -----------------------------------------------------------------------------
# Script: Get-CompInfoWorkflowCheckPointWorkflow.ps1
# Author: ed wilson, msft
# Date: 09/07/2013 17:56:52
# Keywords: workflow
# comments: workflow
# Windows PowerShell 4.0 Best Practices, Microsoft Press, 2013
# Chapter 22
# -----------------------------------------------------------------------------
workflow Get-CompInfo
{
  Get-NetAdapter
  Get-Disk
  Get-Volume
  Checkpoint-Workflow
}