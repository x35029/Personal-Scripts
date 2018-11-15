# -----------------------------------------------------------------------------
# Script: ConvertToFahrenheit.ps1
# Author: ed wilson, msft
# Date: 08/25/2013 16:57:58
# Keywords: Profile, functions
# comments: Configuring a profile
# Windows PowerShell 4.0 Best Practices, Microsoft Press, 2013
# Chapter 5
# -----------------------------------------------------------------------------
Param($Celsius)
Function ConvertToFahrenheit($Celsius)
{
 "$Celsius Celsius equals $((1.8 * $Celsius) + 32) Fahrenheit"
} #end ConvertToFahrenheit
ConvertToFahrenheit($Celsius)
