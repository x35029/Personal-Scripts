# -----------------------------------------------------------------------------
# Script: GetWmiClassesFunction1.ps1
# Author: ed wilson, msft
# Date: 09/06/2013 13:07:26
# Keywords: help
# comments: Using comment-based help
# Windows PowerShell 4.0 Best Practices, Microsoft Press, 2013
# Chapter 9
# -----------------------------------------------------------------------------
Function Get-WmiClasses(
                        $class=($paramMissing=$true),
                        $ns="root\cimv2"
                       )
{
<#
    .SYNOPSIS 
      Displays a list of WMI Classes based upon a search criteria
    .EXAMPLE
     Get-WmiClasses -class disk -ns root\cimv2"
     This command finds wmi classes that contain the word disk. The 
     classes returned are from the root\cimv2 namespace.
#>
  If($local:paramMissing)
    {
      throw "USAGE: getwmi2 -class <class type> -ns <wmi namespace>"
    } #$local:paramMissing
  "`nClasses in $ns namespace ...."
  Get-WmiObject -namespace $ns -list | 
  where-object {
                 $_.name -match $class -and `
                 $_.name -notlike 'cim*' 
               }
  # mred function
} #end get-wmiclasses
