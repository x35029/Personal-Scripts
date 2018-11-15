# -----------------------------------------------------------------------------
# Script: get-WmiClass.ps1
# Author: ed wilson, msft
# Date: 08/25/2013 15:40:55
# Keywords: function
# comments: Configuring a profile
# Windows PowerShell 4.0 Best Practices, Microsoft Press, 2013
# Chapter 5
# -----------------------------------------------------------------------------
Function Get-WmiClass()
{
 #.Help Get-WmiClass "root\cimv2" "Processor"
 $ns = $args[0]
 $class = $args[1]
 Get-WmiObject -List -Namespace $ns |
 Where-Object { $_.name -match $class }
} #end Get-WmiClass
