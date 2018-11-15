# -----------------------------------------------------------------------------
# Script: Get-MoreHelpWithAlias.ps1
# Author: ed wilson, msft
# Date: 08/25/2013 14:47:19
# Keywords: function, alias
# comments: Configuring a profile
# Windows PowerShell 4.0 Best Practices, Microsoft Press, 2013
# Chapter 5
# -----------------------------------------------------------------------------
Function Get-MoreHelp()
{
 Get-Help $args[0] -full | 
 more
} #End Get-MoreHelp
New-Alias -name gmh -value Get-MoreHelp -Option allscope
