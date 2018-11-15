param( 
    [switch]$DebugLog=$false, 
    [switch]$NoRelaunch=$False, 
    [string]$ComputerName=$sMachineName,
    [ValidateSet("Check","Run")][string]$Behavior="Check",
    [switch]$Push=$false,
    [switch]$Force=$false,
    [ValidateSet("AddCBException","RemoveCBException","None")][string]$Action="None"    
)
# --------------------------------------------------------------------------------------------
#region HEADER
$SCRIPT_TITLE = "Manage-XomFacts"
$SCRIPT_VERSION = "1.0"

$ErrorActionPreference 	= "Continue"	# SilentlyContinue / Stop / Continue

# -Script Name: Manage-XomFacts.ps1------------------------------------------------------ 
# Version: 1.0
# Based on PS Template Script Version: 1.0
# Author: Jose Varandas
# Owned By: WDS OS Engineering
# Purpose: Change content of Xom_Facts puppet file
#
# Created:  7/25/2017
#
# Dependencies: 
#                Script must be run with administrative rights
#                If excecuted remotely, ID must have permission to execute remotely and admin rights in remote machine
#
# Known Issues: None
#
# Arguments: 
Function HowTo-Script(){
    Write-Log -sMessage "----------------------------------------------------------------------------------------------------------------------------" -iTabs 1            
    Write-Log -sMessage "NAME:" -iTabs 1
        Write-Log -sMessage ".\$sScriptName " -iTabs 2     
    Write-Log -sMessage "----------------------------------------------------------------------------------------------------------------------------" -iTabs 1            
    Write-Log -sMessage "ARGUMENTS:" -iTabs 1
            Write-Log -sMessage "-DebugLog ($false(Default)/$true) - Enables debug logging in the script, and disables default On Error Resume Next statements" -iTabs 3        
	        Write-Log -sMessage "-Force ($false(Default)/$true) - Skips requirement checks. Script might return unexpected result" -iTabs 3        
            Write-Log -sMessage "-Push ($false(Default)/$true) - Hides User Interface" -iTabs 3        
            Write-Log -sMessage "-ComputerName (localhost(Default)/Serverlist in CSV) - Hides User Interface" -iTabs 3        
            Write-Log -sMessage "-Behavior (Check/Action) -> Defines Script Execution Mode" -iTabs 3        
                Write-Log -sMessage "-> Check (Default)-> Script will run Pre-checks and Pos-Checks. No Exceution" -iTabs 4        
                Write-Log -sMessage "-> Run -> Runs script (Pre-Checks,Excecution,Post-Checks)" -iTabs 4        
            Write-Log -sMessage "-Action -> Sets script scope" -iTabs 3        
                Write-Log -sMessage "-> None (Default)-> No action to be done. General Health Check" -iTabs 4        
                #Write-Log -sMessage "-> All -> All errors covered in this script will be checked/remediated" -iTabs 4        
                Write-Log -sMessage "-> AddCBException -> Adds line in xom_facts, inserting server into CB Exception for Puppet" -iTabs 4    
                Write-Log -sMessage "-> RemoveCBException -> Removes line in xom_facts, removing server into CB Exception for Puppet" -iTabs 4    
    Write-Log -sMessage "----------------------------------------------------------------------------------------------------------------------------" -iTabs 1            
    Write-Log -sMessage "EXAMPLE:" -iTabs 1
        Write-Log -sMessage ".\$sScriptName -Behavior Check" -iTabs 2     
            Write-Log -sMessage "Script will run all Pre-Checks. No Changes will happen to the device. *Action* Argument not used with `"Action Check`"" -iTabs 3     
        Write-Log -sMessage ".\$sScriptName -Behavior Run -Action AddCBException -ComputerName c:\temp\serverlist.txt" -iTabs 2     
            Write-Log -sMessage "Script will read xom_fact files and if CB Exception entry is not found, specific line will be added to file." -iTabs 3  
    Write-Log -sMessage "----------------------------------------------------------------------------------------------------------------------------" -iTabs 1            
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
#            5001 - Unable to confirm Script executed as intended            
#
#            8XXX - INFORMATION           
#
#            9XXX - ERROR
#            9001 - Device not valid for this script
#            9002 - XomFacts file not found
#            9003 - Computer not responsing to ICMPv4
#            9004 - SrvList not found
#			 9999 - Script completed unsuccessfully, throwing an unhandled error
# 
# Output: C:\XOM\Logs\System\Puppet\Manage_XomFacts.log
#    
# Revision History: (Date, Author, Description)
#		(Date 2018-06-25)
#			v1.0
#			Jose Varandas
#           CHANGELOG:
#               Script Created
#		
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
    $OSArchitecture = Get-WMIObject -class "Win32_OperatingSystem" -computername $computer
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
   $CompConfig = Get-WmiObject Win32_ComputerSystem  -computername $computer
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
    $osRoles = Get-WmiObject Win32_ServerFeature  -computername $computer
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
	$version = Get-WMIObject -class "Win32_OperatingSystem"  -computername $computer -ErrorAction SilentlyContinue
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
	$sModel = Get-WMIObject -class "Win32_ComputerSystem" -computername $computer
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
	Write-Log -sMessage "Machine Name.....:$computer" -iTabs 1
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
    sleep 0.1
    $sContent = "||"+$(Get-Date -UFormat %Y-%m-%d_%H:%M:%S)+"|| "+$sTabs + $sMessage

    #Write contect to the file and if debug is on, to the console for troubleshooting
    Add-Content $sFileName -value  $sContent -ErrorAction SilentlyContinue
    IF (!$?){                
        #$global:iExitCode = 5001            
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
    Write-Log -sMessage "############################################################" -iTabs 0 
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
    If (($global:bIs32Bit -eq $false) -and ( $bAddToWow6432 -eq $true ))
    {
        Show-Debug "Entries should be added to WOW6432Node."
        $sRegWOWKeyName = $sRegKeyName.Replace("Software", "Software\Wow6432Node")
        
		SetRegistryValue -sRegKeyName $sRegWOWKeyName -sRegValueName $sRegValueName -sType $sType -value $value		
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
        }
        Else #No error
        {
            Show-Debug -sText "Entry successfully added to registry" -iTabs 1 
        }
    }
    Else #CheckRegistryKeys returned failure
    {
        Show-Debug -sText "Could not set registry value. Parent key(s) didn't exist." -iTabs 0 
    }
    
    Write-Log -sMessage "" -iTabs 0 

}        ##End of Set-Registry function
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

Function Set-EndOfLine {

# --------------------------------------------------------------------------------------------
# Function Set-EndOfLine

# Purpose: Change the line endings of a text file to: Windows (CR/LF), Unix (LF) or Mac (CR)
#          Requires PowerShell 3.0 or greater
# Parameters: 
#          -lineEnding: {mac|unix|win} 
#          -file: FullFilename
# Returns: 
#          $False = Key does not Exist
#          $value - Value for the key
# --------------------------------------------------------------------------------------------


    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$True,Position=1)]
        [ValidateSet("mac","unix","win")] 
        [string]$lineEnding,
        [Parameter(Mandatory=$True)]
        [string]$file
    )

    # Convert the friendly name into a PowerShell EOL character
    Switch ($lineEnding) {
        "mac"  { $eol="`r" }
        "unix" { $eol="`n" }
        "win"  { $eol="`r`n" }
    } 

    # Replace CR+LF with LF
    $text = [IO.File]::ReadAllText($file) -replace "`r`n", "`n"
    [IO.File]::WriteAllText($file, $text)

    # Replace CR with LF
    $text = [IO.File]::ReadAllText($file) -replace "`r", "`n"
    [IO.File]::WriteAllText($file, $text)

    #  At this point all line-endings should be LF.

    # Replace LF with intended EOL char
    if ($eol -ne "`n") {
      $text = [IO.File]::ReadAllText($file) -replace "`n", $eol
      [IO.File]::WriteAllText($file, $text)
    }
    return $true
}      ##End of Get-PendingReboot
#endregion
# --------------------------------------------------------------------------------------------

# --------------------------------------------------------------------------------------------
#region VARIABLES

# Standard Variables
    # *****  Change Logging Path and File Name Here  *****
    $sLogContext	= "System" 		# System / User 
    $sLogFolder		= "Puppet"	# Folder Name
    $sOutFileName	= "Manage-XomFacts.log" # Log File Name
    $sEventIDSource = "WDS-Script" # Source to be used in EventViewer Log creation    
    $sRights = "Administrator" # Rights required to run this script 
            <# ValueOptions: 
                "AccountOperator","Administrator","BackupOperator",
                "Guest","PowerUser","PrintOperator","Replicator",
                "SystemOperator","User" #>
    # ****************************************************
    $sScriptName 	= $MyInvocation.MyCommand
    $sScriptPath 	= Split-Path -Parent $MyInvocation.MyCommand.Path
    #$sOSBit			= Get-OSArchitecture    
    #$bIsVM			= Check-VM
    #$sOSVersion		= Get-OSVersion    
    #$bIs64bit		= $sOSBit -eq "64-bit"
    #$sSysType       = Get-SystemType 
    #$bIsOnVPN		= Check-VPN
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
        if (test-connection $computer -quiet -count 1){
            Write-Log -sMessage "(2) - Machine $computer is responding to ICMPv4. Proceeding..." -iTabs 2                              
        }
        else{
            Write-Log -sMessage "(2) - Machine $computer is not responding to ICMPv4. Proceeding..." -iTabs 2                
            $global:iExitCode = 9003
            Return $global:iExitCode
        }
    #endregion
    #region 1.3: Checking if Machine is WS2016. 
        $validDevice = $true<#
        $sysType = Get-SystemType
        $osVer = Get-OSVersion
        $validDevice = $false
        If ($sysType -eq "Server"){            
            if ($osver -like "10.*"){
                Write-Log -sMessage "(3) - Machine $env:computername is Windows Server 2016. Machine valid for this script. Proceeding..." -iTabs 2                        
                $validDevice = $true
            }
            else{
                Write-Log -sMessage "(3) - Machine $env:computername isn't Windows Server 2016. Machine not valid for this script. Proceeding..." -iTabs 2                        
                $validDevice = $false
                $global:iExitCode = 9001
                Return $global:iExitCode
            }
        }
        else{
            Write-Log -sMessage "(3) - Machine $env:computername isn't Windows Server 2016. Machine not valid for this script. Proceeding..." -iTabs 2                        
            $validDevice = $false                    
            $global:iExitCode = 9001
            Return $global:iExitCode
        }#>
    #endregion
    #region 1.4: Checking for XomFacts. 
        $xomFactsFile = $false
        $cbException = $false
        #building Path
        $factsPath = "\\"+$computer+"\c$\ProgramData\PuppetLabs\facter\facts.d\xom_facts.yaml"
        if (Test-Path $factsPath){
            Write-Log "(4.1) - Machine $env:computername has xom_facts file in expected location. Proceeding..." -iTabs 2                        
            $xomFactsFile = $true
            $file = Get-Content $factsPath            
            Write-Log "Printing File Content" -iTabs 3            
            foreach ($line in $file){                 
                Write-Log $line -iTabs 4           
                if ($line -eq "is_carbonblack_exclusion: true"){
                    Write-Log "(4.2) - Machine $env:computername has xom_facts file with CB Exception entry. Proceeding..." -iTabs 2                        
                    $cbException = $true
                }
            }
            if (!($cbException)){
                Write-Log "(4.2) - Machine $env:computername has xom_facts file without CB Exception entry. Proceeding..." -iTabs 2                        
            }
        }
        else{
            Write-Log "(4.1) - Machine $env:computername does not have xom_facts file in expected location. Proceeding..." -iTabs 2                        
            Write-Log "(4.2) - Machine $env:computername does not have xom_facts file. CB Exception not present. Proceeding..." -iTabs 2                        
            $xomFactsFile = $false
            $cbException = $false
            $global:iExitCode = 9002
            return $global:iExitCode
        }
    #endregion
    <#
    #region 1.5: Checking for XOMWindowsUpdate Remediation in Registry. 
        #Check if REG HKLM XOM\WindowsUpdate\ exists
        $sXWURPath = 'HKLM:\SOFTWARE\ExxonMobil\WindowsUpdate\' 
        $bXWURKey = Get-Registry -sRegKey $sXWURPath  
        # If it doesnt exist, create default keys and values     
        if (!$bXWURKey) { 
            #Write-Log -sMessage "(5) - Machine $env:computername has no traces of XOMWindowsUpdate Remediation. Creating..." -iTabs 2
            $bXWURKey = Create-Registry -sRegKey $sXWURPath 
            if ($bXWURKey){
                #Write-Log -sMessage "Created $sXWURPath..." -iTabs 3
                $buffer = New-ItemProperty -Path $sXWURPath -Name LastRun -Value $(Get-date -DisplayHint DateTime -Format yyyyMMddTHHmmssffff)
                $buffer = New-ItemProperty -Path $sXWURPath -Name CountRun -Value 0 -PropertyType dWORD
                $buffer = New-ItemProperty -Path $sXWURPath -Name CountCheck -Value 0 -PropertyType dWORD                
            }
            else {
                Write-Log -sMessage "Error while creating $sXWURPath..." -iTabs 3
                $global:iExitCode = 9005
                If (!$force){return  $global:iExitCode}
            }
        }
        elseif ($bXWURKey) { 
            Write-Log -sMessage "(5) - Machine $env:computername has traces of XOMWindowsUpdate Remediation. Collecting and presenting Information..." -iTabs 2
            $key = Get-Item $sXWURPath
            $Property = @{Name = 'Property';Expression = {$_}}
            $Value = @{Name = 'Value';Expression = {$key.GetValue($_)}}
            $ValueType = @{Name = 'ValueType'; Expression = {$key.GetValueKind($_)}}
            $mXWURValues = $key.Property | select $Property, $value, $ValueType
            #Error listing/control
            $Count0x80004005 = 'false' 
            $Count0x8007000E = 'false' 
            foreach ($reg in $mXWURValues){                                               
                SWITCH ($($reg.Property)){
                    "lastRun"{
                        $lastRun = $($reg.value)
                        Write-Log -sMessage "LastRun: $lastRun ($($reg.ValueType))" -iTabs 3
                    }
                    "countRun"{
                        $countRun = $($reg.value)
                        Write-Log -sMessage "CountRun: $countRun ($($reg.ValueType))" -iTabs 3
                    }
                    "countCheck"{
                        $countCheck = $($reg.value)
                        Write-Log -sMessage "CountCheck: $countCheck ($($reg.ValueType))" -iTabs 3
                    }
                    "Count0x80004005"{
                        $Count0x80004005 = $($reg.value)                        
                        Write-Log -sMessage "Count0x80004005: $Count0x80004005 ($($reg.ValueType))" -iTabs 3

                    }
                    "Count0x8007000E"{
                        $Count0x8007000E = $($reg.value)                        
                        Write-Log -sMessage "Count0x8007000E: $Count0x8007000E ($($reg.ValueType))" -iTabs 3

                    }
                    default{
                        Write-Log -sMessage "$($reg.Property) : $($reg.value)($($reg.ValueType))" -iTabs 3
                    }
                }
            }
            if($Count0x80004005 -eq 'false'){
                $buffer = New-ItemProperty -Path $sXWURPath -Name Count0x80004005 -Value 0 -PropertyType dWORD
                Write-Log -sMessage "Count0x80004005: 0 (dWORD)" -iTabs 3
            }
             if($Count0x8007000E -eq 'false'){
                $buffer = New-ItemProperty -Path $sXWURPath -Name Count0x8007000E -Value 0 -PropertyType dWORD
                Write-Log -sMessage "Count0x8007000E: 0 (dWORD)" -iTabs 3
            }
        }
    #endregion  
    #region 1.6: SCCM Logs/Cycles dates
        Write-Log -sMessage "(6) - Collecting file information." -iTabs 2
        #Get WUAUEng.dll Version
        try{
            $WUAUEngVer = ((Get-Item -Path C:\Windows\System32\wuaueng.dll).VersionInfo).ProductVersion
            Write-Log -sMessage "Windows Update Client Version.....: $WUAUEngVer" -iTabs 3                                            
        }
        catch{
            $WUAUEngVer = $false
            Write-Log -sMessage "Windows Update Client Version.....: Unable to Check" -iTabs 3                                            
        }
        #Get WUAHandler.log Last Modified Date
        try{
            $wuaHandlerlLastWrite = (Get-Item -Path C:\Windows\CCM\Logs\WuaHandler.log).LastWriteTime
            Write-Log -sMessage "WUAHandler.log Last Write.........: $wuaHandlerlLastWrite" -iTabs 3                                            
        }
        catch{
            $wuaHandlerlLastWrite = $false
            Write-Log -sMessage "WUAHandler.log Last Write.........: Unable to Check" -iTabs 3                                            
        }
        
        #Get Software Update Evaluation Cycle date
        try{
            $upDeploylLastWrite = (Get-Item -Path C:\Windows\CCM\Logs\UpdatesDeployment.log).LastWriteTime
            Write-Log -sMessage "UpdatesDeployment.log Last Write..: $upDeploylLastWrite" -iTabs 3  
        }
        catch{            
            $upDeploylLastWrite = $false
            Write-Log -sMessage "UpdatesDeployment.log Last Write..: Unable to Check" -iTabs 3                                            
        }
        #get WindowsUpdatelog date
        if($sOSVersion.StartsWith('10')){
            Write-Log -sMessage "WindowsUpdate.log Last Write......: Unable to Check. OS is Win10." -iTabs 3  
        }
        else{
            try{
                $wuLogLastWrite = (Get-Item -Path C:\Windows\WindowsUpdate.log).LastWriteTime
                Write-Log -sMessage "WindowsUpdate.log Last Write......: $wuLogLastWrite" -iTabs 3  
            }
            catch{
                $wuLogLastWrite = $false
                Write-Log -sMessage "WindowsUpdate.log Last Write......: Unable to Check" -iTabs 3                                            
            }
        }
    #endregion
    #>
    Write-Log -sMessage "Completed 1 - Pre-Checks." -iTabs 1  
    Write-Log -sMessage "============================================================" -iTabs 0    
#endregion
# ===============================================================================================================================================================================

# ===============================================================================================================================================================================
#region 2_EXECUTION
    Write-Log -sMessage "Starting 2 - Execution." -iTabs 1               
        #If behavior is check, execution block will be skipped
        if ($Behavior -eq "Check"){
            Write-Log -sMessage "CHECK parameter was found. Script will skip Execution block. No changes will be made. Proceeding..." -iTabs 2            
        }
        elseif (!($xomFactsFile)){
            Write-Log -sMessage "xom_fact files not found. Excecution block will be skipped. Proceeding..." -iTabs 2            
        }
        #Starting Actions
        elseif (($Behavior -eq "Run" ) -and ($Action -ne "None")){
            Write-Log -sMessage "RUN parameter was found. Script will execute actions if indicators were found. Proceeding..." -iTabs 2   
            if ($Action -eq "AddCBException"){               
                if (!($cbException)){
                    Add-Content -Value "is_carbonblack_exclusion: true" -Path $factsPath  
                    Write-Log -sMessage "Added Entry for CarbonBlack exception in $factsPath. Proceeding..." -iTabs 2                              
                }
                else{
                    Write-Log -sMessage "CarbonBlack exception entry already found in $factsPath. Proceeding..." -iTabs 2                              
                }               
            } 
            if ($Action -eq "RemoveCBException"){               
                if ($cbException){
                    foreach ($line in $file){
                        if (!($line -eq "is_carbonblack_exclusion: true")){
                            Add-Content -Value $line -Path $factsPath                              
                        }
                    }
                    Write-Log -sMessage "Removed Entry for CarbonBlack exception in $factsPath. Proceeding..." -iTabs 2                              
                }
                else{
                    Write-Log -sMessage "CarbonBlack exception entry is not presentin $factsPath. No action required. Proceeding..." -iTabs 2                              
                }            
            }           
        }        
    
    #region 2.2: Code Block for wrong script usage
        else{
            Write-Log -sMessage "!!!Script Usage!!!To run script:" -iTabs 2
            HowTo-Script                   
            $global:iExitCode = 9001
        }        
    #endregion
    Write-Log -sMessage "Completed Execution." -iTabs 1  
    Write-Log -sMessage "============================================================" -iTabs 0     
#endregion
# ===============================================================================================================================================================================
        
# ===============================================================================================================================================================================
#region 3_POST-CHECKS
# ===============================================================================================================================================================================
    Write-Log -sMessage "Starting 3 - Post-Checks." -iTabs 1      
    if ($Behavior -eq "Run"){ 
        $cbException = $false
        #Setting End of Line
        try{
            Set-EndOfLine -lineEnding Win -file $factsPath
            Write-Log "Set facts end of Line compatible with Windows (CR+LF)"
        }
        catch {
            Write-Log "Error trying to properly set End of Line" -iTabs 2
        }
        $file = Get-Content $factsPath
        foreach ($line in $file){
            if ($line -eq "is_carbonblack_exclusion: true"){         
                $cbException = $true
            }
        }          
        if ((($Action -eq "AddCBException") -and $cbException) -or (($Action -eq "RemoveCBException" -and !($cbException)))){   
              Write-Log -sMessage "Arguments and result are matching. Proceeding." -iTabs 2  
              $global:iExitCode = 0
        }
       
        else{
            Write-Log -sMessage "Arguments are not able to code intended action. POS-Checks will not run." -iTabs 2  
            $global:iExitCode = 5001
        }   
    }
    else{
        Write-Log -sMessage "POS-Check will not run since Script has not performed any actions." -iTabs 2  
        $global:iExitCode = 0
    }    
    Write-Log -sMessage "Completed Post-Checks." -iTabs 1  
    Write-Log -sMessage "============================================================" -iTabs 0    
#endregion
# ===============================================================================================================================================================================

} #End of MainSub

#endregion
# --------------------------------------------------------------------------------------------

# --------------------------------------------------------------------------------------------
#region MAIN_PROCESSING

If($DebugLog) { $ErrorActionPreference = "Continue" }

# Prior to logging, determine if we are in the 32-bit scripting host on a 64-bit machine and need and want to re-launch
If(!($NoRelaunch) -and $bIs64bit -and ($PSHOME -match "SysWOW64") -and $bAllow64bitRelaunch) {
    Relaunch-In64
}
Else {
    # Starting the log
    Start-Log
    Try {
        try{
            $srvlist = Get-Content $ComputerName
        }
        catch{
            $global:iExitCode = 9004
        }
        foreach ($computer in $srvlist){            
                MainSub
                If($DebugLog) {}            
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
    #if ($global:iExitCode -le 8999){$global:iExitCode = 0}
}
# Quiting with exit code
Exit $global:iExitCode
#endregion