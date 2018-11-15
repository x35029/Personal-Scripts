# -----------------------------------------------------------------------------
# Script: New-TempFile.ps1
# Author: ed wilson, msft
# Date: 09/07/2013 14:07:55
# Keywords: Networked Log Files
# comments: Writing to Text
# Windows PowerShell 4.0 Best Practices, Microsoft Press, 2013
# Chapter 18
# -----------------------------------------------------------------------------
Function New-TempFile
{
 [CmdletBinding()]
 Param(
  [Parameter(Position=0,ValueFromPipeline=$true)]
  [PSObject[]]$inputObject
 )#end param
  $tmpFile = [Io.Path]::getTempFileName()
  $inputObject | Out-File -filepath $tmpFile
  $tmpFile
} #end function New-TempFile

# *** Entry Point to Script ***
 $destination = "\\berlin\fileshare\services.txt"
 $rtn = New-TempFile  -inputObject (Get-Service)
 Move-Item -path $rtn -destination $destination
