# -----------------------------------------------------------------------------
# Script: PinToStartAndTaskBar.ps1
# Author: ed wilson, msft
# Date: 09/09/2013 15:42:27
# Keywords: Working
# comments: Accessing
# Windows PowerShell 4.0 Best Practices, Microsoft Press, 2013
# Chapter 1
# -----------------------------------------------------------------------------
$pinToStart = "Pin to Start"
$pinToTaskBar = "Pin to Taskbar"
$file = @((Join-Path -Path $PSHOME  -childpath "PowerShell.exe"),
          (Join-Path -Path $PSHOME  -childpath "powershell_ise.exe") )
Foreach($f in $file)
 {$path = Split-Path $f
  $shell=New-Object -com "Shell.Application" 
  $folder=$shell.Namespace($path)   
  $item = $folder.parsename((Split-Path $f -leaf))
  $verbs = $item.verbs()
  foreach($v in $verbs)
    {if($v.Name.Replace("&","") -match $pinToStart){$v.DoIt()}}
  foreach($v in $verbs)
    {if($v.Name.Replace("&","") -match $pinToTaskBar){$v.DoIt()}} }
