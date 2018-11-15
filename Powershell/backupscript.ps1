<#

Script Backup

Author: Rodrigo Varandas
Version: 1.0

USAGE: backupscript.ps1
#>

#VARIABLES

$timeStamp = get-date -UFormat "%Y-%m%-%d-%H-%M-%S"
$logMethod = "Not Defined"

#CONSTANTS

$SOURCELOCATION = "M:\ "
$DESTINLOCATION = "N:\"

$JOB = "Backup"
$LOGLOCATION = "P:\Users\rodri\Dropbox\Dev\Logs\"
$LOGNAME = $JOB+"_LOG"
$LOGFILE = $LOGLOCATION+$LOGNAME
$ROBOCOPYLOG = "/LOG+:$LOGFILE-Robocopy-$timeStamp.log"
$SCRIPTLOG = "$LOGFILE-Script-$timeStamp.log"


#TREATED ERRORS
$logMessage = @{
    "102"="Error with logging functions. Do not Consider backup consistent."
    "101"="Error creating EventLog Source. Script will log errors at $SCRIPTLOG"
    "100"="Script running without Admin Rights. It might not execute all instructions properly. Review $SCRIPTLOG for details"
    "16"="Serious error. robocopy did not copy any files. Examine the output log: $LOGFILE`-Robocopy`-$timeStamp.log"
    "15"="Serious error. robocopy did not copy any files. Examine the output log: $LOGFILE`-Robocopy`-$timeStamp.log"
    "14"="Serious error. robocopy did not copy any files. Examine the output log: $LOGFILE`-Robocopy`-$timeStamp.log"
    "13"="Serious error. robocopy did not copy any files. Examine the output log: $LOGFILE`-Robocopy`-$timeStamp.log"
    "12"="Serious error. robocopy did not copy any files. Examine the output log: $LOGFILE`-Robocopy`-$timeStamp.log"
    "11"="Serious error. robocopy did not copy any files. Examine the output log: $LOGFILE`-Robocopy`-$timeStamp.log"
    "10"="Serious error. robocopy did not copy any files. Examine the output log: $LOGFILE`-Robocopy`-$timeStamp.log"
    "9"= "Serious error. robocopy did not copy any files. Examine the output log: $LOGFILE`-Robocopy`-$timeStamp.log"
    "8"="Some files or directories could not be copied (copy errors occurred and the retry limit was exceeded). Check these errors further: $LOGFILE`-Robocopy`-$timeStamp.log"
    "7"="Files were copied, a file mismatch was present, and additional files were present."
    "6"="Additional files and mismatched files exist. No files were copied and no failures were encountered. This means that the files already exist in the destination directory"
    "5"="Some files were copied. Some files were mismatched. No failure was encountered."
    "4"="Some Mismatched files or directories were detected. Examine the output log: $LOGFILE`-Robocopy`-$timeStamp.log. Housekeeping is probably necessary."
    "3"="Some files were copied. Additional files were present. No failure was encountered"
    "2"="Some Extra files or directories were detected and removed in $DESTINLOCATION. Check the output log for details: $LOGFILE`-Robocopy`-$timeStamp.log"
    "1"="New files from $SOURCELOCATION copied to $DESTINLOCATION. Check the output log for details: $LOGFILE`-Robocopy`-$timeStamp.log"
    "0"="$SOURCELOCATION and $DESTINLOCATION in sync. No files copied. Check the output log for details: $LOGFILE`-Robocopy`-$timeStamp.log"
}

$logType = @{
    "102"="Error"
    "101"="Warning"
    "100"="Warning"
    "16"="Error"
    "15"="Error"
    "14"="Error"
    "13"="Error"
    "12"="Error"
    "11"="Error"
    "10"="Error"
    "9"="Error"
    "8"="Error"
    "7"="Warning"
    "6"="Warning"
    "5"="Warning"
    "4"="Warning"
    "3"="Information"
    "2"="Information"
    "1"="Information"
    "0"="Information"
}
cls
function Check-Credentials ($role) {
    switch ($role) {
        Administrator {
            $user = [Security.Principal.WindowsIdentity]::GetCurrent();
            (New-Object Security.Principal.WindowsPrincipal $user).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
            write-host "Script running with Admin Rights" 
            return $TRUE
        }
        default {
            Write-Host "Role not coded in Check-Credentials function. Not able to validate credential rights"
            return $FALSE
        }
    }
}

function Create-EventLogSource ($sourceName){    
  	if ([System.Diagnostics.EventLog]::SourceExists("$sourceName") -eq $FALSE) {
	    Write-Host "Creating EventLog Source `"$sourceName`""
        [System.Diagnostics.EventLog]::CreateEventSource("$sourceName", "Application")
	}
    if ([System.Diagnostics.EventLog]::SourceExists("$sourceName") -eq $FALSE) {   
        write-host " Script not able to create $sourceName EventLog Source"     
        return $FALSE
    }else {        
        write-host "Script able to create $sourceName EventLog Source" 
        return $TRUE
    }
}

function Write-CustomEventLog ($sourceName,$ExitCode,$logType,$logMessage) {    
    if ($logMessage."$ExitCode" -gt $null) {
		Write-EventLog -LogName Application -Source $sourceName -EventID $ExitCode -EntryType $logType."$ExitCode" -Message $logMessage."$ExitCode"
        write-host "     Script able to create Eventlog as:"
        write-host "          LogName:Application Source:$sourceName EventID:$ExitCode EntryType:$($logType["$ExitCode"]) `n          Message:$($logMessage["$ExitCode"])`n"  
	}	else {
		Write-EventLog -LogName Application -Source $sourceName -EventID $ExitCode -EntryType Warning -Message "Unknown ExitCode. EventID equals ExitCode"
        write-host "     Script able to create Eventlog as:"
        write-host "          LogName:Application Source:$sourceName EventID:$ExitCode EntryType:Warning `n          Message:Unknown ExitCode. EventID equals ExitCode" 
	}
}

function Write-CustomScriptLog ($sourceName,$ExitCode,$logType,$logMessage) {
    $logTime = get-date -UFormat "%Y-%m%-%d-%H-%M-%S"
    if ($logMessage."$ExitCode" -gt $null) {    
        write-Output "$logTime - Source: $sourceName - EventID: $ExitCode - EntryType:$($logType["$ExitCode"]) - Message:$($logMessage["$ExitCode"])" >> $SCRIPTLOG
        write-host "     Script able to create Scriptlog as:"
        write-host "          $logTime - Source: $sourceName - EventID: $ExitCode - EntryType:$($logType["$ExitCode"]) - `n          Message:$($logMessage["$ExitCode"])`n"  
    }else {
        write-Output "$logTime - Source: $sourceName - EventID: $ExitCode - EntryType: Warning - Message: Unknown ExitCode. EventID equals ExitCode" >> $SCRIPTLOG
        write-host "     Script able to create Scriptlog as:"
        write-host "          $logTime - Source: $sourceName - EventID: $ExitCode - EntryType:Warning - `n          Message: Unknown ExitCode. EventID equals ExitCode"
	}
}

If ((Check-Credentials ("Administrator")) -eq $FALSE) {    
    Write-CustomEventLog $JOB "100" $logType $logMessage    
}

If (!(Create-EventLogSource ($JOB))) { 
    $logMethod = "TXT"
    Write-CustomEventLog  $JOB "101" $logtype $logMessage
}else {    
    $logMethod = "EventLog"
}
$roboArgs = @("","",$ROBOCOPYTYPE,"/R:3","/W:10",$ROBOCOPYLOG)
Robocopy $SOURCELOCATION $DESTINLOCATION /MIR /R:3 /W:10 /XF *.db /XA:SHT $ROBOCOPYLOG
$exitCode=$LASTEXITCODE
if ($logMethod -eq "TXT") { 
    Write-CustomScriptLog $JOB $exitCode $logtype $logMessage
}elseif ($logMethod -eq "EventLog") {
    Write-CustomEventLog $JOB $exitCode $logtype $logMessage
}else {
    Write-CustomScriptLog $JOB 102 $logtype $logMessage
}