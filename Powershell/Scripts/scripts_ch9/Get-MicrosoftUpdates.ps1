# -----------------------------------------------------------------------------
# Script: Get-MicrosoftUpdates.ps1
# Author: ed wilson, msft
# Date: 08/28/2013 17:46:25
# Keywords: help
# comments: Thirteen Rules for effective comments
# Windows PowerShell 4.0 Best Practices, Microsoft Press, 2013
# Chapter 9
# -----------------------------------------------------------------------------
# ------------------------------------------------------------------------
# NAME: Get-MicrosoftUpdates.ps1
# AUTHOR: ed wilson, Microsoft
# DATE: 2/25/2009
#
# KEYWORDS: Microsoft.Update.Session, com
#
# COMMENTS: This script lists the Microsoft Updates
# you can select a certain number, or you can choose 
# all of the updates.
#
# HSG 3-9-2009
# ------------------------------------------------------------------------
Function Get-MicrosoftUpdates
{ 
  Param(
        $NumberOfUpdates,
        [switch]$all
       )
  $Session = New-Object -ComObject Microsoft.Update.Session
  $Searcher = $Session.CreateUpdateSearcher()
  if($all)
    {
      $HistoryCount = $Searcher.GetTotalHistoryCount()
      $Searcher.QueryHistory(1,$HistoryCount)
    } #end if all
  Else 
    { 
      $Searcher.QueryHistory(1,$NumberOfUpdates) 
    } #end else
} #end Get-MicrosoftUpdates

# *** entry point to script ***

# lists the latest update
# Get-MicrosoftUpdates -NumberofUpdates 1 

# lists All updates
Get-MicrosoftUpdates -all
