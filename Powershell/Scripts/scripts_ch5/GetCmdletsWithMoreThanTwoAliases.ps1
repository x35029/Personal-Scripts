# -----------------------------------------------------------------------------
# Script: GetCmdletsWithMoreThanTwoAliases.ps1
# Author: ed wilson, msft
# Date: 08/25/2013 12:35:05
# Keywords: Alias
# comments: Configuring a profile
# Windows PowerShell 4.0 Best Practices, Microsoft Press, 2013
# Chapter 5
# -----------------------------------------------------------------------------
Get-Alias | 
Group-Object -Property definition | 
Sort-Object -Property count -Descending | 
Where-Object count -gt 2 
