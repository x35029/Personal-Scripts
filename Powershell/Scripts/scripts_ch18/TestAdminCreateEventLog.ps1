# -----------------------------------------------------------------------------
# Script: TestAdminCreateEventLog.ps1
# Author: ed wilson, msft
# Date: 09/07/2013 14:09:17
# Keywords: Logging to the Event Log
# comments: EventLog
# Windows PowerShell 4.0 Best Practices, Microsoft Press, 2013
# Chapter 18
# -----------------------------------------------------------------------------
function Test-IsAdministrator
{
    <#
    .Synopsis
        Tests if the user is an administrator
    .Description
        Returns true if a user is an administrator, 
        false if the user is not an administrator        
    .Example
        Test-IsAdministrator
    #>   
    param() 
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    (New-Object Security.Principal.WindowsPrincipal $currentUser).IsInRole `
    ([Security.Principal.WindowsBuiltinRole]::Administrator)
} #end function Test-IsAdministrator

# *** Entry Point to Script ***
If(-not (Test-IsAdministrator)) { "Admin rights are required for this script" ; exit }
New-EventLog -LogName scripting -Source processAudit
