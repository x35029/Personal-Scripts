# -----------------------------------------------------------------------------
# Script: ConvertToFahrenheit_include.ps1
# Author: ed wilson, msft
# Date: 08/28/2013 13:46:16
# Keywords: help
# comments: Thirteen Rules for effective comments
# Windows PowerShell 4.0 Best Practices, Microsoft Press, 2013
# Chapter 9
# -----------------------------------------------------------------------------
# ------------------------------------------------------------------------
# NAME: ConvertToFahrenheit_include.ps1
# AUTHOR: ed wilson, Microsoft
# DATE: 9/24/2008
# EMAIL: Scripter@Microsoft.com
# Version 2.0
#   12/1/2008 added test-path check for include file
#             modified the way the include file is called
# KEYWORDS: Converts Celsius to Fahrenheit
#
# COMMENTS: This script converts Celsius to Fahrenheit
# It uses command line parameters and an include file. 
# If the ConversionFunctions.ps1 script is not available,
# the script will fail.
#
# ------------------------------------------------------------------------
Param($Celsius)
#The $includeFile variable points to the ConversionFunctions.ps1 
#script. Make sure you edit the path to this script. 
$includeFile = "c:\data\scriptingGuys\ConversionFunctions.ps1"
if(!(test-path -path $includeFile))
  {
   "Unable to find $includeFile"
   Exit
  }
. $includeFile
ConvertToFahrenheit($Celsius)
