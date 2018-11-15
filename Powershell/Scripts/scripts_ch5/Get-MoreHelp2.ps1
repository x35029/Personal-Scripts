# -----------------------------------------------------------------------------
# Script: Get-MoreHelp2.ps1
# Author: ed wilson, msft
# Date: 08/25/2013 14:48:31
# Keywords: function, alias
# comments: Configuring a profile
# Windows PowerShell 4.0 Best Practices, Microsoft Press, 2013
# Chapter 5
# -----------------------------------------------------------------------------
Function Get-MoreHelp
{
 # .help Get-MoreHelp Get-Command Get-Process
 For($i = 0 ;$i -le $args.count ; $i++)
 {
  Get-Help $args[$i] -full |
  more
 } #end for
} #end Get-MoreHelp
New-Alias -name gmh -value Get-MoreHelp -Option allscope
