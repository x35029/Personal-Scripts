param(

    [switch]$DebugLog,

    [switch]$NoRelaunch,

    [ValidateSet("Install","Uninstall","Clean")][string]$Action,

    [switch]$Push,

    [switch]$Force,

    [ValidateSet("CAS","CS2","PP1","LTS")][string]$sccmSite

)

 

$SCRIPT_TITLE = "SCCM Console Install"

$SCRIPT_VERSION = "2.0"

 

#Set default behavior if an error occurs. this should be set to "SilentlyContinue" for deployment, but can be changed for testing.

$ErrorActionPreference                = "SilentlyContinue"       # SilentlyContinue / Stop / Continue

 

# -Script Name: SCCMConsoleInstall.ps1------------------------------------------------------

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

# Purpose: Install SCCM Console

#

# Created:  12/26/2016

#

# Dependencies:

#                Script must be run with administrative rights

#                .NET must be installed:

#                         Win7/Win2008R2   -> .NET 4 or higher

#                         Win8.1/Win2012R2 -> .NET 4.5 or higher

#                         Win10/Win2016    -> .NET 4.6 or higher

#

# Known Issues: None

#

# Arguments:

#                             -debug - Enables debug logging in the script, and disables default On Error Resume Next statements

#                 -force - Skips requirement checks. Software might not work after install                                                                             

#       -push  - hides all user prompts

#       -install/uninstall/clean ->

#           install -> Installs SCCM Console

#           uninstall -> Uninstalls SCCM Console

#           clean -> Removes any SCCM Console

#       -sccmSite -> Defines default site for console launch

#

# Exit Codes:

#            0 - Script completed successfully

#

#            3xxx - SUCCESS

#            3001 - SCCM Console Installed with success

#            3002 - SCCM Console Uninstalled with success

#            3003 - Old SCCM Console Uninstalled with success

#

#            5xxx - WARNING

#            5001 - Unable to update LogFile

#            5002 - Unable to update EventLog

#            5003 - Script is running without Error Handling

#            5004 - Missing MSI

#

#            8XXX - INFORMATION

#            8001 - Information Only

#            8002 - Script Start

#            8003 - Script End

#

#            9XXX - ERROR

#            9001 - Wrong Script Usage

#            9002 - Script not runnign with $sRights

#            9003 - Machine is pending reboot

#            9004 - WMI error

#            9005 - Platform not supported by this script

#            9006 - Missing Application Dependency

#            9007 - Missing MSI. Unable to install

#            9008 - Error installing SCCM Console

#            9010 - Error uninstalling SCCM Console

#            9009 - Error uninstalling old SCCM Console

#                                             9999 - Script completed unsuccessfully, throwing an unhandled error

#

# Output: C:\XOM\Logs\System\SCCM\Deployment\XXXXX - SCCMConsoleInstall.log

#   

# Revision History: (Date, Author, Description)

#                             (Date 2016-12-27

#                                             v1.0

#                                             Jose Varandas

#                                             TBD - [PACE-TS64] Complex SW -  System Center Configuration Manager Console

#                                                            

#                                                            

# --------------------------------------------------------------------------------------------

#>

 

# --------------------------------------------------------------------------------------------

# Subroutines and Functions

# --------------------------------------------------------------------------------------------

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

        [System.Version]$VersionToCheck,

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

                    IF (($_.DisplayName -eq "$soft") -and ($_.DisplayVersion -eq "$VersionToCheck")){

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

                Write-Log -sMessage "Is Windows 7.....:$bIsWin7" -iTabs 1

                Write-Log -sMessage "Is Windows 8.1...:$bIsWin81" -iTabs 1

                Write-Log -sMessage "Is Windows 10....:$bIsWin10" -iTabs 1

    Write-Log -sMessage "Is Windows 2003..:$bIsWin2K3" -iTabs 1

    Write-Log -sMessage "Is Windows 2008..:$bIsWin2K8" -iTabs 1

    Write-Log -sMessage "Is Windows 2008R2:$bIsWin2K8R2" -iTabs 1

    Write-Log -sMessage "Is Windows 2012..:$bIsWin2K12" -iTabs 1

    Write-Log -sMessage "Is Windows 2012R2:$bIsWin2K12R2" -iTabs 1

    Write-Log -sMessage "Is Windows 2016..:$bIsWin2K16" -iTabs 1

    Write-Log -sMessage "Is TerminalServer:$bIsTS" -iTabs 1          

    Write-Log -sMessage "Is RemoteDesktop.:$bIsRDS" -iTabs 1    

    Write-Log -sMessage "Is 64-bit OS.....:$bIs64bit" -iTabs 1   

                Write-Log -sMessage "Is VM............:$bIsVM" -iTabs 1

                Write-Log -sMessage "VPN Connected....:$bIsOnVPN" -iTabs 1

                Write-Log -sMessage "Log File.........:$sLogFile" -iTabs 1

                Write-Log -sMessage "Command Line.....:$sCMDArgs" -iTabs 1

                Write-Log -sMessage "Debug............:$DebugLog" -iTabs 1

    Write-Log -sMessage "Force Execution..:$Force" -iTabs 1

                Write-Log -sMessage "============================" -iTabs 0

    Write-Log -sMessage "" -iTabs 0                           

    Write-Log -sMessage "Starting to execute Script" -iTabs 0

    Write-Log -sMessage "" -iTabs 0

    Log-Event -sMessage "$SCRIPT_TITLE ($sScriptName) $SCRIPT_VERSION

                        Starting to execute Script

                        --------------------------

                        Script Title.....:$SCRIPT_TITLE

                                    Script Name......:$sScriptName

                                    Script Version...:$SCRIPT_VERSION

                                    Script Path......:$sScriptPath

                                    User Name........:$sUserDomain\$sUserName

                                    Machine Name.....:$sMachineName

                                    OS Version.......:$sOSVersion

                                    OS Architecture..:$sOSBit

                                    System Type......:$sSysType

                                    Is Windows 7.....:$bIsWin7

                                    Is Windows 8.1...:$bIsWin81

                                    Is Windows 10....:$bIsWin10

                                    Is Windows 2003..:$bIsWin2K3

                                    Is Windows 2008..:$bIsWin2K8

                                    Is Windows 2008R2:$bIsWin2K8R2

                                    Is Windows 2012..:$bIsWin2K12

                                    Is Windows 2012R2:$bIsWin2K12R2

                                    Is Windows 2016..:$bIsWin2K16

                                    Is TerminalServer:$bIsTS       

                                    Is RemoteDesktop.:$bIsRDS

                                    Is 64-bit OS.....:$bIs64bit   

                                    Is VM............:$bIsVM

                                    VPN Connected....:$bIsOnVPN

                                    Log File.........:$sLogFile

                                    Command Line.....:$sCMDArgs

                                    Debug............:$DebugLog

                                    Force Execution..:$Force" -iEventID 8002 -sEventLogType Information 

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

        $global:iExitCode = 5001           

    }

    Show-Debug $sContent

               

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

    Log-Event -sMessage "$SCRIPT_TITLE ($sScriptName) $SCRIPT_VERSION`n

                          `n

                          Script $sScriptName Completed at $(Get-date) with Exit Code $global:iExitCode" -iEventID 8003 -sEventLogType Information

    Write-Log -sMessage "" -iTabs 0

    Write-Log -sMessage "" -iTabs 0

    Write-Log -sMessage "" -iTabs 0

}             ##End of End-Log function

function Log-Event {

# --------------------------------------------------------------------------------------------

# Sub Name: Log-Event

 

# Purpose: Log information to machine's Event Viewer

# Variables: None

# --------------------------------------------------------------------------------------------

 

    param( [string]$sMessage="", [int]$iEventID=0, [ValidateSet("Error","Information","Warning")][string]$sEventLogType,[string]$sSource=$sEventIDSource)

    New-EventLog -LogName Application -Source $sSource -ErrorAction SilentlyContinue

    Write-EventLog -LogName Application -Source $sSource -EntryType $sEventLogType -EventId $iEventID -Message $sMessage -ErrorAction SilentlyContinue

}            ##End of Log-Event

Function Show-Debug(){

# --------------------------------------------------------------------------------------------

# Function Show-Debug

 

# Purpose: Allows you to show debug information

# Parameters:

#    sText - Text to display as debug

#    iTabs - number of tabs to indent the text

# Returns: none

# --------------------------------------------------------------------------------------------

    param( [string]$sText="", [int]$iTabs=0 )

    

    if ($DebugLog -eq $true) {Write-Host  $sText}

 

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

    If (!(Test-Path -Path $sRegKey))

    {

        #If key doesn't exist, get parent key and check to see if it exists and create if necessary

        $sParent = Split-Path $sRegKey

        #Check to see if the parent was a "null" value

        If ($sParent -ne $null)

        {

            $bReturn = Create-Registry -sRegKey $sParent

        }

        #after all parent keys have been processed, create key

        #Check to see if the function returned a success

        if ($bReturn)

        {

            New-Item -path $sRegKey

            Show-Debug "$sRegKey was created"

        }

        Else

        {

            Write-Log -sMessage "Error Creating Key: $error[0]" -iTabs 1

            Return $false

        }

    }

    Else

    {

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

    param(             [string]$sRegKeyName,

                                                [string]$sRegValueName,

                                                [ValidateSet("String","ExpandString","Binary","DWord","MultiString","QWord")]$sType="String",

                                                $value,

                                                [boolean]$bAddToWow6432=$false )

 

    #Check to see if we should update the WOW6432Node as well

    If (($global:bIs32Bit -eq $false) -and ( $bAddToWow6432 -eq $true ))

    {

        Write-Log -sMessage "Entries should be added to WOW6432Node." -iTabs 0

        $sRegWOWKeyName = $sRegKeyName.Replace("Software", "Software\Wow6432Node")

       

                                SetRegistryValue -sRegKeyName $sRegWOWKeyName -sRegValueName $sRegValueName -sType $sType -value $value                     

    }

       

    #Check to see if the Registy Key exists

    $bRegReturn = Create-Registry -sRegKey $sRegKeyName

   

                #If the registry keys exist or were created successfully

    If ($bRegReturn)

    {

        #Add registry keys

        Write-Log -sMessage "Updating Registry..." -iTabs 0            

        Write-Log -sMessage "Registry Key = $sRegKeyName" -iTabs 1

        Write-Log -sMessage "Registry Value Name = $sRegValueName" -iTabs 1

        Write-Log -sMessage "Registry Value Type = $sType" -iTabs 1

        Write-Log -sMessage "Registry Value = $value" -iTabs 1

        

        #Clear errors

        $error.Clear()

        Set-ItemProperty $sRegKeyName -name $sRegValueName -type $sType -value $value

                               

        #Check to see if an error occurred

        If (!($?))

        {

            Write-Log -sMessage "Error adding entry to registry: $error" -iTabs 1

        }

        Else #No error

        {

            Write-Log -sMessage "Entry successfully added to registry" -iTabs 1

        }

    }

    Else #CheckRegistryKeys returned failure

    {

        Write-Log -sMessage "Could not set registry value. Parent key(s) didn't exist." -iTabs 0

    }

   

    Write-Log -sMessage "" -iTabs 0

 

}        ##End of Set-Registry function

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

# --------------------------------------------------------------------------------------------

# End of FUNCTIONS

# --------------------------------------------------------------------------------------------

 

# --------------------------------------------------------------------------------------------

# Variable Declarations

# --------------------------------------------------------------------------------------------

    # Standard Variables

        # *****  Change Logging Path and File Name Here  *****

        $sLogContext           = "System"                          # System / User

        $sLogFolder                               = "SCCM\Deployment" # Folder Name

        $sOutFileName        = "XXXXX - SCCMConsole.log" # Log File Name

        $sEventIDSource = "WDS-Script" # Source to be used in EventViewer Log creation

        $sRights = "Administrator" # "AccountOperator","Administrator","BackupOperator","Guest","PowerUser","PrintOperator","Replicator","SystemOperator","User"

        # ****************************************************

        $sScriptName           = $MyInvocation.MyCommand

        $sScriptPath              = Split-Path -Parent $MyInvocation.MyCommand.Path

        $sOSBit                                        = Get-OSArchitecture

        $bIs64bit                     = $sOSBit -eq "64-bit"

        $bIsVM                                       = Check-VM

        $sOSVersion                             = Get-OSVersion

        $sSysType       = Get-SystemType      

        if ($sSysType -eq "Workstation") {

            $bIsWin7                                = $sOSVersion.StartsWith("6.1")

            $bIsWin8                                = $sOSVersion.StartsWith("6.2")

            $bIsWin81                              = $sOSVersion.StartsWith("6.3")

            $bIsWin10                              = $sOSVersion.StartsWith("10.")

            $bIsTS=$bIsRDS=$bIsWin2K3=$bIsWin2K8=$bIsWin2K8R2=$bIsWin2K12=$bIsWin2K12R2=$bIsWin2K16 = $false

        }

        elseif ($sSysType -eq "Server"){

            $bIsTS           = Get-OSRole("Terminal Services")

            $bIsRDS          = Get-OSRole("Remote-Desktop-Services")

            $bIsWin2K3      = $sOSVersion.StartsWith("5.")

            $bIsWin2K8      = $sOSVersion.StartsWith("6.0")

            $bIsWin2K8R2    = $sOSVersion.StartsWith("6.1")

            $bIsWin2K12                         = $sOSVersion.StartsWith("6.2")

            $bIsWin2K12R2    = $sOSVersion.StartsWith("6.3")

            $bIsWin2K16                         = $sOSVersion.StartsWith("10.")

            $bIsWin7=$bIsWin8=$bIsWin81=$bIsWin10=$false

        }

        else {     

            Write-Log -sMessage "$sScriptName not able to query WMI. Machine information is not reliable. Exiting script..." -iTabs 1

            Write-Log -sMessage "" -iTabs 0

            Log-Event -sMessage "$SCRIPT_TITLE ($sScriptName) $SCRIPT_VERSION

                                 $sScriptName not able to query WMI. Machine information is not reliable. Exiting script..." -iEventID 9004 -sEventLogType Error

            $global:iExitCode = 9004

            If (!$force){return  $global:iExitCode}       

        }

        $bIsOnVPN                = Check-VPN

        $sLogRoot                  = "C:\XOM\Logs"

        $sOutFilePath           = Join-Path -Path (Join-Path -Path $sLogRoot -ChildPath $sLogContext) -ChildPath $sLogFolder

        $sLogFile                     = Join-Path -Path $sOutFilePath -ChildPath $sOutFileName

        $global:iExitCode = 0

        $sUserName                             = $env:username

        $sUserDomain         = $env:userdomain

        $sMachineName     = $env:computername

        $sCMDArgs                = $MyInvocation.Line

        $bAllow64bitRelaunch = $true

        $iLogFileSize              = 1048576

    # Script Specific Variables

        $appName = "System Center Configuration Manager Console"

        #SCCM Sites for install command       

            switch ($sccmSite) {

                "CAS" {

                    $sccmSiteParam = " DefaultSiteServerName=DALCFG01.NA.XOM.COM"

                }

                "CS2" {

                    $sccmSiteParam = " DefaultSiteServerName=DALCFG03.NA.XOM.COM"

                }

                "PP1" {

                    $sccmSiteParam = " DefaultSiteServerName=DALCFG02.NA.XOM.COM"

                }

                "LTS" {

                   $sccmSiteParam = " DefaultSiteServerName=HOECFG50.NA.XOM.COM"

                }

                default {

                    $sccmSiteParam = ""

                }

            }

        #File Paths

            $msiPath = $sScriptPath+"\AdminConsole.msi"

# --------------------------------------------------------------------------------------------

# Main Sub

# --------------------------------------------------------------------------------------------

Function MainSub{

# ===============================================================================================================================================================================

# 1 - Pre-Checks

# ===============================================================================================================================================================================   

        # "-FORCE": Disables error handling

            Write-Log -sMessage "Starting Pre-Checks. 7 tests." -iTabs 1               

            Write-Log -sMessage "" -iTabs 0               

            If ($force){

                Write-Log -sMessage "(1/7) - Script running with `"-Force`" parameter. Pre-checks will run, but will not terminate script. Script might not return expected result.Proceeding..." -iTabs 1               

                Log-Event -sMessage "$SCRIPT_TITLE ($sScriptName) $SCRIPT_VERSION                         

                                    Force Execution.:$Force

                                    <<<< Script running with `"-Force`" parameters. Pre-checks will run, but will not terminate script. Script might not return expected result.>>>>" -iEventID 5003 -sEventLogType Warning           

                IF (!$?){

                    Write-Log -sMessage "Error writting to Event Viewer. No events will be recorded" -iTabs 1

                    Write-Log -sMessage "" -iTabs 0

                    $global:iExitCode = 5003

                }

            }

            else{

                Write-Log -sMessage "(1/7) - Script not running with `"-Force`" parameter. Pre-checks will run and will terminate script is necessary. Proceeding... (1/6)" -iTabs 1               

            }

        # Checking if script is running with Role defined by $sRights. If not, exit

            $bUserRights = Check-Credentials -sRole $sRights

            if (!$bUserRights){

                Write-Log -sMessage "(2/7) - $sScriptName not running with $sRights" -iTabs 1

                Write-Log -sMessage "" -iTabs 0

                Log-Event -sMessage "$SCRIPT_TITLE ($sScriptName) $SCRIPT_VERSION

                                        $sScriptName not running with $sRights." -iEventID 9002 -sEventLogType Error

                $global:iExitCode = 9002

                If (!$force){return  $global:iExitCode}

            }

            else{

                Write-Log -sMessage "(2/7) - $sScriptName running with $sRights rights. Proceeding..." -iTabs 1               

            }

        # Checking if Machine is pending reboot. If yes, exit

            $bRebootState = Get-PendingReboot  

            If ($bRebootState.RebootPending){

                Write-Log -sMessage "(3/7) - Machine $env:computername is pending reboot. Running script again at a later time." -iTabs 1

                Write-Log -sMessage "" -iTabs 0 

                Log-Event -sMessage "$SCRIPT_TITLE ($sScriptName) $SCRIPT_VERSION

                                        $env:computername is pending reboot. Running script again at a later time." -iEventID 9003 -sEventLogType Error

                $global:iExitCode = 9003

                If (!$force){return  $global:iExitCode}

            }

            else{

                Write-Log -sMessage "(3/7) - Machine $env:computername is not pending reboot. Proceeding..." -iTabs 1               

            }

        # Checking Machine OS, Arch or any other requirement. If fail, exit

            $bAppDep = $false

            if (($bIsWin7) -or (($bIsWin2K8R2) -and ($bIsRDS) -and ($bIs64bit))){

                $netVer = [Version]"4.0"

                $testAppDep = $true               

            }

            elseif ((($bIsWin81) -and ($bIs64bit)) -or (($bIsWin2K12R2) -and ($bIsRDS))){

                $netVer = [Version]"4.5"               

                $testAppDep = $true

            }

            elseif ((($bIsWin10) -and ($bIs64bit)) -or (($bIsWin2K16) -and ($bIsRDS))){

                $netVer = [Version]"4.6"

                $testAppDep = $true              

            }

            else{

                Write-Log -sMessage "(4/7) - Machine $env:computername does not meet the platform requirement for this script." -iTabs 1

                Write-Log -sMessage "This script was developed and tested for:" -iTabs 2

                Write-Log -sMessage "Windows 7 (x86 or x64) with .NET 4 installed" -iTabs 2

                Write-Log -sMessage "Windows 8.1 (x64) with .NET 4.5 installed" -iTabs 2

                Write-Log -sMessage "Windows 10 (x64) with .NET 4.6 installed" -iTabs 2

                Write-Log -sMessage "Windows Server 2008R2 (x64) with .NET 4 and Remote Desktop Services role installed" -iTabs 2

                Write-Log -sMessage "Windows Server 2012R2 (x64) with .NET 4.5 and Remote Desktop Services role installed" -iTabs 2

                Write-Log -sMessage "Windows Server 2016 (x64) with .NET 4.6 and Remote Desktop Services role installed" -iTabs 2           

                Log-Event -sMessage "$SCRIPT_TITLE ($sScriptName) $SCRIPT_VERSION

                                        Machine $env:computername does not meet the platform requirement for this script.

                                        This script was developed and tested for:

                                        Windows 7 (x86 or x64) with .NET 4 installed

                                        Windows 8.1 (x64) with .NET 4.5 installed

                                        Windows 10 (x64) with .NET 4.6 installed

                                        Windows Server 2008R2 (x64) with .NET 4 and Remote Desktop Services role installed

                                        Windows Server 2012R2 (x64) with .NET 4.5 and Remote Desktop Services role installed

                                        Windows Server 2016 (x64) with .NET 4.6 and Remote Desktop Services role installed" -iEventID 9005 -sEventLogType Error

                $global:iExitCode = 9005

                If (!$force){return  $global:iExitCode}

            }

            if ($testAppDep){

                Write-Log -sMessage "(4/7) - Machine $env:computername meets platform requirement. Proceeding..." -iTabs 1               

                $bAppDep = Check-NetFramework               

                if ($bAppDep[0].Product -lt $netver){

                   Write-Log -sMessage "(5/7) - Machine $env:computername does not meet the application dependency requirement." -iTabs 1

                    Write-Log -sMessage "Please have the proper .NET version installed:" -iTabs 1

                    Write-Log -sMessage "Windows 7 or Windows Server 2008R2: Microsoft .NET Framework 4 or higher" -iTabs 2

                    Write-Log -sMessage "Windows 8.1 or Windows Server 2012R2: Microsoft .NET Framework 4.5 or higher" -iTabs 2

                    Write-Log -sMessage "Windows 10 or Windows Server 2016: Microsoft .NET Framework 4.6 or higher" -iTabs 2

                    Log-Event -sMessage "$SCRIPT_TITLE ($sScriptName) $SCRIPT_VERSION

                                            Machine $env:computername does not meet the application dependency requirement.

                                            Please have the proper .NET version installed:

                                            Windows 7 or Windows Server 2008R2: Microsoft .NET Framework 4 or higher

                                            Windows 8.1 or Windows Server 2012R2: Microsoft .NET Framework 4.5 or higher

                                            Windows 10 or Windows Server 2016: Microsoft .NET Framework 4.6 or higher" -iEventID 9006 -sEventLogType Error

                    $global:iExitCode = 9006

                    If (!$force){return  $global:iExitCode}

                }

                else{

                    Write-Log -sMessage "(5/7) - Machine $env:computername meets application dependency requirement. Proceeding..." -iTabs 1               

                }

            }

            else{   

                Write-Log -sMessage "(4/7) - Application Dependency will not be checked due to Platform incompatibility." -iTabs 1               

            }

        # Checking if App is already installed           

            $chkApp = Check-App -SoftToCheck $appName -equalOrHigher           

            if ($chkApp -ne $false){                          

                $bAppInstalled = $true               

                $appVer = [Version]$chkApp[0].Version

                $appProductCode = $chkApp[0].ProductCode  

                $appUnString = $chkApp[0].UninstallString 

                Write-Log -sMessage "(6/7) - $appName was found installed." -iTabs 1                               

                Write-Log -sMessage "Name: $appName" -iTabs 2

                Write-Log -sMessage "Version: $appVer" -iTabs 2  

                Write-Log -sMessage "ProductCode: $appProductCode" -iTabs 2           

                Write-Log -sMessage "UninstallString: $appUnString" -iTabs 2  

            }

            else{

                    $bAppInstalled = $false

                    Write-Log -sMessage "(6/7) - SCCM Console was not found installed." -iTabs 1                               

                }

            if (($Uninstall) -and !($chkApp.MSIInstaller)){

                    Write-Log -sMessage "(6/7) - $sScriptName unable to remove SCCM Console Automatically." -iTabs 1

                    Write-Log -sMessage "Uninstall string was not found for SCCM Console currently installed." -iTabs 1

                    Write-Log -sMessage "" -iTabs 0

                    Log-Event -sMessage "$SCRIPT_TITLE ($sScriptName) $SCRIPT_VERSION

                                            $sScriptName unable to remove SCCM Console Automatically.

                                            Uninstall string was not found for SCCM Console currently installed." -iEventID 9009 -sEventLogType Error

                    $global:iExitCode = 9009

                    If (!$force){return  $global:iExitCode}

                }               

        # Checking new SCCM Console MSI Info

            if (Test-Path $msiPath){

                $newApp = Get-MSIInfo -Path $msiPath

                $newAppName = $($newApp.ProductName)

                $newAppVer = [version]$($newApp.ProductVersion)

                $newAppProductCode = $($newApp.ProductCode)

                $newAppUnString = "MsiExec.exe /X"+$newApp.ProductCode

                Write-Log -sMessage "(7/7) - MSI found at $msiPath" -iTabs 1               

                Write-Log -sMessage "Name: $newAppName" -iTabs 2

                Write-Log -sMessage "Version: $newAppVer" -iTabs 2  

                Write-Log -sMessage "ProductCode: $newAppProductCode" -iTabs 2  

                Write-Log -sMessage "UninstallString: $newAppUnString" -iTabs 2

            }

            elseif($install){

                Write-Log -sMessage "(7/7) - MSI not found at $msiPath" -iTabs 1

                Write-Log -sMessage "Unable to install Console" -iTabs 1

                Write-Log -sMessage "" -iTabs 0 

                Log-Event -sMessage "$SCRIPT_TITLE ($sScriptName) $SCRIPT_VERSION

                                     MSI not found at $msiPath

                                     Unable to install Console" -iEventID 9007 -sEventLogType Error

                $global:iExitCode = 9007

                If (!$force){return  $global:iExitCode}

            }

            else{

                Write-Log -sMessage "(7/7) - MSI not found at $msiPath" -iTabs 1

                Write-Log -sMessage "Proceeding since `"-INSTALL`" parameter was not used." -iTabs 1

                Write-Log -sMessage "" -iTabs 0 

                Log-Event -sMessage "$SCRIPT_TITLE ($sScriptName) $SCRIPT_VERSION

                                     MSI not found at $msiPath

                                     Proceeding since `"-INSTALL`" parameter was not used." -iEventID 5004 -sEventLogType Warning

                $global:iExitCode = 5004

            }

            Write-Log -sMessage "" -iTabs 0 

            Write-Log -sMessage "Completed Pre-Checks." -iTabs 1 

            Write-Log -sMessage "" -iTabs 0 

# ===============================================================================================================================================================================

# 2 - Execution

# ===============================================================================================================================================================================

        Write-Log -sMessage "" -iTabs 0 

        Write-Log -sMessage "Starting Execution." -iTabs 1

        Write-Log -sMessage "" -iTabs 0 

        if($Push){

                $userInterface = " /quiet"

            }

            else{

                $userInterface = " /passive"

            }

        If($Action -eq "Install"){

            Write-Log -sMessage "Script will Start $newAppName $newAppver installation. Proceeding..." -iTabs 1

            Write-Log -sMessage "PUSH: $Push" -iTabs 2

            Write-Log -sMessage "FORCE: $Force" -iTabs 2

            Write-Log -sMessage "" -iTabs 1

 

            if (!($bAppInstalled) -or ($appVer -lt $newAppVer)){               

                #Write-Progress -Activity "Installing SCCM Console..."            

                $filepath = ".\consolesetup.exe"

                $arg = "TargetDir=`"C:\Program Files\Microsoft Configuration Manager\AdminConsole`" EnableSQM=0 $sccmSiteParam $userInterface"

                Write-Log -sMessage "Command sent to OS: $filepath $arg" -iTabs 1           

                Write-Log -sMessage "Please wait. This operation might take a few minutes..." -iTabs 1

                Log-Event -sMessage "$SCRIPT_TITLE ($sScriptName) $SCRIPT_VERSION

                                     Script installing $newAppName $newAppVer

                                        PUSH: $Push

                                        FORCE: $Force

                                        Command sent to OS: $filepath $arg" -iEventID 8001 -sEventLogType Information

                $exitCode = 0#(Start-Process -FilePath $filepath -ArgumentList $arg -wait -PassThru).ExitCode

                Write-Log -sMessage "MSI Exit Code: $exitCode" -iTabs 1

            }

            else{

                Write-Log -sMessage "$AppName $AppVer is already installed at highest version." -iTabs 1           

                Write-Log -sMessage "No installation will occur." -iTabs 1

                Log-Event -sMessage "$SCRIPT_TITLE ($sScriptName) $SCRIPT_VERSION

                                     $AppName $AppVer is already installed at highest version.

                                     No installation will occur." -iEventID 8001 -sEventLogType Information

            }

        }   

        elseif($Action -eq "Uninstall"){

            if (($bAppInstalled) -and ($appVer -eq $newAppVer)){               

                Write-Log -sMessage "Script will will Start $newAppName $newAppver uninstallation. Proceeding..." -iTabs 1

                Write-Log -sMessage "PUSH: $Push" -iTabs 2

                Write-Log -sMessage "FORCE: $Force" -iTabs 2

                Write-Log -sMessage "" -iTabs 1

                #Write-Progress -Activity "Uninstalling app..."            

                $filepath = "MsiExec.exe"

                $arg = "/x $newAppProductCode $userInterface"           

                Write-Log -sMessage "Command sent to OS: $filepath $arg" -iTabs 1

                Log-Event -sMessage "$SCRIPT_TITLE ($sScriptName) $SCRIPT_VERSION

                                        Script uninstalling $newAppName $newAppVer

                                        PUSH: $Push

                                        FORCE: $Force

                                        Command: $filepath $arg" -iEventID 8001 -sEventLogType Information       

                $exitCode = 0#(Start-Process -FilePath $filepath -ArgumentList $arg -wait -PassThru).ExitCode

                Write-Log -sMessage "MSI Exit Code: $exitCode" -iTabs 1

            }

            elseif(!($bAppInstalled)){

                Write-Log -sMessage "$newAppName $newAppVer is not present in the system." -iTabs 1           

                Write-Log -sMessage "No uninstallation will occur." -iTabs 1

                Log-Event -sMessage "$SCRIPT_TITLE ($sScriptName) $SCRIPT_VERSION

                                     $newAppName $newAppVer is not present in the system.

                                     No uninstallation will occur." -iEventID 8001 -sEventLogType Information

            }

            elseif($appVer -ne $newAppVer){

                Write-Log -sMessage "$AppName has a different version installed and in this installation script." -iTabs 1           

                Write-Log -sMessage "To uninstall this version, use -Action Clean parameter." -iTabs 1

               Write-Log -sMessage "No uninstallation will occur." -iTabs 1

                Log-Event -sMessage "$SCRIPT_TITLE ($sScriptName) $SCRIPT_VERSION

                                     $AppName has a different version installed and in this installation script.

                                     $newAppName $newAppVer is not present in the system.

                                     No uninstallation will occur." -iEventID 8001 -sEventLogType Information

            }

        }

        elseif($Action -eq "Clean"){

            if ($bappInstalled -ne $false){

                Write-Log -sMessage "Script will Start to remove any $newAppName version. Proceeding..." -iTabs 1

                Write-Log -sMessage "PUSH: $Push" -iTabs 2

                Write-Log -sMessage "FORCE: $Force" -iTabs 2

                Write-Log -sMessage "" -iTabs 1

                $appInstalled = Check-App -SoftToCheck $newAppName -equalOrHigher

                Write-Log -sMessage "SCCM Consoles:" -iTabs 1

                foreach ($app in $appInstalled){

                    $filepath = "MsiExec.exe"

                    $arg = "/x "+$app.ProductCode+$userInterface           

                    Write-Log -sMessage "Removing $($app.Name) $($app.Version)..." -iTabs 2

                    Write-Log -sMessage "Command sent to OS: $filepath $arg" -iTabs 2

                    Log-Event -sMessage "$SCRIPT_TITLE ($sScriptName) $SCRIPT_VERSION

                                     Script uninstalling any $newAppVersion

                                        PUSH: $Push

                                        FORCE: $Force

                                        Command: $filepath $arg" -iEventID 8001 -sEventLogType Information       

                    $exitCode = 0#(Start-Process -FilePath $filepath -ArgumentList $arg -wait -PassThru).ExitCode

                    Write-Log -sMessage "MSI Exit Code: $exitCode" -iTabs 2

                }

            }

            else{

                Write-Log -sMessage "$newAppName is not present in the system." -iTabs 1           

                Write-Log -sMessage "No uninstallation will occur." -iTabs 1

                Log-Event -sMessage "$SCRIPT_TITLE ($sScriptName) $SCRIPT_VERSION

                                     $newAppName is not present in the system.

                                     No uninstallation will occur." -iEventID 8001 -sEventLogType Information

            }

        }   

        else{       

            Write-Log -sMessage "Wrong Script usage." -iTabs 1

            Write-Log -sMessage "Install $newAppName....: .\$sScriptName -(Install/Uninstall/Clean) -(Push) -(Force)" -iTabs 2

            Write-Log -sMessage "=>Action: (Install/Uninstall/Clean)" -iTabs 3

            Write-Log -sMessage "Install: Install SCCM Console from MSI file" -iTabs 4

            Write-Log -sMessage "Uninstall: Removes SCCM Console from MSI file" -iTabs 4

            Write-Log -sMessage "Clean: Removes any SCCM Console" -iTabs 4

            Write-Log -sMessage "=>PUSH: Supresses User Interface" -iTabs 3

            Write-Log -sMessage "=>FORCE: Disables Error Handling" -iTabs 3

            Log-Event -sMessage "Wrong Script $sScriptName usage.

                             Install SCCM Console....: .\$sScriptName -(Install/Uninstall/Clean) -(Push) -(Force)

                              =>Install/Uninstall/Clean: Script Mode

                                    Install: Install SCCM Console from MSI file

                                    Uninstall: Removes SCCM Console from MSI file

                                    Clean: Removes any SCCM Console

                              =>PUSH: Supresses User Interface

                              =>FORCE: Disables Error Handling" -iEventID 9001 -sEventLogType Error

            $global:iExitCode = 9001

            If (!$force){return  $global:iExitCode}

        }

        Write-Log -sMessage "" -iTabs 0 

        Write-Log -sMessage "Completed Execution." -iTabs 1 

        Write-Log -sMessage "" -iTabs 0

# ===============================================================================================================================================================================

# 3 - Post-Checks

# ===============================================================================================================================================================================

        Write-Log -sMessage "" -iTabs 0 

        Write-Log -sMessage "Starting Post-Checks." -iTabs 1 

        Write-Log -sMessage "" -iTabs 0

        If($action -eq "Install"){

            #Check if app was installed is installed

            $bAppDep = Check-App -SoftToCheck $newAppName -VersionToCheck $newAppVer -Exact

            If ($bAppDep){

                Write-Log -sMessage "SUCCESS: $newAppName $newAppVer is present in the system." -iTabs 2 

                Log-Event -sMessage "$SCRIPT_TITLE ($sScriptName) $SCRIPT_VERSION

                                        $newAppName $newAppVer is present in the system." -iEventID 3001 -sEventLogType Information

                $global:iExitCode = 3001           

            }

            else{

                Write-Log -sMessage "ERROR: $newAppName $newAppVer not present in the system." -iTabs 2 

                Log-Event -sMessage "$SCRIPT_TITLE ($sScriptName) $SCRIPT_VERSION

                                        $newAppName $newAppVer not present in the system." -iEventID 9008 -sEventLogType Error

                $global:iExitCode = 9008

            }

        }   

        elseif($action -eq "Uninstall"){

            #Check if app was NOT installed

            $bAppDep = Check-App -SoftToCheck $newAppName -VersionToCheck $newAppVer -Exact

            If (!$bAppDep){

                Write-Log -sMessage "SUCCESS: $newAppName $newAppVer not present in the system." -iTabs 2 

                Log-Event -sMessage "$SCRIPT_TITLE ($sScriptName) $SCRIPT_VERSION

                                        $newAppName $newAppVer not present in the system." -iEventID 3002 -sEventLogType Information

                $global:iExitCode = 3002           

            }

            else{

                Write-Log -sMessage "ERROR: $newAppName $newAppVer is present in the system." -iTabs 2 

                Log-Event -sMessage "$SCRIPT_TITLE ($sScriptName) $SCRIPT_VERSION

                                        $newAppName $newAppVer is present in the system." -iEventID 9010 -sEventLogType Error

                $global:iExitCode = 9010

            }

        }

        elseif($action -eq "Clean"){

            #Check if all app versions were removed

            $bAppDep = Check-App -SoftToCheck $newAppName -Like       

            If ($bAppDep){

                Write-Log -sMessage "SUCCESS: $newAppName has no versions installed." -iTabs 2 

                Log-Event -sMessage "$SCRIPT_TITLE ($sScriptName) $SCRIPT_VERSION

                                        All $newAppName versions uninstalled with Sucess." -iEventID 3003 -sEventLogType Information

                $global:iExitCode = 3003           

            }

            else{

                Write-Log -sMessage "ERROR: $newAppName has versions installed." -iTabs 2 

                Log-Event -sMessage "$SCRIPT_TITLE ($sScriptName) $SCRIPT_VERSION

                                        $newAppName not uninstalled properly." -iEventID 9009 -sEventLogType Error

                $global:iExitCode = 9009

            }

        }  

        Write-Log -sMessage "" -iTabs 0 

        Write-Log -sMessage "Completed Post-Checks." -iTabs 1 

        Write-Log -sMessage "" -iTabs 0

} #End of MainSub

 

# --------------------------------------------------------------------------------------------

# Main Processing (DO NOT CHANGE HERE)

# --------------------------------------------------------------------------------------------

 

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

    }

    Catch {

                    # Log a general exception error

                    Write-Log -sMessage "Error running script" -iTabs 0       

        if ($global:iExitCode -eq 0){

                        $global:iExitCode = 9999

        }

        Log-Event -sMessage "Error running script" -iEventID $global:iExitCode -sEventLogType Error

    }

 

    # Stopping the log

    End-Log

}

 

# Quiting with exit code

Exit $global:iExitCode

 