# -----------------------------------------------------------------------------
# Script: ConvertToFahrenheit_Include2.ps1
# Author: ed wilson, msft
# Date: 08/25/2013 17:01:00
# Keywords: Profile, functions
# comments: Configuring a profile
# Windows PowerShell 4.0 Best Practices, Microsoft Press, 2013
# Chapter 5
# -----------------------------------------------------------------------------
Param($Celsius)
$includeFile = "c:\data\scriptingGuys\ConversionFunctions.ps1"
if(!(test-path -path $includeFile))
  {
   "Unable to find $includeFile"
   Exit
  }
. $includeFile
ConvertToFahrenheit($Celsius)
