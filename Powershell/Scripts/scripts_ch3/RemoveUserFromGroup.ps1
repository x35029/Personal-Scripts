# -----------------------------------------------------------------------------
# Script: RemoveUserFromGroup.ps1
# Author: ed wilson, msft
# Date: 09/09/2013 16:39:02
# Keywords: AD
# comments: AD
# Windows PowerShell 4.0 Best Practices, Microsoft Press, 2013
# Chapter 3
# -----------------------------------------------------------------------------
import-module activedirectory
Remove-ADGroupMember -Identity TestGroup1 -Members UserGroupTest -Confirm:$false
