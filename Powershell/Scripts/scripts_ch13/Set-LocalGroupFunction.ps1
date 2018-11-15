# -----------------------------------------------------------------------------
# Script: Set-LocalGroupFunction.ps1
# Author: ed wilson, msft
# Date: 09/06/2013 21:33:09
# Keywords: Use Standard Parameters
# comments: Verbose
# Windows PowerShell 4.0 Best Practices, Microsoft Press, 2013
# Chapter 13
# -----------------------------------------------------------------------------
Function Set-LocalGroup
{
  <#
   .Synopsis
    This function adds or removes a local user to a local group 
   .Description
    This function adds or removes a local user to a local group
   .Example
    Set-LocalGroup -username "ed" -groupname "administrators" -add
    Assigns the local user ed to the local administrators group
   .Example
    Set-LocalGroup -username "ed" -groupname "administrators" -remove
    Removes the local user ed to the local administrators group
   .Parameter username
    The name of the local user
   .Parameter groupname
    The name of the local group
   .Parameter ComputerName
    The name of the computer
   .Parameter add
    causes function to add the user
   .Parameter remove
    causes the function to remove the user
   .Notes
    NAME:  Set-LocalGroup
    AUTHOR: ed wilson, msft
    LASTEDIT: 09/6/2013 10:23:53
    REQUIRES: admin rights
    KEYWORDS: Local Account Management, Users, Groups
    HSG: HSG-06-30-11
   .Link
     Http://www.ScriptingGuys.com/blog
 #Requires -Version 2.0
 #>
 [CmdletBinding()]
 Param(
  [Parameter(Position=0,
      Mandatory=$True,
      ValueFromPipeline=$True)]
  [string]$userName,
  [Parameter(Position=1,
      Mandatory=$True,
      ValueFromPipeline=$True)]
  [string]$GroupName,
  [string]$computerName = $env:ComputerName,
  [Parameter(ParameterSetName='addUser')]
  [switch]$add,
  [Parameter(ParameterSetName='removeuser')]
  [switch]$remove
 )
 Write-Verbose "Connecting to $GroupName on $computerName"
 $group = [ADSI]"WinNT://$ComputerName/$GroupName,group"
 if($add)
  {
  Write-Debug "Preparing to add $userName to $groupName"
  Write-Verbose "Preparing to add $userName to $GroupName"
   $group.add("WinNT://$ComputerName/$UserName")
  }
  if($remove)
   {
    Write-Debug "Preparing to remove $userName to $groupName"
    Write-Verbose "Preparing to remove $userName to $GroupName"
   $group.remove("WinNT://$ComputerName/$UserName")
   }
} #end function Set-LocalGroup