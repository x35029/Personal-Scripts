# -----------------------------------------------------------------------------
# Script: DocsFolderVariable.ps1
# Author: ed wilson, msft
# Date: 08/25/2013 16:50:39
# Keywords: variable
# comments: Configuring a profile
# Windows PowerShell 4.0 Best Practices, Microsoft Press, 2013
# Chapter 5
# -----------------------------------------------------------------------------
New-Variable -Name docs -Value (Join-Path -Path $home -ChildPath documents) `
-Option readonly -Description "MrEd Variable"
