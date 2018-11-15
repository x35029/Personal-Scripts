# -----------------------------------------------------------------------------
# Script: Get-WmiProviderFunction.ps1
# Author: ed wilson, msft
# Date: 09/06/2013 18:30:41
# Keywords: Missing WMI Providers
# comments: Providers
# Windows PowerShell 4.0 Best Practices, Microsoft Press, 2013
# Chapter 12
# -----------------------------------------------------------------------------
Function Get-WmiProvider
{
 [cmdletbinding()]
 Param ([string]$providerName)
 $provider =  Get-WmiObject -Class __provider -filter "name = '$providerName'"
 If($provider -ne $null)
   {
    $clsID = $provider.clsID
    Write-Verbose "$providerName WMI provider found. CLSID is $($CLSID)"
   }
 Else 
   {
     Return $false
   }
   Write-Verbose "Checking for proper registry registration ..."
   If(Test-Path -path HKCR:)
      {
        Write-Verbose "HKCR: drive found. Testing for $clsID"
        Test-path -path (Join-Path -path HKCR:\CLSID -childpath $CLSID)  
      }
   Else
     {
      Write-Verbose "HKCR: drive not found. Creating same." 
      New-PSDrive -Name HKCR -PSProvider registry -Root HKEY_Classes_Root | Out-Null
      Write-Verbose "Testing for $clsID" 
      Test-path -path (Join-Path -path HKCR:\CLSID -childpath $CLSID)  
      Write-Verbose "Test complete."
      Write-Verbose "Removing HKCR: drive." 
      Remove-PSDrive -Name HKCR | Out-Null
     }
} #end Get-WmiProvider function

# *** Entry Point to Script ***
$providerName = "msiprov"

 if(Get-WmiProvider -providerName $providerName  -verbose ) 
  { 
    Get-WmiObject -class win32_product 
  } 
else 
  { 
   "$providerName provider not found" 
  }
