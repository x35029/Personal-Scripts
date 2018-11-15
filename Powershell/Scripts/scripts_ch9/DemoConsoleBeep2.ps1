# -----------------------------------------------------------------------------
# Script: DemoConsoleBeep2.ps1
# Author: ed wilson, msft
# Date: 08/28/2013 17:44:43
# Keywords: help
# comments: Thirteen Rules for effective comments
# Windows PowerShell 4.0 Best Practices, Microsoft Press, 2013
# Chapter 9
# -----------------------------------------------------------------------------
# ------------------------------------------------------------------------
# NAME: DemoConsoleBeep2.ps1
# AUTHOR: ed wilson, Microsoft
# DATE: 4/1/2009
# VERSION 2.0
# 4/4/2009 cleaned up comments. Removed use of % alias. Reformatted.
#
# KEYWORDS: Beep
#
# COMMENTS: This script demonstrates using the console
# beep. The first parameter is the frequency. Allowable range is between
# 37..32767. A number above 7500 is barely audible. 37 is the lowest
# note the console beep will play. 
# The second parameter is the length of time.
#
# ------------------------------------------------------------------------

37..32000 | 
Foreach-Object { $_ ; [console]::beep($_ , 1) }

