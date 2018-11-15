# -----------------------------------------------------------------------------
# Script: SearchAllComputersInDomain.ps1
# Author: ed wilson, msft
# Date: 08/28/2013 17:45:51
# Keywords: help
# comments: Thirteen Rules for effective comments
# Windows PowerShell 4.0 Best Practices, Microsoft Press, 2013
# Chapter 9
# -----------------------------------------------------------------------------
$Filter = "ObjectCategory=computer"
$Searcher = New-Object System.DirectoryServices.DirectorySearcher($Filter)
$Searcher.Findall() | 
Foreach-Object `
  -Begin { "Results of $Filter query: " } `
  -Process { $_.properties ; "`r"} `
  -End { [string]$Searcher.FindAll().Count + " $Filter results were found" }
