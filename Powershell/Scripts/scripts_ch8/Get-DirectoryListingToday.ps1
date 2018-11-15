# -----------------------------------------------------------------------------
# Script: Get-DirectoryListingToday.ps1
# Author: ed wilson, msft
# Date: 08/28/2013 11:56:48
# Keywords: function
# comments: multiple input parameters
# Windows PowerShell 4.0 Best Practices, Microsoft Press, 2013
# Chapter 8
# -----------------------------------------------------------------------------
Function Get-DirectoryListing
{
 Param(
       [String]$Path,
       [String]$Extension = "txt",
       [Switch]$Today
      )
 If($Today)
   {
    Get-ChildItem -Path $path\* -include *.$Extension |
    Where-Object { $_.LastWriteTime -ge (Get-Date).Date }
   }
 ELSE 
  {
   Get-ChildItem -Path $path\* -include *.$Extension
  }
} #end Get-DirectoryListing

# *** Entry to script ***
Get-DirectoryListing -p c:\fso –t
