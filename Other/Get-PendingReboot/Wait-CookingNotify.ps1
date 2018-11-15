param([switch]$NoRelaunch,[ValidateSet("Force","Notify")][string]$RebootBehaviour,[switch]$skipCBServicing,[switch]$skipWindowsUpdate,[switch]$skipCCMClientSDK,[switch]$skipPendComputerRename,[switch]$skipPendFileRenVal,[int]$TimeCycle=300)

$SCRIPT_TITLE = "Wait Cooking"
$SCRIPT_VERSION = "1.0"

#Set default behavior if an error occurs. this should be set to "SilentlyContinue" for deployment, but can be changed for testing.
$ErrorActionPreference 	= "SilentlyContinue"	# SilentlyContinue / Stop / Continue

# -Script Name: Wait-Cooking.ps1------------------------------------------------------
<# 
#
# Version: 1.0
#
# Based on PS Template Script Version: 1.0
#
# Author: Jose Varandas
#
# Owned By: WDS OS Engineering
#
# Purpose: Monitors Pending reboot switches and take action as needed
#
# Created:  11/3/2016
#
# Dependencies: Script must be run with administrative rights
#               
#
# Known Issues: None
#
# Arguments: 
#		-Debug - Enables debug logging in the script, and disables default 
#							On Error Resume Next statements
#       -TimeCycle [int]  - In seconds, determine loop time (Default 300).
#       -ForceReboot - Will automatically reboot if necessary
#       -NotifyReboot - Will inform need for reboot if necessary (Default ON)

Needs Reboot?.....: $($result.RebootPending)
                            CBServicing.......: $($result.CBServicing)
                            WindowsUpdate.....: $($result.WindowsUpdate)
                            CCMClientSDK......: $($result.CCMClientSDK)
                            PendComputerRename: $($result.PendComputerRename)
                            PendFileRenVal....: $($result.PendFileRename)
#
# Exit Codes:
#            0 - Script completed successfully
#            8001 - Information Only
#            9002 - Script Wrong usage
#            9004 - Script not runnign with $sRights
#            9005 - Machine is pending reboot
#			 9999 - Script completed unsuccessfully, throwing an unhandled error
# 
# Output: C:\XOM\Logs\System\Wait-Cooking\Wait-Cooking.log
#    
# Revision History: (Date, Author, Description)
#		(Date 2016-10-26
#			v1.0
#			Jose Varandas
#			TBD
#				
#				
# -------------------------------------------------------------------------------------------- 
#>


# --------------------------------------------------------------------------------------------
# Subroutines and Functions
# --------------------------------------------------------------------------------------------

# Sub Name: Check-Credentials-----------------------------------------------------------------	
# Sub Name: Check-Credentials
# Purpose: Check if script is running with necessary rights
# Param: $sRole
# Variables: $user
# --------------------------------------------------------------------------------------------
function Check-Credentials {
    param( [ValidateSet("AccountOperator","Administrator","BackupOperator","Guest","PowerUser","PrintOperator","Replicator","SystemOperator","User")][string]$sRole)
    $user = [Security.Principal.WindowsIdentity]::GetCurrent();
    IF((New-Object Security.Principal.WindowsPrincipal $user).IsInRole([Security.Principal.WindowsBuiltinRole]::$sRole)){
        return $true
    }
    ELSE{
        return $false
    }
}

# Sub Name: EventLogIt-----------------------------------------------------------------------	
# Sub Name: EventLogIt
# Purpose: Log information to machine's Event Viewer
# Variables: None
# --------------------------------------------------------------------------------------------

function EventLogIt {
    param( [string]$sMessage="", [int]$iEventID=0, [ValidateSet("Error","Information","Warning")][string]$sEventLogType,[string]$sSource=$sEventIDSource)
    New-EventLog -LogName Application -Source $sSource -ErrorAction SilentlyContinue
    Write-EventLog -LogName Application -Source $sSource -EntryType $sEventLogType -EventId $iEventID -Message $sMessage -ErrorAction SilentlyContinue
}

# --------------------------------------------------------------------------------------------	
# Sub Name: RelaunchIn64
# Purpose: To relaunch the script as a 64bit process
# Variables: None
# --------------------------------------------------------------------------------------------
Function RelaunchIn64{
    ShowDebug "Restarting script in 64-bit PowerShell"
    
    $xpath = (Join-Path -Path ($PSHOME -replace "syswow64", "sysnative") -ChildPath "powershell.exe")
    ShowDebug "PS Engine = $xpath"
    ShowDebug "Command = $xpath $sCMDArgs"

    $global:iExitCode = (Start-Process -FilePath $xpath -ArgumentList $sCMDArgs -Wait -PassThru -WindowStyle Hidden).ExitCode
    ShowDebug "Exit Code = $global:iExitCode"
    
} #End of RelaunchIn64 function

# --------------------------------------------------------------------------------------------
# Function GetOSArchitecture
# Purpose: Gets the OS Architecture version from WIM
# Parameters: None
# Returns: String with OSArchitecture
# --------------------------------------------------------------------------------------------
Function GetOSArchitecture(){
    $OSArchitecture = Get-WMIObject -class "Win32_OperatingSystem" -computername "."
	$OSArchitecture = $OSArchitecture.OSArchitecture.toString().toLower()
    return $OSArchitecture
} #End of GetOSArchitecture function

# --------------------------------------------------------------------------------------------
# Function Name: IsVirtualMachine
# Purpose: To identify if the machine is a virtual machine or not
# Variables: None
# Returns: Boolean value (True or False) of whether the machine is a virtual machine or not
# --------------------------------------------------------------------------------------------
Function IsVirtualMachine(){
	$bReturn = $false
	$sModel = Get-WMIObject -class "Win32_ComputerSystem" -computername "."
	$sModel = $sModel.Model.toString().toLower()
	If(($sModel.Contains("virtual machine")) -or ($sModel.Contains("vmware virtual platform")))
	{
		$bReturn = $true
	}
	return $bReturn
} #End of IsVirtualMachine function

# --------------------------------------------------------------------------------------------	
# Function Name: GetOSVersion
# Purpose: To get the OS Version via WMI
# Variables: None
# Returns: OS Version from WMI
# --------------------------------------------------------------------------------------------	
Function GetOSVersion(){
	$version = Get-WMIObject -class "Win32_OperatingSystem" -computername "."
	$version = $version.Version.toString().toLower()
	return $version
} #End of GetOSVersion function

# --------------------------------------------------------------------------------------------	
# Function Name: IsOnVPN
# Purpose: Checks to see if the machine is currently connected to VPN
# Variables: None
# Returns: Boolean (True or False) if the machine is connected to VPN
# --------------------------------------------------------------------------------------------
Function IsOnVPN(){
	$iRegData = 0
	$bReturn = $false
	$iRegData = (Get-ItemProperty -Path hklm:\SOFTWARE\ExxonMobil\GME).VPNConnected
	If($iRegData -eq 1) { $bReturn = $true }
	return $bReturn
} #End of IsOnVPN function

# --------------------------------------------------------------------------------------------
# Function StartLog
# Purpose: Checks to see if a log file exists and if not, created it
#          Also checks log file size
# Parameters:
# Returns: None
# --------------------------------------------------------------------------------------------
Function StartLog(){	
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

    LogIt $sHeader -iTabs 0  
	LogIt -sMessage "############################################################" -iTabs 0 
    LogIt -sMessage "" -iTabs 0 
    LogIt -sMessage "============================================================" -iTabs 0 	
    LogIt -sMessage "$SCRIPT_TITLE ($sScriptName) $SCRIPT_VERSION" -iTabs 0 
	LogIt -sMessage "============================================================" -iTabs 0 
	LogIt -sMessage "Script Started at $(Get-Date)" -iTabs 0 
	LogIt -sMessage "" -iTabs 0 

} #End of CheckLogFile function

# --------------------------------------------------------------------------------------------
# Function ShowDebug
# Purpose: Allows you to show debug information
# Parameters: 
#    sText - Text to display as debug
#    iTabs - number of tabs to indent the text
# Returns: none
# --------------------------------------------------------------------------------------------
Function ShowDebug(){
    param( [string]$sText="", [int]$iTabs=0 ) 
    
    if ($Debug -eq $true) {Write-Host  $sText}

} #End of ShowDebug function

# --------------------------------------------------------------------------------------------
# Function LogIt
# Purpose: Writes specified text to the log file
# Parameters: 
#    sMessage - Message to write to the log file
#    iTabs - Number of tabs to indent text
#    sFileName - name of the log file (optional. If not provied will default to the $sLogFile in the script
# Returns: None
# --------------------------------------------------------------------------------------------
Function LogIt(){
    param( [string]$sMessage="", [int]$iTabs=0, [string]$sFileName=$sLogFile )
    
    #Loop through tabs provided to see if text should be indented within file
    $sTabs = ""
    For ($a = 1; $a -le $iTabs; $a++) {
        $sTabs = $sTabs + "    "
    }

    #Populated content with tabs and message
    $sContent = $sTabs + $sMessage

    #Write contect to the file and if debug is on, to the console for troubleshooting
    Add-Content $sFileName -value  $sContent
    ShowDebug $sContent
	
} #End of LogIt function

# --------------------------------------------------------------------------------------------
# Function EndLog
# Purpose: Writes the last log information to the log file
# Parameters: None
# Returns: None
# --------------------------------------------------------------------------------------------
Function EndLog(){
    #Loop through tabs provided to see if text should be indented within file
	LogIt -sMessage "" -iTabs 0 
    LogIt -sMessage "Script Completed at $(Get-date) with Exit Code $global:iExitCode" -iTabs 0  
    LogIt -sMessage "============================================================" -iTabs 0     
    LogIt -sMessage "" -iTabs 0 
    EventLogit -sMessage "Script $sScriptName Completed at $(Get-date) with Exit Code $global:iExitCode" -iEventID 1010 -sEventLogType Information

} #End of EndLog function

# --------------------------------------------------------------------------------------------
# Function CreateRegistryKeys
# Purpose: Creates the registry key that is provided and 
#          loops through the entire key to make sure all
#          keys exist
# Parameters: sRegKey - Registry key to check for\create
# Returns: True = key exists or was created
# --------------------------------------------------------------------------------------------
Function CreateRegistryKeys(){
    param( [string]$sRegKey="HKLM:\" ) 
    
    $bReturn = $false
    #Clear any errors that may exist
    $error.Clear()
    #LogIt -sMessage "Checking for existance of $sRegKey..." -iTabs 0 
    
    #Check to see if the provided registry key exists
    If (!(Test-Path -Path $sRegKey))
    {
        #If key doesn't exist, get parent key and check to see if it exists and create if necessary
        $sParent = Split-Path $sRegKey
        #Check to see if the parent was a "null" value
        If ($sParent -ne $null)
        {
            $bReturn = CreateRegistryKeys -sRegKey $sParent
        }
        #after all parent keys have been processed, create key
        #Check to see if the function returned a success
        if ($bReturn)
        {
            New-Item -path $sRegKey
            ShowDebug "$sRegKey was created"
        }
        Else
        {
            LogIt -sMessage "Error Creating Key: $error[0]" -iTabs 1 
            Return $false
        }
    }
    Else
    {
        Return $true
    }
        
} #End of CreateRegistryKeys function

# --------------------------------------------------------------------------------------------
# Function Get-PendingReboot
# Purpose: This function will query the registry on a local and determine if the
#          system is pending a reboot, from Microsoft updates, Configuration Manager Client SDK, Pending Computer 
#           Rename, Component Based Servicing, Domain Join or Pending File Rename Operations. 	
#               CBServicing = Component Based Servicing (Windows 2008+)
#               WindowsUpdate = Windows Update / Auto Update (Windows 2003+)
#               CCMClientSDK = SCCM 2012 Clients only (DetermineIfRebootPending method) otherwise $null value
#               PendComputerRename = Detects either a computer rename or domain join operation (Windows 2003+)
#               PendFileRename = PendingFileRenameOperations (Windows 2003+)
#               PendFileRenVal = PendingFilerenameOperations registry value
# Parameters: N/A
# Returns: Custom Object
#               Computer = STRING
#               CBServicing = BOOLEAN
#               WindowsUpdate = BOOLEAN
#               CCMClientSDK = BOOLEAN
#               PendComputerRename = BOOLEAN
#               PendFileRename = BOOLEAN
#               PendFileRenVal = @(STRING)
#               RebootPending = BOOLEAN
# --------------------------------------------------------------------------------------------

Function Get-PendingReboot{
[CmdletBinding()]
param(
	[Parameter(Position=0,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
	[Alias("CN","Computer")]
	[String[]]$ComputerName="$env:COMPUTERNAME",
	[String]$ErrorLog
	)

Begin {  }## End Begin Script Block
Process {
  Foreach ($Computer in $ComputerName) {
	Try {
	    ## Setting pending values to false to cut down on the number of else statements
	    $CompPendRen,$PendFileRename,$Pending,$SCCM = $false,$false,$false,$false
                        
	    ## Setting CBSRebootPend to null since not all versions of Windows has this value
	    $CBSRebootPend = $null
						
	    ## Querying WMI for build version
	    $WMI_OS = Get-WmiObject -Class Win32_OperatingSystem -Property BuildNumber, CSName -ComputerName $Computer -ErrorAction Stop

	    ## Making registry connection to the local/remote computer
	    $HKLM = [UInt32] "0x80000002"
	    $WMI_Reg = [WMIClass] "\\$Computer\root\default:StdRegProv"
						
	    ## If Vista/2008 & Above query the CBS Reg Key
	    If ([Int32]$WMI_OS.BuildNumber -ge 6001) {
		    $RegSubKeysCBS = $WMI_Reg.EnumKey($HKLM,"SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\")
		    $CBSRebootPend = $RegSubKeysCBS.sNames -contains "RebootPending"		
	    }
							
	    ## Query WUAU from the registry
	    $RegWUAURebootReq = $WMI_Reg.EnumKey($HKLM,"SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\")
	    $WUAURebootReq = $RegWUAURebootReq.sNames -contains "RebootRequired"
						
	    ## Query PendingFileRenameOperations from the registry
	    $RegSubKeySM = $WMI_Reg.GetMultiStringValue($HKLM,"SYSTEM\CurrentControlSet\Control\Session Manager\","PendingFileRenameOperations")
	    $RegValuePFRO = $RegSubKeySM.sValue

	    ## Query JoinDomain key from the registry - These keys are present if pending a reboot from a domain join operation
	    $Netlogon = $WMI_Reg.EnumKey($HKLM,"SYSTEM\CurrentControlSet\Services\Netlogon").sNames
	    $PendDomJoin = ($Netlogon -contains 'JoinDomain') -or ($Netlogon -contains 'AvoidSpnSet')

	    ## Query ComputerName and ActiveComputerName from the registry
	    $ActCompNm = $WMI_Reg.GetStringValue($HKLM,"SYSTEM\CurrentControlSet\Control\ComputerName\ActiveComputerName\","ComputerName")            
	    $CompNm = $WMI_Reg.GetStringValue($HKLM,"SYSTEM\CurrentControlSet\Control\ComputerName\ComputerName\","ComputerName")

	    If (($ActCompNm -ne $CompNm) -or $PendDomJoin) {
	        $CompPendRen = $true
	    }
						
	    ## If PendingFileRenameOperations has a value set $RegValuePFRO variable to $true
	    If ($RegValuePFRO) {
		    $PendFileRename = $true
	    }

	    ## Determine SCCM 2012 Client Reboot Pending Status
	    ## To avoid nested 'if' statements and unneeded WMI calls to determine if the CCM_ClientUtilities class exist, setting EA = 0
	    $CCMClientSDK = $null
	    $CCMSplat = @{
	        NameSpace='ROOT\ccm\ClientSDK'
	        Class='CCM_ClientUtilities'
	        Name='DetermineIfRebootPending'
	        ComputerName=$Computer
	        ErrorAction='Stop'
	    }
	    ## Try CCMClientSDK
	    Try {
	        $CCMClientSDK = Invoke-WmiMethod @CCMSplat
	    } Catch [System.UnauthorizedAccessException] {
	        $CcmStatus = Get-Service -Name CcmExec -ComputerName $Computer -ErrorAction SilentlyContinue
	        If ($CcmStatus.Status -ne 'Running') {
	            Write-Warning "$Computer`: Error - CcmExec service is not running."
	            $CCMClientSDK = $null
	        }
	    } Catch {
	        $CCMClientSDK = $null
	    }

	    If ($CCMClientSDK) {
	        If ($CCMClientSDK.ReturnValue -ne 0) {
		        Write-Warning "Error: DetermineIfRebootPending returned error code $($CCMClientSDK.ReturnValue)"          
		    }
		    If ($CCMClientSDK.IsHardRebootPending -or $CCMClientSDK.RebootPending) {
		        $SCCM = $true
		    }
	    }
            
	    Else {
	        $SCCM = $null
	    }

	    ## Creating Custom PSObject and Select-Object Splat
	    $SelectSplat = @{
	        Property=(
	            'Computer',
	            'CBServicing',
	            'WindowsUpdate',
	            'CCMClientSDK',
	            'PendComputerRename',
	            'PendFileRename',
	            'PendFileRenVal',
	            'RebootPending'
	        )}
	    New-Object -TypeName PSObject -Property @{
	        Computer=$WMI_OS.CSName
	        CBServicing=$CBSRebootPend
	        WindowsUpdate=$WUAURebootReq
	        CCMClientSDK=$SCCM
	        PendComputerRename=$CompPendRen
	        PendFileRename=$PendFileRename
	        PendFileRenVal=$RegValuePFRO
	        RebootPending=($CompPendRen -or $CBSRebootPend -or $WUAURebootReq -or $SCCM -or $PendFileRename)
	    } | Select-Object @SelectSplat

	} Catch {
	    Write-Warning "$Computer`: $_"
	    ## If $ErrorLog, log the file to a user specified location/path
	    If ($ErrorLog) {
	        Out-File -InputObject "$Computer`,$_" -FilePath $ErrorLog -Append
	    }				
	}			
  }## End Foreach ($Computer in $ComputerName)			
}## End Process

End {  }## End End

}## End Function Get-PendingReboot

# --------------------------------------------------------------------------------------------
# Function SetRegistryValue
# Purpose: Sets\Updates a registry value 
# Parameters: $sRegKeyName = Registry Key
#             $sRegValueName = Name of the registry value
#             $sType = Type of registry value (DWORD, STRING, etc)
#             $value = Value to be set in the $sRegValueName
#             $bAddToWow6432 = Boolean to indicate whether to add same
#                 value to the Wow6432Node (only if OS type is 64-bit)
# Returns: True = Success
#         False = Failure
# --------------------------------------------------------------------------------------------
Function SetRegistryValue(){
    param(	[string]$sRegKeyName, 
			[string]$sRegValueName, 
			[ValidateSet("String","ExpandString","Binary","DWord","MultiString","QWord")]$sType="String", 
			$value, 
			[boolean]$bAddToWow6432=$false )

    #Check to see if we should update the WOW6432Node as well
    If (($global:bIs32Bit -eq $false) -and ( $bAddToWow6432 -eq $true ))
    {
        LogIt -sMessage "Entries should be added to WOW6432Node." -iTabs 0 
        $sRegWOWKeyName = $sRegKeyName.Replace("Software", "Software\Wow6432Node")
        
		SetRegistryValue -sRegKeyName $sRegWOWKeyName -sRegValueName $sRegValueName -sType $sType -value $value		
    }
        
    #Check to see if the Registy Key exists
    $bRegReturn = CreateRegistryKeys -sRegKey $sRegKeyName
    
	#If the registry keys exist or were created successfully
    If ($bRegReturn)
    {
        #Add registry keys 
        LogIT -sMessage "Updating Registry..." -iTabs 0             
        LogIt -sMessage "Registry Key = $sRegKeyName" -iTabs 1 
        LogIt -sMessage "Registry Value Name = $sRegValueName" -iTabs 1 
        LogIt -sMessage "Registry Value Type = $sType" -iTabs 1 
        LogIt -sMessage "Registry Value = $value" -iTabs 1 
        
        #Clear errors
        $error.Clear()
        Set-ItemProperty $sRegKeyName -name $sRegValueName -type $sType -value $value
		
        #Check to see if an error occurred
        If (!($?)) 
        {
            LogIt -sMessage "Error adding entry to registry: $error" -iTabs 1 
        }
        Else #No error
        {
            LogIt -sMessage "Entry successfully added to registry" -iTabs 1 
        }
    }
    Else #CheckRegistryKeys returned failure
    {
        LogIt -sMessage "Could not set registry value. Parent key(s) didn't exist." -iTabs 0 
    }
    
    LogIt -sMessage "" -iTabs 0 

} #End of SetRegistryValue function

# --------------------------------------------------------------------------------------------
# End of FUNCTIONS
# --------------------------------------------------------------------------------------------
# --------------------------------------------------------------------------------------------
# Variable Declarations
# --------------------------------------------------------------------------------------------
# *****  Change Logging Path and File Name Here  *****
$sLogContext	= "System" 		# System / User 
$sLogFolder		= "Wait-Cooking"	# Folder Name
$sOutFileName	= "Wait-Cooking.log" # Log File Name
$sEventIDSource = "WDS-Script" # Source to be used in EventViewer Log creation
$sRights = "Administrator" # "AccountOperator","Administrator","BackupOperator","Guest","PowerUser","PrintOperator","Replicator","SystemOperator","User"
# ****************************************************
$sScriptName 	= $MyInvocation.MyCommand
$sScriptPath 	= Split-Path -Parent $MyInvocation.MyCommand.Path
$sOSBit			= GetOSArchitecture
$bIs64bit		= $sOSBit -eq "64-bit"
$bIsVM			= IsVirtualMachine
$sOSVersion		= GetOSVersion
$bIsWin7		= $sOSVersion.StartsWith("6.1") 
$bIsWin8		= $sOSVersion.StartsWith("6.2")
$bIsWin81		= $sOSVersion.StartsWith("6.3")
$bIsWin10		= $sOSVersion.StartsWith("10.")
$bIsOnVPN		= IsOnVPN
$sLogRoot		= "C:\XOM\Logs"
$sOutFilePath	= Join-Path -Path (Join-Path -Path $sLogRoot -ChildPath $sLogContext) -ChildPath $sLogFolder
$sLogFile		= Join-Path -Path $sOutFilePath -ChildPath $sOutFileName
$global:iExitCode = 0
$sUserName		= $env:username
$sUserDomain	= $env:userdomain
$sMachineName	= $env:computername
$sCMDArgs		= $MyInvocation.Line
$bAllow64bitRelaunch = $true
$iLogFileSize 	= 1048576

# Script Specific Variables


# --------------------------------------------------------------------------------------------
# Main Sub
# --------------------------------------------------------------------------------------------
Function MainSub
{
    #Write default log file information to the log file
	LogIt -sMessage "Variables:" -iTabs 0 
	LogIt -sMessage "Script Title = $SCRIPT_TITLE" -iTabs 1 
	LogIt -sMessage "Script Name = $sScriptName" -iTabs 1 
	LogIt -sMessage "Script Version = $SCRIPT_VERSION" -iTabs 1 
	LogIt -sMessage "Script Path = $sScriptPath" -iTabs 1
	LogIt -sMessage "User Name = $sUserDomain\$sUserName" -iTabs 1
	LogIt -sMessage "Machine Name = $sMachineName" -iTabs 1
	LogIt -sMessage "OS Version = $sOSVersion" -iTabs 1
	LogIt -sMessage "OS Architecture = $sOSBit" -iTabs 1
	LogIt -sMessage "Is Windows 7 = $bIsWin7" -iTabs 1
	LogIt -sMessage "Is Windows 8.1 = $bIsWin81" -iTabs 1
	LogIt -sMessage "Is Windows 10 = $bIsWin10" -iTabs 1
	LogIt -sMessage "Is 64-bit OS = $bIs64bit" -iTabs 1
	LogIt -sMessage "Is Virtual Machine = $bIsVM" -iTabs 1
	LogIt -sMessage "VPN Connected = $bIsOnVPN" -iTabs 1
	LogIt -sMessage "Log File = $sLogFile" -iTabs 1
	LogIt -sMessage "Command Line: $sCMDArgs" -iTabs 1
	LogIt -sMessage "Debug = $Debug" -iTabs 1
	LogIt -sMessage "" -iTabs 0
	LogIt -sMessage "If a Reboot is necessary script will $RebootBehaviour" -iTabs 1
    LogIt -sMessage "Is CBServicing able to trigger a reboot? $skipCBServicing" -iTabs 1
    LogIt -sMessage "Is WindowsUpdate able to trigger a reboot? $skipWindowsUpdate" -iTabs 1
    LogIt -sMessage "Is CCMClientSDK able to trigger a reboot? $skipCCMClientSDK" -iTabs 1
    LogIt -sMessage "Is PendComputerRename able to trigger a reboot? $skipPendComputerRename" -iTabs 1
    LogIt -sMessage "Is PendFileRenVal able to trigger a reboot? $skipPendFileRenVal" -iTabs 1
    LogIt -sMessage "Script will re-run every $TimeCycle seconds." -iTabs 1
    LogIt -sMessage "" -iTabs 0

	# Your scripts starts here
	    
    LogIt -sMessage "Starting to execute Script" -iTabs 0
    EventLogIt -sMessage "$SCRIPT_TITLE ($sScriptName) $SCRIPT_VERSION
                          Starting to execute Script 
                          --------------------------
                          Script Name = $sScriptName
	                      Script Version = $SCRIPT_VERSION
	                      Script Path = $sScriptPath
                          User Name = $sUserDomain\$sUserName
	                      Machine Name = $sMachineName
                          OS Version = $sOSVersion
                          OS Architecture = $sOSBit
                          Is Windows 7 = $bIsWin7
                          Is Windows 8.1 = $bIsWin81
                          Is Windows 10 = $bIsWin10
                          Is 64-bit OS = $bIs64bit
                          Is Virtual Machine = $bIsVM
                          VPN Connected = $bIsOnVPN
                          Log File = $sLogFile
                          Command Line: $sCMDArgs
                          Debug = $Debug
                          
	                      If a Reboot is necessary script will $RebootBehaviour
                          Is CBServicing able to trigger a reboot? $skipCBServicing
                          Is WindowsUpdate able to trigger a reboot? $skipWindowsUpdate
                          Is CCMClientSDK able to trigger a reboot? $skipCCMClientSDK
                          Is PendComputerRename able to trigger a reboot? $skipPendComputerRename
                          Is PendFileRenVal able to trigger a reboot? $skipPendFileRenVal
                          Script will re-run every $TimeCycle seconds." -iEventID 8001 -sEventLogType Information

    IF (!$?){
        LogIt -sMessage "Error writting to Event Viewer. No events will be recorded" -iTabs 1
    }
    <#$bUserRights = Check-Credentials -sRole $sRights
    if (!$bUserRights){
        LogIt -sMessage "$sScriptName not running with $sRights" -iTabs 1
        EventLogIt -sMessage "$SCRIPT_TITLE ($sScriptName) $SCRIPT_VERSION
                              $sScriptName not running with $sRights." -iEventID 9004 -sEventLogType Error
        $global:iExitCode = 9004
        return 9004
    }
    else{
        LogIt -sMessage "$sScriptName running with $sRights" -iTabs 1
        EventLogIt -sMessage "$SCRIPT_TITLE ($sScriptName) $SCRIPT_VERSION
                              $sScriptName running with $sRights." -iEventID 8001 -sEventLogType Information
    }#>
    <#$bRebootState = Get-PendingReboot   
    If ($bRebootState.RebootPending){
        LogIt -sMessage "Machine $env:computername is pending reboot. Running script again at a later time." -iTabs 1
        EventLogIt -sMessage "$SCRIPT_TITLE ($sScriptName) $SCRIPT_VERSION
                              $env:computername is pending reboot. Running script again at a later time." -iEventID 9005 -sEventLogType Error
        $global:iExitCode = 9005
        return 9005
    }
    else{
        LogIt -sMessage "Machine $env:computername is not pending reboot. Proceeding." -iTabs 1
    }#>
cls
Logit -sMessage "Time,Needs Reboot?,Computer,CBServicing,WindowsUpdate,CCMClientSDK,PendComputerRename,PendFileRename,PendFileRenVal" -iTabs 1
$count=0
$loopEscape=$false
Do {        
    $result = Get-PendingReboot    
    $time = get-date -UFormat %y-%m-%d-%H-%M-%S
    Logit -sMessage  "$time,$($result.RebootPending),$($result.Computer),$($result.CBServicing),$($result.WindowsUpdate),$($result.CCMClientSDK),$($result.PendComputerRename),$($result.PendFileRename),$($result.PendFileRenVal)"    
    Write-Host "Time..............: $time"
    Write-Host "Computer..........: $($result.Computer)"
    Write-Host ""
    Write-Host "Needs Reboot?.....: $($result.RebootPending)"
    Write-Host ""
    Write-Host "CBServicing.......: $($result.CBServicing)"
    Write-Host "WindowsUpdate.....: $($result.WindowsUpdate)" 
    Write-Host "CCMClientSDK......: $($result.CCMClientSDK)"
    Write-Host "PendComputerRename: $($result.PendComputerRename)"    
    Write-Host "PendFileRenVal....: $($result.PendFileRename)"
    if($result.PendFileRenVal.Count -gt 0){
        $count=1
        foreach ($file in $result.PendFileRenVal){
            if (($count % 2) -eq 1){
                $index = $count/2                
            Write-Host "                    $("{0:N0}" -f $index) - $file"
            }
        $count++
        }    
    }else{
        Write-Host "                    No pending file rename"
    }    
    Write-Host ""
    Write-Host "===================="
    Write-Host ""
    EventLogIt -sMessage "$SCRIPT_TITLE ($sScriptName) $SCRIPT_VERSION
                            Needs Reboot?.....: $($result.RebootPending)
                            CBServicing.......: $($result.CBServicing)
                            WindowsUpdate.....: $($result.WindowsUpdate)
                            CCMClientSDK......: $($result.CCMClientSDK)
                            PendComputerRename: $($result.PendComputerRename)
                            PendFileRenVal....: $($result.PendFileRename)
                            PendFileRenValNam.: $($result.PendFileRenVal)" -iEventID 8001 -sEventLogType Information
    
    If($result.RebootPending){
        $loopEscape=$true
        if (($skipCBServicing) -and ($result.CBServicing)){
            $loopEscape=$false
        }
        if (($skipWindowsUpdate) -and ($result.WindowsUpdate)){
            $loopEscape=$false
        }
        if (($skipCCMClientSDK) -and ($result.CCMClientSDK)){
            $loopEscape=$false
        }
        if (($skipPendComputerRename) -and ($result.PendComputerRename)){
            $loopEscape=$false
        }
        if (($skipPendFileRenVal) -and ($result.PendFileRename)){
            $loopEscape=$false
        }   
    }
    sleep $TimeCycle
}
While (!($loopEscape))    
Write-Host "============================================================" -ForegroundColor Yellow
Write-Host "============================================================" -ForegroundColor Red
Write-Host ""
Write-Host "Computer needs reboot" 
Write-Host ""
Write-Host "============================================================" -ForegroundColor Red
Write-Host "============================================================" -ForegroundColor Yellow
    
if ($RebootBehaviour -eq "Force"){
    Write-Host "============================================================" -ForegroundColor Yellow
    Write-Host "============================================================" -ForegroundColor Red
    Write-Host ""
    Write-Host "Computer will reboot in $TimeCycle seconds" 
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Red
    Write-Host "============================================================" -ForegroundColor Yellow
    EventLogIt -sMessage "$SCRIPT_TITLE ($sScriptName) $SCRIPT_VERSION
                            Rebooting $result.Computer
                            Needs Reboot?.....: $($result.RebootPending)
                            CBServicing.......: $($result.CBServicing)
                            WindowsUpdate.....: $($result.WindowsUpdate)
                            CCMClientSDK......: $($result.CCMClientSDK)
                            PendComputerRename: $($result.PendComputerRename)
                            PendFileRenVal....: $($result.PendFileRename)
                            PendFileRenValNam.: $($result.PendFileRenVal)" -iEventID 3001 -sEventLogType Information
    sleep $TimeCycle  
    Restart-computer
}
pause
    if(($Uninstall) -and ($Push)){       
    }
    elseif($Uninstall){
    }    
    else{
        EventLogIt -sMessage "Wrong Script $sScriptName usage.
                         Check Reboot and Notify: .\$sScriptName -RebootBehaviour `"Notify`"
                         Check and Force Reboot: .\$sScriptName -RebootBehaviour `"Force`"
                         Reboot reasons can be skipped by adding aparameter -skip<REASON>" -iEventID 9002 -sEventLogType Warning
        LogIt -sMessage "Wrong Script usage." -iTabs 1
        LogIt -sMessage "Check Reboot and Notify: .\$sScriptName -RebootBehaviour `"Notify`"" -iTabs 2
        LogIt -sMessage "Check and Force Reboot: .\$sScriptName -RebootBehaviour `"Force`"" -iTabs 2
        LogIt -sMessage "Reboot reasons can be skipped by adding aparameter -skip<REASON>" -iTabs 2
        return 9002
    }

} #End of MainSub


# --------------------------------------------------------------------------------------------
# Main Processing (DO NOT CHANGE HERE)
# --------------------------------------------------------------------------------------------

If($Debug) { $ErrorActionPreference = "Stop" }

# Prior to logging, determine if we are in the 32-bit scripting host on a 64-bit machine and need and want to re-launch
If(!($NoRelaunch) -and $bIs64bit -and ($PSHOME -match "SysWOW64") -and $bAllow64bitRelaunch) {
    Relaunchin64
}
Else {
    # Starting the log
    StartLog

    Try {
	    MainSub
    }
    Catch {
	    # Log a general exception error
	    LogIt -sMessage "Error running script" -iTabs 0        
        if ($global:iExitCode -eq 0){
	        $global:iExitCode = 9999
        }
        EventLogIt -sMessage "Error running script" -iEventID $global:iExitCode -sEventLogType Error
    }

    # Stopping the log
    EndLog
}

# Quiting with our exit code
Exit $global:iExitCode