# -----------------------------------------------------------------------------
# Script: ScriptFolderVersionUnzipCreateUsersAndProfile.ps1
# Author: ed wilson, msft
# Date: 09/08/2013 20:30:00
# Keywords: DSC configuration data
# comments: creating users and groups
# Windows PowerShell 4.0 Best Practices, Microsoft Press, 2013
# Chapter 23
# -----------------------------------------------------------------------------
#Requires -Version 4.0
Configuration ScriptFolder
{
 Param ($modulePath = ($env:PSModulePath -split ';' | 
    ?  {$_ -match 'Program Files'}))
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
      Group Scripters
      {
        GroupName = "Scripters"
        Credential = $cred
        Description = "Scripting Dudes"
        Members = @("ed")
        DependsOn = "[user]Eduser"
      }
      File ScriptFiles
      {
        SourcePath = "\\dc1\Share\"
        DestinationPath = "C:\scripts"
        Ensure = "present"
        Type = "Directory"
        Recurse = $true
      }
      Registry AddScriptVersion
      {
        Key = "HKEY_Local_Machine\Software\ForScripting"
        ValueName = "ScriptsVersion"
        ValueData = "1.0"
        Ensure = "Present"
      }
      Archive ZippedModule
      {
        DependsOn = "[File]ScriptFiles"
        Path = "C:\scripts\PoshModules\PoshModules.zip"
        Destination = $modulePath
        Ensure = "Present"
      }
      File PoshProfile
      {
        DependsOn = "[File]ScriptFiles"
        SourcePath = "C:\scripts\PoshProfiles\Microsoft.PowerShell_profile.ps1"
        DestinationPath = "$env:USERPROFILE\WindowsPowerShell\Microsoft.PowerShell_profile.ps1"
        Ensure = "Present"
        Type = "File"
        Recurse = $true
      }
      
    }
}

$cred = get-credential
$configData = @{
                AllNodes = @(
                              @{
                                 NodeName = "Server1";
                                 PSDscAllowPlainTextPassword = $true
                                    }
                    )
               }

ScriptFolder -ConfigurationData $configData
Start-DscConfiguration Scriptfolder