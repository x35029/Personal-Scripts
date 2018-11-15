# -----------------------------------------------------------------------------
# Script: CreateRegistryKey.ps1
# Author: ed wilson, msft
# Date: 09/07/2013 16:19:43
# Keywords: Using Set-PSDebug
# comments: Tracing the Script
# Windows PowerShell 4.0 Best Practices, Microsoft Press, 2013
# Chapter 19
# -----------------------------------------------------------------------------
Function Add-RegistryValue($key,$value)
{
 $scriptRoot = "HKCU:\software\ForScripting"
 if(-not (Test-Path -path $scriptRoot))
   { 
    New-Item -Path HKCU:\Software\ForScripting | Out-null 
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
