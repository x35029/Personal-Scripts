# -----------------------------------------------------------------------------
# Script: HelloUserTimeworkflow.ps1
# Author: ed wilson, msft
# Date: 09/07/2013 17:58:25
# Keywords: workflow
# comments: workflow
# Windows PowerShell 4.0 Best Practices, Microsoft Press, 2013
# Chapter 22
# -----------------------------------------------------------------------------
Workflow HelloUserTime
{
 $dateHour = Get-date -UFormat '%H'
 if($dateHour -lt 12) {"good morning"}
 ELSeIF ($dateHour -ge 12 -AND $dateHour -le 18) {"good afternoon"}
 ELSE {"good evening"}
}