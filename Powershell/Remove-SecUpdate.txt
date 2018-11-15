param( [switch]$Debug, [switch]$NoRelaunch, [switch]$Uninstall, [switch]$Push )

$SCRIPT_TITLE = "Remove-SecUpdates"
$SCRIPT_VERSION = "1.2"

#Set default behavior if an error occurs. this should be set to "SilentlyContinue" for deployment, but can be changed for testing.
$ErrorActionPreference 	= "SilentlyContinue"	# SilentlyContinue / Stop / Continue

# -Script Name: Remove-SecUpdates.ps1------------------------------------------------------
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
# Purpose: Remove KBs once the machine is added to Security Update Exception Collection
#
# Created:  10/26/2016
#
# Dependencies: Script must be run with administrative rights
#               TXT File with KB numbers
#
# Known Issues: None
#
# Arguments: 
#		/debug or -debug - Enables debug logging in the script, and disables default 
#							On Error Resume Next statements
#
# Exit Codes:
#            0 - Script completed successfully
#
#            3xxx - SUCCESS
#            3001 - KB Removed
#            3002 - KB to remove not found
#
#            5xxx - WARNING
#
#            8xxx - INFORMATION
#            8001 - Information Only
#            8002 - Script Start
#            8003 - Script End
#            8004 - Error creating EventLog
#            8005 - Error creating LogFile
#
#            9xxx - ERROR
#            9001 - Unable to remove KB
#            9002 - Script Wrong usage
#            9004 - Script not runnign with $sRights
#            9005 - Machine is pending reboot
#            9007 - Error getting list of KBs
#			 9999 - Script completed unsuccessfully, throwing an unhandled error
# 
# Output: C:\XOM\Logs\System\SCCM\WindowsUpdate\Remove-SecUpdates.ps1
#    
# Revision History: (Date, Author, Description)
#		(Date 2016-10-26
#			v1.0
#			Jose Varandas
#			TBD
#       (Date 2016-12-15
#			v1.1
#			Jose Varandas
#			 - Change Log output
#       (Date 2016-12-27
#			v1.2
#			Jose Varandas
#			 - Change Log output, EventLog created more exit codes
#				
#				
# -------------------------------------------------------------------------------------------- 
#>

# --------------------------------------------------------------------------------------------
# Subroutines and Functions
# --------------------------------------------------------------------------------------------
function Check-Credentials {
# Sub Name: Check-Credentials-----------------------------------------------------------------	
# Sub Name: Check-Credentials
# Purpose: Check if script is running with necessary rights
# Param: $sRole
# Variables: $user
# --------------------------------------------------------------------------------------------
    param( [ValidateSet("AccountOperator","Administrator","BackupOperator","Guest","PowerUser","PrintOperator","Replicator","SystemOperator","User")][string]$sRole)
    $user = [Security.Principal.WindowsIdentity]::GetCurrent();
    IF((New-Object Security.Principal.WindowsPrincipal $user).IsInRole([Security.Principal.WindowsBuiltinRole]::$sRole)){
        return $true
    }
    ELSE{
        return $false
    }
} #End of Check-Credentials function
function EventLogIt {
# Sub Name: EventLogIt-----------------------------------------------------------------------	
# Sub Name: EventLogIt
# Purpose: Log information to machine's Event Viewer
# Variables: None
# --------------------------------------------------------------------------------------------
    param( [string]$sMessage="", [int]$iEventID=0, [ValidateSet("Error","Information","Warning")][string]$sEventLogType,[string]$sSource=$sEventIDSource)
    New-EventLog -LogName Application -Source $sSource -ErrorAction SilentlyContinue
    Write-EventLog -LogName Application -Source $sSource -EntryType $sEventLogType -EventId $iEventID -Message $sMessage -ErrorAction SilentlyContinue
} #End of EventLogIt function
Function RelaunchIn64{
# --------------------------------------------------------------------------------------------	
# Sub Name: RelaunchIn64
# Purpose: To relaunch the script as a 64bit process
# Variables: None
# --------------------------------------------------------------------------------------------
    ShowDebug "Restarting script in 64-bit PowerShell"
    
    $xpath = (Join-Path -Path ($PSHOME -replace "syswow64", "sysnative") -ChildPath "powershell.exe")
    ShowDebug "PS Engine = $xpath"
    ShowDebug "Command = $xpath $sCMDArgs"

    $global:iExitCode = (Start-Process -FilePath $xpath -ArgumentList $sCMDArgs -Wait -PassThru -WindowStyle Hidden).ExitCode
    ShowDebug "Exit Code = $global:iExitCode"
    
} #End of RelaunchIn64 function
Function GetOSArchitecture(){
# --------------------------------------------------------------------------------------------
# Function GetOSArchitecture
# Purpose: Gets the OS Architecture version from WIM
# Parameters: None
# Returns: String with OSArchitecture
# --------------------------------------------------------------------------------------------
    $OSArchitecture = Get-WMIObject -class "Win32_OperatingSystem" -computername "."
	$OSArchitecture = $OSArchitecture.OSArchitecture.toString().toLower()
    return $OSArchitecture
} #End of GetOSArchitecture function
Function IsVirtualMachine(){
# --------------------------------------------------------------------------------------------
# Function Name: IsVirtualMachine
# Purpose: To identify if the machine is a virtual machine or not
# Variables: None
# Returns: Boolean value (True or False) of whether the machine is a virtual machine or not
# --------------------------------------------------------------------------------------------
	$bReturn = $false
	$sModel = Get-WMIObject -class "Win32_ComputerSystem" -computername "."
	$sModel = $sModel.Model.toString().toLower()
	If(($sModel.Contains("virtual machine")) -or ($sModel.Contains("vmware virtual platform")))
	{
		$bReturn = $true
	}
	return $bReturn
} #End of IsVirtualMachine function
Function GetOSVersion(){
# --------------------------------------------------------------------------------------------	
# Function Name: GetOSVersion
# Purpose: To get the OS Version via WMI
# Variables: None
# Returns: OS Version from WMI
# --------------------------------------------------------------------------------------------	
	$version = Get-WMIObject -class "Win32_OperatingSystem" -computername "."
	$version = $version.Version.toString().toLower()
	return $version
} #End of GetOSVersion function
Function IsOnVPN(){
# --------------------------------------------------------------------------------------------	
# Function Name: IsOnVPN
# Purpose: Checks to see if the machine is currently connected to VPN
# Variables: None
# Returns: Boolean (True or False) if the machine is connected to VPN
# --------------------------------------------------------------------------------------------
	$iRegData = 0
	$bReturn = $false
	$iRegData = (Get-ItemProperty -Path hklm:\SOFTWARE\ExxonMobil\GME).VPNConnected
	If($iRegData -eq 1) { $bReturn = $true }
	return $bReturn
} #End of IsOnVPN function
Function StartLog(){	
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

    #LogIt $sHeader -iTabs 0  
	LogIt -sMessage "############################################################" -iTabs 0 
    LogIt -sMessage "" -iTabs 0 
    LogIt -sMessage "============================================================" -iTabs 0 	
    LogIt -sMessage "$SCRIPT_TITLE ($sScriptName) $SCRIPT_VERSION" -iTabs 0 
	LogIt -sMessage "============================================================" -iTabs 0 
	LogIt -sMessage "Script Started at $(Get-Date)" -iTabs 0 
	LogIt -sMessage "" -iTabs 0 

} #End of CheckLogFile function
Function ShowDebug(){
# --------------------------------------------------------------------------------------------
# Function ShowDebug
# Purpose: Allows you to show debug information
# Parameters: 
#    sText - Text to display as debug
#    iTabs - number of tabs to indent the text
# Returns: none
# --------------------------------------------------------------------------------------------
    param( [string]$sText="", [int]$iTabs=0 ) 
    
    if ($Debug -eq $true) {Write-Host  $sText}

} #End of ShowDebug function
Function LogIt(){
# --------------------------------------------------------------------------------------------
# Function LogIt
# Purpose: Writes specified text to the log file
# Parameters: 
#    sMessage - Message to write to the log file
#    iTabs - Number of tabs to indent text
#    sFileName - name of the log file (optional. If not provied will default to the $sLogFile in the script
# Returns: None
# --------------------------------------------------------------------------------------------
    param( [string]$sMessage="", [int]$iTabs=0, [string]$sFileName=$sLogFile )
    
    #Loop through tabs provided to see if text should be indented within file
    $sTabs = ""
    For ($a = 1; $a -le $iTabs; $a++) {
        $sTabs = $sTabs + "    "
    }

    #Populated content with tabs and message
    $sContent = $sTabs + $sMessage

    #Write contect to the file and if debug is on, to the console for troubleshooting
    Add-Content $sFileName -value  $sContent -ErrorAction SilentlyContinue
    IF (!$?){                
        $global:iExitCode = 8005            
    }
    ShowDebug $sContent
	
} #End of LogIt function
Function EndLog(){
# --------------------------------------------------------------------------------------------
# Function EndLog
# Purpose: Writes the last log information to the log file
# Parameters: None
# Returns: None
# --------------------------------------------------------------------------------------------
    #Loop through tabs provided to see if text should be indented within file
	LogIt -sMessage "" -iTabs 0 
    LogIt -sMessage "Script Completed at $(Get-date) with Exit Code $global:iExitCode" -iTabs 0  
    LogIt -sMessage "============================================================" -iTabs 0     
    LogIt -sMessage "" -iTabs 0 
    EventLogit -sMessage "$SCRIPT_TITLE ($sScriptName) $SCRIPT_VERSION`n
                          `n
                          Script $sScriptName Completed at $(Get-date) with Exit Code $global:iExitCode" -iEventID 8003 -sEventLogType Information
    LogIt -sMessage "" -iTabs 0 
    LogIt -sMessage "" -iTabs 0 
    LogIt -sMessage "" -iTabs 0 
} #End of EndLog function
Function CreateRegistryKeys(){
# --------------------------------------------------------------------------------------------
# Function CreateRegistryKeys
# Purpose: Creates the registry key that is provided and 
#          loops through the entire key to make sure all
#          keys exist
# Parameters: sRegKey - Registry key to check for\create
# Returns: True = key exists or was created
# --------------------------------------------------------------------------------------------
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
Function Get-PendingReboot{
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
Function SetRegistryValue(){
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
function Get-InstalledUpdates {       
# --------------------------------------------------------------------------------------------
# Function Get-InstalledUpdates
# Purpose: Returns object with installed updates
# Parameters: None
# Returns: @(KB) of FALSE if failed to query updates
# --------------------------------------------------------------------------------------------
    $oUpdateSession = New-Object -ComObject Microsoft.Update.Session -ErrorAction SilentlyContinue
    if (!$?){        
        return $false
    }
    $mUpdateSearcher = $oUpdateSession.CreateUpdateSearcher()  
    $iHistoryCount = $mUpdateSearcher.GetTotalHistoryCount()     
    $UpdateList = $mUpdateSearcher.QueryHistory(0,$iHistoryCount)  
    $aUpdateArray = @()    
    foreach ($oUpdate in $aUpdateList) {         
        [regex]::match($oUpdate.Title,'(KB[0-9]{6,7})').value | Where-Object {$_ -ne ""} | foreach {                     
            $oKB = New-Object -TypeName PSObject 
            $oKB | Add-Member -MemberType NoteProperty -Name KB -Value $_.replace("KB","")                               
        }         
        $aUpdateArray += $oKB 
    }
    $HotFixes = Get-HotFix -ErrorAction SilentlyContinue | Select-Object -ExpandProperty HotFixID      
    if (!$?){
        return $false
    }
    foreach ($HotFix in $HotFixes) {   
        $oKB = New-Object -TypeName PSObject       
        $oKB | Add-Member -MemberType NoteProperty -Name KB -Value $HotFix.replace("KB","")        
        $aUpdateArray += $oKB        
    } 
return $aUpdateArray | Sort-Object -Property @{Expression = "KB"} -Descending
} # ENF OF function Get-InstalledUpdates
# --------------------------------------------------------------------------------------------
# End of FUNCTIONS
# --------------------------------------------------------------------------------------------

# --------------------------------------------------------------------------------------------
# Variable Declarations

# --------------------------------------------------------------------------------------------
# *****  Change Logging Path and File Name Here  *****

    $sLogContext	= "System" 		# System / User 
    $sLogFolder		= "SCCM\WindowsUpdate"	# Folder Name
    $sOutFileName	= "Remove-SecUpdates.log" # Log File Name
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

# End of Variables Declaration
# --------------------------------------------------------------------------------------------


# Main Sub
# --------------------------------------------------------------------------------------------
Function MainSub
{
    #Write default log file information to the log file
	LogIt -sMessage "Variables:" -iTabs 0 
	LogIt -sMessage "Script Title.....:$SCRIPT_TITLE" -iTabs 1 
	LogIt -sMessage "Script Name......:$sScriptName" -iTabs 1 
	LogIt -sMessage "Script Version...:$SCRIPT_VERSION" -iTabs 1 
	LogIt -sMessage "Script Path......:$sScriptPath" -iTabs 1
	LogIt -sMessage "User Name........:$sUserDomain\$sUserName" -iTabs 1
	LogIt -sMessage "Machine Name.....:$sMachineName" -iTabs 1
	LogIt -sMessage "OS Version.......:$sOSVersion" -iTabs 1
	LogIt -sMessage "OS Architecture..:$sOSBit" -iTabs 1
	LogIt -sMessage "Is Windows 7.....:$bIsWin7" -iTabs 1
	LogIt -sMessage "Is Windows 8.1...:$bIsWin81" -iTabs 1
	LogIt -sMessage "Is Windows 10....:$bIsWin10" -iTabs 1
	LogIt -sMessage "Is 64-bit OS.....:$bIs64bit" -iTabs 1
	LogIt -sMessage "Is VM............:$bIsVM" -iTabs 1
	LogIt -sMessage "VPN Connected....:$bIsOnVPN" -iTabs 1
	LogIt -sMessage "Log File.........:$sLogFile" -iTabs 1
	LogIt -sMessage "Command Line.....:$sCMDArgs" -iTabs 1
	LogIt -sMessage "Debug............:$Debug" -iTabs 1
	LogIt -sMessage "============================" -iTabs 0
    LogIt -sMessage "" -iTabs 0
	
	# Your scripts starts here
	    
    # Script Header
    LogIt -sMessage "Starting to execute Script" -iTabs 0
    LogIt -sMessage "" -iTabs 0
    EventLogIt -sMessage "$SCRIPT_TITLE ($sScriptName) $SCRIPT_VERSION
                          Starting to execute Script 
                          --------------------------
                          Script Name.....:$sScriptName
	                      Script Version..:$SCRIPT_VERSION
	                      Script Path.....:$sScriptPath
                          User Name.......:$sUserDomain\$sUserName
	                      Machine Name....:$sMachineName
                          OS Version......:$sOSVersion
                          OS Architecture.:$sOSBit
                          Is Windows 7....:$bIsWin7
                          Is Windows 8.1..:$bIsWin81
                          Is Windows 10...:$bIsWin10
                          Is 64-bit OS....:$bIs64bit
                          Is VM...........:$bIsVM
                          VPN Connected...:$bIsOnVPN
                          Log File........:$sLogFile
                          Command Line....:$sCMDArgs
                          Debug...........:$Debug" -iEventID 8002 -sEventLogType Information
    # Checking if EventLogIt is working
    IF (!$?){
        LogIt -sMessage "Error writting to Event Viewer. No events will be recorded" -iTabs 1
        LogIt -sMessage "" -iTabs 0
        $global:iExitCode = 8004
    }

    # Checking if script is runnign with admin
    $bUserRights = Check-Credentials -sRole $sRights
    if (!$bUserRights){
        LogIt -sMessage "$sScriptName not running with $sRights" -iTabs 1
        LogIt -sMessage "" -iTabs 0
        EventLogIt -sMessage "$SCRIPT_TITLE ($sScriptName) $SCRIPT_VERSION
                              $sScriptName not running with $sRights." -iEventID 9004 -sEventLogType Error
        $global:iExitCode = 9004
        return 9004
    }
    else{
        LogIt -sMessage "$sScriptName running with $sRights" -iTabs 1
        LogIt -sMessage "" -iTabs 0        
    }

    # Checking if Machine is pending reboot
    $bRebootState = Get-PendingReboot   
    If ($bRebootState.RebootPending){
        LogIt -sMessage "Machine $env:computername is pending reboot. Running script again at a later time." -iTabs 1
        LogIt -sMessage "" -iTabs 0  
        EventLogIt -sMessage "$SCRIPT_TITLE ($sScriptName) $SCRIPT_VERSION
                              $env:computername is pending reboot. Running script again at a later time." -iEventID 9005 -sEventLogType Error
        $global:iExitCode = 9005
        return 9005
    }
    else{
        LogIt -sMessage "Machine $env:computername is not pending reboot. Proceeding..." -iTabs 1
        LogIt -sMessage "" -iTabs 0  
    }

    # Script uninstalling KBs silently
    if(($Uninstall) -and ($Push)){
        LogIt -sMessage "Script will uninstall KBs silently" -iTabs 1
        LogIt -sMessage "" -iTabs 0
        #Check if KBList exists
        LogIt -sMessage "Getting KBList Content..." -iTabs 1
        $aKBToRemove = Get-Content -Path "$PSScriptRoot\KBList.txt" -ErrorAction SilentlyContinue -Force        
        if (!$?){
            LogIt -sMessage "... ERROR" -iTabs 1
            LogIt -sMessage "Unable to load KBList.txt $PSScriptRoot. ERROR 9006. Exiting Script." -iTabs 1
            LogIt -sMessage "" -iTabs 0
            EventLogIt -sMessage "$SCRIPT_TITLE ($sScriptName) $SCRIPT_VERSION
                                  Unable to load KBList.txt in Execution location.  ERROR 9006. Exiting Script." -iEventID 9006 -sEventLogType Error
            $global:iExitCode = 9006
            return 9006          
        }                
        LogIt -sMessage "... SUCCESS" -iTabs 1        
        LogIt -sMessage "List of KBs to be removed was retrieved." -iTabs 2        
        LogIt -sMessage "" -iTabs 2        
        LogIt -sMessage "=================" -iTabs 3
        LogIt -sMessage "# - KB" -iTabs 3
        LogIt -sMessage "=================" -iTabs 3
        $count=1
        foreach ($kb in $aKBtoremove){
            LogIt -sMessage "$count - $kb" -iTabs 3
            $count++
        }
        LogIt -sMessage "=================" -iTabs 3
        LogIt -sMessage "Total: $($count-1)"  -iTabs 2
        LogIt -sMessage "=================" -iTabs 2
        LogIt -sMessage "" -iTabs 0
        
        # Getting updates installed
        LogIt -sMessage "Getting Installed KBs..." -iTabs 1
        $aInstalledUpdates = Get-InstalledUpdates
        if (!$aInstalledUpdates){
            LogIt -sMessage "... ERROR" -iTabs 1
            LogIt -sMessage "Error getting list of installed KBs." -iTabs 1
            LogIt -sMessage "" -iTabs 0
            EventLogIt -sMessage "$SCRIPT_TITLE ($sScriptName) $SCRIPT_VERSION
                                  Error getting list of installed KBs.  ERROR 9007. Exiting Script." -iEventID 9007 -sEventLogType Error
            $global:iExitCode = 9007
            return 9007            
        }    
        LogIt -sMessage "... SUCCESS" -iTabs 1        
        LogIt -sMessage "List of KBs already installed was retrieved." -iTabs 2        
        LogIt -sMessage "" -iTabs 2                 
        LogIt -sMessage "Sum of KBs found installed: $($aInstalledUpdates.count)" -iTabs 2        
        LogIt -sMessage "" -iTabs 0
        #going through installed KBs
        $eventOutput = "$SCRIPT_TITLE ($sScriptName) $SCRIPT_VERSION`n"
        $eventOutput +="`n"     
        $eventOutput +="KBs to be removed:"
        $eventOutput +="`n"
        $count=1    
        $kbCnt=0
        LogIt -sMessage "# of Sum|KB     |Remove?|WUSA ExitCode" -iTabs 3
        foreach($KB in $aInstalledUpdates) {
            if ($debug){
                sleep -m 100
            }         
            $toRemove = $false
            #checking if KB needs removal            
            foreach ($kbToRemove in $aKBToRemove){               
                if ($kb.KB -eq $kbToRemove){                   
                    $toRemove = $true
                    $kbCnt++
                }                   
            }             
            if ($ToRemove){                           
                LogIt -sMessage "" -iTabs 2                 
                LogIt -sMessage "Calling WUSA for $($KB.KB). This might take a few minutes. You may track WUSA.exe in tskmgr.exe" -iTabs 2        
                LogIt -sMessage "" -iTabs 2
                $exitWusa = (Start-Process -FilePath "c:\windows\system32\wusa.exe" -ArgumentList "/kb:$($kb.KB) /uninstall /quiet /norestart" -PassThru -wait -ErrorAction Stop).ExitCode                                                 
                $eventOutput +="Removal instruction #: $kbCnt`n"                
                $eventOutput +="        KB...........: $($KB.KB)"               
                $eventOutput +="        WUSA ExitCode: $exitWusa"
                $eventOutput +="`n"
            }
            else {
                $exitWusa = "Removal not requested"                
            }             
            LogIt -sMessage "$count|$($KB.KB)|$toRemove|$exitWusa" -iTabs 3            
            $count++
        }
        if ($kbCnt -eq 0 ){
                $eventOutput += "No KBs require removal.`n"                      
            }
        EventLogIt -sMessage $eventOutput -iEventID 8001 -sEventLogType Information
    }    
    else{
        EventLogIt -sMessage "Wrong Script $sScriptName usage.                         
                         Uninstall Silently: .\$sScriptName -Uninstall -PUSH" -iEventID 9002 -sEventLogType Warning
        LogIt -sMessage "Wrong Script usage." -iTabs 1        
        LogIt -sMessage "Uninstall Silently: .\$sScriptName -Uninstall -PUSH" -iTabs 2
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