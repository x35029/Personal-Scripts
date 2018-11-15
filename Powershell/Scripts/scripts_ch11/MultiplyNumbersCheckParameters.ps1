# -----------------------------------------------------------------------------
# Script: MultiplyNumbersCheckParameters.ps1
# Author: ed wilson, msft
# Date: 09/06/2013 14:57:41
# Keywords: Input
# comments: Validate Parameter INput
# Windows PowerShell 4.0 Best Practices, Microsoft Press, 2013
# Chapter 11
# -----------------------------------------------------------------------------
#requires -version 4.0
Param(
             [Parameter(mandatory=$true,
                                 Position=0,
                                 HelpMessage="A number between 1 and 10")]
             [alias("fn")]
             [ValidateRange(1,10)]
             $FirstNumber,
             [Parameter(mandatory=$true,
                                 Position=1,
                                 HelpMessage="Not null or empty")]
             [alias("ln")]
             [int16]
             [ValidateNotNullOrEmpty()]
             $LastNumber
)

$FirstNumber*$LastNumber
