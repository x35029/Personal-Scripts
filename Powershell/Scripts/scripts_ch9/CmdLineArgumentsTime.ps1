# -----------------------------------------------------------------------------
# Script: CmdLineArgumentsTime.ps1
# Author: ed wilson, msft
# Date: 08/28/2013 13:47:03
# Keywords: help
# comments: Thirteen Rules for effective comments
# Windows PowerShell 4.0 Best Practices, Microsoft Press, 2013
# Chapter 9
# -----------------------------------------------------------------------------
# ===========================================================================
# 
# NAME: CmdLineArgumentsTime.ps1
# AUTHOR: Ed Wilson , microsoft
# DATE  : 2/19/2009
# EMAIL: Scripter@Microsoft.com
# Version .0
# KEYWORDS: Add-PSSnapin, powergadgets, Get-Date
# 
# COMMENT: The $args[0] is unnamed argument that accepts command line input. 
# C:\cmdLineArgumentsTime.ps1 23 52
# No commas are used to separate the arguments. Will generate an error if used.
# Requires powergadgets.
# INPROGRESS: Add a help function to script. 
# ===========================================================================
#INPROGRESS: change unnamed arguments to a more user friendly method
[int]$inthour = $args[0]
[int]$intMinute = $args[1]
#INPROGRESS: find a better way to check for existence  of powergadgets
#This causes errors to be ignored and is used when checking for PowerGadgets
$erroractionpreference = "SilentlyContinue"
#this clears all errors and is used to see if errors are present.
$error.clear()
#This command will generate an error if PowerGadgets are not installed
Get-PSSnapin *powergadgets | Out-Null
#INPROGRESS: Prompt before loading powergadgets
If ($error.count -ne 0)
{Add-PSSnapin powergadgets} 

New-TimeSpan -Start (get-date) -end (get-date -Hour $inthour -Minute $intMinute) | 
Out-Gauge -Value minutes -Floating -refresh 0:0:30  -mainscale_max 60
