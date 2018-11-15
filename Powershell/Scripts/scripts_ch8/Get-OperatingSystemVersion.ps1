# -----------------------------------------------------------------------------
# Script: Get-OperatingSystemVersion.ps1
# Author: ed wilson, msft
# Date: 08/28/2013 10:42:38
# Keywords: function
# comments: understanding
# Windows PowerShell 4.0 Best Practices, Microsoft Press, 2013
# Chapter 8
# -----------------------------------------------------------------------------
Function Get-OperatingSystemVersion
{
 (Get-WmiObject -Class Win32_OperatingSystem).Version
} #end Get-OperatingSystemVersion

"This OS is version $(Get-OperatingSystemVersion)"
