# -----------------------------------------------------------------------------
# Script: Resolve-ZipCode.ps1
# Author: ed wilson, msft
# Date: 08/28/2013 11:49:56
# Keywords: function
# comments: type constraint
# Windows PowerShell 4.0 Best Practices, Microsoft Press, 2013
# Chapter 8
# -----------------------------------------------------------------------------
#Requires -Version 2.0
Function Resolve-ZipCode
{
 Param ([int]$zip)
 $URI = "http://www.webservicex.net/uszip.asmx?WSDL"
 $zipProxy = New-WebServiceProxy -uri $URI -namespace WebServiceProxy -class ZipClass
 $zipProxy.getinfobyzip($zip).table
} #end Get-ZipCode

Resolve-ZipCode 28273
