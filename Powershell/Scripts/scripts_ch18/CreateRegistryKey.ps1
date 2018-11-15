# -----------------------------------------------------------------------------
# Script: CreateRegistryKey.ps1
# Author: ed wilson, msft
# Date: 09/07/2013 14:10:14
# Keywords: Log to Registry
# comments: Registry
# Windows PowerShell 4.0 Best Practices, Microsoft Press, 2013
# Chapter 18
# -----------------------------------------------------------------------------
Function Add-RegistryValue
{
 Param ($key,$value)
 $scriptRoot = "HKCU:\software\ForScripting"
 if(-not (Test-Path -path $scriptRoot))
   { 
    New-Item -Path HKCU:\Software\ForScripting | Out-Null 
    New-ItemProperty -Path $scriptRoot -Name $key -Value $value `
    -PropertyType String | Out-Null
    }
  Else
  {
   Set-ItemProperty -Path $scriptRoot -Name $key -Value $value | `
   Out-Null
  }
  
} #end function Add-RegistryValue

# *** Entry Point to Script ***
Add-RegistryValue -key forscripting -value test
