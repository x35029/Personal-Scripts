param( 
    [switch]$DebugLog=$false, 
    [switch]$NoRelaunch=$False, 
    [ValidateSet("Check","Run")][string]$Action="Check",
    [switch]$Push=$false,
    [switch]$Force=$false,
    [ValidateSet("None","BlockNet47Update","AllowNet47Update","All")][string]$Setting="None"    
)
# --------------------------------------------------------------------------------------------
#region HEADER
$SCRIPT_TITLE = "Manage-Net47"
$SCRIPT_VERSION = "1.0"

$ErrorActionPreference 	= "Continue"	# SilentlyContinue / Stop / Continue

# -Script Name: Manage-Net47.ps1------------------------------------------------------ 
# Version: 1.0
# Based on PS Template Script Version: 1.0
# Author: Jose Varandas
# Owned By: WDS OS Engineering
# Purpose: Manages (Allow or Prevent) .NET 4.7/4.7.1 Upgrade
#
# Created:  03/16/2018
#
# Dependencies: 
#                Script must be run with administrative rights
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
	        Write-Log -sMessage "-Force ($false(Default)/$true) - Skips requirement checks. Script might return unexpected result" -iTabs 3        
            Write-Log -sMessage "-Push ($false(Default)/$true) - Hides User Interface" -iTabs 3        
            Write-Log -sMessage "-Action (Check/Run) -> Defines Script Execution Mode" -iTabs 3        
                Write-Log -sMessage "-> Check (Default)-> Script will run Pre-checks and Pos-Checks. No Exceution" -iTabs 4        
                Write-Log -sMessage "-> Run -> Runs script (Pre-Checks,Excecution,Post-Checks)" -iTabs 4        
            Write-Log -sMessage "-Setting -> Sets script scope" -iTabs 3        
                Write-Log -sMessage "-> None (Default)-> No errors to be remediated. General Health Check" -iTabs 4        
                Write-Log -sMessage "-> All -> All errors covered in this script will be checked/remediated" -iTabs 4        
                Write-Log -sMessage "-> BlockNet47Update -> Adds registry to prevent .NET Upgrade to versions 4.7 or 4.7.1" -iTabs 4    
                Write-Log -sMessage "-> AllowNet47Update -> Removes registry to prevent .NET Upgrade to versions 4.7 or 4.7.1" -iTabs 4    
    Write-Log -sMessage "============================================================================================================================" -iTabs 1            
    Write-Log -sMessage "EXAMPLE:" -iTabs 1
        Write-Log -sMessage ".\$sScriptName -Action Check" -iTabs 2     
            Write-Log -sMessage "Script will run all Pre-Checks. No Changes will happen to the device. ErrorCode Argument not used with `"Action Check`"" -iTabs 2     
        Write-Log -sMessage ".\$sScriptName -Action Run -ErrorCode All" -iTabs 2     
            Write-Log -sMessage "Script will run all coded remediations, pre and  post checks." -iTabs 2  
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
#
#            9XXX - ERROR
#
#			 9999 - Script completed unsuccessfully, throwing an unhandled error
# 
# Output: C:\XOM\Logs\System\SCCM\WindowsUpdate\Manage-Net47 1.0.log
#    
# Revision History: (Date, Author, Description)
#		(Date 2018-03-16)
#			v1.0
#			Jose Varandas
#           CHANGELOG:
#               Script Created
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
Function Get-OSArchitecture(){
# --------------------------------------------------------------------------------------------
# Function GetOSArchitecture

# Purpose: Gets the OS Architecture version from WIM
# Parameters: None
# Returns: String with OSArchitecture
# --------------------------------------------------------------------------------------------
    $OSArchitecture = Get-WMIObject -class "Win32_OperatingSystem" -computername "."
	$OSArchitecture = $OSArchitecture.OSArchitecture.toString().toLower()
    return $OSArchitecture
}  ##End of Get-OSArchitecture function
Function Get-SystemType(){
# --------------------------------------------------------------------------------------------
# Function Get-SystemType

# Purpose: Gets the OS Type version from WMI
# Parameters: None
# Returns: Workstation, Server, DC or False
# --------------------------------------------------------------------------------------------
   $CompConfig = Get-WmiObject Win32_ComputerSystem
    foreach ($ObjItem in $CompConfig) {
        $Role = $ObjItem.DomainRole
        Switch ($Role) {
            0 { return "Workstation"}
            1 { return "Workstation"}
            2 { return "Server"}
            3 { return "Server"}
            4 { return "Server"}
            5 { return "Server"}
            default { return $false}
        }
    } 
}      ##End of Get-SystemType function
Function Get-OSRole($role){
# --------------------------------------------------------------------------------------------
# Function Get-OSRoles

# Purpose: Gets the OS Roles from Server OS
# Parameters: $role
# Returns: Workstation, Server, DC or False
# --------------------------------------------------------------------------------------------
    $osRoles = Get-WmiObject Win32_ServerFeature
    if ($role -eq $null){
        return $osRoles
    }
    else{
        foreach ($item in $osRoles) {
            if ($item.Name -eq $role){
                return $true
            }
        }
        return $false
    }
}     ##End of Get-OSRoles function
Function Get-OSVersion(){
# --------------------------------------------------------------------------------------------	
# Function Name: GetOSVersion

# Purpose: To get the OS Version via WMI
# Variables: None
# Returns: OS Version from WMI
# --------------------------------------------------------------------------------------------	
	$version = Get-WMIObject -class "Win32_OperatingSystem" -computername "." -ErrorAction SilentlyContinue
	$version = $version.Version.toString().toLower()
	return $version
}       ##End of Get-OSVersion function
function Get-MSIInfo{
# --------------------------------------------------------------------------------------------	
# Function Name: Get-MSIInfo

# Purpose: To get information from msi package
# Variables: Path
# Returns: PowerShell Object {"ProductCode", "ProductName", "ProductVersion", "Manufacturer"}
# --------------------------------------------------------------------------------------------
    param(
        [parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [System.IO.FileInfo]$Path
    )
    Process {
        try {
            $msi = @()
            $info = @("ProductCode", "ProductName", "ProductVersion", "Manufacturer")
            $obj = New-Object -TypeName PSObject
            foreach ($Property in $info){
                Write-Verbose $Property
                # Read property from MSI database
                $WindowsInstaller = New-Object -ComObject WindowsInstaller.Installer
                $MSIDatabase = $WindowsInstaller.GetType().InvokeMember("OpenDatabase", "InvokeMethod", $null, $WindowsInstaller, @($Path.FullName, 0))
                $Query = "SELECT Value FROM Property WHERE Property = '$($Property)'"
                $View = $MSIDatabase.GetType().InvokeMember("OpenView", "InvokeMethod", $null, $MSIDatabase, ($Query))
                $View.GetType().InvokeMember("Execute", "InvokeMethod", $null, $View, $null)
                $Record = $View.GetType().InvokeMember("Fetch", "InvokeMethod", $null, $View, $null)
                $Value = $Record.GetType().InvokeMember("StringData", "GetProperty", $null, $Record, 1)
                Write-Verbose $Value    
                $obj | Add-Member -Name $Property -MemberType NoteProperty -Value $value
                Write-Verbose $obj
            }
            $msi+=$obj
                
            # Commit database and close view            
            $MSIDatabase.GetType().InvokeMember("Commit", "InvokeMethod", $null, $MSIDatabase, $null)
            $View.GetType().InvokeMember("Close", "InvokeMethod", $null, $View, $null)           
            $MSIDatabase = $null
            $View = $null
            
 
            # Return the value
            return $msi
        } 
        catch {
            Write-Warning -Message $_.Exception.Message ; break
        }
    }
    End {
        # Run garbage collection and release ComObject
        [System.Runtime.Interopservices.Marshal]::ReleaseComObject($WindowsInstaller) | Out-Null
        [System.GC]::Collect()
    }
}           ##End of Get-MSIInfo function
function Check-Credentials {
# --------------------------------------------------------------------------------------------	
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
}    ##End of Check-Credentials function
Function Check-App {
# --------------------------------------------------------------------------------------------
# Function Name: Check-App

# Purpose: Verifies if an application is installed
# Parameters: Software Name: $SoftToCheck
#             Software Version: $VersionToCheck
#             Comparison Mode
#                 Like(Default) -> Name *like*, Version *like*
#                 Exact -> Name equal, Version equal
#                 Equal or Higher -> Name equal, Version equal or greater
#                 Like or Higher -> Like name, Version equal or higher
#                 
# Returns: False is no app was found or Obj Array with apps found by this script
# --------------------------------------------------------------------------------------------
    Param(
        [ValidateNotNullOrEmpty()]$SoftToCheck = "*",
        [Version]$VersionToCheck,
        [Parameter(ParameterSetName='Mode')][switch]$Exact=$false,
        [Parameter(ParameterSetName='Mode')][switch]$equalOrHigher=$false,
        [Parameter(ParameterSetName='Mode')][switch]$likeOrHigher=$false,
        [Parameter(ParameterSetName='Mode')][switch]$Like=$true
    )
    $params = @{
        ScriptBlock = {
            Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* -ErrorAction SilentlyContinue
            Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* -ErrorAction SilentlyContinue
        }
    }    
    $AppInstalled = 0
    $CheckInstalled = Invoke-Command @params
    $installedApps = @()
    $SoftToCheck | ForEach-Object {         
        $soft = $_
        $CheckInstalled | ForEach-Object {
            $bAddObj=$false            
            if ($($_.PSChildName).length -eq 38){      
                if ($Exact){
                    IF (($_.DisplayName -eq "$soft") -and ([Version]$_.DisplayVersion -eq "$VersionToCheck")){
                        $AppInstalled++
                        $bAddObj=$true
                    }
                }
                elseif ($equalOrHigher){
                    IF (($_.DisplayName -eq "$soft") -and ($_.DisplayVersion -ge "$VersionToCheck")){
                        $AppInstalled++
                        $bAddObj=$true
                    }
                }
                elseif ($likeOrHigher){
                    IF (($_.DisplayName -like "*$soft*") -and ($_.DisplayVersion -ge "$VersionToCheck")){
                        $AppInstalled++
                        $bAddObj=$true
                    }
                }
                elseif ($Like){
                    IF (($_.DisplayName -like "*$soft*") -and ($_.DisplayVersion -like "*$VersionToCheck*")){
                        $AppInstalled++
                        $bAddObj=$true
                    }
                }
                if ($bAddObj){      
                    $obj = New-Object -TypeName PSObject
                    $obj | Add-Member -Name 'ProductCode' -MemberType NoteProperty -Value $($_.PSChildName)
                    $obj | Add-Member -Name 'Name' -MemberType NoteProperty -Value $($_.DisplayName)
                    $obj | Add-Member -Name 'Version' -MemberType NoteProperty -Value $([System.Version]$_.DisplayVersion)
                    $obj | Add-Member -Name 'Publisher' -MemberType NoteProperty -Value $($_.Publisher)
                    $uString = $($_.UninstallString)                
                    if ($uString -Like "MsiExec.exe /I*"){
                        $uString = $uString.replace("MsiExec.exe /I","MsiExec.exe /X")              
                        $obj | Add-Member -Name 'MSIInstaller' -MemberType NoteProperty -Value $true
                    }
                    elseif (!($uString -like "MsiExec.exe*")){                           
                        $obj | Add-Member -Name 'MSIInstaller' -MemberType NoteProperty -Value $false
                    }
                    else{
                        $obj | Add-Member -Name 'MSIInstaller' -MemberType NoteProperty -Value $true
                    }
                    $obj | Add-Member -Name 'UninstallString' -MemberType NoteProperty -Value $uString
                    $installedApps+=$obj
                }
            }             
        } #$CheckInstalled | ForEach-Object 
    } #$SoftToCheck | ForEach-Object 
    if ($AppInstalled -eq 0){
        return $false
    }
    else{        
        return $installedApps | Sort-Object Version -Descending
    }
}            ##End of Check-App function
Function Check-NetFramework{
    Get-ChildItem 'HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP' -recurse |
    Get-ItemProperty -name Version,Release -EA 0 |
    Where { $_.PSChildName -match '^(?!S)\p{L}'} |    
    Select PSChildName, Version, Release, @{
        name="Product"
        expression={
            if ([Version]$_.Version -lt [Version]"3.0"){
                [Version]"2.0"
            }
            elseif(([Version]$_.Version -lt [Version]"3.5") -and ([Version]$_.Version -ge [Version]"3.0")){
                [Version]"3.0"
            }
            elseif(([Version]$_.Version -lt [Version]"4.0") -and ([Version]$_.Version -ge [Version]"3.5")){
                [Version]"3.5"
            }
            elseif(([Version]$_.Version -lt [Version]"4.5") -and ([Version]$_.Version -ge [Version]"4.0")){
                [Version]"4.0"
            }
            else{
                switch -regex ($_.Release) {        
                    "378389" {[Version]"4.5"}
                    "378675|378758" {[Version]"4.5.1"}
                    "379893" {[Version]"4.5.2"}
                    "393295|393297" {[Version]"4.6"}
                    "394254|394271" {[Version]"4.6.1"}
                    "394802|394806" {[Version]"4.6.2"}
                    {$_ -gt 394806} {[Version]"Undocumented 4.6.2 or higher, please update script"}
                }
            }
        }
    }  |
    Sort Product -Descending
}    ##End of Check-NetFramework
Function Check-VM(){
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
}            ##End of Check-VM function
Function Check-VPN(){
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
}           ##End of Check-VPN function
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
    Write-Log -sMessage "-Setting..:$Setting" -iTabs 1    
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
    sleep 0.5
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
Function Create-Registry(){
# --------------------------------------------------------------------------------------------
# Function Create-Registry

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
    #Write-Log -sMessage "Checking for existance of $sRegKey..." -iTabs 0     
    #Check to see if the provided registry key exists
    If (!(Test-Path -Path $sRegKey)){
        #If key doesn't exist, get parent key and check to see if it exists and create if necessary
        $sParent = Split-Path $sRegKey
        #Check to see if the parent was a "null" value
        If ($sParent -ne $null)        {
            $bReturn = Create-Registry -sRegKey $sParent
        }
        #after all parent keys have been processed, create key
        #Check to see if the function returned a success
        if ($bReturn){
            New-Item -path $sRegKey
            Show-Debug "$sRegKey was created"
        }
        Else{
            Show-Debug "Error Creating Key: $error[0]"
            Return $false
        }
    }
    Else{
        Return $true
    }        
}     ##End of Create-Registry function
Function Set-Registry(){
# --------------------------------------------------------------------------------------------
# Function Set-Registry

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
    If (($global:bIs64Bit -eq $true) -and ( $bAddToWow6432 -eq $true ))
    {
        Show-Debug "Entries should be added to WOW6432Node."
        $sRegWOWKeyName = $sRegKeyName.Replace("Software", "Software\Wow6432Node")
        
		Set-Registry -sRegKeyName $sRegWOWKeyName -sRegValueName $sRegValueName -sType $sType -value $value		
    }
        
    #Check to see if the Registy Key exists
    $bRegReturn = Create-Registry -sRegKey $sRegKeyName
    
	#If the registry keys exist or were created successfully
    If ($bRegReturn)
    {
        #Add registry keys         
        Show-Debug -sText "Updating Registry..." -iTabs 0             
        Show-Debug -sText "Registry Key = $sRegKeyName" -iTabs 1 
        Show-Debug -sText "Registry Value Name = $sRegValueName" -iTabs 1 
        Show-Debug -sText "Registry Value Type = $sType" -iTabs 1 
        Show-Debug -sText "Registry Value = $value" -iTabs 1 
        
        #Clear errors
        $error.Clear()
        Set-ItemProperty $sRegKeyName -name $sRegValueName -type $sType -value $value
		
        #Check to see if an error occurred
        If (!($?)) 
        {
            Show-Debug -sText "Error adding entry to registry: $error" -iTabs 1 
            Return $false
        }
        Else #No error
        {
            Show-Debug -sText "Entry successfully added to registry" -iTabs 1 
            Return $true
        }
    }
    Else #CheckRegistryKeys returned failure
    {
        Show-Debug -sText "Could not set registry value. Parent key(s) didn't exist." -iTabs 0 
    }
    
    Write-Log -sMessage "" -iTabs 0 

}        ##End of Set-Registry function
Function Delete-Registry(){
# --------------------------------------------------------------------------------------------
# Function Delete-Registry

# Purpose: Deletes a registry value 
# Parameters: $sRegKeyName = Registry Key
#             $sRegValueName = Name of the registry value#             
#             $bRemoveFromWow6432 = Boolean to indicate whether to add same
#                 value to remove from Wow6432Node (only if OS type is 64-bit)
# Returns: True = Success
#         False = Failure
# --------------------------------------------------------------------------------------------
    param(	[string]$sRegKeyName, 
			[string]$sRegValueName, 			
			[boolean]$bRemoveFromWow6432=$false )

    #Check to see if we should update the WOW6432Node as well
    If (($global:bIs32Bit -eq $false) -and ( $bAddToWow6432 -eq $true ))
    {
        Show-Debug "Entries should be added to WOW6432Node."
        $sRegWOWKeyName = $sRegKeyName.Replace("Software", "Software\Wow6432Node")
        
		Delete-Registry -sRegKeyName $sRegWOWKeyName -sRegValueName $sRegValueName -sType $sType -value $value		
    }
        
    #Check to see if the Registy Key exists
    $bRegReturn = Create-Registry -sRegKey $sRegKeyName
    
	#If the registry keys exist or were created successfully
    If ($bRegReturn)
    {
        #Add registry keys         
        Show-Debug -sText "Updating Registry..." -iTabs 0             
        Show-Debug -sText "Registry Key = $sRegKeyName" -iTabs 1 
        Show-Debug -sText "Registry Value Name = $sRegValueName" -iTabs 1 
        Show-Debug -sText "Registry Value Type = $sType" -iTabs 1 
        Show-Debug -sText "Registry Value = $value" -iTabs 1 
        
        #Clear errors
        $error.Clear()
        Remove-ItemProperty $sRegKeyName -name $sRegValueName -Force
		
        #Check to see if an error occurred
        If (!($?)) 
        {
            Show-Debug -sText "Error removing entry from registry: $error" -iTabs 1 
        }
        Else #No error
        {
            Show-Debug -sText "Entry successfully removed from registry" -iTabs 1 
        }
    }
    Else #CheckRegistryKeys returned failure
    {
        Show-Debug -sText "Could not remove registry value. Parent key(s) didn't exist." -iTabs 0 
    }
    
    Write-Log -sMessage "" -iTabs 0 

}     ##End of Delete-Registry function
Function Get-Registry(){
# --------------------------------------------------------------------------------------------
# Function Get-Registry

# Purpose: Return registry key value/existance and 
#          loops through the entire key to make sure all
#          keys exist
# Parameters: sRegKey - Registry key to be queried
# Returns: 
#          $False = Key does not Exist
#          $value - Value for the key
# --------------------------------------------------------------------------------------------
    param([string]$sRegKey="HKLM:\",[string]$sRegKeyVal=$false )     
    $bReturn = $false
    #Clear any errors that may exist
    $error.Clear()
    Show-Debug "Checking for existance of $sRegKey..." -iTabs 0     
    #Check to see if the provided registry key exists
    If (!(Test-Path -Path $sRegKey)){
        Show-Debug "$sRegKey not found"        
        $bReturn=$false
    }
    Else {
        Show-Debug "$sRegKey found"
        #Check to see if the provided registry key value exists
        if($sRegKeyVal -ne $false){
            $bReturn=$false
        }
        else{            
            $bReturn=$true        
        }        
    }
    return $bReturn        
}        ##End of Get-Registry function
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

}     ##End of Get-PendingReboot
#endregion
# --------------------------------------------------------------------------------------------

# --------------------------------------------------------------------------------------------
#region VARIABLES

# Standard Variables
    # *****  Change Logging Path and File Name Here  *****
    $sLogContext	= "System" 		# System / User 
    $sLogFolder		= "WindowsUpdate"	# Folder Name
    $sOutFileName	= "Manage-Net47Upgrade 1.0.log" # Log File Name
    $sEventIDSource = "WDS-Script" # Source to be used in EventViewer Log creation    
    $sRights = "Administrator" # Rights required to run this script 
            <# ValueOptions: 
                "AccountOperator","Administrator","BackupOperator",
                "Guest","PowerUser","PrintOperator","Replicator",
                "SystemOperator","User" #>
    # ****************************************************
    $sScriptName 	= $MyInvocation.MyCommand
    $sScriptPath 	= Split-Path -Parent $MyInvocation.MyCommand.Path
    $sOSBit			= Get-OSArchitecture    
    $bIsVM			= Check-VM
    $sOSVersion		= Get-OSVersion    
    $bIs64bit		= $sOSBit -eq "64-bit"
    $sSysType       = Get-SystemType 
    $bIsOnVPN		= Check-VPN
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
      
#endregion 
# --------------------------------------------------------------------------------------------

# --------------------------------------------------------------------------------------------
#region MAIN_SUB

Function MainSub{
# ===============================================================================================================================================================================
#region 1_PRE-CHECKS    
    Write-Log -sMessage "Starting 1 - Pre-Checks." -iTabs 1                     
    #region 1.1: "-FORCE": Disables error handling       
        If ($force){
            Write-Log -sMessage "(1) - Script running with `"-Force`" parameter. Pre-checks will run, but will not terminate script. Script might not return expected result.Proceeding..." -iTabs 2                                        
        }
        else{
            Write-Log -sMessage "(1) - Script not running with `"-Force`" parameter. Pre-checks will run and will terminate script if necessary. Proceeding..." -iTabs 2                
        }
    #endregion
    #region 1.2: Checking if script is running with Role defined by $sRights. If not, exit
        $bUserRights = Check-Credentials -sRole $sRights
        if (!$bUserRights){
            Write-Log -sMessage "(2) - $sScriptName not running with $sRights" -iTabs 2                      
            $global:iExitCode = 9002
            If (!$force){return  $global:iExitCode}
        }
        else{
            Write-Log -sMessage "(2) - $sScriptName running with $sRights rights. Proceeding..." -iTabs 2                
        }
    #endregion
    #region 1.3: Checking if Machine is pending reboot. 
        $bRebootState = Get-PendingReboot   
        If ($bRebootState.RebootPending){
            Write-Log -sMessage "(3) - Machine $env:computername is pending reboot. Proceeding..." -iTabs 2            
            #$global:iExitCode = 9003
            #If (!$force){return  $global:iExitCode}
        }
        else{
            Write-Log -sMessage "(3) - Machine $env:computername is not pending reboot. Proceeding..." -iTabs 2                
        }
    #endregion
    #region 1.4: Checking for Installed .NET Version. 
        #Checking for .NET Versions until .NET 4
            #ToBeImplemented
        #Checking for .NET Versions after 4.5
            $netBuild = Get-ChildItem "HKLM:SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full\" | Get-ItemPropertyValue -Name Release         
            if ($netBuild -ge 461308){
                Write-Log -sMessage "(4) - .NET Version Detected: 4.7.1" -iTabs 2            
                $sNetVer = "4.7.1"
            }
            elseif($netBuild -ge 460798){
                Write-Log -sMessage "(4) - .NET Version Detected: 4.7" -iTabs 2            
                $sNetVer = "4.7"
            }
            elseif($netBuild -ge 394802){
                Write-Log -sMessage "(4) - .NET Version Detected: 4.6.2" -iTabs 2            
                $sNetVer = "4.6.2"
            }
            elseif($netBuild -ge 394254){
                Write-Log -sMessage "(4) - .NET Version Detected: 4.6.1" -iTabs 2            
                $sNetVer = "4.6.1"
            }
            elseif($netBuild -ge 393295){
                Write-Log -sMessage "(4) - .NET Version Detected: 4.6" -iTabs 2            
                $sNetVer = "4.6"
            }
            elseif($netBuild -ge 379893){
                Write-Log -sMessage "(4) - .NET Version Detected: 4.5.2" -iTabs 2            
                $sNetVer = "4.5.2"
            }
            elseif($netBuild -ge 378675){
                Write-Log -sMessage "(4) - .NET Version Detected: 4.5.1" -iTabs 2            
                $sNetVer = "4.5.1"
            }
            elseif($netBuild -ge 378389){
                Write-Log -sMessage "(4) - .NET Version Detected: 4.5" -iTabs 2            
                $sNetVer = "4.5"
            }
            else{
                Write-Log -sMessage "(4) - .NET Version Detected: Older than 4.5" -iTabs 2            
                $sNetVer = "Other"
            }               
    #endregion
    #region 1.5: Checking for exisintg Registry to manage .NET Upgrade 
        #Check if REG HKLM SOFTWARE\Microsoft\NET Framework Setup\NDP\WU exists
        $sNetPath = 'HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\WU\' 
        $bNetKey = Get-Registry -sRegKey $sNetPath          
        if (!$bNetKey) { # If it doesnt exist
            Write-Log -sMessage "(5) - Keys for managing .NET Upgrade were not found. Machine is able to upgrade .NET from Windows Update/WSUS normally." -iTabs 2
        }
        elseif ($bNetKey) { 
            Write-Log -sMessage "(5) - Keys for managing .NET Upgrade were found. Checking which versions are blocked..." -iTabs 2
            $key = Get-Item $sNetPath
            $Property = @{Name = 'Property';Expression = {$_}}
            $Value = @{Name = 'Value';Expression = {$key.GetValue($_)}}
            $ValueType = @{Name = 'ValueType'; Expression = {$key.GetValueKind($_)}}
            $aNetValues = $key.Property | select $Property, $value, $ValueType
            $bUpNet471,$bUpNet47,$bUpNet462,$bUpNet461,$bUpNet46,$bUpNet452,$bUpNet451,$bUpNet45 = $true #Means all versons are able to upgrade
            #Going into Key            
            foreach ($reg in $aNetValues){                                               
                SWITCH ($($reg.Property)){
                    "BlockNetFramework471"{                        
                        if ($($reg.value) -eq "1"){
                            Write-Log -sMessage "(5.1) - Upgrade to .NET 4.7.1 is blocked" -iTabs 3
                            $bUpNet471 = $true
                        }
                    }
                    "BlockNetFramework47"{            
                        if ($($reg.value) -eq "1"){            
                            Write-Log -sMessage "(5.1) - Upgrade to .NET 4.7 is blocked" -iTabs 3
                            $bUpNet47 = $true
                        }
                    }
                    "BlockNetFramework462"{                        
                        if ($($reg.value) -eq "1"){
                            Write-Log -sMessage "(5.1) - Upgrade to .NET 4.6.2 is blocked" -iTabs 3
                            $bUpNet462 = $true
                        }
                    }
                    "BlockNetFramework461"{                        
                        if ($($reg.value) -eq "1"){
                            Write-Log -sMessage "(5.1) - Upgrade to .NET 4.6.1 is blocked" -iTabs 3
                            $bUpNet461 = $true
                        }
                    }
                    "BlockNetFramework46"{                        
                        if ($($reg.value) -eq "1"){
                            Write-Log -sMessage "(5.1) - Upgrade to .NET 4.6 is blocked" -iTabs 3
                            $bUpNet46 = $true
                        }
                    }
                    "BlockNetFramework452"{                        
                        if ($($reg.value) -eq "1"){
                            Write-Log -sMessage "(5.1) - Upgrade to .NET 4.5.2 is blocked" -iTabs 3
                            $bUpNet452 = $true
                        }
                    }
                    "BlockNetFramework451"{                        
                        if ($($reg.value) -eq "1"){
                            Write-Log -sMessage "(5.1) - Upgrade to .NET 4.5.1 is blocked" -iTabs 3
                            $bUpNet451 = $true
                        }
                    }
                    "BlockNetFramework45"{                        
                        if ($($reg.value) -eq "1"){
                            Write-Log -sMessage "(5.1) - Upgrade to .NET 4.5 is blocked" -iTabs 3
                            $bUpNet45 = $true
                        }
                    }
                    default{
                        if ($($reg.value) -eq "1"){
                            Write-Log -sMessage "(5.1) - RegKey not coded in this script" -iTabs 3
                        }
                    }
                }
            }
            
        }
    #endregion          
    #endregion      
    Write-Log -sMessage "Completed Pre-Checks." -iTabs 1  
    Write-Log -sMessage "" -iTabs 0                  
#endregion
# ===============================================================================================================================================================================

# ===============================================================================================================================================================================
#region 2_EXECUTION
    Write-Log -sMessage "Starting 2 - Execution." -iTabs 1           
    
        #If action is check, execution block will be skipped
        if ($Action -eq "Check" ){
            Write-Log -sMessage "CHECK parameter was found. Script will skip Execution block. No changes will be made. Proceeding..." -iTabs 2            
        }
        #Starting Actions and Remediations
        elseif ($Action -eq "Run"){
            Write-Log -sMessage "RUN parameter was found. Script will execute remediations if indicators were found. Proceeding..." -iTabs 2               
            if($Setting -eq "None"){                 
                Write-Log -sMessage "SETTING: NONE." -iTabs 3               
                Write-Log -sMessage "No action to RUN as no setting found in Script parameter." -iTabs 3               
                Write-Log -sMessage "!!!Script Usage!!!To run script:" -iTabs 2
                HowTo-Script                   
                $global:iExitCode = 9001
            }
            elseif($Setting -eq "All") {
                Write-Log -sMessage "SETTING: ALL." -iTabs 3               
                Write-Log -sMessage "All script actions will RUN as ALL setting found in Script parameter." -iTabs 3               
            }
            if (($Setting -eq "All") -or ($Setting -eq "BlockNet47Update")) {
                Write-Log -sMessage "SETTING: BLOCK .NET 4.7/4.7.1 UPGRADE." -iTabs 3               
                Write-Log -sMessage "Script will add keys to prevent .NET Upgrade to 4.7 and 4.7.1." -iTabs 3               
                if(($bUpNet471) -and ($bUpNet47) -and ($bNetKey)){
                    Write-Log -sMessage "Machine is already set to block upgrade to .NET 4.7/4.7.1. No action to be done." -iTabs 3               
                }
                else{                    
                        $buffer = Set-Registry -sRegKeyName $sNetPath -sRegValueName "BlockNetFramework471" -sType DWord -value 1
                        if ($buffer){
                            Write-Log -sMessage "Key $sNetPath BlockNetFramework471 Value 1 created" -iTabs 3               
                        }
                        else{
                            Write-Log -sMessage "Error creating Key $sNetPath BlockNetFramework471" -iTabs 3     
                        }          
                        $buffer = Set-Registry -sRegKeyName $sNetPath -sRegValueName "BlockNetFramework47" -sType DWord -value 1
                        if ($buffer){
                            Write-Log -sMessage "Key $sNetPath BlockNetFramework47 Value 1 created" -iTabs 3               
                        }
                        else{
                            Write-Log -sMessage "Error creating Key $sNetPath BlockNetFramework47" -iTabs 3     
                        } 
                                        
                }
            }
            if (($Setting -eq "All") -or ($Setting -eq "AllowNet47Update")) {                 
                Write-Log -sMessage "SETTING: ALLOW .NET 4.7/4.7.1 UPGRADE." -iTabs 3               
                Write-Log -sMessage "Script will remove, if found, keys that prevent .NET Upgrade to 4.7 and 4.7.1." -iTabs 3               
                if((!$bUpNet471) -and (!$bUpNet47) -and ($bNetKey)){
                    Write-Log -sMessage "Machine is already set to allow upgrade to .NET 4.7/4.7.1. No action to be done." -iTabs 3               
                }
                else{    
                    Remove-Item $sNetPath
                }
            }                
        }      
    #endregion
    #region 2.2: Code Block for wrong script usage
        else{
            Write-Log -sMessage "!!!Script Usage!!!To run script:" -iTabs 2
            HowTo-Script                   
            $global:iExitCode = 9001
        }        
    #endregion
    Write-Log -sMessage "Completed Execution." -iTabs 1  
    Write-Log -sMessage "" -iTabs 0    
#endregion
# ===============================================================================================================================================================================
        
# ===============================================================================================================================================================================
#region 3_POST-CHECKS
# ===============================================================================================================================================================================
    Write-Log -sMessage "Starting 3 - Post-Checks." -iTabs 1      
    if ($action -eq "Run"){ 
        if ($Setting -eq "All"){
            Write-Log -sMessage "Skipping POST CHECKS due to ALL setting" -iTabs 2
        }
        else{
            #Check if REG HKLM SOFTWARE\Microsoft\NET Framework Setup\NDP\WU exists
            $sNetPath = 'HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\WU\' 
            $bNetKey = Get-Registry -sRegKey $sNetPath                      
            if ($bNetKey) { # If key is found                
                Write-Log -sMessage "Keys for blocking .NET Upgrade were found." -iTabs 2
                #Going into Key
                $key = Get-Item $sNetPath
                $Property = @{Name = 'Property';Expression = {$_}}
                $Value = @{Name = 'Value';Expression = {$key.GetValue($_)}}
                $ValueType = @{Name = 'ValueType'; Expression = {$key.GetValueKind($_)}}
                $aNetValues = $key.Property | select $Property, $value, $ValueType
                $bUpNet471,$bUpNet47,$bUpNet462,$bUpNet461,$bUpNet46,$bUpNet452,$bUpNet451,$bUpNet45 = $true 
                foreach ($reg in $aNetValues){                                                               
                    SWITCH ($($reg.Property)){
                        "BlockNetFramework471"{                        
                            if ($($reg.value) -eq "1"){
                                Write-Log -sMessage "Upgrade to .NET 4.7.1 is blocked" -iTabs 3
                                $bUpNet471 = $true
                            }
                        }
                        "BlockNetFramework47"{            
                            if ($($reg.value) -eq "1"){            
                                Write-Log -sMessage "Upgrade to .NET 4.7 is blocked" -iTabs 3
                                $bUpNet47 = $true
                            }
                        }
                        "BlockNetFramework462"{                        
                            if ($($reg.value) -eq "1"){
                                Write-Log -sMessage "Upgrade to .NET 4.6.2 is blocked" -iTabs 3
                                $bUpNet462 = $true
                            }
                        }
                        "BlockNetFramework461"{                        
                            if ($($reg.value) -eq "1"){
                                Write-Log -sMessage "Upgrade to .NET 4.6.1 is blocked" -iTabs 3
                                $bUpNet461 = $true
                            }
                        }
                        "BlockNetFramework46"{                        
                            if ($($reg.value) -eq "1"){
                                Write-Log -sMessage "Upgrade to .NET 4.6 is blocked" -iTabs 3
                                $bUpNet46 = $true
                            }
                        }
                        "BlockNetFramework452"{                        
                            if ($($reg.value) -eq "1"){
                                Write-Log -sMessage "Upgrade to .NET 4.5.2 is blocked" -iTabs 3
                                $bUpNet452 = $true
                            }
                        }
                        "BlockNetFramework451"{                        
                            if ($($reg.value) -eq "1"){
                                Write-Log -sMessage "Upgrade to .NET 4.5.1 is blocked" -iTabs 3
                                $bUpNet451 = $true
                            }
                        }
                        "BlockNetFramework45"{                        
                            if ($($reg.value) -eq "1"){
                                Write-Log -sMessage "Upgrade to .NET 4.5 is blocked" -iTabs 3
                                $bUpNet45 = $true
                            }
                        }
                        default{
                            if ($($reg.value) -eq "1"){
                                Write-Log -sMessage "RegKey not coded in this script" -iTabs 3
                            }
                        }
                    }
                }
                if (($Setting -eq "BlockNet47Update") -and $bUpNet471 -and $bUpNet47){
                    Write-Log -sMessage "Script Completed Successfully!" -iTabs 2
                    $global:iExitCode = 0
                }
                else{
                    Write-Log -sMessage "Script Failed" -iTabs 2
                    $global:iExitCode = 9002
                }
            }
            else{
                Write-Log -sMessage "Keys for blocking .NET Upgrade were not found." -iTabs 2
                if ($Setting -eq "AllowNet47Update"){
                    Write-Log -sMessage "Script Completed Successfully!" -iTabs 2
                    $global:iExitCode = 0
                }
                else{
                    Write-Log -sMessage "Script Failed" -iTabs 2
                    $global:iExitCode = 9002
                }
            }            
        }       
    }
    else{
        Write-Log -sMessage "POS-Check will not run since Script has not performed any remediation." -iTabs 2  
    }    
    Write-Log -sMessage "Completed Post-Checks." -iTabs 1  
    Write-Log -sMessage "" -iTabs 0
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
        If($DebugLog) {
            Write-Log -sMessage "DebugLog Param Found. Script is complete. Hit any Key to continue." -iTabs 1        
            pause
        }
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