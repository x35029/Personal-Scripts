# -----------------------------------------------------------------------------
# Script: SetServicesConfig.ps1
# Author: ed wilson, msft
# Date: 09/08/2013 22:54:25
# Keywords: DSC configuration data
# comments: configure services
# Windows PowerShell 4.0 Best Practices, Microsoft Press, 2013
# Chapter 23
# -----------------------------------------------------------------------------
Configuration SetServices
{
 node @('Server1', 'Server2')
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

SetServices -OutputPath C:\ServerConfig
Start-DscConfiguration -Path C:\ServerConfig
