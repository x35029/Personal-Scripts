# -----------------------------------------------------------------------------
# Script: Get-ValidWmiClassFunction.ps1
# Author: ed wilson, msft
# Date: 09/06/2013 18:38:21
# Keywords: Incorrect Data Types
# comments: Data types
# Windows PowerShell 4.0 Best Practices, Microsoft Press, 2013
# Chapter 12
# -----------------------------------------------------------------------------
Param (
   [string]$computer = $env:computername, 
   [string]$class, 
   [string]$namespace = "root\cimv2"
) #end param

Function Get-ValidWmiClass([string]$computer, [string]$class, [string]$namespace)
{
 $oldErrorActionPreference = $errorActionPreference
 $errorActionPreference = "SilentlyContinue"
 $Error.Clear()
 [wmiclass]"\\$computer\$($namespace):$class" | out-null
 If($error.count) { Return $false } Else { Return $true }
 $Error.Clear()
 $errorActionPreference =  $oldErrorActionPreference
} # end Get-ValidWmiClass function

Function Get-WmiInformation ([string]$computer, [string]$class, [string]$namespace)
{
  Get-WmiObject -class $class -computername $computer -namespace $namespace|
  Format-List -property [a-z]*
} # end Get-WmiInformation function

# *** Entry point to script ***

If(Get-ValidWmiClass -computer $computer -class $class -namespace $namespace) 
  {
    Get-WmiInformation -computer $computer -class $class -namespace $namespace
  }
Else
 {
   "$class is not a valid wmi class in the $namespace namespace on $computer" 
 }
