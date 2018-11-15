# -----------------------------------------------------------------------------
# Script: Get-Version.ps1
# Author: ed wilson, msft
# Date: 08/26/2013 13:32:00
# Keywords: Version
# comments: trapping OS version
# Windows PowerShell 4.0 Best Practices, Microsoft Press, 2013
# Chapter 6
# -----------------------------------------------------------------------------
Function Get-Version
{
  <#
   .Synopsis
    This returns OS information from local or remote comptuers 
   .Description
    This function returns OS information from local or remote computers
   .Example
    Get-Version -computername client1, server1 -credential (Get-Credential iammred\administrator)
    Returns OS information from two remote computers using credentials supplied when run
   .Example
    $cred = Get-Credential iammred\administrator
    Get-Version -computername client1, server1, edlt -credential $cred | select caption, version
    Returns caption and version from two remote computers using credentials stored in variable
   .Parameter Computername
    The name of target computer or computers
   .Parameter Credential
    The credentials to use to make the connection
   .Notes
    NAME:  Get-Version
    AUTHOR: ed wilson, msft
    LASTEDIT: 08/26/2013 13:25:38
    KEYWORDS: CIM, OS
    HSG: 
   .Link
     Http://www.ScriptingGuys.com
 #Requires -Version 2.0
 #>
 Param([string[]]$computername,
 [System.Management.Automation.PSCredential]$credential)
 $cim = New-CimSession @PSBoundParameters
 Get-CimInstance -CimSession $cim -ClassName Win32_OperatingSystem
}