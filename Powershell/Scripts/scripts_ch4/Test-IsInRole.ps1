# -----------------------------------------------------------------------------
# Script: Test-IsInRole.ps1
# Author: ed wilson, msft
# Date: 08/24/2013 20:20:25
# Keywords: Security
# comments: Security Requirements
# Windows PowerShell 4.0 Best Practices, Microsoft Press, 2013
# Chapter 4
# -----------------------------------------------------------------------------
Function Test-Isinrole
{
 <#
    .Synopsis
        Tests if the user is in a specific role
    .Description
        Returns true if a user is the role, false if the user is not in the role        
    .Example
        Test-Isinrole -role Guest
    #>
    Param($roleName)
 $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
 $principal = New-Object Security.Principal.WindowsPrincipal $identity
 $principal.IsInRole([Security.Principal.WindowsBuiltinRole]::$roleName)
}