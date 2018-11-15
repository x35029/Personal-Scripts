# -----------------------------------------------------------------------------
# Script: Get-MoreHelp.ps1
# Author: ed wilson, msft
# Date: 08/25/2013 13:31:05
# Keywords: function
# comments: Configuring a profile
# Windows PowerShell 4.0 Best Practices, Microsoft Press, 2013
# Chapter 5
# -----------------------------------------------------------------------------
Function Get-MoreHelp()
{
 Get-Help $args[0] -Full | 
 more
} #end Get-MoreHelp
