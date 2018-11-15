# -----------------------------------------------------------------------------
# Script: GetComputerInfoWorkFlow.ps1
# Author: ed wilson, msft
# Date: 09/07/2013 17:57:27
# Keywords: workflow
# comments: workflow
# Windows PowerShell 4.0 Best Practices, Microsoft Press, 2013
# Chapter 22
# -----------------------------------------------------------------------------
Workflow GetComputerInfo
{
 $computers = "server1","client1"
 Foreach -Parallel ($cn in $computers)
 { Get-CimInstance -PSComputerName $cn -ClassName win32_computersystem } }