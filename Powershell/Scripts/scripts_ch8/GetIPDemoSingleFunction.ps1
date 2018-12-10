﻿# -----------------------------------------------------------------------------
# Script: GetIPDemoSingleFunction.ps1
# Author: ed wilson, msft
# Date: 08/28/2013 12:01:28
# Keywords: function
# comments: Ease of use
# Windows PowerShell 4.0 Best Practices, Microsoft Press, 2013
# Chapter 8
# -----------------------------------------------------------------------------
Function Get-IPDemo
{
 $IP = Get-WmiObject -class Win32_NetworkAdapterConfiguration -Filter "IPEnabled = $true"
 "IP Address: " + $IP.IPAddress[0]
 "Subnet: " + $IP.IPSubNet[0]
 "GateWay: " + $IP.DefaultIPGateway
 "DNS Server: " + $IP.DNSServerSearchOrder[0]
 "FQDN: " + $IP.DNSHostName + "." + $IP.DNSDomain
} #end Get-IPDemo

# *** Entry Point To Script ***

Get-IPDemo