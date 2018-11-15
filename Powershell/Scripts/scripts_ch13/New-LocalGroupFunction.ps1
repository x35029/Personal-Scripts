# -----------------------------------------------------------------------------
# Script: New-LocalGroupFunction.ps1
# Author: ed wilson, msft
# Date: 09/06/2013 21:10:18
# Keywords: Use Standard Parameters
# comments: Whatif
# Windows PowerShell 4.0 Best Practices, Microsoft Press, 2013
# Chapter 13
# -----------------------------------------------------------------------------
Function New-LocalGroup
{
 <#
   .Synopsis
    This function creates a local group 
   .Description
    This function creates a local group
   .Example
    New-LocalGroup -GroupName "mygroup" -description "cool local users"
    Creates a new local group named mygroup with a description of cool local users. 
   .Parameter ComputerName
    The name of the computer upon which to create the group
   .Parameter GroupName
    The name of the Group to create
   .Parameter description
    The description for the newly created group
   .Notes
    NAME:  New-LocalGroup
    AUTHOR: ed wilson, msft
    LASTEDIT: 09/6/2013 10:07:42
    REQUIRES: Admin rights
    KEYWORDS: Local Account Management, Groups
    HSG: Based upon HSG-06-30-11
   .Link
     Http://www.ScriptingGuys.com/blog
 #>
 [CmdletBinding()]
 Param(
  [Parameter(Position=0,
      Mandatory=$True,
      ValueFromPipeline=$True)]
  [string]$GroupName,
  [string]$computerName = $env:ComputerName,
  [string]$description = "Created by PowerShell",
  [switch]$whatif)

  If($whatif) 
  {
   "WHATIF: Creating new local group $groupName with description $description on $computername"
   Return
  } #end Whatif
  $adsi = [ADSI]"WinNT://$computerName"
  $objgroup = $adsi.Create("Group", $groupName)
  $objgroup.SetInfo()
  $objgroup.description = $description
  $objgroup.SetInfo()
 
} #end function New-LocalGroup