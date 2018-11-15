# -----------------------------------------------------------------------------
# Script: BasicFunctions.psm1
# Author: ed wilson, msft
# Date: 09/07/2013 17:39:25
# Keywords: modules
# comments: creating
# Windows PowerShell 4.0 Best Practices, Microsoft Press, 2013
# Chapter 10
# -----------------------------------------------------------------------------
Function Get-OptimalSize
{
 <#
  .Synopsis
    Converts Bytes into the appropriate unit of measure. 
   .Description
    The Get-OptimalSize function converts bytes into the appropriate unit of 
    measure. It returns a string representation of the number.
   .Example
    Get-OptimalSize 1025
    Converts 1025 bytes to 1.00 KiloBytes
    .Example
    Get-OptimalSize -sizeInBytes 10099999 
    Converts 10099999 bytes to 9.63 MegaBytes
   .Parameter SizeInBytes
    The size in bytes to be converted
   .Inputs
    [int64]
   .OutPuts
    [string]
   .Notes
    NAME:  Get-OptimalSize
    AUTHOR: Ed Wilson
    LASTEDIT: 6/30/2012
    KEYWORDS: Scripting Techniques, Modules
   .Link
     Http://www.ScriptingGuys.com
 #Requires -Version 2.0
 #>
[CmdletBinding()]
param(
      [Parameter(Mandatory = $true,Position = 0,valueFromPipeline=$true)]
      [int64]
      $sizeInBytes
) #end param
 Switch ($sizeInBytes) 
  {
   {$sizeInBytes -ge 1TB} {"{0:n2}" -f  ($sizeInBytes/1TB) + " TeraBytes";break}
   {$sizeInBytes -ge 1GB} {"{0:n2}" -f  ($sizeInBytes/1GB) + " GigaBytes";break}
   {$sizeInBytes -ge 1MB} {"{0:n2}" -f  ($sizeInBytes/1MB) + " MegaBytes";break}
   {$sizeInBytes -ge 1KB} {"{0:n2}" -f  ($sizeInBytes/1KB) + " KiloBytes";break}
   Default { "{0:n2}" -f $sizeInBytes + " Bytes" }
  } #end switch
  $sizeInBytes = $null
} #end Function Get-OptimalSize 

Function Get-ComputerInfo
{
 <#
  .Synopsis
    Retrieves basic information about a computer. 
   .Description
    The Get-ComputerInfo cmdlet retrieves basic information such as
    computer name, domain name, and currently logged on user from
    a local or remote computer.
   .Example
    Get-ComputerInfo 
    Returns comptuer name, domain name and currently logged on user
    from local computer.
    .Example
    Get-ComputerInfo -computer berlin
    Returns comptuer name, domain name and currently logged on user
    from remote computer named berlin.
   .Parameter Computer
    Name of remote computer to retrieve information from
   .Inputs
    [string]
   .OutPuts
    [object]
   .Notes
    NAME:  Get-ComputerInfo
    AUTHOR: Ed Wilson
    LASTEDIT: 6/30/2012
    KEYWORDS: Desktop mgmt, basic information
   .Link
     Http://www.ScriptingGuys.com
 #Requires -Version 2.0
 #>
 Param([string]$computer=$env:COMPUTERNAME)
 $wmi = Get-WmiObject -Class win32_computersystem -ComputerName $computer
 $pcinfo = New-Object psobject -Property @{"host" = $wmi.DNSHostname
           "domain" = $wmi.Domain 
           "user" = $wmi.Username}
 $pcInfo
} #end function Get-ComputerInfo
