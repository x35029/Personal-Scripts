# -----------------------------------------------------------------------------
# Script: FindLargeDocs.ps1
# Author: ed wilson, msft
# Date: 08/28/2013 11:58:44
# Keywords: function
# comments: Business Logic
# Windows PowerShell 4.0 Best Practices, Microsoft Press, 2013
# Chapter 8
# -----------------------------------------------------------------------------
Function Get-Doc
{
 Param ($path)
 Get-ChildItem -Path $path -include *.doc,*.docx,*.dot -recurse
} #end Get-Doc

Filter LargeFiles($size)
{
  $_ | Where-Object length -ge $size 
} #end LargeFiles

Get-Doc("C:\FSO") |  LargeFiles 1000
