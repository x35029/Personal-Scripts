# -----------------------------------------------------------------------------
# Script: Get-ScriptHelp.ps1
# Author: ed wilson, msft
# Date: 09/08/2013 12:16:30
# Keywords: documentation
# comments: Get-Help
# Windows PowerShell 4.0 Best Practices, Microsoft Press, 2013
# Chapter 14
# -----------------------------------------------------------------------------
function New-Underline
{
<#
.Synopsis
 Creates an underline the length of the input string
.Example
 New-Underline -strIN "Hello world"
.Example
 New-Underline -strIn "Morgen welt" -char "-" -sColor "blue" -uColor "yellow"
.Example
 "this is a string" | New-Underline
.Notes
 NAME: New-Underline
 AUTHOR: Ed Wilson
 LASTEDIT: 9/9/2013
 KEYWORDS: Utility
.Link
 Http://www.ScriptingGuys.com
#>
[CmdletBinding()]
param(
      [Parameter(Mandatory = $true,Position = 0,valueFromPipeline=$true)]
      [string]
      $strIN,
      [string]
      $char = "-",
      [string]
      $sColor = "Green",
      [string]
      $uColor = "darkGreen",
      [switch]
      $pipe
 ) #end param
 $strLine= $char * $strIn.length
 if(-not $pipe)
  {
   Write-Host -ForegroundColor $sColor $strIN
   Write-Host -ForegroundColor $uColor $strLine
  }
  Else
  {
  $strIn
  $strLine
  }
} #end New-Underline function

Function Get-ScriptHelp 
{
 [cmdletbinding()]
 Param ($scriptPath,$filePath) 
 Get-ChildItem -Path $scriptPath -filter *.ps1 -Recurse |
 ForEach-Object {
  If(-not($_.psIsContainer))
   { 
     New-Underline "$_" -pipe | Out-File -FilePath $filepath -Append
     Write-Verbose "Getting help for $_.fullName"
     Get-Help $_.fullname -detailed | Out-File -FilePath $filepath -Append
   } #end if
 } #end foreach-object
} #end function get-Scripthelp


# *** Entry Point to Script ***
$ErrorActionPreference = "continue"
$filepath = "C:\fso\BestPracticeScripts.txt"
$Scriptpath = "C:\ScriptFolder"
if(Test-Path $filepath) {Remove-Item $filepath}
Get-ScriptHelp -filepath $filepath -scriptpath $scriptpath -Verbose
Notepad $filepath

