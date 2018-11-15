# -----------------------------------------------------------------------------
# Script: CreateCab2.ps1
# Author: ed wilson, msft
# Date: 08/26/2013 17:53:13
# Keywords: NET
# comments: Cab
# Windows PowerShell 4.0 Best Practices, Microsoft Press, 2013
# Chapter 6
# -----------------------------------------------------------------------------
Param(
      $filepath = "C:\fso", 
      $path = "C:\fso1\cabfiles",
      [switch]$debug
     )
Function New-DDF($path,$filePath)
{
 $ddfFile = Join-Path -path $filePath -childpath temp.ddf
 Write-Debug "DDF file path is $ddfFile"
 $ddfHeader =@"
;*** MakeCAB Directive file
;
.OPTION EXPLICIT			
.Set CabinetNameTemplate=Cab.*.cab
.set DiskDirectory1=C:\fso1\Cabfiles
.Set MaxDiskSize=CDROM
.Set Cabinet=on
.Set Compress=on
"@
 Write-Debug "Writing ddf file header to $ddfFile" 
 $ddfHeader | Out-File -filepath $ddfFile -force -encoding ASCII
 Write-Debug "Generating collection of files from $filePath"
 Get-ChildItem -path $filePath | 
 Where-Object { !$_.psiscontainer } |
 Foreach-Object `
  { 
    '"' + $_.fullname.tostring() + '"'  | 
   Out-File -filepath $ddfFile -encoding ASCII -append
  }
 Write-Debug "ddf file is created. Calling New-Cab function"
 New-Cab($ddfFile)
} #end New-DDF

Function New-Cab($ddfFile)
{
 Write-Debug "Entering the New-Cab function. The DDF File is $ddfFile"
 if($debug)
    { makecab /f $ddfFile /V3 }
 Else
    { makecab /f $ddfFile }
} #end New-Cab

# *** entry point to script ***
if($debug) {$DebugPreference = "continue"}
New-DDF -path $path -filepath $filepath
