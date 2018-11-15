# -----------------------------------------------------------------------------
# Script: Get-MyModule.ps1
# Author: ed wilson, msft
# Date: 09/07/2013 17:36:18
# Keywords: modules
# comments: installing
# Windows PowerShell 4.0 Best Practices, Microsoft Press, 2013
# Chapter 10
# -----------------------------------------------------------------------------
Function Get-MyModule
{
 Param([string]$name)
 if(-not(Get-Module -name $name)) 
   { 
    if(Get-Module -ListAvailable | 
        Where-Object { $_.name -eq $name })
       { 
        Import-Module -Name $name 
        $true
       } #end if module available then import
    else { $false } #module not available
    } # end if not module
  else { $true } #module already loaded
        
} #end function get-MyModule

get-mymodule -name "bitsTransfer"
