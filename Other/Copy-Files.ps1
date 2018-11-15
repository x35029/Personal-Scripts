# Robocopy Error Handling  
#############################################################
#   Script to copy SCCM Packages from Packaging Server to 	#
#	FI DR File Servers  									#
# 					by Jose Varandas					 	#
#############################################################
# Create Date: 		07/28/2015								#
# Version: 			1.0										#
# Last Modified:	07/28/2015								#
# Modified by:		Jose Varandas							#
#############################################################

# CONSTANT
$JOB = "SCCMApps_Copy"                             # Unique Name for this robocopy script$PKGSERVER = 'daldat01'                            # Server where Packaging maintain their packages before submitting to SCCM$PKGPATH = '\\'+$PKGSERVER+'\SCCMPAckages\App\x64' # Path containing target packages to be copied$FIPATH = 'f:\SCCMPAckages\App\x64'                # Path to store copied packages
$LOGPATH = "F:\SCCMPackages"                       # location for Logs
$LOGFILE = "$LOGPATH\$JOB"                         # naming logs (same job)
$TIMESTAMP = get-date -uformat "%Y-%m%-%d-%H-%M"   # Time and Date Info

#Function to test admin credentials (needed for eventlog creation)
function Test-Administrator{  
    $user = [Security.Principal.WindowsIdentity]::GetCurrent();
    (New-Object Security.Principal.WindowsPrincipal $user).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)  
}

#Function to write custom EventLogs

function Write-CustomEvenLogs ($JOB,$ExitCode){
    # Create EventLog Source if not created already
    if ([System.Diagnostics.EventLog]::SourceExists($JOB) -eq $false) {    
        [System.Diagnostics.EventLog]::CreateEventSource($JOB, "Application")
    }

    #Error Details 
    $MSGType=@{
        "104"="Error"
        "103"="Warning"
        "102"="Warning"
        "101"="Error"
        "100"="Error"
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

    # Message descriptions for each ExitCode.
    $MSG=@{
        "104"="Re-run Copy_SCCMPAckages_x64 does not have enough permissions to excecute.
        Re-run Copy_SCCMPAckages_x64 scheduled task, once issue is resolved."
        "103"="Server Disk space running low. Increase free disk space up to 20GB. 
        Re-run Copy_SCCMPAckages_x64 scheduled task, once free space is available."
        "102"="Server Disk space running low. Increase free disk space up to 20GB. 
        Re-run Copy_SCCMPAckages_x64 scheduled task, once free space is available."
        "101"="Test-Path to $PKGPATH Failed. Check if path is accessible.  
        Re-run Copy_SCCMPAckages_x64 scheduled task, once path is restored."
        "100"="Test-Connection to $PKGSERVER Failed. 
        Check if Server is online, active and accepting connections. 
        Re-run Copy_SCCMPAckages_x64 scheduled task, once conectivity is restored."
        "16"="Serious error. $JOB did not copy any files.`n
        Examine the output log: $LOGFILE`-Robocopy`-$TIMESTAMP.log `n
        Re-run Copy_SCCMPAckages_x64 scheduled task, once issue is resolved."
        "15"="Serious error. $JOB did not copy any files.`n
        Examine the output log: $LOGFILE`-Robocopy`-$TIMESTAMP.log `n
        Re-run Copy_SCCMPAckages_x64 scheduled task, once issue is resolved."
        "14"="Serious error. $JOB did not copy any files.`n
        Examine the output log: $LOGFILE`-Robocopy`-$TIMESTAMP.log `n
        Re-run Copy_SCCMPAckages_x64 scheduled task, once issue is resolved."
        "13"="Serious error. $JOB did not copy any files.`n
        Examine the output log: $LOGFILE`-Robocopy`-$TIMESTAMP.log `n
        Re-run Copy_SCCMPAckages_x64 scheduled task, once issue is resolved."
        "12"="Serious error. $JOB did not copy any files.`n
        Examine the output log: $LOGFILE`-Robocopy`-$TIMESTAMP.log `n
        Re-run Copy_SCCMPAckages_x64 scheduled task, once issue is resolved."
        "11"="Serious error. $JOB did not copy any files.`n
        Examine the output log: $LOGFILE`-Robocopy`-$TIMESTAMP.log `n
        Re-run Copy_SCCMPAckages_x64 scheduled task, once issue is resolved."
        "10"="Serious error. $JOB did not copy any files.`n
        Examine the output log: $LOGFILE`-Robocopy`-$TIMESTAMP.log `n
        Re-run Copy_SCCMPAckages_x64 scheduled task, once issue is resolved."
        "9"="Serious error. $JOB did not copy any files.`n
        Examine the output log: $LOGFILE`-Robocopy`-$TIMESTAMP.log `n
        Re-run Copy_SCCMPAckages_x64 scheduled task, once issue is resolved."
        "8"="Some files or directories could not be copied (copy errors occurred and the retry limit was exceeded).`n
        Check these errors further: $LOGFILE`-Robocopy`-$TIMESTAMP.log `n
        Re-run Copy_SCCMPAckages_x64 scheduled task, once issue is resolved."
        "7"="Files were copied, a file mismatch was present, and additional files were present.`n
        Examine the output log: $LOGFILE`-Robocopy`-$TIMESTAMP.log.`
        Housekeeping is probably necessary. Re-run Copy_SCCMPAckages_x64 scheduled task and compare results."
        "6"="Some files were deleted and some Mismatched files or directories were detected.`n
        Examine the output log: $LOGFILE`-Robocopy`-$TIMESTAMP.log.`
        Housekeeping is probably necessary. Re-run Copy_SCCMPAckages_x64 scheduled task and compare results."
        "5"="Some files were copied and some Mismatched files or directories were detected.`n
        Examine the output log: $LOGFILE`-Robocopy`-$TIMESTAMP.log.`
        Housekeeping is probably necessary. Re-run Copy_SCCMPAckages_x64 scheduled task and compare results."
        "4"="Some Mismatched files or directories were detected.`n
        Examine the output log: $LOGFILE`-Robocopy`-$TIMESTAMP.log.`
        Housekeeping is probably necessary. Re-run Copy_SCCMPAckages_x64 scheduled task and compare results."
        "3"="Some Extra and New files or directories were detected and removed in $FIPATH.`n
        Check the output log for details: $LOGFILE`-Robocopy`-$TIMESTAMP.log"
        "2"="Some Extra files or directories were detected and removed in $FIPATH.`n
        Check the output log for details: $LOGFILE`-Robocopy`-$TIMESTAMP.log"
        "1"="New files from $PKGPATH copied to $FIPATH.`n
        Check the output log for details: $LOGFILE`-Robocopy`-$TIMESTAMP.log"
        "0"="$PKGPATH and $FIPATH in sync. No files copied.`n
        Check the output log for details: $LOGFILE`-Robocopy`-$TIMESTAMP.log"
    }
    #Check if event is documented
    if ($MSG."$ExitCode" -gt $null) {
	    Write-EventLog -LogName Application -Source $JOB -EventID $ExitCode -EntryType $MSGType."$ExitCode" -Message $MSG."$ExitCode"
    }else {
	    $UnknownCode = 999
        Write-EventLog -LogName Application -Source $JOB -EventID $UnknownCode -EntryType Error -Message "Unknown ExitCode. EventID equals ExitCode. Re-run Copy_SCCMPAckages_x64 scheduled task, once issue is resolved."
    }
}

cls
#testing admin rights
If (Test-Administrator -eq $FALSE) {
    $ExitCode = 104
    Write-CustomEvenLogs ($JOB,$ExitCode)   
    exit
}

# Checking $PKGSERVER Accessbility
if (!(Test-Connection -ComputerName $PKGSERVER -count 1 -quiet)) {
    $ExitCode = 100
    Write-CustomEvenLogs ($JOB,$ExitCode)   
    exit
}else{
    # Checking $PKGPATH
    if (!(Test-Path -Path $PKGPATH)) {
        $ExitCode = 101
        Write-CustomEvenLogs ($JOB,$ExitCode)   
        exit
    }
}

#Checking Drive free space
$disk = Get-WmiObject Win32_LogicalDisk -Filter "DeviceID='C:'" | Select-Object Size,FreeSpace
If ( ($disk.FreeSpace /1GB) -le 20) {
    $ExitCode = 102
    Write-CustomEvenLogs ($JOB,$ExitCode)  
    If ( ($disk.FreeSpace /1GB) -le 5) {
        $ExitCode = 103
        Write-CustomEvenLogs ($JOB,$ExitCode)  
    }
}

#Robocopy Arguments
$robocopyArgs = @("$PKGPATH", "$FIPATH", "/MIR","/LOG+:$LOGFILE`-Robocopy`-$TIMESTAMP.log","/R:3","/W:30")

#Running Robocopy
& C:\Windows\System32\Robocopy.exe $robocopyArgs

# Get LastExitCode and store in variable
$ExitCode = $LastExitCode