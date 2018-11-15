# -----------------------------------------------------------------------------
# Script: Get-IPObjectDefaultEnabledFormatNonIPOutput.ps1
# Author: ed wilson, msft
# Date: 08/28/2013 12:04:03
# Keywords: function
# comments: Ease of use
# Windows PowerShell 4.0 Best Practices, Microsoft Press, 2013
# Chapter 8
# -----------------------------------------------------------------------------
Function Get-IPObject
{
 Param ([bool]$IPEnabled = $true)
 Get-WmiObject -class Win32_NetworkAdapterConfiguration -Filter "IPEnabled = $IPEnabled"
} #end Get-IPObject

Function Format-NonIPOutput
{ 
 Param ($IP)
  Begin { "Index #  Description" }
 Process {
  ForEach ($i in $ip)
  {
   Write-Host $i.Index `t $i.Description
  } #end ForEach
 } #end Process
} #end Format-NonIPOutPut

$ip = Get-IPObject -IPEnabled $False
Format-NonIPOutput($ip)
