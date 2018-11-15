# -----------------------------------------------------------------------------
# Script: ConfigServices.ps1
# Author: ed wilson, msft
# Date: 09/08/2013 21:35:41
# Keywords: DSC configuration data
# comments: convigure services
# Windows PowerShell 4.0 Best Practices, Microsoft Press, 2013
# Chapter 23
# -----------------------------------------------------------------------------
#Requires -version 4.0
Configuration StartBits
{
 node Server1
 {
  Service Bits
  {
   Name = "Bits"
   StartUpType = "Automatic"
   State = "Running"
   BuiltinAccount = 'LocalSystem' 
  }
  Service Browser
  {
   Name = "Browser"
   StartUpType = "Disabled"
   State = "Stopped"
   BuiltinAccount = 'LocalSystem' 
  }
  Service DHCP
  {
   Name = "DHCP"
   StartUpType = "Automatic"
   State = "Running"
   BuiltinAccount = 'LocalService' 
  }
 }
}

StartBits -OutputPath C:\ScriptFolder
Start-DscConfiguration -Path C:\ScriptFolder
