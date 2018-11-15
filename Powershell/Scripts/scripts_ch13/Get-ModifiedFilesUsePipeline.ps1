# -----------------------------------------------------------------------------
# Script: Get-ModifiedFilesUsePipeline.ps1
# Author: ed wilson, msft
# Date: 09/06/2013 19:30:54
# Keywords: Performance
# comments: Store and Forward
# Windows PowerShell 4.0 Best Practices, Microsoft Press, 2013
# Chapter 13
# -----------------------------------------------------------------------------
Param(
    $path = "D:",
    $days = 30
) #end param

$dteModified= (Get-Date).AddDays(-$days)
Get-ChildItem -path $path -recurse |
ForEach-Object {
  if($_.LastWriteTime -ge $dteModified)
    { $changedFiles ++ }
}

"The $path has $changedFiles modified files since $dteModified"
