# -----------------------------------------------------------------------------
# Script: Get-WMiClass2withAlias.ps1
# Author: ed wilson, msft
# Date: 08/25/2013 15:47:46
# Keywords: function
# comments: Configuring a profile
# Windows PowerShell 4.0 Best Practices, Microsoft Press, 2013
# Chapter 5
# -----------------------------------------------------------------------------
Function Get-WmiClass
{
  <#
   .Synopsis
    This searches for WMI classes 
   .Description
    This function searches for WMI classes
   .Example
    Get-WmiClass -ns "root\cimv2" -class "Processor"
    Finds WMI classes related to processor 
   .Parameter ns
    The namespace
   .Parameter class
    The class
   .Notes
    NAME:  Get-WmiClass
    AUTHOR: ed wilson, msft
    LASTEDIT: 08/25/2013 15:45:16
    KEYWORDS: WMI, Scripting Technique
    HSG: 
   .Link
     Http://www.ScriptingGuys.com
 #Requires -Version 2.0
 #>
 Param ([string]$ns, [string]$class)
 Get-WmiObject -List -Namespace $ns |
 Where-Object { $_.name -match $class }
} #end Get-WmiClass

New-Alias -Name gwc -Value Get-WmiClass -Description "Mred Alias" `
-Option readonly,allscope
