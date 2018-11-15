# -----------------------------------------------------------------------------
# Script: UpdateHelpTrackErrors.ps1
# Author: ed wilson, msft
# Date: 09/09/2013 15:43:35
# Keywords: Working
# comments: Accessing
# Windows PowerShell 4.0 Best Practices, Microsoft Press, 2013
# Chapter 1
# -----------------------------------------------------------------------------
#requires -version 4.0
#Requires -RunAsAdministrator 
Update-Help -Module * -Force -ea 0
For ($i = 0 ; $i -le $error.Count ; $i ++) 
  { "`nerror $i" ; $error[$i].exception }
