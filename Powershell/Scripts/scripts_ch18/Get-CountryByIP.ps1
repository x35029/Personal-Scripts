 # -----------------------------------------------------------------------------
# Script: Get-CountryByIP.ps1
# Author: ed wilson, msft
# Date: 09/07/2013 13:59:16
# Keywords: Designing logging approach
# comments: Text Location
# Windows PowerShell 4.0 Best Practices, Microsoft Press, 2013
# Chapter 18
# -----------------------------------------------------------------------------
<#
   .Synopsis
    Gets country location by IP address
   .Description
    This script gets country location based up an IP address. It uses
    a Web service, and therefore must be connected to Internet.
   .Example
    Get-CountryByIP.ps1 -ip 10.1.1.1, 192.168.1.1 -log iplog.txt
    Writes country information to %mydocuments%\iplog.txt and to screen
   .Inputs
    [string]
   .OutPuts
    [PSObject]
   .Notes
    NAME: Get-CountryByIP.ps1
    AUTHOR: Ed Wilson 
    VERSION: 1.0.0
    LASTEDIT: 8/20/2009
    KEYWORDS: New-WebServiceProxy, IP, New-Object, PSObject
   .Link
     Http://www.ScriptingGuys.com
#requires -version 2.0
#>
[CmdletBinding()]
Param(
   [Parameter(Mandatory = $true,Position = 0,ValueFromPipeline = $true)]
   [string[]]$ip, 
   [string]$log = "ipLogFile.txt",
   [string]$folder = "Personal"
)#end param

# *** Function below ***
Function Get-CountryByIP($IP)
{
 $URI = "http://www.webservicex.net/geoipservice.asmx?wsdl"
 $Proxy = New-WebServiceProxy -uri $URI -namespace WebServiceProxy -class IP
 $RTN = $proxy.GetGeoIP($IP)
 
 $ipReturn = New-Object PSObject -Property @{
    'ip' = $rtn.ip;
    'CountryName' = $rtn.countryname; 
    'CountryCode'=$rtn.countrycode}
 
 $ipReturn
} #end Get-CountryByIP

Function Get-Folder($folderName)
{
 [Environment]::GetFolderPath([environment+SpecialFolder]::$folderName)
} #end function Get-Folder

# *** Entry Point to Script ***

$ip | 
ForEach-Object { Get-CountryByIP -ip $_ } |
Tee-Object -Variable results

$results | 
Out-File -FilePath `
  (Join-Path -Path (Get-Folder -folderName $folder) -childPath $log)
