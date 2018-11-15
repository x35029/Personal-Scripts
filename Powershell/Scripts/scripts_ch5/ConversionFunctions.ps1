# -----------------------------------------------------------------------------
# Script: ConversionFunctions.ps1
# Author: ed wilson, msft
# Date: 08/25/2013 16:59:23
# Keywords: Profile, functions
# comments: Configuring a profile
# Windows PowerShell 4.0 Best Practices, Microsoft Press, 2013
# Chapter 5
# -----------------------------------------------------------------------------
Function ConvertToMeters($feet)
{
  "$feet feet equals $($feet*.31) meters"
} #end ConvertToMeters
Function ConvertToFeet($meters)
{
 "$meters meters equals $($meters * 3.28) feet"
} #end ConvertToFeet
Function ConvertToFahrenheit($celsius)
{
 "$celsius celsius equals $((1.8 * $celsius) + 32 ) fahrenheit"
} #end ConvertToFahrenheit
Function ConvertTocelsius($fahrenheit)
{
 "$fahrenheit fahrenheit equals $( (($fahrenheit - 32)/9)*5 ) celsius"
} #end ConvertTocelsius
Function ConvertToMiles($kilometer)
{
  "$kilometer kilometers equals $( ($kilometer *.6211) ) miles"
} #end convertToMiles
Function ConvertToKilometers($miles)
{
  "$miles miles equals $( ($miles * 1.61) ) kilometers"
} #end convertToKilometers
