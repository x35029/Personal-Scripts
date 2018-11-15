# -----------------------------------------------------------------------------
# Script: Get-FreeDiskSpace.ps1
# Author: ed wilson, msft
# Date: 08/28/2013 11:48:05
# Keywords: function
# comments: two inputs
# Windows PowerShell 4.0 Best Practices, Microsoft Press, 2013
# Chapter 8
# -----------------------------------------------------------------------------
Function Get-FreeDiskSpace
{
 Param ($drive,$computer)
 $driveData = Get-WmiObject -class win32_LogicalDisk `
 -computername $computer -filter "Name = '$drive'" 
"
 $computer free disk space on drive $drive 
    $("{0:n2}" -f ($driveData.FreeSpace/1MB)) MegaBytes
" 
}

Get-FreeDiskSpace -drive "C:" -computer "dc1"
