<#

Script File FullName dump

Author: Rodrigo Varandas
Version: 1.0

USAGE: Get-FullNameDump.ps1
#>

#Variables
$TimeStamp = Get-Date -UFormat "%Y-%m%-%d-%H-%M-%S"
$JOB = "FullNameDump"
$LOGLOCATION = "C:\Users\rodri\Dropbox\Dev\Logs\"


#D drive Dump
$LOG = $LOGLOCATION+$job+"-D-"+$TimeStamp+".log"
Get-ChildItem -Path D:\ -Recurse | Where { $_.fullname -notlike "D:\Plex\*" -and $_.fullname -notlike "D:\Lab\*" -and $_.fullname -notlike "D:\Game\*" -and $_.fullname -notlike "*.jpg" }  | Select FullName |ft >> $LOG
Get-ChildItem -Path I:\ -Recurse | Where { $_.fullname -notlike "I:\Lab\*" }  | Select FullName |ft >> $LOG
Get-ChildItem -Path H:\ -Recurse | Where { $_.fullname -notlike "H:\Lab\*" -and $_.fullname -notlike "\`$OF\*" }  | Select FullName |ft  >> $LOG
<#E drive Dump
$LOG = $LOGLOCATION+$job+"-E-"+$TimeStamp+".log"
Get-ChildItem -Path G:\ -Recurse | Select FullName >> $LOG#>