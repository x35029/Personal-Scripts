# -----------------------------------------------------------------------------
# Script: ConvertUseFunctions.ps1
# Author: ed wilson, msft
# Date: 08/25/2013 17:01:51
# Keywords: Profile, functions
# comments: Configuring a profile
# Windows PowerShell 4.0 Best Practices, Microsoft Press, 2013
# Chapter 5
# -----------------------------------------------------------------------------
Param($action,$value,[switch]$help)
Function GetHelp()
{
  if($help)
  {
   "choose conversion: M(eters), F(eet) C(elsius),Fa(renheit),Mi(les),K(ilometers) and value"
   " Convert -a M -v 10 converts 10 meters to feet."
  } #end if help
} #end getHelp
Function GetInclude()
{
 $includeFile = "c:\data\scriptingGuys\ConversionFunctions.ps1"
 if(!(test-path -path $includeFile))
   {
    "Unable to find $includeFile"
    Exit
   }
. $includeFile
} #end GetInclude
Function ParseAction()
{ 
 switch ($action)
 {
  "M" { ConvertToFeet($value) }
  "F"  { ConvertToMeters($value) }
  "C" { ConvertToFahrenheit($value) }
  "Fa" { ConvertToCelsius($value) }
  "Mi" { ConvertToKilometers($value) }
  "K"  { ConvertToMiles($value) }
  DEFAULT { "Dude illegal value." ; GetHelp ; exit }
 } #end action
} #end ParseAction
# *** Entry Point ***
If($help) { GetHelp ; exit }
if(!$action) { "Missing action" ; GetHelp ; exit }
GetInclude
ParseAction
