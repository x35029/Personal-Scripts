# -----------------------------------------------------------------------------
# Script: PingComputers.ps1
# Author: ed wilson, msft
# Date: 09/06/2013 14:52:14
# Keywords: Input
# comments: Validate Parameter INput
# Windows PowerShell 4.0 Best Practices, Microsoft Press, 2013
# Chapter 11
# -----------------------------------------------------------------------------
#requires -version 4.0
Param(
     [ValidatePattern("DC")]
     [alias("CN")]
     $computername
 )

Function New-TestConnection($computername)
{
 Test-connection -computername $computername -buffersize 16 -count 2 
} #end new-testconnection

# *** Entry Point to script
New-TestConnection($computername)
