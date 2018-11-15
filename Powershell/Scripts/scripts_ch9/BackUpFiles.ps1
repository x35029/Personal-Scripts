# -----------------------------------------------------------------------------
# Script: BackUpFiles.ps1
# Author: ed wilson, msft
# Date: 08/28/2013 12:48:13
# Keywords: help
# comments: Adding Help Documentation
# Windows PowerShell 4.0 Best Practices, Microsoft Press, 2013
# Chapter 9
# -----------------------------------------------------------------------------
# ------------------------------------------------------------------------
# NAME: BackUpFiles.ps1
# AUTHOR: ed wilson, Microsoft
# DATE: 12/12/2008
#
# KEYWORDS: Filesystem, get-childitem, where-object
# date manipulation, regular expressions
#
# COMMENTS: This script backs up a folder. It will
# back up files that have been modified within the past 
# 24 hours. You can change the interval, the destination, 
# and the source. It creates a backup folder that is named based upon
# the time the script runs. If the destination folder does not exist, it
# will be created. The destination folder is based upon the time the 
# script is run and will look like this: C:\bu\12.12.2008.1.22.51.PM.
# The interval is the age in days of the files to be copied.
#
# ---------------------------------------------------------------------
Function New-BackUpFolder($destinationFolder)
{
 #Receives the path to the destination folder and creates the path to 
 #a child folder based upon the date / time. It then calls the New-Backup
 #function while passing the source path, destination path, and interval
 #in days. 
 $dte = get-date
 #The following regular expression pattern removes white space, colon,
 #and forward slash from the date and replaces with a period to create the
 #backup folder name. 
 $dte = $dte.tostring() -replace "[:\s/]", "."
 $backUpPath = "$destinationFolder" + $dte
 $null = New-Item -path $backUpPath -itemType directory
 New-Backup $dataFolder $backUpPath $backUpInterval
} #end New-BackUpFolder

Function New-Backup($dataFolder,$backUpPath,$backUpInterval)
{
 #Does a recursive copy of all files in the data folder and filters out
 #all files that have been written to within the number of days specified
 #by the interval. Writes copied files to the destination and will create 
 #if the destination (including parent path) does not exist. Will overwrite
 #if destination already exists. This is unlikely, however, unless the 
 #script is run twice during the same minute. 
 "backing up $dataFolder... check $backUppath for your files"
 Get-Childitem -path $dataFolder -recurse |
 Where-Object { $_.LastWriteTime -ge (get-date).addDays(-$backUpInterval) } |
 Foreach-Object { copy-item -path $_.FullName -destination $backUpPath -force }
} #end New-BackUp

# *** entry point to script ***

$backUpInterval = 1
$dataFolder = "C:\fso"
$destinationFolder = "C:\BU\"
New-BackupFolder $destinationFolder
