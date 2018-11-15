# -----------------------------------------------------------------------------
# Script: CheckProviderThenQuery.ps1
# Author: ed wilson, msft
# Date: 09/06/2013 18:18:45
# Keywords: Missing WMI Providers
# comments: Providers
# Windows PowerShell 4.0 Best Practices, Microsoft Press, 2013
# Chapter 12
# -----------------------------------------------------------------------------
If(Get-WmiObject -Class __provider -filter "name = 'cimwin32'")
 {
  Get-WmiObject -class Win32_bios
 }
Else
 {
  "Unable to query Win32_Bios because the provider is missing"
 } 
