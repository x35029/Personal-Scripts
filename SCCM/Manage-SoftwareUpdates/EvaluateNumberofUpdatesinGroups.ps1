# This script will examine the count of updates in each deployed update group and provide a warning
# when the number of updates in a given group exceeds 900.

Param(
    [Parameter(Mandatory = $true)]
    $SiteServerName,
    [Parameter(Mandatory = $true)]
    $SiteCode
    )

# --------------------------------------------------------------------------------------------
#region FUNCTIONS
Function Start-Log(){	
# --------------------------------------------------------------------------------------------
# Function StartLog

# Purpose: Checks to see if a log file exists and if not, created it
#          Also checks log file size
# Parameters:
# Returns: None
# --------------------------------------------------------------------------------------------
    #Check to see if the log folder exists. If not, create it.
    If (!(Test-Path $sOutFilePath )) {
        New-Item -type directory -path $sOutFilePath | Out-Null
    }
    #Check to see if the log file exists. If not, create it
    If (!(Test-Path $sLogFile )) {
        New-Item $sOutFilePath -name $sOutFileName -type file | Out-Null
    }
	Else
	{
        #File exists, check file size
		$sLogFile = Get-Item $sLogFile
        
        # Check to see if the file is > 1 MB and purge if possible
        If ($sLogFile.Length -gt $iLogFileSize) {
            $sHeader = "`nMax file size reached. Log file deleted at $global:dtNow."
            Remove-Item $sLogFile  #Remove the existing log file
            New-Item $sOutFilePath -name $sOutFileName -type file  #Create the new log file
        }
    }

    Write-Log $sHeader -iTabs 0  
	Write-Log -sMessage "############################################################" -iTabs 0 
    Write-Log -sMessage "" -iTabs 0 
    Write-Log -sMessage "============================================================" -iTabs 0 	
    Write-Log -sMessage "$SCRIPT_TITLE ($sScriptName) $SCRIPT_VERSION" -iTabs 0 
	Write-Log -sMessage "============================================================" -iTabs 0 
	Write-Log -sMessage "Script Started at $(Get-Date)" -iTabs 0 
	Write-Log -sMessage "" -iTabs 0     
	Write-Log -sMessage "Variables:" -iTabs 0 
	Write-Log -sMessage "Script Title.....:$SCRIPT_TITLE" -iTabs 1 
	Write-Log -sMessage "Script Name......:$sScriptName" -iTabs 1 
	Write-Log -sMessage "Script Version...:$SCRIPT_VERSION" -iTabs 1 
	Write-Log -sMessage "Script Path......:$sScriptPath" -iTabs 1
	Write-Log -sMessage "User Name........:$sUserDomain\$sUserName" -iTabs 1
	Write-Log -sMessage "Machine Name.....:$sMachineName" -iTabs 1
	Write-Log -sMessage "OS Version.......:$sOSVersion" -iTabs 1
	Write-Log -sMessage "OS Architecture..:$sOSBit" -iTabs 1
	Write-Log -sMessage "System Type......:$sSysType" -iTabs 1	
	Write-Log -sMessage "Is VM............:$bIsVM" -iTabs 1    
	Write-Log -sMessage "VPN Connected....:$bIsOnVPN" -iTabs 1
	Write-Log -sMessage "Log File.........:$sLogFile" -iTabs 1
	Write-Log -sMessage "Command Line.....:$sCMDArgs" -iTabs 1
    Write-Log -sMessage "Arguments===================================================" -iTabs 0 
	Write-Log -sMessage "-DebugLog...:$DebugLog" -iTabs 1
    Write-Log -sMessage "-Force......:$Force" -iTabs 1
    Write-Log -sMessage "-NoRelaunch.:$NoRelaunch" -iTabs 1 
    Write-Log -sMessage "-Action.....:$Action" -iTabs 1 
    Write-Log -sMessage "-Push.......:$Push" -iTabs 1     
    Write-Log -sMessage "-ErrorCode..:$ErrorCode" -iTabs 1    
	Write-Log -sMessage "============================================================" -iTabs 0    
}           ##End of Start-Log function
Function Write-Log(){
# --------------------------------------------------------------------------------------------
# Function Write-Log

# Purpose: Writes specified text to the log file
# Parameters: 
#    sMessage - Message to write to the log file
#    iTabs - Number of tabs to indent text
#    sFileName - name of the log file (optional. If not provied will default to the $sLogFile in the script
# Returns: None
# --------------------------------------------------------------------------------------------
    param( 
        [string]$sMessage="", 
        [int]$iTabs=0, 
        [string]$sFileName=$sLogFile,
        [boolean]$bTxtLog=$true,
        [boolean]$bEventLog=$false,
        [int]$iEventID=0,
        [ValidateSet("Error","Information","Warning")][string]$sEventLogType,
        [string]$sSource=$sEventIDSource 
    )
    
    #Loop through tabs provided to see if text should be indented within file
    $sTabs = ""
    For ($a = 1; $a -le $iTabs; $a++) {
        $sTabs = $sTabs + "    "
    }

    #Populated content with tabs and message
    $sContent = "||"+$(Get-Date -UFormat %Y-%m-%d_%H:%M:%S)+"||"+$sTabs + $sMessage

    #Write contect to the file and if debug is on, to the console for troubleshooting
    Add-Content $sFileName -value  $sContent -ErrorAction SilentlyContinue
    IF (!$?){                
        $global:iExitCode = 5001            
    }
    Show-Debug $sContent -sColor "white"
    if($bEventLog){
        try{
            New-EventLog -LogName Application -Source $sSource -ErrorAction SilentlyContinue
            Write-EventLog -LogName Application -Source $sSource -EntryType $sEventLogType -EventId $iEventID -Message $sMessage -ErrorAction SilentlyContinue
        }
        catch{
            $global:iExitCode = 5003
        }
    }
	
}           ##End of Write-Log function
Function End-Log(){
# --------------------------------------------------------------------------------------------
# Function EndLog
# Purpose: Writes the last log information to the log file
# Parameters: None
# Returns: None
# --------------------------------------------------------------------------------------------
    #Loop through tabs provided to see if text should be indented within file
	Write-Log -sMessage "" -iTabs 0 
    Write-Log -sMessage "Script Completed at $(Get-date) with Exit Code $global:iExitCode" -iTabs 0  
    Write-Log -sMessage "============================================================" -iTabs 0     
    Write-Log -sMessage "" -iTabs 0     
    Write-Log -sMessage "" -iTabs 0 
    Write-Log -sMessage "" -iTabs 0 
    Write-Log -sMessage "" -iTabs 0 
}             ##End of End-Log function
Function Show-Debug(){
# --------------------------------------------------------------------------------------------
# Function Show-Debug

# Purpose: Allows you to show debug information
# Parameters: 
#    sText - Text to display as debug
#    iTabs - number of tabs to indent the text
# Returns: none
# --------------------------------------------------------------------------------------------
    param( [string]$sText="", [int]$iTabs=0, [string]$sColor="Gray") 
    
    if ($DebugLog -eq $true) {Write-Host  $sText -ForegroundColor $scolor}

}          ##End of Show-Debug function
#endregion
# --------------------------------------------------------------------------------------------

# --------------------------------------------------------------------------------------------
#region VARIABLES

# Standard Variables
    # *****  Change Logging Path and File Name Here  *****
    $sLogContext	= "System" 		# System / User 
    $sLogFolder		= "SCCM"	# Folder Name
    $sOutFileName	= "Evaluate-UpdatesinSUG.log" # Log File Name    
    # ****************************************************
    $sScriptName 	= $MyInvocation.MyCommand
    $sScriptPath 	= Split-Path -Parent $MyInvocation.MyCommand.Path
    $sLogRoot		= "C:\Logs"
    $sOutFilePath	= Join-Path -Path (Join-Path -Path $sLogRoot -ChildPath $sLogContext) -ChildPath $sLogFolder
    $sLogFile		= Join-Path -Path $sOutFilePath -ChildPath $sOutFileName
    $global:iExitCode = 0
    $sUserName		= $env:username
    $sUserDomain	= $env:userdomain
    $sMachineName	= $env:computername
    $sCMDArgs		= $MyInvocation.Line
    $bAllow64bitRelaunch = $true
    $iLogFileSize 	= 1048576
    $VerbosePreference = "SilentlyContinue" 
    # Script Specific Variables
      
#endregion 
# --------------------------------------------------------------------------------------------
Import-module ($Env:SMS_ADMIN_UI_PATH.Substring(0,$Env:SMS_ADMIN_UI_PATH.Length-5) + '\ConfigurationManager.psd1')

# Connect to discovered top level site
cd $SiteCode":"

$UpdateCount = 0

# Get all of the software update groups current configured.
$SoftwareUpdateGroups = Get-cmsoftwareupdategroup
# Loop through each software update group and check the total number of updates in each.
$textColor="Green"
Write-Host 
ForEach ($Group in $SoftwareUpdateGroups){        
    # Only test update groups that are deployed.  Reporting software update groups may be used
    # in some environments and as long as these groups aren't deployed they can contain greater
    # than 1000 updates.  Accordingly, warning for those groups doesn't apply.
    If ($Group.IsDeployed -eq 'True'){
        ForEach ($UpdateID in $Group.Updates){
            $UpdateCount=$UpdateCount + 1
        }
        If ($UpdateCount -gt 900){
            $textColor="Red"
        }
        else{
            $textColor="Green"
        }
        write-host "Evaluating SUG: $($Group.LocalizedDisplayName) - Updates found: $UpdateCount" -ForegroundColor $textColor
    }
    $UpdateCount = 0    
}