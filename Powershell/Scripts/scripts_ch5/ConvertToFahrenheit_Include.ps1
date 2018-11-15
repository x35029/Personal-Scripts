# -----------------------------------------------------------------------------
# Script: ConvertToFahrenheit_Include.ps1
# Author: ed wilson, msft
# Date: 08/25/2013 17:00:21
# Keywords: Profile, functions
# comments: Configuring a profile
# Windows PowerShell 4.0 Best Practices, Microsoft Press, 2013
# Chapter 5
# -----------------------------------------------------------------------------
Param($Celsius)
. C:\data\scriptingGuys\ConversionFunctions.ps1
ConvertToFahrenheit($Celsius)
