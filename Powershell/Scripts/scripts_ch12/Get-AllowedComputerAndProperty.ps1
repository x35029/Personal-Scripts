# -----------------------------------------------------------------------------
# Script: Get-AllowedComputerAndProperty.ps1
# Author: ed wilson, msft
# Date: 09/06/2013 16:43:35
# Keywords: Liimiting choices
# comments: using -contains
# Windows PowerShell 4.0 Best Practices, Microsoft Press, 2013
# Chapter 12
# -----------------------------------------------------------------------------
Param([string]$computer = $env:computername,[string]$property="name")

Function Get-AllowedComputer([string]$computer, [string]$property)
{
 $servers = Get-Content -path c:\fso\serversAndProperties.txt 
 $s = $servers -contains $computer
 $p = $servers -contains $property
 Return $s -and $p
} #end Get-AllowedComputer function

# *** Entry point to Script ***

if(Get-AllowedComputer -computer $computer -property $property)
 {
   Get-WmiObject -class Win32_Bios -computer $computer | 
   Select-Object -property $property
 }
Else
 {
  "Either $computer is not an allowed computer, `r`nor $property is not an allowed property"
 }
