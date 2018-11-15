# -----------------------------------------------------------------------------
# Script: Get-ModifiedFiles.ps1
# Author: ed wilson, msft
# Date: 09/06/2013 19:06:29
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
$files = Get-ChildItem -path $path -recurse 

Foreach($file in $files)
{
  if($file.LastWriteTime -ge $dteModified)
    { $changedFiles ++ }
}

"The $path has $changedFiles modified files since $dteModified"
