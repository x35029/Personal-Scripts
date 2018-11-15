﻿# -----------------------------------------------------------------------------
# Script: Test-ScriptHarness.ps1
# Author: ed wilson, msft
# Date: 09/06/2013 18:58:48
# Keywords: Basic Syntax Checking
# comments: Test Script Harness
# Windows PowerShell 4.0 Best Practices, Microsoft Press, 2013
# Chapter 13
# -----------------------------------------------------------------------------
if((Get-WmiObject win32_computersystem).model -ne "virtual machine")
  {
    $response = Read-Host -prompt "This script is best run in a VM. 
    Do you wish to continue? <y / n>"
    if ($response -eq "n") { exit }
  }
$path = "C:\ScriptFolder"
$report = [io.path]::GetTempFileName()
Get-ChildItem -Path $path -Include *.ps1 -Recurse |
ForEach-Object -Begin `
  { 
   $stime = Get-Date
   $ErrorActionPreference = "SilentlyContinue" 
   "Testing ps1 scripts in $path $stime" | 
     Out-File -append -FilePath $report
  } -Process `
  {
   $error.Clear() 
   $startTime = Get-Date
   "  Begin Testing $_ at $startTime" | 
     Out-File -append -FilePath $report
   Invoke-Expression -Command $_ 
   $endTime = Get-Date
   "  End testing $_ at $endTime." | 
     Out-File -append -FilePath $report
   "    Script generated $($error.Count) errors" | 
     Out-File -append -FilePath $report
   "    Elasped time: $($endTime - $startTime)" |
     Out-File -append -FilePath $report
  } -end `
  { 
   $etime = Get-Date
   $ErrorActionPreference = "Continue"
   "Completed testing all scripts in $path $etime" | 
     Out-File -append -FilePath $report
   "Testing took $($etime - $stime)" | 
     Out-File -append -FilePath $report
  }
  
  Notepad $report
