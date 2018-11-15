# -----------------------------------------------------------------------------
# Script: Get-BiosMandatoryParameterWithAlias.ps1
# Author: ed wilson, msft
# Date: 09/06/2013 14:04:32
# Keywords: Input
# comments: Using Param Statement
# Windows PowerShell 4.0 Best Practices, Microsoft Press, 2013
# Chapter 11
# -----------------------------------------------------------------------------
#requires -version 4.0
Param(
    [Parameter(Mandatory = $true)]
    [alias("CN")]
    [string[]]
    $computername)

Get-WmiObject -class Win32_Bios -computername $computername
