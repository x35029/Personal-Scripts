# -----------------------------------------------------------------------------
# Script: UseGetMemberOf.ps1
# Author: ed wilson, msft
# Date: 08/24/2013 19:47:31
# Keywords: Security
# comments: Security Requirements
# Windows PowerShell 4.0 Best Practices, Microsoft Press, 2013
# Chapter 4
# -----------------------------------------------------------------------------
Function Get-MemberOf
{
 Param ([string]$group,
        [string]$path)
 $user = [System.Security.Principal.WindowsIdentity]::GetCurrent()
 $nt = "System.Security.Principal.NTAccount" -as [type]
 If( $user.Groups.translate($NT) -match "$group" )
   { if(Test-Path -Path $path)
       {
         Add-Content -Path $path -Value "Added bogus content`r`n"
         "Added content to $path"
         Notepad $path
       } #end if Test-Path 
    ELSE
       { "Unable to find $path"} }
 ELSE
 { "$($user.name) is not a member of a $group group" }
} # end function Get-MemberOf

#Get-Memberof -group bogus -path 'C:\bogus\bogusfile.txt'