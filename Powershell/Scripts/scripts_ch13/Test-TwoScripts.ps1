# -----------------------------------------------------------------------------
# Script: Test-TwoScripts.ps1
# Author: ed wilson, msft
# Date: 09/06/2013 20:31:35
# Keywords: Performance
# comments: Functions
# Windows PowerShell 4.0 Best Practices, Microsoft Press, 2013
# Chapter 13
# -----------------------------------------------------------------------------
Param(
  [string]$baseLineScript,
  [string]$modifiedScript,
  [int]$numberOfTests = 20,
  [switch]$log
) #end param

Function Test-Scripts
{
  Param(
  [string]$baseLineScript,
  [string]$modifiedScript,
  [int]$numberOfTests,
  [switch]$log
) #end param
 Measure-Command -Expression { $baseLineScript }
 Measure-Command -Expression { $modifiedScript }
} #end Test-Scripts function

Function Get-Change($baseLine, $modified)
{
  (($baseLine - $modified)/$baseLine)*100
} #end Get-Change function

Function Get-TempFile
{
 [io.path]::GetTempFileName()
} #end Get-TempFile function

# *** Entry Point To Script
if($log) { $logFile = Get-TempFile }
For($i = 0 ; $i -le $numberOfTests ; $i++)
{
 "Test $i of $numberOfTests" ; start-sleep -m 50 ; cls
 $results= Test-Scripts -baseLineScript $baseLineScript -modifiedScript $modifedScript
 $baseLine += $results[0].TotalSeconds
 $modified += $results[1].TotalSeconds
 If($log)
  {
     "$baseLineScript run $i of $numberOfTests $(get-date)" >> $logFile
     $results[0] >> $logFile
     "$modifiedScript run $i of $numberOfTests $(get-date)" >> $logFile
     $results[1] >> $logFile
  } #if $log
} #for $i 

"Average change over $numberOfTests tests"
"BaseLine: $baseLineScript average Total Seconds: $($baseLine/$numberOfTests)"
"Modified: $modifiedScript average Total Seconds: $($modified/$numberOfTests)"
"Percent Change: " + "{0:N2}" -f (Get-Change -baseLine $baseLine -modified $modified)
if($log)
{
 "Average change over $numberOfTests tests" >> $logFile
 "BaseLine: $baseLineScript average Total Seconds: $($baseLine/$numberOfTests)" >> $logFile
 "Modified: $modifiedScript average Total Seconds: $($modified/$numberOfTests)" >> $logFile
 "Percent Change: " + "{0:N2}" -f (Get-Change -baseLine $baseLine -modified $modified) >> $logFile
} #if $log
if($log) { Notepad $logFile }
