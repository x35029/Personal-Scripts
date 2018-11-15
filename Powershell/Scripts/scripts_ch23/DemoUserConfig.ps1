# -----------------------------------------------------------------------------
# Script: DemoUserConfig.ps1
# Author: ed wilson, msft
# Date: 09/08/2013 20:36:21
# Keywords: DSC configuration data
# comments: creating users and groups
# Windows PowerShell 4.0 Best Practices, Microsoft Press, 2013
# Chapter 23
# -----------------------------------------------------------------------------
#Requires -version 4.0
Configuration DemoUser
{
 $Password = Get-Credential
    node Server1
    {
      User EdUser
      {
        UserName = "ed"
        Password = $cred
        Description = "local ed account"
        Ensure = "Present"
        Disabled = $false
        PasswordNeverExpires = $true
        PasswordChangeRequired = $false
      } 
     }
    }

DemoUser