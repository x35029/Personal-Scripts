# -----------------------------------------------------------------------------
# Script: Get-ModifiedFilesUsePipeline2.ps1
# Author: ed wilson, msft
# Date: 09/06/2013 20:28:07
# Keywords: Performance
# comments: Reduce code complexity
# Windows PowerShell 4.0 Best Practices, Microsoft Press, 2013
# Chapter 13
# -----------------------------------------------------------------------------
Param(
    $path = "D:\",
    $days = 30
) #end param


$changedFiles = $null
$dteModified= (Get-Date).AddDays(-$days)
$changedFiles = Get-ChildItem -path $path -recurse |
where-object { $_.LastWriteTime -ge $dteModified }

"The $path has $($changedFiles.count) modified files since $dteModified"
