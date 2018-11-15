# -----------------------------------------------------------------------------
# Script: Get-MemberOf.ps1
# Author: ed wilson, msft
# Date: 08/24/2013 17:16:41
# Keywords: Security
# comments: Security Requirements
# Windows PowerShell 4.0 Best Practices, Microsoft Press, 2013
# Chapter 4
# -----------------------------------------------------------------------------
Function Get-MemberOf
{
 Param ($group)
 $user = [System.Security.Principal.WindowsIdentity]::GetCurrent()
 $nt = "System.Security.Principal.NTAccount" -as [type]
 If( $user.Groups.translate($NT) -match "$group" )
  { "$($user.name) is a member of a $group group" }
 ELSE
 { "$($user.name) is not a member of a $group group" }
}
