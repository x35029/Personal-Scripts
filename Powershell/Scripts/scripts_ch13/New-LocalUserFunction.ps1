# -----------------------------------------------------------------------------
# Script: New-LocalUserFunction.ps1
# Author: ed wilson, msft
# Date: 09/06/2013 20:50:48
# Keywords: Use Standard Parameters
# comments: Debug
# Windows PowerShell 4.0 Best Practices, Microsoft Press, 2013
# Chapter 13
# -----------------------------------------------------------------------------
Function New-LocalUser
{
  <#
   .Synopsis
    This function creates a local user 
   .Description
    This function creates a local user
   .Example
    New-LocalUser -userName "ed" -description "cool Scripting Guy" `
        -password "password"
    Creates a new local user named ed with a description of cool scripting guy
    and a password of password. 
   .Parameter ComputerName
    The name of the computer upon which to create the user
   .Parameter UserName
    The name of the user to create
   .Parameter password
    The password for the newly created user
   .Parameter description
    The description for the newly created user
   .Notes
    NAME:  New-LocalUser
    AUTHOR: ed wilson, msft
    LASTEDIT: 09/6/2013 10:07:42
    KEYWORDS: Local Account Management, Users
    HSG: Based upon HSG-06-30-11
    Requires Admin rights
   .Link
     Http://www.ScriptingGuys.com/blog
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
  [string]$password,
  [string]$computerName = $env:ComputerName,
  [string]$description = "Created by PowerShell"
 )
 Write-Debug "Connecting to ADSI on $computerName"
 $computer = [ADSI]"WinNT://$computerName"
 Write-Debug "Calling Create method to create user: $userName"
 $user = $computer.Create("User", $userName)
 $user.setpassword($password)
 $user.put("description",$description) 
 Write-Debug "Calling SetInfo"
 $user.SetInfo()
} #end function New-LocalUser