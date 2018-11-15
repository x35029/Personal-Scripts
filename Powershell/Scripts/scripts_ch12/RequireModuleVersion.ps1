# -----------------------------------------------------------------------------
# Script: RequireModuleVersion.ps1
# Author: ed wilson, msft
# Date: 09/06/2013 18:16:14
# Keywords: Using Requires
# comments: admin rights
# Windows PowerShell 4.0 Best Practices, Microsoft Press, 2013
# Chapter 12
# -----------------------------------------------------------------------------
#Requires -version 4.0
#Requires -RunAsAdministrator
#Requires -modules ScheduledTasks, @{ModuleName='StartScreen';ModuleVersion='1.0.0.0'}
Import-Module StartScreen
Get-StartApps
Get-ScheduledTask

