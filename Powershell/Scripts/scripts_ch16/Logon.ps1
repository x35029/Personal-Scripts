# -----------------------------------------------------------------------------
# Script: Logon.ps1
# Author: ed wilson, msft
# Date: 09/07/2013 12:00:57
# Keywords: logon scripts
# comments: creates registry and eventlog entries
# Windows PowerShell 4.0 Best Practices, Microsoft Press, 2013
# Chapter 16
# -----------------------------------------------------------------------------
$ErrorActionPreference = "SilentlyContinue"
if(-not(Test-path -path HKCU:\Software\logonScripts))
 {
  new-Item -path HKCU:\Software\logonScripts
  new-Itemproperty -path HKCU:\Software\logonScripts -name logon `
   -Value $(get-date).tostring() -Force
  new-Itemproperty -path HKCU:\Software\logonScripts -name user `
   -Value $env:USERNAME -Force
 }
else
 {
  set-Itemproperty -path HKCU:\Software\logonScripts -name logon `
   -Value $(get-date).tostring() -Force
  set-Itemproperty -path HKCU:\Software\logonScripts -name user `
   -Value $env:USERNAME -Force
 }

try
{
 New-EventLog -source logonscript -logname logonscript
}
Catch{ [System.Exception] }
Finally
{ 
 Write-EventLog -LogName logonscript -Source logonScript `
  -EntryType information `
 -EventId 1 `
 -Message "logon script $($myinvocation.invocationName) ran at $(get-date)"
}
$ErrorActionPreference = "Continue"
