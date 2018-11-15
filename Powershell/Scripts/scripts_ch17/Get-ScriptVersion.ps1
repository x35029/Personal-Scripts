# -----------------------------------------------------------------------------
# Script: Get-ScriptVersion.ps1
# Author: ed wilson, msft
# Date: 09/07/2013 13:08:03
# Keywords: Version number
# comments: Version
# Windows PowerShell 4.0 Best Practices, Microsoft Press, 2013
# Chapter 17
# -----------------------------------------------------------------------------
function get-ScriptVersion ([string]$path)
{
 $scripts = Get-ChildItem -Path $path -recurse
 ForEach($script in $scripts)
 { 
  $info = New-Object psobject
  $scriptText = Get-Content $script.fullname 
  $info | 
  Add-Member -Name "name" -Value $script.name -MemberType noteproperty
  $lastedit = $scriptText | 
  Select-String -Pattern "\s\d{1,1}/\d{1,2}/\d{1,4}"
  
  if($lastedit.count -gt 1)
   {
     $info | 
     Add-Member -Name "LastEdit" -Value $lastedit[0].matches[0].value `
     -membertype noteproperty
   }
  if($lastedit.matches.count -gt 0)
   { 
    $info | 
    Add-Member -Name "LastEdit" -Value $lastedit.matches[0].value `
    -membertype noteproperty -Force
   }
  $version =  $scriptText | 
  Select-String -Pattern "\s\d\.\d\.\d"
  
  if($version.count -gt 1)
   {
    $info | 
    Add-Member -Name version -Value $version[0].matches[0].value `
    -membertype noteproperty -Force
   }
  if($version.matches.count -gt 0)
   {
    $info | 
    Add-Member -Name version -Value $version.matches[0].value `
    -membertype noteproperty -Force
   }
  $info 
  $version = $lastedit = $scriptText = $null
 } #end foreach
} #end function get-ScriptVersion

# *** Entry Point ***

Get-ScriptVersion -path C:\data\BookDOcs\PS4_BestPractices\Scripts | 
Format-Table -Property * -AutoSize -Wrap
