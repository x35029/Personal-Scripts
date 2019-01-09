param( 
    [switch]$DebugLog=$false, 
    [switch]$NoRelaunch=$False, 
    [ValidateSet("Check","Run","Auto-Run")][string]$Action="Check",
    [ValidateSet("CAS","CS2","S2M-WKS","S2M","Other","VAR","PVA","PVALAB","VARLAB")][string]$SCCMScope="Other"
)
# --------------------------------------------------------------------------------------------
#region HEADER
$SCRIPT_TITLE = "SUP-Maintenance"
$SCRIPT_VERSION = "4.0"

$ErrorActionPreference 	= "Continue"	# SilentlyContinue / Stop / Continue

# -Script Name: SUP-Maintenance.ps1------------------------------------------------------ 
# Version: 4.0
# Based on PS Template Script Version: 1.0
# Author: Jose Varandas

# Credits: Credit to Tevor Sullivan.  Modified from his original for use here.
#          http://trevorsullivan.net/2011/11/29/configmgr-cleanup-software-updates-objects/
#            ->Test-SCCMUpdateAge
#            ->Test-SccmUpdateExpired
#            ->Test-SccmUpdateSuperseded
#          Credit to Steve Rachui for this function.  Modified from his original for use here.
#          https://blogs.msdn.microsoft.com/steverac/2014/06/11/automating-software-updates/
#            ->MaintainSoftwareUpdateGroupDeploymentPackages
#            ->EvaluateNumberOfUpdatesinGRoups
#            ->SingleUpdateGroupMaintenance
#            ->UpdateGroupPairMaintenance
#            ->ReportingSoftwareUpdateGroupMaintenance
#
# Owned By: DWS
# Purpose: Use series of script to properly maintain SUP environment
#
# Created:  
#
# Dependencies: 
#                ID running script must be SCCM administrator
#                SCCM Powershell Module
#                ID running script must be able to reach SMSPRoviderWMI
#                Script must run locally in SMSProvider Server
#
# Known Issues: None
#
# Arguments: 
Function HowTo-Script(){
    Write-Log -sMessage "============================================================================================================================" -iTabs 1            
    Write-Log -sMessage "NAME:" -iTabs 1
        Write-Log -sMessage ".\$sScriptName " -iTabs 2     
    Write-Log -sMessage "============================================================================================================================" -iTabs 1            
    Write-Log -sMessage "ARGUMENTS:" -iTabs 1
            Write-Log -sMessage "-DebugLog ($false(Default)/$true) - Enables debug logging in the script, and disables default On Error Resume Next statements" -iTabs 3        	        
            Write-Log -sMessage "-Action (Check/Run) -> Defines Script Execution Mode" -iTabs 3        
                Write-Log -sMessage "-> Check (Default)-> Script will run Pre-checks and Pos-Checks. No Exceution" -iTabs 4        
                Write-Log -sMessage "-> Run -> Runs script (Pre-Checks,Excecution,Post-Checks)" -iTabs 4
                Write-Log -sMessage "-> Auto-Run -> Runs script accepting default options while running Pre-Checks,Excecution,Post-Checks" -iTabs 4
            Write-Log -sMessage "-SCCMScope (CAS/CS2/S2M/Other) -> Defines which SCCM Scope will be targeted." -iTabs 3        
                Write-Log -sMessage "-> CAS: Script targets DALCFG01.na.xom.com as Central Server/WMIProvider and WKS-SecurityUpdates as naming convention" -iTabs 4        
                Write-Log -sMessage "-> CS2: Script targets DALCFG03.na.xom.com as Central Server/WMIProvider and WKS-SecurityUpdate as naming convention" -iTabs 4
                Write-Log -sMessage "-> S2M-WKS: Script targets X1XCFG01.inf-na.xom.com as Central Server/WMIProvider and WKS-SecurityUpdates as naming convention" -iTabs 4
                Write-Log -sMessage "-> S2M: Script targets X1XCFG01.inf-na.xom.com as Central Server/WMIProvider and no naming convention" -iTabs 4
                Write-Log -sMessage "-> Other: Script doesn't have a target server or naming convention and will require all info to be entered manually." -iTabs 4
                Write-Log -sMessage "-> VAR: Script targets SCCM01.vlab.varandas.com as Central Server/WMIProvider and VAR as naming convention" -iTabs 4
                Write-Log -sMessage "-> PVA: Script targets SCCM01.plab.varandas.com as Central Server/WMIProvider and VAR as naming convention" -iTabs 4
                Write-Log -sMessage "-> VARLAB: Script targets SCCM01.vlab.varandas.com as Central Server/WMIProvider and VAR-LAB as naming convention" -iTabs 4
    Write-Log -sMessage "============================================================================================================================" -iTabs 1            
    Write-Log -sMessage "EXAMPLE:" -iTabs 1
        Write-Log -sMessage ".\$sScriptName -Action Check" -iTabs 2     
            Write-Log -sMessage "Script will run all Pre-Checks. No Changes will happen to the device. Action Argument will not be used with `"-Behavior Check`"" -iTabs 2     
        Write-Log -sMessage ".\$sScriptName -Action Run" -iTabs 2     
            Write-Log -sMessage "Script will run all coded remediations, pre and  post checks." -iTabs 2  
    Write-Log -sMessage "============================================================================================================================" -iTabs 1            
    Write-Log -sMessage "NOTE:" -iTabs 1
        Write-Log -sMessage "Action Auto-Run is not supported with SCCMScope Other" -iTabs 2                 
    Write-Log -sMessage "============================================================================================================================" -iTabs 1            
#		
}
#endregion
#region EXIT_CODES
# Exit Codes:
#            0 - Script completed successfully
#
#            3xxx - SUCCESS
#
#            5xxx - WARNING
#
#            8XXX - INFORMATION
#            8001 - Script aborted per user request
#
#            9XXX - ERROR     
#            9001 - Unable to load SCCM Powershell Module   
#            9002 - User does not have permissions to run this script    
#            9003 - Unable to retrieve package information
#            9004 - Unable to retrieve SUG Information
#            9005 - Unable to access SMSProvider via Powershell location
#            9006 - Error while updating Report SUG
#            9007 - Not able to find Sustainer or Report SUGs
#            9008 - Not able to find Sustainer or Monthly PKGs
#            9009 - Error evaluating Sustainer SUG
#            9010 - Error evaluating Report SUG
#            9011 - Script executed with wrong parameters
#            9012 - Error getting ADR information
#            9013 - Error getting SUG Information
#            9014 - Error getting Deployment Package info
# 
# Output: 
#    
# Revision History: (Date, Author, Description)
#		(Date )
#			v4.0
#			Jose Varandas
#           CHANGELOG:
#               -> Added more default options for script execution
#							
# -------------------------------------------------------------------------------------------- 
#endregion
# --------------------------------------------------------------------------------------------

# --------------------------------------------------------------------------------------------
#region FUNCTIONS
Function Relaunch-In64{
# --------------------------------------------------------------------------------------------	
# Sub Name: RelaunchIn64

# Purpose: To relaunch the script as a 64bit process
# Variables: None
# --------------------------------------------------------------------------------------------
    Show-Debug "Restarting script in 64-bit PowerShell"
    
    $xpath = (Join-Path -Path ($PSHOME -replace "syswow64", "sysnative") -ChildPath "powershell.exe")
    Show-Debug "PS Engine = $xpath"
    Show-Debug "Command = $xpath $sCMDArgs"

    $global:iExitCode = (Start-Process -FilePath $xpath -ArgumentList $sCMDArgs -Wait -PassThru -WindowStyle Hidden).ExitCode
    Show-Debug "Exit Code = $global:iExitCode"
    
}         ##End of Relaunch-In64 function
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
	Write-Log -sMessage "Log File.........:$sLogFile" -iTabs 1
	Write-Log -sMessage "Command Line.....:$sCMDArgs" -iTabs 1
    Write-Log -sMessage "Arguments===================================================" -iTabs 0 
	Write-Log -sMessage "-DebugLog...:$DebugLog" -iTabs 1
    Write-Log -sMessage "-NoRelaunch.:$NoRelaunch" -iTabs 1 
    Write-Log -sMessage "-Action.....:$Action" -iTabs 1 
    Write-Log -sMessage "-SCCMScope:$SCCMScope" -iTabs 1    
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
        [boolean]$bConsole=$false,
        [string]$sColor="white",         
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

    #Populated content with timeanddate, tabs and message
    $sContent = "||"+$(Get-Date -UFormat %Y-%m-%d_%H:%M:%S)+"|"+$sTabs + "|"+$sMessage

    #Write content to the file
    if ($bTxtLog){
        Add-Content $sFileName -value  $sContent -ErrorAction SilentlyContinue
    }    
    #write content to Event Viewer
    if($bEventLog){
        try{
            New-EventLog -LogName Application -Source $sSource -ErrorAction SilentlyContinue
            Write-EventLog -LogName Application -Source $sSource -EntryType $sEventLogType -EventId $iEventID -Message $sMessage -ErrorAction SilentlyContinue
        }
        catch{
            $global:iExitCode = 5003
        }
    }
    # Write Content to Console
    if($bConsole){        
            Write-Host $sContent -ForegroundColor $scolor        
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
function ConvertTo-Array{
    begin{
        $output = @(); 
    }
    process{
        $output += $_;   
    }
    end{
        return ,$output;   
    }
}
#endregion
# --------------------------------------------------------------------------------------------

# --------------------------------------------------------------------------------------------
#region SUP-FUNCTIONS
Function ReportingSoftwareUpdateGroupMaintenance{
# This script is designed to ensure consistent membership of the reporting software update group.
# In this version it is assumed there is only one reporting software update group.  A reporting software
# update group is assumed to never be deployed.  Accordingly, The script will first check to see if the 
# reporting software update group is deployed.  If so the script will display an error and exit.
# If no error then the updates in every other software update group will be reviewed and added to the
# reporting software update group.  There is no check to see if the update is already in the reporting
# software update group because if it is it won't be added twice.
    Param(
        [Parameter(Mandatory = $true)]
        $SiteServerName,
        [Parameter(Mandatory = $true)]
        $SiteCode,
        [Parameter(Mandatory = $true)]
        $ReportingUpdateGroup,
        [Parameter(Mandatory = $false)]
        $DeploySUGName
        )
    # Connect to discovered top level site.    
    try{
        # Check to see if the reporting software update group is deployed.  If so, exit.
        If ((Get-CMSoftwareUpdateGroup -Name $ReportingUpdateGroup).IsDeployed -eq $true){
            write-host "    Reporting Software Update Group is deployed.  This is not allowed.  Exiting." -ForegroundColor Red
            Write-Log "Reporting Software Update Group is deployed.  This is not allowed.  Exiting." -iTabs 3
            exit
        }
        else{
            $initialRptUpdates = $(Get-CMSoftwareUpdateGroup -Name $ReportingUpdateGroup).NumberofUpdates            
            Write-Host "    $ReportingUpdateGroup found with $initialRptUpdates updates."
            Write-Log "$ReportingUpdateGroup found with $initialRptUpdates updates." -iTabs 3            
        }
    }
    catch{
        write-host "    $ReportingUpdateGroup not found. Exiting." -ForegroundColor Red
        Write-Log "$ReportingUpdateGroup not found. Exiting." -iTabs 3            
        exit
    }

    # Get all of the software update groups currently configured.  This list will be used for pupulating the reporting
    # software update group.
    $AllSoftwareUpdateGroups = Get-CMSoftwareUpdateGroup | Where {$_.LocalizedDisplayName -like "$DeploySUGName*"}        
    $currentSUG = 1
    # Work through each software update group and add all updates from each to the reporting software update group.
    ForEach ($UpdateGroup in $AllSoftwareUpdateGroups){            
        # As long as the update group being handled is not the reporting software update group, proceed to process.
        If ($UpdateGroup.LocalizedDisplayName -ne $ReportingUpdateGroup){
            # Get all of the updates from the update group being evaluated.
            Write-Host "    ($currentSUG of $($AllSoftwareUpdateGroups.Count-1)) Evaluating SUG: $($UpdateGroup.LocalizedDisplayName)."
            Write-Log      "($currentSUG of $($AllSoftwareUpdateGroups.Count-1)) Evaluating SUG: $($UpdateGroup.LocalizedDisplayName)." -iTabs 3
            $Updates = Get-CMSoftwareUpdate -updategroupname $UpdateGroup.LocalizedDisplayName -Fast
            Write-Host "        Adding $($Updates.Count) updates" -ForegroundColor DarkGray
            Write-Log          "Adding $($Updates.Count) updates" -iTabs 4            
            # Loop through each update and add to the reporting software update group
            ForEach ($Update in $Updates){
                if ($Action -eq "Run"){
                    Add-CMSoftwareUpdateToGroup -SoftwareUpdateGroupName $ReportingUpdateGroup -SoftwareUpdateID $Update.CI_ID
                }
            }
            $currentSUG++
        }        
    }
    $finalRptUpdates = $(Get-CMSoftwareUpdateGroup -Name $ReportingUpdateGroup).NumberofUpdates            
    Write-Host "    $ReportingUpdateGroup now has $finalRptUpdates updates."
    Write-Log      "$ReportingUpdateGroup now has $finalRptUpdates updates." -iTabs 4
}
function UpdateGroupPairMaintenance{
# This script is designed to automate the routine maintenance of software update group pairs.
# Specifically, the script will take two software update groups as input - one that contains
# the most recent set of updates for deployment and another that represents the group of persistent
# updates being deployed.  The idea is that the first group will contain the current month or quarter
# of updates while the persistent group will contain those updates that need to remain deployed to 
# the environment in case unpatched systems are brought online.  The expectation though is the majority
# of the environment will already have received the updates in the persistent group.  
# This script will optionally handle scanning of both groups to remove expired or superseded patches 
# and will scan the recent, or current, update group to identify updates over the age threshold that 
# may should be moved to the persistend update group.  If the script is configured to handle aged updates
# but no age threshold is specified then 90 days will be used.
    Param(
        [Parameter(Mandatory = $true)]
        $SiteProviderServerName,
        [Parameter(Mandatory = $true)]
        $SiteCode,
        [Parameter(Mandatory = $true)]
        $CurrentUpdateGroup,
        [Parameter(Mandatory = $true)]
        $PersistentUpdateGroup,
        [Parameter(Mandatory = $false)]  
        $HandleAgedUpdates=$false,
        [Parameter(Mandatory = $false)]  
        $NumberofDaystoKeep=365,
        [Parameter(Mandatory = $false)]
        $PurgeExpired=$false,
        [Parameter(Mandatory = $false)]
        $PurgeSuperseded=$false
        )

    If ($CurrentUpdateGroup -eq $PersistentUpdateGroup){
        write-host ("The Current and Persistent update groups are the same group.  This is not allowed.  Exiting")
        exit
    }         
    # Credit to Tevor Sullivan for this function.  Modified from his original for use here.
    # http://trevorsullivan.net/2011/11/29/configmgr-cleanup-software-updates-objects/
    Function Test-SccmUpdateExpired{
        param(
            [Parameter(Mandatory = $true)]
            $UpdateId,
            [Parameter(Mandatory = $true)]
            $TakeAction
        )

        #Test to see if we should purge expired updates based on input.  If not, return false
        If ($TakeAction -eq $false)
            {            
            return $false
            }

        # Find update that is expired with the specified CI_ID (unique ID) value
        $ExpiredUpdateQuery = "select * from SMS_SoftwareUpdate where IsExpired = 'true' and CI_ID = '$UpdateId'"
        $Update = @(Get-WmiObject -ComputerName $SiteProviderServerName -Namespace root\sms\site_$($SiteCode) -Query $ExpiredUpdateQuery)
  
        # If the WMI query returns more than 0 instances (should NEVER be more than 1 at most), then the update is expired.
        if ($Update.Count -gt 0)
            {
            
            return $true
            }
        else
            {
            
            return $false
            }
    }
    Function Test-SccmUpdateSuperseded{
        param(
            [Parameter(Mandatory = $true)]
            $UpdateId,
            [Parameter(Mandatory = $true)]
            $TakeAction
        )

        #Test to see if we should purge superseded updates based on input.  If not, return false
        If ($TakeAction -eq $false)
            {
            
            return $false
            }

        # Find update that is superseded with the specified CI_ID (unique ID) value
        # Changing the format of Get-WmiObject because for some reason trying to pull
        # IsSuperseded information using the same query format as is used for checking
        # Expired updates fails here
        $Update = Get-WmiObject -ComputerName $SiteProviderServerName -Namespace root\sms\site_$($SiteCode) -Class SMS_SoftwareUpdate -filter "CI_ID='$UpdateID'"
        
        # If the WMI query returns more than 0 instances (should NEVER be more than 1 at most), then the update is expired.
        If ($Update.IsSuperseded -eq "True")
            {
            
            return $true
            }
        else
            {
            return $false
            }
    }
    Function Test-SCCMUpdateAge{
        param(
            [Parameter(Mandatory = $true)]
            $UpdateId,
            [Parameter(Mandatory = $true)]
            $AgeThreshold,
            [Parameter(Mandatory = $true)]
            $TakeAction,
            [Parameter(Mandatory = $true)]
            $PersistentGroup
        )

        #Test to see if we should handle aged updates based on input.  If not, return false
        If ($TakeAction -eq $false)
            {
            
            return $false
            }

        # Find update that is older than the specified threshold.  This will be done
        # by first pulling each update remaining in the list and querying the DateLastModified
        # property from WMI.  This property will then be converted to a proper datetime format
        # and then simple mathmatical comparison can be done to test the age.  If the update age
        # is outside of the threshold remove from the current update group and store for later
        # move into persistent update group.
        $AgedUpdateQuery = "select * from SMS_SoftwareUpdate where CI_ID = '$UpdateId'"
        $Update = @(Get-WmiObject -ComputerName $SiteProviderServerName -Namespace root\sms\site_$($SiteCode) -Query $AgedUpdateQuery)
        $UpdateDate = [System.Management.ManagementDateTimeConverter]::ToDateTime($Update.DatePosted)
    
        if ($UpdateDate -lt $AgeThreshold){            
            if ($Action -eq "Run"){
                Add-CMSoftwareUpdateToGroup -SoftwareUpdateGroupName "$PersistentGroup" -SoftwareUpdateID $Update.CI_ID            
            }
            
            Write-Host "        KB$($Update.ArticleID) added to Sustainer: (CI_ID:$UpdateId)" -ForegroundColor DarkGreen
            Write-Log          "KB$($Update.ArticleID) added to Sustainer: (CI_ID:$UpdateId)" -iTabs 4
            return $true
            }
        else
            {
            
            return $false
            }
    }

    # Get current date and calculate the aged update threshold based on either 365
    # days or the value passed in.
    $CurrentDate=Get-Date  
    $CurrentDateLessKeepThreshold=$CurrentDate.AddDays(-$NumberofDaystoKeep)

    # Retrieve the update group that was passed in as the current update group.
    # These are the update groups where we will be performing maintenance.
    $CurrentUpdateList = Get-WmiObject -Namespace root\sms\site_$($SiteCode) -Class SMS_AuthorizationList -ComputerName $SiteProviderServerName -filter "localizeddisplayname = '$CurrentUpdateGroup'"
    $PersistentUpdateList = Get-WmiObject -Namespace root\sms\site_$($SiteCode) -Class SMS_AuthorizationList -ComputerName $SiteProviderServerName -filter "localizeddisplayname = '$PersistentUpdateGroup'"

    #Process the Current Update Group 
    $CurrentUpdateList = [wmi]"$($CurrentUpdateList.__PATH)" #There is a double _ in front of PATH
    #write-host "$($CurrentUpdateList.localizeddisplayname) has $($CurrentUpdateList.Updates.Count) updates in it"

    # Loop through each update in the current update group handling expired, superseded or age threshold per
    # configuration.    
    ForEach ($UpdateID in $CurrentUpdateList.Updates){               
        If (Test-SccmUpdateExpired -UpdateID $UpdateID -TakeAction $PurgeExpired){            
            $CurrentUpdateList.Updates = @($CurrentUpdateList.Updates | ? {$_ -ne $UpdateID})   
            Write-Host "        KB Expired removed from SUG. (CI_ID:$UpdateId)." -ForegroundColor DarkGray
            Write-Log          "KB Expired removed from SUG. (CI_ID:$UpdateId)." -iTabs 4                        
            <#
            $UpdateQuery = "select * from SMS_SoftwareUpdate where CI_ID = '$UpdateID'"
            $updateInfo = @(Get-WmiObject -ComputerName $SiteProviderServerName -Namespace root\sms\site_$($SiteCode) -Query $UpdateQuery)            
            
            #>
        }
        elseIf (Test-SCCMUpdateSuperseded -UpdateID $UpdateID -TakeAction $PurgeSuperseded){            
            $CurrentUpdateList.Updates = @($CurrentUpdateList.Updates | ? {$_ -ne $UpdateID})  
            Write-Host "        KB Superseded removed from SUG. (CI_ID:$UpdateId)." -ForegroundColor DarkYellow
            Write-Log          "KB Superseded removed from SUG. (CI_ID:$UpdateId)." -iTabs 4             
            <#
            $UpdateQuery = "select * from SMS_SoftwareUpdate where CI_ID = '$UpdateID'"
            $updateInfo = @(Get-WmiObject -ComputerName $SiteProviderServerName -Namespace root\sms\site_$($SiteCode) -Query $UpdateQuery)            
            
            #>
        }
        elseIf (Test-SCCMUpdateAge -UpdateID $UpdateID -AgeThreshold $CurrentDateLessKeepThreshold -TakeAction $HandleAgedUpdates -PersistentGroup $PersistentUpdateGroup){            
            $CurrentUpdateList.Updates = @($CurrentUpdateList.Updates | ? {$_ -ne $UpdateID})
            Write-Host "        KB Aged removed from SUG. (CI_ID:$UpdateId)." -ForegroundColor DarkGreen
            Write-Log          "KB Aged removed from SUG. (CI_ID:$UpdateId)." -iTabs 4                  
            <#
            $UpdateQuery = "select * from SMS_SoftwareUpdate where CI_ID = '$UpdateID'"
            $updateInfo = @(Get-WmiObject -ComputerName $SiteProviderServerName -Namespace root\sms\site_$($SiteCode) -Query $UpdateQuery)            
            
            #>
        }
    }
    # Operation on update group is complete, write results to WMI.    
    if ($Action -eq "Run"){  
        if ($($CurrentUpdateList.Updates) -eq $null){
            Write-Host "        No remaining Updates in $CurrentUpdateGroup. Deleting SUG" 
            Write-Log          "No remaining Updates in $CurrentUpdateGroup. Deleting SUG" -iTabs 4 
            Remove-CMSoftwareUpdateGroup -Name $CurrentUpdateGroup -Force
        }
        else{
            $CurrentUpdateList.Put() | Out-Null        
        }
    }       
}
Function SingleUpdateGroupMaintenance{
# This script is designed to handle maintenance of software update groups individually.
# Maintenance options include scanning for and removing superseded, expired or aged updates.
# NOTE 1:  If removing aged updates this script simply removes them without adding them to another update 
# group.  A separate script is available that will handle moving updates to another update group 
# if needed.  When the script is used to purge aged updates the assumption is that this operation will be
# done on the persistent update group.  Accordingly and unless otherwise specified, the default threshold for
# update age is 1 year.
# NOTE 2:  This script does not handle purging updates from the deployment packages.  A separate script is 
# available for that.
    Param(
        [Parameter(Mandatory = $true)]
        $SiteProviderServerName,
        [Parameter(Mandatory = $true)]
        $SiteCode,
        [Parameter(Mandatory = $true)]
        $ManagedUpdateGroup,
        [Parameter(Mandatory = $false)][boolean]
        $HandleAgedUpdates=$false,
        [Parameter(Mandatory = $false)]
        $NumberofDaystoKeep=365,
        [Parameter(Mandatory = $false)][boolean]
        $PurgeSuperseded=$true,
        [Parameter(Mandatory = $false)][boolean]
        $PurgeExpired=$true,
        [boolean]$WhatIf=$true
        )     

    
    # Credit to Tevor Sullivan for this function.  Modified from his original for use here.
    # http://trevorsullivan.net/2011/11/29/configmgr-cleanup-software-updates-objects/
    Function Test-SccmUpdateExpired{
        param(
            [Parameter(Mandatory = $true)]
            $UpdateId,
            [Parameter(Mandatory = $true)]
            $TakeAction
        )

        #Test to see if script should purge expired updates based on input.  If not, return false.
        If ($TakeAction -eq $false){
            #write-host ("Configured to not evaluate update expired function")
            return $false
        }

        # Find update that is expired with the specified CI_ID (unique ID) value
        $ExpiredUpdateQuery = "select * from SMS_SoftwareUpdate where IsExpired = 'true' and CI_ID = '$UpdateId'"
        $Update = @(Get-WmiObject -ComputerName $SiteProviderServerName -Namespace root\sms\site_$($SiteCode) -Query $ExpiredUpdateQuery)
  
        # If the WMI query returns more than 0 instances (should NEVER be more than 1 at most), then the update is expired.
        if ($Update.Count -gt 0){
            #Write-host ("    Cleaned expired software update with title: " + $Update[0].LocalizedDisplayName )
            return $true
        }
        else{
            #write-host ("Returning False from update expired function")
            return $false
        }
    }
    Function Test-SccmUpdateSuperseded{
        param(
            [Parameter(Mandatory = $true)]
            $UpdateId,
            [Parameter(Mandatory = $true)]
            $TakeAction
        )
    
        #Test to see if script should purge superseded updates based on input.  If not, return false
        If ($TakeAction -eq $false){
            #write-host ("Configured to not evaluate update supersedence function")
            return $false
        }

        # Find update that is superseded with the specified CI_ID (unique ID) value
        # Changing the format of Get-WmiObject because for some reason trying to pull
        # IsSuperseded information using the same query format as is used for checking
        # Expired updates fails here.
        $Update = Get-WmiObject -ComputerName $SiteProviderServerName -Namespace root\sms\site_$($SiteCode) -Class SMS_SoftwareUpdate -filter "CI_ID='$UpdateID'"
        
        # If the WMI query returns more than 0 instances (should NEVER be more than 1 at most), then the update is expired.
        If ($Update.IsSuperseded -eq "True"){
            #Write-host ("    Cleaned superseded software update with title: " + $Update.LocalizedDisplayName)
            return $true
        }
        else{
            #write-host ("Returning False from update supersedence function")
            return $false
        }
    }
    Function Test-SCCMUpdateAge{
        param(
            [Parameter(Mandatory = $true)]
            $UpdateId,
            [Parameter(Mandatory = $true)]
            $AgeThreshold,
            [Parameter(Mandatory = $true)]
            $TakeAction
        )

        #Test to see if script should handle aged updates based on input.  If not, return false
        If ($TakeAction -eq $false){
            #write-host ("Configured to not evaluate update age function")
            return $false
        }

        # Find updates that are older than the specified threshold.  This will be done
        # by first pulling each update remaining in the list and querying the DateLastModified
        # property from WMI.  This property will then be converted to a proper datetime format
        # and then simple mathmatical comparison can be done to test the age.  If the update age
        # is outside of the threshold remove from the update group.
        $AgedUpdateQuery = "select * from SMS_SoftwareUpdate where CI_ID = '$UpdateId'"
        $Update = @(Get-WmiObject -ComputerName $SiteProviderServerName -Namespace root\sms\site_$($SiteCode) -Query $AgedUpdateQuery)
        $UpdateDate = [System.Management.ManagementDateTimeConverter]::ToDateTime($Update.DateLastModified)
    
        if ($UpdateDate -lt $AgeThreshold){
            #Write-host ("    Cleaned a software update older than age threshold with title: " + $Update[0].LocalizedDisplayName)
            return $true
        }
        else{
            return $false
        }
    }
    # Get current date and calculate the aged update threshold based on either 360
    # days or the value specified.
    $CurrentDate = Get-Date  
    $CurrentDateLessKeepThreshold = $CurrentDate.AddDays(-$NumberofDaystoKeep)

    # Retrieve the update group that was passed in as the managed update group.
    # This is the update group where maintenance will be performed.
    $MaintenanceUpdateList = Get-WmiObject -Namespace root\sms\site_$($SiteCode) -Class SMS_AuthorizationList -ComputerName $SiteProviderServerName -filter "localizeddisplayname = '$ManagedUpdateGroup'"

    #Process the Current Update Group 
    $MaintenanceUpdateList = [wmi]"$($MaintenanceUpdateList.__PATH)" #There is a double _ in front of PATH
    #write-host "    $($MaintenanceUpdateList.localizeddisplayname) has $($MaintenanceUpdateList.Updates.Count) updates in it"

    # Loop through each update in the update group.  Depending on parameters test update to see if it is expired, superseded
    # or past the age threshold.  Remove from the update group according to configuration and findings.
    $upCount=0
    ForEach ($UpdateID in $MaintenanceUpdateList.Updates){
        <#
        If ((Test-SccmUpdateExpired -UpdateID $UpdateID -TakeAction $PurgeExpired) -or (Test-SCCMUpdateSuperseded -UpdateID $UpdateID -TakeAction $PurgeSuperseded) -or (Test-SCCMUpdateAge -UpdateID $UpdateID -AgeThreshold $CurrentDateLessKeepThreshold -TakeAction $HandleAgedUpdates)){
            $MaintenanceUpdateList.Updates = @($MaintenanceUpdateList.Updates | ? {$_ -ne $UpdateID})
            Write-Log "Removing $UpdateID" -iTabs 4
            $upCount++
        }
        #>
        if (Test-SccmUpdateExpired -UpdateID $UpdateID -TakeAction $PurgeExpired){
            $MaintenanceUpdateList.Updates = @($MaintenanceUpdateList.Updates | ? {$_ -ne $UpdateID})
            Write-Host "        CI_ID:$UpdateId is Expired." -ForegroundColor DarkGray
            Write-Log          "CI_ID:$UpdateId is Expired." -iTabs 4            
            $upCount++
        }
        elseif (Test-SCCMUpdateSuperseded -UpdateID $UpdateID -TakeAction $PurgeSuperseded){
            $MaintenanceUpdateList.Updates = @($MaintenanceUpdateList.Updates | ? {$_ -ne $UpdateID})
            Write-Host "        CI_ID:$UpdateId is Superseded." -ForegroundColor DarkYellow
            Write-Log          "CI_ID:$UpdateId is Superseded." -iTabs 4            
            $upCount++
        }        
        else{
            Write-Host "        CI_ID:$UpdateId is Valid." -ForegroundColor DarkGreen
            Write-Log          "CI_ID:$UpdateId is Valid." -iTabs 4  
        } 
    }
    # Finished evaluating and changing the update group, write the modifications to WMI.
    if ($Action -eq "Run"){
        if ($MaintenanceUpdateList.Updates -eq $null){
            Write-Host "        No remaining Updates in $ManagedUpdateGroup. Verify environment with SME as this result is not expected." 
            Write-Log          "No remaining Updates in $ManagedUpdateGroup. Verify environment with SME as this result is not expected." -iTabs 4 
        }
        else{
            $MaintenanceUpdateList.Put() | Out-Null
        }
    }    
}
function EvaluateNumberOfUpdatesinGRoups{
# This script will examine the count of updates in each deployed update group and provide a warning
# when the number of updates in a given group exceeds 900.
    Param(
        [Parameter(Mandatory = $true)]
        $SiteServerName,
        [Parameter(Mandatory = $true)]
        $SiteCode,
        [Parameter(Mandatory = $true)]
        $SugName
        )
    # Get all of the software update groups current configured.
    $SoftwareUpdateGroups = Get-cmsoftwareupdategroup | WHERE {$_.LocalizedDisplayName -like "$SugName*"}
    # Loop through each software update group and check the total number of updates in each.    
    ForEach ($Group in $SoftwareUpdateGroups){        
        # Only test update groups that are deployed.  Reporting software update groups may be used
        # in some environments and as long as these groups aren't deployed they can contain greater
        # than 1000 updates.  Accordingly, warning for those groups doesn't apply.
        if (($Group.Updates.Count -gt 900) -and ($Group.IsDeployed -eq 'True')){
            $textColor="Red"
        }
        else{
            $textColor="Green"
        }   
        write-host "    Updates found: $($Group.Updates.Count) SUG: $($Group.LocalizedDisplayName)" -ForegroundColor $textColor
        write-log      "Updates found: $($Group.Updates.Count) SUG: $($Group.LocalizedDisplayName)" -iTabs 4
        if ($textcolor -eq "Red"){
            write-host "    SUG that are deployed should contain less than 900 updates. Consider splitting this SUG into more." 
            write-log      "SUG that are deployed should contain less than 900 updates. Consider splitting this SUG into more." -iTabs 4
        }
    }     
}
function MaintainSoftwareUpdateGroupDeploymentPackages {
    # This script is designed to make comparisons between all softwareupdate deployment packages and all software update groups.
    #
    # Each software update deployment package will be scanned against all configured software update
    # groups and where an update remains in a given deployment package that is not a part of any
    # software update group then that update will be removed from the deployment package.  After
    # a given update deployment package completes processing and if there are deletions detected for
    # the software update group then the package will be updated to all associated distribution points.
    # Note:  It is very easy to reconfigure the script to NOT update the distribution points - see comments 
    # in script.
    #
    # In addition, each software update group will be scanned against all configured software update
    # deployment packages.  Where an update is found to exist in an update group but not in a deployment
    # package the update will be called out for potential administrative action.
    # Note:  This script will not add software updates to a deployment package if they are missing.  That
    # action should be handled by an administrator to ensure proper deployment packages are selected for a
    # given update or group.  In addition, this script assumes that only software update groups are being
    # leveraged for deployment of updates to the environment.  If an update has been deployed individually
    # without being included in a software update group then this script will consider such an update as a 
    # candidate for deletion fromt the update deployment package.
    #
    # Note that in ConfigMgr 2012 when an update is removed from a deployment package the source content for
    # the update is automatically removed as well so no specific handling to remove source content is used in
    # the script.

    Param(
        [Parameter(Mandatory = $false)]
        $SiteProviderServerName="SCCM02",
        [Parameter(Mandatory = $false)]
        $SiteCode="VAR",
        [Parameter(Mandatory = $false)]
        $PkgName="VARLAB-TestSUP-",
        [Parameter(Mandatory = $false)]
        $SugName="VARLAB-TestSUP-",
        [Parameter(Mandatory = $false)]
        $takeAction=$false
        )   

if ($Action="Run"){
    $takeAction=$true
}
 # Retrieve all software update deployment packages and softare update groups matching their respective templates
    $SoftwareUpdateDeploymentPackages = Get-CMSoftwareUpdateDeploymentPackage | WHERE {$_.Name -like "*$PkgName*"}
    $SoftwareUpdateGroups = Get-cmsoftwareupdategroup | WHERE {$_.LocalizedDisplayName -like "*$SugName*"}

# Declare hashtables that will be used to keep track of items for comparison and various arrays that will hold 
# temporary values during processing.
$HTUpdateGroupsandUpdates = @{}
$HTUpdateGroupsandUpdatestoRemove = @{}
$HTUpdateDeploymentPackagesandUpdates = @{}
$HTUpdateDeploymentPackagesandUpdatestoRemove = @{}
$TempArray = @()
$TempDepPkgCIRemovalArray = @()
$TempUpdGrpCIRemovalArray = @()
$TempPkgCIArray = @()
$TempUpdCIArray = @()

# Pull and store a list of all configuration items for each deployment package in a hash table.
ForEach ($DeploymentPackage in $SoftwareUpdateDeploymentPackages)
{
    Write-Host "   Checking Package $($DeploymentPackage.Name)"
    Write-Log     "Checking Package $($DeploymentPackage.Name)" -iTabs 4
    $upCount=1
    # Need to convert the Package ID from the deployment package object to a string
    $PkgID = [System.Convert]::ToString($DeploymentPackage.PackageID)
    # The query pulls a list of all software updates in the current package.  This query doesn't
    # pull back a clean value so will store it and then manipulate the string to just get the CI
    # information we need a bit later.
    $Query="SELECT DISTINCT su.* FROM SMS_SoftwareUpdate AS su JOIN SMS_CIToContent AS cc ON  SU.CI_ID = CC.CI_ID JOIN SMS_PackageToContent AS  pc ON pc.ContentID=cc.ContentID  WHERE  pc.PackageID='$PkgID' AND su.IsContentProvisioned=1 ORDER BY su.DateRevised Desc"
    $QueryResults=@(Get-WmiObject -ComputerName $SiteProviderServerName -Namespace root\sms\site_$($SiteCode) -Query $Query)

    # Work one by one through every CI that is part of the package adding each to the array to be
    # stored in the hash table.
    ForEach ($CI in $QueryResults)
    {        
        $upCount++
        # Need to convert the CI information to a string
        $IndividualCIinDeploymentPackage = [System.Convert]::ToString($CI)
        # Since the converted string has more text than just the CI value need to
        # manipulate it to strip off the unneeded parts.
        $Index = $IndividualCIinDeploymentPackage.IndexOf("=")
        $IndividualCIinDeploymentPackage = $IndividualCIinDeploymentPackage.remove(0, ($Index + 1))
        $TempPkgCIArray += $IndividualCIinDeploymentPackage
    }
    Write-Host "    Total Updates: $upCount" -ForegroundColor Gray
    Write-Log      "Total Updates: $upCount" -iTabs 5
    # Add the entry to the hashtable in the format (DeploymentPackageName, Array of CI values) and then
    # reset the array for the next batch of values.
    $HTUpdateDeploymentPackagesandUpdates.Add($DeploymentPackage.Name, $TempPkgCIArray)
    $TempPkgCIArray = @()
}

# Pull and store a list of all configuration items for each software update group in a hash table.
ForEach ($UpdateGroup in $SoftwareUpdateGroups)
{
    Write-Host "   Checking SUG $($UpdateGroup.LocalizedDisplayName)"
    Write-Log     "Checking SUG $($UpdateGroup.LocalizedDisplayName)" -iTabs 4    
    $upCount=1
    # Work one by one throgu every CI that is part of the update group adding each to the array to be
    # stored in the hash table.
    ForEach ($UpdateID in $UpdateGroup.Updates)
    {
        $TempUpdCIArray += $UpdateID        
        $upcount++
    }
    # Add the entry to the hashtable in the format (SoftwareUpdateGroupName, Array of CI values) and then
    # reset the array for the next batch of values.
    $HTUpdateGroupsandUpdates.Add($UpdateGroup.LocalizedDisplayName, $TempUpdCIArray)
    $TempUpdCIArray = @()
    Write-Host "        Total Updates: $upCount" -ForegroundColor Gray
    Write-Log          "Total Updates: $upCount" -iTabs 5
}

# Check Deployment Packages to see if there are any updates that are not currently in an update group.
# Start by examining each package in the hashtable.
Write-Host "    Checking Deployment Packages to see if there are any updates that are not currently in an update group."
Write-Log      "Checking Deployment Packages to see if there are any updates that are not currently in an update group." -iTabs 4
foreach($Package in $HTUpdateDeploymentPackagesandUpdates.Keys)
{
    Write-Host "        Checking Deployment Package $Package"
    # Loop through each CI that has been stored in the array associated with the deployment package
    # entry and compare to see if there is a matching item in any of the software update groups.
    foreach($PkgCI in $HTUpdateDeploymentPackagesandUpdates["$Package"])
    {
        # Flag variable to note whether a match has occurred.  Reset for every loop of a new
        # CI being tested.
        $PkgCIMatch = $false 
        # Now loop through the array of CI's in software update group hashtable and see if a match
        # is detected in any of them.
        foreach($UpdGrpCI in $HTUpdateGroupsandUpdates.Values)
        {
            # This final loop tests individual CI's inside the array pulled from the software updates 
            # group hashtable.
            foreach ($UpdCI in $UpdGrpCI)
            {
                # If a match is detected break out of the loop and move on to the next CI.  Set the
                # PkgCIMatch flag variable to $true indicating a match.
                if ($PkgCI -eq $UpdCI)
                {
                    $PkgCIMatch=$true
                    
                    Write-Host "        PkgCI($PkgCI) is being used in a SUG" -foregroundcolor DarkGreen
                    #Write-Host "$Package|$PkgCI - $UpdCI MATCH!" -ForegroundColor Yellow
                    break
                }
                if($PkgCIMatch){break}
            }
            if($PkgCIMatch){break}
        }
        # If no match is detected then that means there is an update CI in the deployment package that is not
        # found in any software update group.  This update needs to be added to another hash table that will 
        # be used to track updates that need further handling.  The flag variable is not reset here because it
        # is already false.  Note also that no adition is made to the hashtable here becasuse the inner loop
        # needs to fully complete and the flag variable remain false in order to meet the conditions to be added
        # to the hashtable.
        If ($PkgCIMatch -eq $false)
        {
            $TempDepPkgCIRemovalArray += $PkgCI
            Write-Host "        PkgCI($PkgCI) is not being used in a SUG. Flagging for deletion" -foregroundcolor Red
            Write-Log          "$Package|$PkgCI NO MATCH!" -iTabs 5
        }
        $PkgCIMatch = $false
    }
    # Add the package and any mismatched CI's to the hash table for further processing and reinitilize the temporary
    # array for the next pass.
    $HTUpdateDeploymentPackagesandUpdatestoRemove.Add($Package, $TempDepPkgCIRemovalArray)
    # Reinitialize the array for the next pass.
    $TempDepPkgCIRemovalArray = @()
}

# Check Software Update groups to see if there are any updates that are not currently in a deployment package..
# Start by examining each updategroup in the hashtable.
Write-Host "    Check Software Update groups to see if there are any updates that are not currently in a deployment package.." -ForegroundColor Yellow
foreach($UpdateGroup in $HTUpdateGroupsandUpdates.Keys)
{
    Write-Host "        Checking SUG $UpdateGroup"
    # Loop through each CI that has been stored in the array associated with the software update group
    # and compare to see if there is a matching item in any of the deployment packages.
    foreach($UpdCI in $HTUpdateGroupsandUpdates["$UpdateGroup"])
    {
        # Flag variable to note whether a match has occurred.  Reset for every loop of a new
        # CI being tested.
        $UpdCIMatch = $false
        # Now loop through the array of CI's in software update deployment package hashtable and see if a match
        # is detected in any of them.
        foreach($PkgCI in $HTUpdateDeploymentPackagesandUpdates.values)
        {
            # This final loop tests individual CI's inside the array pulled from the software updates deployment
            # package hashtable.
            foreach ($CI in $PkgCI)
            {
                # If a match is detected break out of the loop and move on to the next CI.  Set the
                # PkgCIMatch flag variable to $true indicating a match.
                if ($UpdCI -eq $CI)
                {
                    $UpdCIMatch=$true
                    Write-Host "        SugCI($UpdCI) is present in a package" -foregroundcolor DarkGreen
                    break
                }
                if($UpdCIMatch){break}
            }
            if($UpdCIMatch){break}
        }
        # If no match is detected then that means there is a CI in the software update group that is not
        # found in any deployment package.  This update needs to be added to another hash table that will 
        # be used to track updates that need further handling.  The flag variable is not reset here because it
        # is already false.  Note also that no adition is made to the hashtable here becasuse the inner loop
        # needs to fully complete and the flag variable remain false in order to meet the conditions to be added
        # to the hashtable.
        If ($UpdCIMatch -eq $false)
        {
            $TempUpdGrpCIRemovalArray += $UpdCI
            Write-Host "        SugCI($PkgCI) is not present in a package. Flagging for download" -foregroundcolor Red
            Write-Log          "$UpdateGroup|$UpdCI NO MATCH!" -iTabs 5
        }
        $UpdCIMatch = $false
    }
    $HTUpdateGroupsandUpdatestoRemove.Add($UpdateGroup, $TempUpdGrpCIRemovalArray)
    # Reinitialize array for next loop.
    $TempUpdGrpCIRemovalArray = @()
}

# Have seen some discussion that the removecontent method may error erroneously sometimes so setting to
# silently continue in that section just in case.
$ErrorActionPreference="SilentlyContinue"    
# No process any remove hashtables that were created and remove updates that are part of a deployment package 
# but not part of any update group.
# Start looping through by package.
foreach ($Package in $HTUpdateDeploymentPackagesandUpdatestoRemove.Keys){
    # Reinitialize the array
    $ContentIDArray = @()
    # Check to verify there are CI's in the array associated to the package.  If no CI's then break and continue
    # loop.
    If ($HTUpdateDeploymentPackagesandUpdatestoRemove["$Package"] -ne $Null){
        # Retrieve the specific package from WMI
        $GetPackage = Get-WmiObject -ComputerName $SiteProviderServerName -Namespace root\sms\site_$($SiteCode) -Class SMS_SoftwareUpdatesPackage -Filter "Name ='$Package'"
        # Content removal is done by Content ID and NOT by CI_ID.
        # Declare an array to hold ContentIDs associated with each CI associated with the package.
        $ContentIDArray = @()
        # Loop through each CI associated with the package in the hashtable
        foreach($PkgCI in $HTUpdateDeploymentPackagesandUpdatestoRemove["$Package"]){
            # Retrieve the Content ID associated with each CI and store the value in the ContentID array just created.
            $ContentIDtoContent = Get-WMIObject -NameSpace root\sms\site_$($SiteCode) -Class SMS_CItoContent -Filter "CI_ID='$PkgCI'"
            $ContentIDArray += $ContentIDtoContent.ContentID
        }
        # Call the RemoveContent method on the SMS_SoftwareUpdatesPackage WMI class to remove the content from the specific
        # deployment package currently being processed.  This removal will remove the CI from the deployment package and will
        # also delete the source files from the source directory.
        write-host "    Processing package $Package and removing Content IDs not needed in SUGs"                    
        Write-Log      "Processing package $Package and removing Content IDs not needed in SUGs" -iTabs 4
        if($takeaction){
            $errCount=0
            $pkgClean=$false
            do{
                try{   
                    $GetPackage.RemoveContent($ContentIDArray,$true) | Out-Null
                    $pkgClean=$true
                }
                catch{
                    $errcount++
                    write-host "    Package clean-up failed, but is a known issue. Will retry another $(5-$errCount) times" -ForegroundColor Red                    
                    Write-Log      "Package clean-up failed, but is a known issue. Will retry another $(5-$errCount) times" -iTabs 4
                }
            }while (($errCount -lt 5) -or ($pkgClean -ne $true)) 
        }
        $ContentIDArray = @()
    }
}

# Resetting for normal error handling
$ErrorActionPreference = "Stop"

# List updates that are part of an update group but not part of any deployment package
# This is similar to the above loops but much easier since there is no content removal.
Write-Host "    Listing SUGs Missing Content. Download Article IDs into the listed Package" 
Write-Log      "Listing SUGs Missing Content. Download Article IDs into the listed Package" -iTabs 4
Write-Host "        TargetPackage | Article | Title"
Write-Log          "TargetPackage | Article | Title" -iTabs 5
$AgeThresholdfunc = (GET-DAte).AddDays(-$timeSustainerAge)
foreach ($UpdateGroup in $HTUpdateGroupsandUpdatestoRemove.Keys)
{
    If ($HTUpdateGroupsandUpdatestoRemove["$UpdateGroup"] -ne $Null)
    {
        
        foreach($UpdCI in $HTUpdateGroupsandUpdatestoRemove["$UpdateGroup"])
        {
            $UpdateQuery = "select * from SMS_SoftwareUpdate where CI_ID = '$UpdCI'"
            $updateInfo = @(Get-WmiObject -ComputerName $SiteProviderServerName -Namespace root\sms\site_$($SiteCode) -Query $UpdateQuery)   
            $UpdateDate = [System.Management.ManagementDateTimeConverter]::ToDateTime($updateInfo.DatePosted)    
            if ($UpdateDate -lt $AgeThresholdfunc){
                $targetPkg = "Sustainer"
            }
            else{
                $targetPkg = "Monthly"
            }
                Write-Host "        $targetPkg | $($updateInfo.ArticleID) | $($updateInfo.LocalizedDisplayName)"
                Write-Log          "$targetPkg | $($updateInfo.ArticleID) | $($updateInfo.LocalizedDisplayName)" -itabs 5
        }
    }
}
}
#endregion
# --------------------------------------------------------------------------------------------

# --------------------------------------------------------------------------------------------
#region VARIABLES

# Standard Variables
    # *****  Change Logging Path and File Name Here  *****    
    $sOutFileName	= "SUP-Maintenance.log" # Log File Name    
    # ****************************************************
    $sScriptName 	= $MyInvocation.MyCommand
    $sScriptPath 	= Split-Path -Parent $MyInvocation.MyCommand.Path
    $sLogRoot		= Get-ChildItem -Path HKLM:\SOFTWARE\Microsoft\SMS\Tracing\
    $sLogRoot       = $sLogRoot[0].GetValue('Tracefilename')
    $sLogRoot       = $sLogRoot.Substring(0,$SLogRoot.LastIndexOf('\')+1)    
    $sOutFilePath   = $sLogRoot
    $sLogFile		= Join-Path -Path $SLogRoot -ChildPath $sOutFileName
    $global:iExitCode = 0
    $sUserName		= $env:username
    $sUserDomain	= $env:userdomain
    $sMachineName	= $env:computername
    $sCMDArgs		= $MyInvocation.Line
    $bAllow64bitRelaunch = $true
    $iLogFileSize 	= 1048576
    # Script Specific Variables
    $timeMonthSuperseded = 35 # Defines how long a Monthly SUG will have its superseded KBs preserved.
    $timeSustainerAge = 365 # Defines how long a Monthly SUG will retain valid KBs before having them migrated into a Sustainer deployment
    switch ($SCCMScope){
        #IF CAS
        "CAS"{
            $SMSProvider = "dalcfg01.na.xom.com"            
            $SCCMSite = "CAS"            
            $SUGTemplateName = "WKS-SecurityUpdates-"               
            $PKGTemplateName = "WKS-SecurityUpdates-"               
        }
        #IF CS2
        "CS2" {
            $SMSProvider = "dalcfg03.na.xom.com"
            $SCCMSite = "CS2"
            $SUGTemplateName = "WKS-SecurityUpdate-"
            $PKGTemplateName = "WKS-SecurityUpdate-"               
        }
        #IF S2M
        "S2M" {
            $SMSProvider = "x1xcfg01.inf-na.xomlab.com"
            $SCCMSite = "CAS"
            $SUGTemplateName = "WKS-SecurityUpdates-"
            $PKGTemplateName = "WKS-SecurityUpdates-"
        }        
        #IF VAR
        "VAR"{
            $SMSProvider = "sccm01.vlab.varandas.com"
            $SCCMSite = "VAR"
            $SUGTemplateName = "VAR-"
            $PKGTemplateName = "VAR-"               
        }
        #IF VARLAB
        "VARLAB"{
            $SMSProvider = "sccm01"
            $SCCMSite = "VAR"
            $SUGTemplateName = "VARLAB-TestSUP-"
            $PKGTemplateName = "VARLAB-TestSUP-"               
        }
        #IF PVA
        "PVA"{
            $SMSProvider = "sccm01.plab.varandas.com"
            $SCCMSite = "PVA"
            $SUGTemplateName = "VAR-"
            $PKGTemplateName = "VAR-"               
        }
        #IF PVALAB
        "PVALAB"{
            $SMSProvider = "sccm01.plab.varandas.com"
            $SCCMSite = "PVA"
            $SUGTemplateName = "VARLAB-"
            $PKGTemplateName = "VARLAB-"               
        }
        default{
            $SMSProvider,$SCCMSite,$SUGTemplateName,$PKGTemplateName = $null
        }
    }      
#endregion 
# --------------------------------------------------------------------------------------------

# --------------------------------------------------------------------------------------------
#region MAIN_SUB

Function MainSub{
# ===============================================================================================================================================================================
#region 1_PRE-CHECKS            
    Write-Log -iTabs 1 "Starting 1 - Pre-Checks." -bConsole $true -scolor Cyan
    #region 1.0 Checking/Loading SCCM Powershell Module                
        Write-Log -iTabs 2 "1.0 Checking/Loading SCCM Powershell module from $($Env:SMS_ADMIN_UI_PATH.Substring(0,$Env:SMS_ADMIN_UI_PATH.Length-5) + '\ConfigurationManager.psd1')" -bConsole $true -scolor Cyan
        if (Get-Module | Where-Object {$_.Name -like "*ConfigurationManager*"}){            
            Write-Log -iTabs 3 "SCCM PS Module was found loaded in this session!" -bConsole $true -scolor Green
        }
        else{            
            Write-Log -iTabs 3 "SCCM PS Module was not found in this session! Loading Module. This might take a few minutes..."
            Try{                            
                Write-Log  -iTabs 4 "Looking for Module in $(($Env:SMS_ADMIN_UI_PATH.Substring(0,$Env:SMS_ADMIN_UI_PATH.Length-5) + '\ConfigurationManager.psd1'))" -bConsole $true
                Import-module ($Env:SMS_ADMIN_UI_PATH.Substring(0,$Env:SMS_ADMIN_UI_PATH.Length-5) + '\ConfigurationManager.psd1')                
                Write-Log  -iTabs 4 "Successfully loaded SCCM Powershell module"  -bConsole $true -scolor Green
            }
            catch{                
                Write-Log -iTabs 4 "Unable to Load SCCM Powershell module." -bConsole $true -scolor Red                
                Write-Log -iTabs 4 "Aborting script." -iTabs 4 -bConsole $true -scolor Red
                $global:iExitCode = 9001
                return $global:iExitCode
            }                      
        }
    #endregion
    #region 1.1 Confirm Script Arguments            
        Write-Log -iTabs 2 "1.1 Checking Script arguments" -bConsole $TRUE -sColor Cyan
        Write-Log -iTabs 3 "Script is running with Command Line: $sCMDArgs" -bConsole $true -bTxtLog $false
        if ($SCCMSite -eq $null){
            if ($Action -eq "Auto-Run"){                
                Write-Log -itabs 3 "Action 'Auto-Run' is not supported with SCCMScope 'Other'." -bConsole $true
                HowTo-Script                
                Write-Log -itabs 4 "Aborting script." -bConsole $true -sColor red
                $global:iExitCode = 9011
                return $global:iExitCode
            }            
            Write-Log -iTabs 3 "SCCMScope 'Other' requires data to be collected from User." -bConsole $true
            #Setting SMS Provider
            if ($SMSProvider -eq $null){                                
                $smsProvTest = $false
                do{
                    $SMSProvider = Read-Host "                                      SMS Provider [<ServerFQDN>/Abort] "                    
                    if ($SMSProvider -eq "Abort"){                        
                        Write-Log -iTabs 5 "Aborting script." -bConsole $true -sColor red
                        $global:iExitCode = 8001
                        return $global:iExitCode
                    }
                    Write-Log -iTabs 5 "User set '$SMSProvider' as SMSProvider"
                    Write-Log -iTabs 5 "Testing '$SMSProvider' connection..." -bConsole $true
                    if (Test-Connection -ComputerName $SMSProvider -Count 1 -Quiet){
                        Write-Log -iTabs 5 "$SMSProvider was found and set as SMSProvider" -bConsole $true -sColor green                        
                        $smsProvTest = $true
                    }
                    else{
                        Write-Log -iTabs 5 "Unable to reach $SMSProvider. Ensure server FQDN is valid" -bConsole $true -sColor red                                                
                        $smsProvTest = $false
                    }                
                }while(!$smsProvTest)                
            }  
            #Setting SCCM Site        
            if ($SCCMSite -eq $null){
                $sccmSiteTest = $false
                do{
                    $SCCMSite = Read-Host "                                      SCCM Site [<SITECODE>/Abort] "
                    if ($SCCMSite -eq "Abort"){
                        Write-Log -iTabs 5 "Aborting script." -bConsole $true -sColor red
                        $global:iExitCode = 8001
                        return $global:iExitCode
                    }
                    Write-Log -iTabs 5 "User set '$SCCMSite' as SCCM Site..."
                    Write-Log -iTabs 5 "Testing '$SCCMSite' as SCCM Site..." -bConsole $true
                    try{
                        $qrySccmSite = $(get-WMIObject -ComputerName $SMSProvider -Namespace "root\SMS" -Class "SMS_ProviderLocation" | Where {$_.ProviderForLocalSite -eq "True"} | Select Sitecode).Sitecode
                    }
                    catch{
                        Write-Log -iTabs 5 "Unable to reach $SMSProvider SiteCode via WMI. Ensure user permissions are present for this operation." -bConsole $true -sColor red
                        $sccmSiteTest=$false
                    }
                    if ($qrySccmSite -eq $SCCMSite){
                        Write-Log -iTabs 5 "SCCM Site $SCCMSite found in $SMSProvider. Setting as SCCM Site Code" -bConsole $true -sColor green                        
                        $sccmSiteTest=$true
                    }
                    else{
                        Write-Log -iTabs 5 "SCCM Site $SCCMSite not found in $SMSProvider. Verify Site is valid" -bConsole $true -sColor red                        
                        $sccmSiteTest=$false
                    }                
                }while(!$sccmSiteTest)                  
            }
            # Testing SCCM Drive
            try{
                cd $SCCMSite":"            
            }
            catch{
                Write-Log -iTabs 4 "Unable to connect to SCCM PSDrive. Aborting Script" -bConsole $true -sColor red
                Write-Log -iTabs 5 "Aborting script." -bConsole $true -sColor red
                $global:iExitCode = 9005            
                return $global:iExitCode
            }
            #Setting SUG Template Name
            if ($SUGTemplateName -eq $null){
                $sugTest = $false
                do{
                    $SUGTemplateName = Read-Host "                                      SUG Template Name [<SUGName>/Abort] "
                    if ($SUGTemplateName -eq "Abort"){
                        Write-Log -iTabs 5 "Aborting script." -bConsole $true -sColor red
                        $global:iExitCode = 8001
                        return $global:iExitCode
                    }       
                    else{       
                        Write-Log -iTabs 5 "SUG Template Name was set as '$SUGTemplateName'" -bConsole $true
                        $answer = Read-Host "                                          Do you confirm? [Y/n] "                
                        if ($answer -eq "Y"){
                            Write-Log -iTabs 6 "User confirmed SUG Template Name"
                            $sugTest=$true
                        }
                        else{
                            Write-Log -iTabs 6 "User cleared SUG Template Name"
                        }
                    }      
                }while(!$sugTest)                            
            }
            #Setting PKG Template Name
            if ($PKGTemplateName -eq $null){
                $pkgTest = $false
                do{
                    $PKGTemplateName = Read-Host "                                      Package Template Name [<PKGName>/Abort] "
                    if ($PKGTemplateName -eq "Abort"){
                        Write-Log -iTabs 5 "Aborting script." -bConsole $true -sColor red
                        $global:iExitCode = 8001
                        return $global:iExitCode
                    }    
                    else{       
                        Write-Log -iTabs 5 "Package Template Name was set as '$PKGTemplateName'" -bConsole $true                        
                        $answer = Read-Host "                                          Do you confirm? [Y/n] "                
                        if ($answer -eq "Y"){
                            Write-Log -iTabs 6 "User confirmed Package Template Name"
                            $pkgTest=$true
                        }
                        else{
                            Write-Log -iTabs 6 "User cleared Package Template Name"
                        }
                    }                     
                }while(!$pkgTest)                            
            }
        }                
        #Confirming Settings                              
        Write-Log -iTabs 3 "Setings were defined as:" -bConsole $true        
        Write-Log -iTabs 4 "SCCM Scope: $SCCMScope" -bConsole $true -sColor Yellow        
        Write-Log -iTabs 4 "SMSProvider: $SMSProvider" -bConsole $true                
        Write-Log -iTabs 4 "SCCM Site Code: $SCCMSite" -bConsole $true         
        Write-Log -iTabs 4 "SUG Name Template: $SUGTemplateName" -bConsole $true
        Write-Log -iTabs 4 "PKG Name Template: $PKGTemplateName" -bConsole $true
    #endregion  
    #region 1.2 Is this SCCM Admin User?            
        Write-Log -iTabs 2 "1.2 Checking if user has permissions in SCCM to run this script..." -bConsole $true -sColor Cyan
        $userRoleTest = $false
        <#    
        $userRoles = (Get-CMAdministrativeUser -Name $($sUserDomain+"\"+$sUserName)).RoleNames
        foreach ($role in $userRoles){
            If (($role -eq "Full Administrator") -or ($role -eq "Software Update Manager")){
                $userRoleTest = $true
            }
        }
        if ($userRoleTest){
            Write-Host  "        User has permissions to execute this script." -ForegroundColor Green            
            Write-Log           "User has permissions to execute this script." -iTabs 3
        }
        else{
            Write-Host "        User does not have permissions to execute this script." -ForegroundColor Red
            Write-Log          "User does not have permissions to execute this script." -iTabs 3
            Write-Host "        Aborting script." -ForegroundColor Red
            Write-Log          "Aborting script." -iTabs 3
            $global:iExitCode = 9002
            return $global:iExitCode
        }    
        #>            
        Write-Log  -iTabs 3 "Pre-Check to be implemented" -bConsole $true
    #endregion    
    #region 1.3 Querying Software Update Information        
        Write-Log -iTabs 2 "1.3 Getting SUP Information" -bConsole $true -sColor Cyan
            #region Checking ADR                
                Write-Log -iTabs 3 "Checking if Default ADR is present." -bConsole $true
                try{
                    $defaultAdr = Get-CMAutoDeploymentRule -fast -Name "$($SUGTemplateName)ADR"
                    if ($defaultAdr.Count -gt 0){                        
                        Write-Log -iTabs 4 "Default ADR ($($SUGTemplateName)ADR) was found in SCCM Environment." -bConsole $true -sColor Green
                    }
                    else{                        
                        Write-Log -iTabs 4 "Default ADR ($($SUGTemplateName)ADR) was not found in SCCM Environment." -bConsole $true -sColor red
                        Write-Log -iTabs 4 "For the sake of management, is strongly recomended to have an ADR responsible for creating Monhtly updates." -bConsole $true -sColor red
                    }
                }
                catch{                    
                    Write-Log -iTabs 4 "Unable to verify existing ADRs. Permission Error. Ensure script is running with SCCM Full Admin permissionts and access to SCCM WMI Provider." -bConsole $true -sColor red                    
                    Write-Log -iTabs 4 "Aborting script." -bConsole $true -sColor red
                    $global:iExitCode = 9012
                    return $global:iExitCode
                }
            #endregion
            #region Checking Basic SUGs (Report and Sustainer)                
                Write-Log -iTabs 3 "Checking if required SUGs are present." -bConsole $true
                    #Gettings SUG Info         
                    try{
                        $sugs = Get-CMSoftwareUpdateGroup | Where {$_.LocalizedDisplayName -like "$SUGTemplateName*"} | ConvertTo-Array                       
                        $sugRpt = $sugs | Where {$_.LocalizedDisplayName -eq $SUGTemplateName+"Report"}
                        $sugSustainer = $sugs | Where {$_.LocalizedDisplayName -eq $SUGTemplateName+"Sustainer"}                        
                    }
                    #Error while getting SUG Info
                    catch{                                                                        
                        Write-Log -iTabs 4 "Unable to query Software Update Groups. Permission Error. Ensure script is running with SCCM Full Admin permissionts and access to SCCM WMI Provider." -bConsole $true -sColor red                        
                        Write-Log -iTabs 4 "Aborting script." -bConsole $true -sColor red
                        $global:iExitCode = 9013
                        return $global:iExitCode
                    }
                    #RptSUG was found
                    if ($sugRpt.Count -gt 0){                        
                        Write-Log -iTabs 4 "$($SUGTemplateName)Report was found." -bConsole $true -sColor Green
                    }
                    #Rpt was not found
                    else{                        
                        Write-Log -iTabs 4 "$($SUGTemplateName)Report wasn't found. This SUG is required to proceed with script execution." -bConsole $true -sColor Red
                        do{
                            $answer = Read-Host "                                      Do you want to create Software Update Group '$($SUGTemplateName)Report'?  [Y/n] "                
                        } while (($answer -ne "Y") -and ($answer -ne "n"))
                        #aborting script
                        if ($answer -eq "n"){                
                            Write-Log -iTabs 5 "User don't want to create Software Update Group '$($SUGTemplateName)Report' at this moment."
                            Write-Log -iTabs 5 "Aborting script." -bConsole $true -sColor red                            
                            $global:iExitCode = 8001
                            return $global:iExitCode
                        }   
                        # Creating RptSUG
                        if ($answer -eq "y"){                                            
                            Write-Log -iTabs 4 "Creating $($SUGTemplateName)Report..." -bConsole $true
                            try{
                                New-CMSoftwareUpdateGroup -Name "$($SUGTemplateName)Report" | Out-Null                                
                                Write-Log -iTabs 5 "$($SUGTemplateName)Report was created" -bConsole $true -sColor green                                
                                Write-Log -iTabs 5 "Reloading SUG Array." -bConsole $true 
                                $sugs = Get-CMSoftwareUpdateGroup | Where {$_.LocalizedDisplayName -like "$SUGTemplateName*"} | ConvertTo-Array                       
                            }    
                            catch{                                
                                Write-Log -itabs 5 "Error while creating $($SUGTemplateName)Report. Ensure script is running with SCCM Full Admin permissions and access to SCCM WMI Provider." -bConsole $TRUE -sColor red
                                Write-Log -iTabs 5 "Aborting script." -bConsole $true -sColor red                            
                                $global:iExitCode = 9014
                                return $global:iExitCode                            
                            }
                        }                      
                    }
                    if ($sugSustainer.Count -gt 0){                        
                        Write-Log -iTabs 4 "$($SUGTemplateName)Sustainer was found." -bConsole $true -sColor Green
                    }
                    #Sustainer was not found
                    else{
                        Write-Log -iTabs 4 "$($SUGTemplateName)Sustainer wasn't found. This SUG is required to proceed with script execution." -bConsole $true -sColor red
                        do{
                            $answer = Read-Host "                                      Do you want to create Software Update Group '$($SUGTemplateName)Sustainer'? [Y/n] "                
                        } while (($answer -ne "Y") -and ($answer -ne "n"))
                        #aborting script
                        if ($answer -eq "n"){                
                            Write-Log -iTabs 5 "User don't want to create Software Update Group $($SUGTemplateName)Sustainer at this moment" 
                            Write-Log -iTabs 5 "Aborting script." -bConsole $true -sColor red
                            $global:iExitCode = 8001
                            return $global:iExitCode
                        }   
                        # Creating RptSUG
                        if ($answer -eq "y"){                                            
                            Write-Log -iTabs 4 "Creating $($SUGTemplateName)Sustainer..." -bConsole $true
                            try{
                                New-CMSoftwareUpdateGroup -Name "$($SUGTemplateName)Sustainer" | Out-Null                                
                                Write-Log -iTabs 4 "$($SUGTemplateName)Sustainer was created" -bConsole $true -sColor green                                
                                Write-Log -iTabs 5 "Reloading SUG Array." -bConsole $true
                                $sugs = Get-CMSoftwareUpdateGroup | Where {$_.LocalizedDisplayName -like "$SUGTemplateName*"} | ConvertTo-Array                       
                            }    
                            catch{                                
                                Write-Log -iTabs 4 "Error while creating $($SUGTemplateName)Sustainer. Ensure script is running with SCCM Full Admin permissionts and access to SCCM WMI Provider." -bConsole $true -sColor red
                                Write-Log -iTabs 4 "Aborting script." -bConsole $true -sColor red
                                $global:iExitCode = 9015
                                return $global:iExitCode                            
                            }
                        } 
                    }
            #endregion
            #region Checking Basic Packages (Monthly and Sustainer)                
                Write-Log -iTabs 3 "Checking if required Deployment Packages are present." -bConsole $true
                    #Getting Deployment Package Info 
                    try{
                        $pkgs = Get-CMSoftwareUpdateDeploymentPackage | Where {$_.Name -like "$PKGTemplateName*"} | ConvertTo-Array
                        $pkgMonth     = $pkgs | Where {$_.Name -eq "$($PKGTemplateName)Monthly"}
                        $pkgSustainer = $pkgs | Where {$_.Name -eq "$($PKGTemplateName)Sustainer"}   
                    }
                    #Error while getting Deployment Package Info
                    catch{                        
                        Write-Log -iTabs 4 "Unable to query Deployment Packages. Permission Error. Ensure script is running with SCCM Full Admin permissionts and access to SCCM WMI Provider." -bConsole $true -sColor red                        
                        Write-Log -iTabs 4 "Aborting script."  -bConsole $true -sColor red
                        $global:iExitCode = 9014
                        return $global:iExitCode
                    }
                    #Monthly Deployment Package was found
                    if ($pkgMonth.Count -gt 0){                        
                        Write-Log -iTabs 4 "$($PKGTemplateName)Monthly was found." -bConsole $true -sColor green
                    }
                    #Monthly Deployment Package was not found
                    else{                        
                        Write-Log -iTabs 4 "$($PKGTemplateName)Monthly was not found. This Package is Required to proceed with script execution." -bConsole $true -sColor red
                        do{
                            $answer = Read-Host "                                      Do you want to create Deployment Package '$($PKGTemplateName)Monthly'? [Y/n] "                
                        } while (($answer -ne "Y") -and ($answer -ne "n"))
                        #aborting script
                        if ($answer -eq "n"){                                            
                            Write-Log -iTabs 5 "User don't want to create $($PKGTemplateName)Monthly at this moment." -bConsole $true -sColor red
                            Write-Log -iTabs 5 "Aborting script."  -bConsole $true -sColor red
                            $global:iExitCode = 8001
                            return $global:iExitCode
                        }   
                        # Creating Monthly PKG
                        if ($answer -eq "y"){
                            $pathTest=$false
                            do{
                                Write-Log -iTabs 0 -bTxtLog $false -bConsole $true
                                Write-Log -iTabs 4 "Collecting Network Share path from user"
                                Write-Log -iTabs 4 "Enter a valid Network Share Path to store Updates" -bTxtLog $false -bConsole $true
                                Write-Log -iTabs 4 "Both SCCM Server Account and your ID must have Read/Write access to target location" -bTxtLog $false -bConsole $true
                                $sharePath = Read-Host "                                      Network Share Path (\\<SERVERNAME>\PATH or Abort) "                
                                Write-Log -iTabs 4 "Network Share: $sharePath"                                                               
                                Write-Log -iTabs 5 "Testing Network Share..." -bConsole $true                              
                                $pathTest = Test-Path $("filesystem::$sharePath") 
                                if (!($pathTest)){
                                    Write-Log -iTabs 5 "Network Share Invalid!" -bConsole $true -sColor red
                                }
                                else{
                                    Write-Log -iTabs 5 "Network Share Valid!" -bConsole $true -sColor green
                                }
                            } while (($sharePath -ne "Abort") -and (!($pathTest)))                                      
                            Write-Log -iTabs 4 "Creating $($PKGTemplateName)Monthly..." -bConsole $true
                            try{
                                New-CMSoftwareUpdateDeploymentPackage -Name "$($PKGTemplateName)Monthly" -Path "$sharePath" -Priority High | Out-Null                                
                                Write-Log -iTabs 4 "$($PKGTemplateName)Monthly was created" -bConsole $true -sColor Green                                
                                Write-Log -iTabs 4 "Updating Package Array" -bConsole $true
                                $pkgs = Get-CMSoftwareUpdateDeploymentPackage | Where {$_.Name -like "$PKGTemplateName*"} | ConvertTo-Array
                            }    
                            catch{                                
                                Write-Log -iTabs 4 "Error while creating $($PKGTemplateName)Monthly. Ensure script is running with SCCM Full Admin permissionts and access to SCCM WMI Provider." -bConsole $true -sColor red                                
                                Write-Log -iTabs 4 "Aborting script." -bConsole $true -sColor red
                                $global:iExitCode = 9014
                                return $global:iExitCode                            
                            }
                        }                      
                    }
                    #Sustainer Deployment Package was found
                    if ($pkgSustainer.Count -gt 0){                        
                        Write-Log -iTabs 4 "$($PKGTemplateName)Sustainer was found." -bConsole $true -sColor green
                    }
                    #Monthly Deployment Package was not found
                    else{                        
                        Write-Log -iTabs 4 "$($PKGTemplateName)Sustainer was not found. This Package is Required to proceed with script execution." -bConsole $true -sColor red
                        do{
                            $answer = Read-Host "                                      Do you want to create Deployment Package '$($PKGTemplateName)Sustainer'? [Y/n] "                
                        } while (($answer -ne "Y") -and ($answer -ne "n"))
                        #aborting script
                        if ($answer -eq "n"){                                            
                            Write-Log -iTabs 4 "Create $($PKGTemplateName)Sustainer before executing this script again." -bConsole $true -sColor red                            
                            Write-Log -iTabs 4 "Aborting script." -bConsole $true -sColor red
                            $global:iExitCode = 8001
                            return $global:iExitCode
                        }   
                        # Creating Sustainer PKG
                        if ($answer -eq "y"){
                            $pathTest=$false
                            do{
                                Write-Log -iTabs 0 -bTxtLog $false -bConsole $true
                                Write-Log -iTabs 4 "Collecting Network Share path from user"
                                Write-Log -iTabs 4 "Enter a valid Network Share Path to store Updates" -bTxtLog $false -bConsole $true
                                Write-Log -iTabs 4 "Both SCCM Server Account and your ID must have Read/Write access to target location" -bTxtLog $false -bConsole $true
                                $sharePath = Read-Host "                                      Network Share Path (\\<SERVERNAME>\PATH or Abort) "                
                                Write-Log -iTabs 4 "Network Share: $sharePath"                                                               
                                Write-Log -iTabs 5 "Testing Network Share..." -bConsole $true                              
                                $pathTest = Test-Path $("filesystem::$sharePath") 
                                if (!($pathTest)){
                                    Write-Log -iTabs 5 "Network Share Invalid!" -bConsole $true -sColor red
                                }
                                else{
                                    Write-Log -iTabs 5 "Network Share Valid!" -bConsole $true -sColor green
                                }
                            } while (($sharePath -ne "Abort") -and (!($pathTest)))                                                                      
                            Write-Log -iTabs 4 "Creating $($PKGTemplateName)Sustainer..." -bConsole $true
                            try{
                                New-CMSoftwareUpdateDeploymentPackage -Name "$($PKGTemplateName)Sustainer" -Path $sharePath -Priority High | Out-Null                                
                                Write-Log -iTabs 4 "$($PKGTemplateName)Sustainer was created" -bConsole $true -sColor green
                                Write-Log -iTabs 4 "Updating Package Array" -bConsole $true
                                $pkgs = Get-CMSoftwareUpdateDeploymentPackage | Where {$_.Name -like "$PKGTemplateName*"} | ConvertTo-Array
                            }    
                            catch{                                
                                Write-Log -iTabs 4 "Error while creating $($PKGTemplateName)Sustainer. Ensure script is running with SCCM Full Admin permissionts and access to SCCM WMI Provider." -bConsole $true -sColor red                                
                                Write-Log -iTabs 4 "Aborting script." -bConsole $true -sColor red
                                $global:iExitCode = 9014
                                return $global:iExitCode                            
                            }
                        }                      
                    }                    
            #endregion    
    #endregion    
    #region 1.5 Finalizing Pre-Checks      
    Write-Log -iTabs 2 "1.4 - Finalizing Pre-Checks:" -bConsole $true -sColor cyan    
    Write-Log -itabs 3 "SUG Information - These SUGs will be evaluated/changed by this script." -bConsole $true
    #$sugs | ft
    foreach ($sug in $sugs){
        $sugName = $sug.LocalizedDisplayName
        Write-Log -itabs 4 $sugName -bConsole $true
    }    
    Write-Log -itabs 3 "Package Information - These PKGs will be evaluated/changed by this script." -bConsole $true
    foreach ($pkg in $pkgs){
        $pkgName = $pkg.PackageID+" - "+$pkg.Name
        Write-Log -itabs 4 $pkgName -bConsole $true
    }    
    $initNumUpdates = ($sugs | Measure-Object -Property NumberofUpdates -Sum).Sum
    Write-Log -itabs 3 "Total Number of Updates: $initNumUpdates" -bConsole $true -sColor yellow
    $initNumSugs = $sugs.Count
    Write-Log -itabs 3 "Total Number of SUGs: $initNumSugs" -bConsole $true -sColor yellow
    $initPkgSize = ($pkgs | Measure-Object -Property PackageSize -Sum).Sum
    Write-Log -itabs 3 "Total Space used by Packages: $initPkgSize" -bConsole $true -sColor yellow
    Write-Log -itabs 2 "Pre-Checks are complete. Script will make environment changes in the next interaction." -bConsole $true
    Write-Log -itabs 2 "Getting User confirmation to proceed"
    do{
        Write-Log -iTabs 3 "Above you have the list of Packages and Software Update Groups which will be managed by this script." -bConsole $true
        Write-Log -iTabs 3 "Review the list above and make sureare indeed the right targets for actions." -bConsole $true
        Write-Log -iTabs 3 "Script will make environment changes in the next interaction" -ForegroundColor Yellow
        $answer = Read-Host "                                  Do you want to proceed? [Y/n]"
        Write-Host
    } while (($answer -ne "Y") -and ($answer -ne "n"))
    if ($answer -eq "n"){
        Write-Log -iTabs 3 "User Aborting script." -bConsole $true -sColor red
        $global:iExitCode = 8001
        return $global:iExitCode
    }
    else{
        Write-Log -iTabs 2 "User confirmation received." 
    }
    #endregion
    Write-Log -iTabs 1 "Completed 1 - Pre-Checks." -bConsole $true -sColor Cyan
    
    Write-Log -iTabs 0 -bConsole $true
#endregion
# ===============================================================================================================================================================================

# ===============================================================================================================================================================================
#region 2_EXECUTION
    Write-Log -sMessage "Starting 2 - Execution." -iTabs 1  
    Write-Host          "Starting 2 - Execution." -ForegroundColor Cyan -BackgroundColor Black            
    #region 2.1 Review all Monthly SUGs, removing Expired or Superseded KBs. KBs older than 1 year will be moved to Sustainer.
        Write-Host "2.1 - Review all Monthly SUGs, removing Expired or Superseded KBs. KBs older than 1 year will be moved to Sustainer" -ForegroundColor Cyan
        Write-Log  "2.1 - Review all Monthly SUGs, removing Expired or Superseded KBs. KBs older than 1 year will be moved to Sustainer" -iTabs 2
        Write-Host
        $sugInfo = Get-cmsoftwareupdategroup | Where {$_.LocalizedDisplayName -like "$SUGTemplateName*" -and $_.LocalizedDisplayName -ne $SUGTemplateName+'Report' -and $_.LocalizedDisplayName -ne $SUGTemplateName+'Sustainer'}                 
                          
        $timeMonthSuperseded=$(Get-Date).AddDays(-$timeMonthSuperseded)
        $tSustainerAge=$(Get-Date).AddDays(-$timeSustainerAge)
        $sugCount=1
        foreach ($sug in $suginfo){        
            Write-Host "    ($sugCount of $($suginfo.Count)) Evaluating SUG: $($sug.LocalizedDisplayName)."
            Write-Log      "($sugCount of $($suginfo.Count)) Evaluating SUG: $($sug.LocalizedDisplayName)." -iTabs 3
            #Skip if Report SUG
            if ($sug.LocalizedDisplayName -eq $($SUGTemplateName+"Report")){
                Write-Host "    Skipping Report SUG at this moment. No Action will be taken."
                Write-Log      "Skipping Report SUG at this moment. No Action will be taken." -iTabs 3
            }
            #Skip if Sustainer SUG
            elseif (($sug.LocalizedDisplayName -eq $($SUGTemplateName+"Sustainer"))){
                Write-Host "    Skipping Sustainer SUG at this moment. No Action will be taken."
                Write-Log      "Skipping Sustainer SUG at this moment. No Action will be taken." -iTabs 3
            }
            #if SUG is new ( less than 35 days) remove Expired and Superseded KBs Only
            elseif ($sug.DateCreated -gt $timeMonthSuperseded){                
                Write-Host "    New SUG - Removing Expired KBs."
                Write-Log      "New SUG - Removing Expired KBs." -iTabs 3
                UpdateGroupPairMaintenance -SiteProviderServerName $SMSProvider -SiteCode $SCCMSite -CurrentUpdateGroup $sug.LocalizedDisplayName -PersistentUpdateGroup $($SUGTemplateName+"Sustainer") -HandleAgedUpdates $false -NumberofDaystoKeep $timeSustainerAge -PurgeExpired $true -PurgeSuperseded $false
            }
            #if SUG is stable (DateCreate is lesser than Today-35 days and greater than Today-365 days) remove Expired and Superseded KBs Only. Delete Deployments to small DGs
            elseif ($sug.DateCreated -gt $tSustainerAge){                
                Write-Host "    Removing Expired and Superseeded KBs. Deployments to initial DGs will be deleted."
                Write-Log      "Removing Expired and Superseeded KBs. Deployments to initial DGs will be deleted." -iTabs 3
                UpdateGroupPairMaintenance -SiteProviderServerName $SMSProvider -SiteCode $SCCMSite -CurrentUpdateGroup $sug.LocalizedDisplayName -PersistentUpdateGroup $($SUGTemplateName+"Sustainer") -HandleAgedUpdates $false -NumberofDaystoKeep $timeSustainerAge -PurgeExpired $true -PurgeSuperseded $true
            }
            #if SUG is old (DateCreate is lesser than Today-365 days) remove Expired and Superseded KBs Only. Move valid KBs to Sustainer and Delete SUG
            elseif ($sug.DateCreated -lt $tSustainerAge){                
                Write-Host "    Removing Expired, Superseeded and Aged KBs. Aged KBs will be moved into Sustainer SUG. Deployments to initial DGs will be deleted."
                Write-Log      "Removing Expired KBs and Superseeded KBs, Moving year-old Valid KBs into Sustainer SUG. Deployments to initial DGs will be deleted." -iTabs 3
                UpdateGroupPairMaintenance -SiteProviderServerName $SMSProvider -SiteCode $SCCMSite -CurrentUpdateGroup $sug.LocalizedDisplayName -PersistentUpdateGroup $($SUGTemplateName+"Sustainer") -HandleAgedUpdates $true -NumberofDaystoKeep $timeSustainerAge -PurgeExpired $true -PurgeSuperseded $true
            }            
            $sugcount++
        }
        Write-Host
    #endregion
    #region 2.2 Review Sustainer SUG, removing Expired or Superseded KBs.
        Write-Host "Execution 2.2 - Review Sustainer SUG, removing Expired or Superseded KBs." -ForegroundColor Cyan
        Write-Log  "2.2 - Review Sustainer SUG, removing Expired or Superseded KBs." -iTabs 2
        Write-Host
        try{
            SingleUpdateGroupMaintenance -SiteProviderServerName $SMSProvider -SiteCode $SCCMSite -ManagedUpdateGroup $($($SUGTemplateName)+"Sustainer") -PurgeSuperseded $true -PurgeExpired $true -HandleAgedUpdates $false
        }
        catch {
            Write-Host "    Error while processing Sustainer Eval. Aborting script."
            Write-Log      "Error while processing Sustainer Eval. Aborting script." -iTabs 3
            $global:iExitCode = 9009
            return $global:iExitCode
        }
        write-host
    #endregion
    #region 2.3 Review Report SUG, removing Expired or Superseded KBs.
        Write-Host "Execution 2.3 - Review Report SUG, removing Expired or Superseded KBs." -ForegroundColor Cyan
        Write-Log  "2.3 - Review Report SUG, removing Expired or Superseded KBs." -iTabs 2
        Write-Host
        try{
            SingleUpdateGroupMaintenance -SiteProviderServerName $SMSProvider -SiteCode $SCCMSite -ManagedUpdateGroup $($($SUGTemplateName)+"Report") -PurgeSuperseded $true -PurgeExpired $true -HandleAgedUpdates $false
        }
        catch {
            Write-Host "    Error while processing Report SUG Eval. Aborting script."
            Write-Log      "Error while processing Report SUG Eval. Aborting script." -iTabs 3
            $global:iExitCode = 9010
            return $global:iExitCode
        }    
        write-host
    #endregion
    #region 2.4 Review all SUGs, and ensure all KBs are member of <SUG_NAME>-Report SUG.    
    Write-Host "Execution 2.4 - Review all SUGs, and ensure all deployed KBs are member of $($SUGTemplateName)Report SUG." -ForegroundColor Cyan
    Write-Log  "2.4 - Review all SUGs, and ensure all valid KBs are member of $($SUGTemplateName)Report SUG." -iTabs 2    
    write-host
    try{
        ReportingSoftwareUpdateGroupMaintenance -SiteServerName $SMSProvider -SiteCode $SCCMSite -ReportingUpdateGroup $($SUGTemplateName+"Report") -DeploySUGName $SUGTemplateName
    }    
    catch{
        Write-Host "    Error while processing Report SUG. Aborting script."
        Write-Log      "Error while processing Report SUG. Aborting script." -iTabs 3
        $global:iExitCode = 9006
        return $global:iExitCode
    }
    write-host
    #endregion    
    #region 2.5 Remove unused KBs from Packages (KBs not deployed) and Reports KBs deployed not in any package
    Write-Host "Execution 2.5 Remove unused KBs from Packages (KBs not deployed) and list KBs deployed not in any package" -ForegroundColor Cyan
    Write-Log  "2.5 Remove unused KBs from Packages (KBs not deployed) and list KBs deployed not in any package" -iTabs 2
    write-host
    try{
        MaintainSoftwareUpdateGroupDeploymentPackages -SiteProviderServerName $SMSProvider -SiteCode $SCCMSite -PkgName $PKGTemplateName -SugName $SUGTemplateName
    }
    catch{
        Write-Host "    Error while handling packages" -ForegroundColor Red
        Write-Log      "Error while handling packages" -iTabs 3
    }
    Write-Host
    #endregion    
    #region 2.6 EvaluateNumberofUpdatesinGroups checking if SUGs are over 900 KBs limit
    Write-Host "Execution 2.6 EvaluateNumberofUpdatesinGroups checking if SUGs are over 900 KBs limit" -ForegroundColor Cyan
    Write-Log  "2.6 EvaluateNumberofUpdatesinGroups checking if SUGs are over 900 KBs limit" -iTabs 2
    write-host
    try{
        EvaluateNumberOfUpdatesinGRoups -SiteServerName $SMSProvider -SiteCode $SCCMSite -SugName $SUGTemplateName
    }
    catch{
        Write-Host "    Error while evaliating SUGs" -ForegroundColor Red
        Write-Log      "Error while evaliating SUGs" -iTabs 3
    }
    Write-Host
    #endregion
    Write-Host          "Completed 2 - Execution." -ForegroundColor Cyan -BackgroundColor Black            
    Write-Log -sMessage "Completed 2 - Execution." -iTabs 1  
    Write-Log -sMessage "" -iTabs 1    
#endregion
# ===============================================================================================================================================================================
        
# ===============================================================================================================================================================================
#region 3_POST-CHECKS
# ===============================================================================================================================================================================
    Write-Log -sMessage "Starting 3 - Post-Checks." -iTabs 1   
    Write-Host          "Starting 3 - Post-Checks." -ForegroundColor Cyan -BackgroundColor Black            
    #get current number of sugs and number of KBs in them
    #get size of deployment packages
    #get number of updates in reporting group
    Write-Host          "Completed 3 - Post-Checks." -ForegroundColor Cyan -BackgroundColor Black            
    Write-Log -sMessage "Completed 3 - Post-Checks." -iTabs 1  
    Write-Log -sMessage "" -iTabs 1 
#endregion
# ===============================================================================================================================================================================

} #End of MainSub

#endregion
# --------------------------------------------------------------------------------------------

# --------------------------------------------------------------------------------------------
#region MAIN_PROCESSING

If($DebugLog) { $ErrorActionPreference = "Stop" }

# Prior to logging, determine if we are in the 32-bit scripting host on a 64-bit machine and need and want to re-launch
If(!($NoRelaunch) -and $bIs64bit -and ($PSHOME -match "SysWOW64") -and $bAllow64bitRelaunch) {
    Relaunch-In64
}
Else {
    # Starting the log
    Start-Log

    Try {
	    MainSub
        If($DebugLog) { pause }
    }
    Catch {
	    # Log a general exception error
	    Write-Log -sMessage "Error running script" -iTabs 0        
        if ($global:iExitCode -eq 0){
	        $global:iExitCode = 9999
        }                
    }
    # Stopping the log
    End-Log
}
# Quiting with exit code
Exit $global:iExitCode
#endregion
