# -----------------------------------------------------------------------------
# Script: Get-BiosMandatoryParameter.ps1
# Author: ed wilson, msft
# Date: 09/06/2013 13:52:04
# Keywords: Input
# comments: Using Param Statement
# Windows PowerShell 4.0 Best Practices, Microsoft Press, 2013
# Chapter 11
# -----------------------------------------------------------------------------
#requires -version 4.0
Param(
    [Parameter(Mandatory = $true)]
    [string[]]
    $computername)

Get-WmiObject -class Win32_Bios -computername $computername
