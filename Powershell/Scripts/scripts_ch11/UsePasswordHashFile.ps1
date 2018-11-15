# -----------------------------------------------------------------------------
# Script: UsePasswordHashFile.ps1
# Author: ed wilson, msft
# Date: 09/06/2013 15:15:06
# Keywords: Input
# comments: Password Input
# Windows PowerShell 4.0 Best Practices, Microsoft Press, 2013
# Chapter 11
# -----------------------------------------------------------------------------
$user = "Nwtraders\administrator"
$password = ConvertTo-SecureString -String (Get-content C:\fso\passwordHash.txt)
$credential = new-object system.management.automation.PSCredential $user,$password
Get-WmiObject -class Win32_Bios -computername berlin -credential $credential
