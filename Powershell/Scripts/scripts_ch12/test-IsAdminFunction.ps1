# -----------------------------------------------------------------------------
# Script: Test-IsAdminFunction.ps1
# Author: ed wilson, msft
# Date: 08/24/2013 20:13:55
# Keywords: Security
# comments: Security Requirements
# Windows PowerShell 4.0 Best Practices, Microsoft Press, 2013
# Chapter 12
# -----------------------------------------------------------------------------
Function Test-IsAdmin
{
 <#
    .Synopsis
        Tests if the user is an administrator
    .Description
        Returns true if a user is an administrator, false if the user is not an administrator        
    .Example
        Test-IsAdmin
    #>
 $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
 $principal = New-Object Security.Principal.WindowsPrincipal $identity
 $principal.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
}