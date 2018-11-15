﻿# -----------------------------------------------------------------------------
# Script: Copy-Modules.ps1
# Author: ed wilson, msft
# Date: 09/07/2013 17:33:15
# Keywords: modules
# comments: installing
# Windows PowerShell 4.0 Best Practices, Microsoft Press, 2013
# Chapter 10
# -----------------------------------------------------------------------------
Function Get-OperatingSystemVersion
{
 (Get-WmiObject -Class Win32_OperatingSystem).Version
} #end Get-OperatingSystemVersion

Function Test-ModulePath
{
 $VistaPath = "$env:userProfile\documents\WindowsPowerShell\Modules"
 $XPPath =  "$env:Userprofile\my documents\WindowsPowerShell\Modules" 
 if ([int](Get-OperatingSystemVersion).substring(0,1) -ge 6) 
   { 
     if(-not(Test-Path -path $VistaPath))
       {
         New-Item -Path $VistaPath -itemtype directory | Out-Null
       } #end if
   } #end if
 Else 
   {  
     if(-not(Test-Path -path $XPPath))
       {
         New-Item -path $XPPath -itemtype directory | Out-Null
       } #end if
   } #end else
} #end Test-ModulePath

Function Copy-Module([string]$name)
{
 $UserPath = $env:PSModulePath.split(";")[0]
 $ModulePath = Join-Path -path $userPath `
               -childpath (Get-Item -path $name).basename
 New-Item -path $modulePath -itemtype directory | Out-Null
 Copy-Item -path $name -destination $ModulePath | Out-Null
}

# *** Entry Point to Script *** 
Test-ModulePath
Get-ChildItem -Path C:\fso -Include *.psm1,*.psd1 -Recurse |
ForEach-Object { Copy-Module -name $_.fullName }
