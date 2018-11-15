# -----------------------------------------------------------------------------
# Script: ExpandCab.ps1
# Author: ed wilson, msft
# Date: 08/26/2013 17:52:28
# Keywords: NET
# comments: Cab
# Windows PowerShell 4.0 Best Practices, Microsoft Press, 2013
# Chapter 6
# -----------------------------------------------------------------------------
Param(
      $cab = "C:\fso\acab.cab",
      $destination = "C:\fso1",
      [switch]$debug
     )
Function ConvertFrom-Cab($cab,$destination)
{
 $comObject = "Shell.Application"
 Write-Debug "Creating $comObject"
 $shell = New-Object -Comobject $comObject
 if(!$?) { $(Throw "unable to create $comObject object")}
 Write-Debug "Creating source cab object for $cab"
 $sourceCab = $shell.Namespace($cab).items()
 Write-Debug "Creating destination folder object for $destination"
 $DestinationFolder = $shell.Namespace($destination)
 Write-Debug "Expanding $cab to $destination"
 $DestinationFolder.CopyHere($sourceCab)
}

# *** entry point ***
if($debug) { $debugPreference = "continue" }
ConvertFrom-Cab -cab $cab -destination $destination
