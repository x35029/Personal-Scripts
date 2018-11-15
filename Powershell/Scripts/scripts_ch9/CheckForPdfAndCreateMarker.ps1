# -----------------------------------------------------------------------------
# Script: CheckForPdfAndCreateMarker.ps1
# Author: ed wilson, msft
# Date: 08/28/2013 13:44:34
# Keywords: help
# comments: Thirteen Rules for effective comments
# Windows PowerShell 4.0 Best Practices, Microsoft Press, 2013
# Chapter 9
# -----------------------------------------------------------------------------
# -----------------------------------------------------------------------------------
# CheckForPdfAndCreateMarker.ps1
# ed wilson, msft, 12/11/2008
# 
# Hey Scripting Guy! 12/29/2008
# -----------------------------------------------------------------------------------
$path = "c:\fso"
$include = "*.pdf"
$name = "nopdf.txt"
if(!(Get-ChildItem -path $path -include $include -Recurse)) 
  { 
    "No pdf was found in $path. Creating $path\$name marker file."
    New-Item -path $path -name $name -itemtype file -force |
    out-null
  } #end if not Get-Childitem
ELSE
 {
  $response = Read-Host -prompt "PDF files were found. Do you wish to delete <y> /<n>?"
  if($response -eq "y")
    {
     "PDF files will be deleted."
     Get-ChildItem -path $path -include $include -recurse |
      Remove-Item
    } #end if response
  ELSE
   { 
    "PDF files will not be deleted."
   } #end else reponse
 } #end else not Get-Childitem
