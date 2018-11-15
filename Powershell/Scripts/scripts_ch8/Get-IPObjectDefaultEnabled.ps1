# -----------------------------------------------------------------------------
# Script: Get-IPObjectDefaultEnabled.ps1
# Author: ed wilson, msft
# Date: 08/28/2013 12:03:01
# Keywords: function
# comments: Ease of use
# Windows PowerShell 4.0 Best Practices, Microsoft Press, 2013
# Chapter 8
# -----------------------------------------------------------------------------
Function Get-IPObject([bool]$IPEnabled = $true)
{
 Get-WmiObject -class Win32_NetworkAdapterConfiguration -Filter "IPEnabled = $IPEnabled"
} #end Get-IPObject

Get-IPObject -IPEnabled $False
