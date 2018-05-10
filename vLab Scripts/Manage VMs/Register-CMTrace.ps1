<# 
.SYNOPSIS 
    A summary of what this script does:
        Copies CMtrace locally and registers it as default log viewer
.DESCRIPTION 
    Copies CMTrace to Program Files folder and changes register to set it as default viewer for *.log files 
.NOTES     
    File Name  : Register-CMTrace.ps1 
    Author     : Rodrigo Varandas - rodrigovarandas@gmail.com
    Requires   : PowerShell V2    
.LINK     
    https://social.technet.microsoft.com/Forums/en-US/39e4b496-05d5-407e-9a15-ee5c660b2041/deploying-cmtrace-only-including-setting-log-association?forum=configmanagergeneral 
    
.EXAMPLE     
         C:\> .\Register-CMTrace.ps1
         CMTrace registered    
.EXAMPLE 
         C:\> .\Register-CMTrace.ps1
         CMTrace failed to register - Access Denied
.EXAMPLE 
         C:\> .\Register-CMTrace.ps1
         CMTrace failed to register - Missing Files
.INPUTTYPE 
   N/A
.RETURNVALUE 
    SUCCESS
        0    -> Success
        3010 -> Pending Reboot
        3300 -> Sucess Unhandled
        3301 -> Eventlog Source Created
        3302 -> Script running with proper rights
        3303 -> Wrote to Eventlog
        3304 -> Created Eventlog Log and Source
    INFORMATION
        4400 -> Unhandled Information
        4401 -> Script Executing
        4402 -> Eventlog Log and Source exists
    WARNING
        5500 -> Unhandled Warning
        5501 -> Unable to create EventLog Source
        5502 -> Unable to write to  EventLog
    ERROR
        9900 -> Unhandled Error
        9901 -> Unable to check System Type
        9902 -> Not running with with proper rights        

.COMPONENT 
    VARIABLES
        $error = Error Code
        $sysType = Contains System Archtechture.
            VALUES: 
             -> x64-based PC - 64 bit Operating System
             -> x86-based PC - 32 bit Operating System
             -> Unable to determine - Error 9901 -> Unable to check System Type
    CONSTANTS
        $logName -> WDS
        $sourceName -> <SCRIPT_NAME>
        $scriptName -> <SCRIPT_NAME>
.ROLE  
   N/A
.FUNCTIONALITY 
   N/A
.PARAMETER  
   N/A
.PARAMETER 
   N/A
#> 

$error = "9900" # Default error value
$scriptScope = "User\" # or System\
$scriptPath = "SCCM\CMTrace\" 
$scriptName = "Register-CMTrace"

cls

<######### FUNCTIONS #########>

function Check-Credentials{
<#  =========================================================================================
    SYNOPSIS: Checks if script is running with proper rights given a role in $role
    PARAM
        =>$role -> STRING
            AccountOperator	-> Account operators manage the user accounts on a computer or domain.
            Administrator	-> Administrators have complete and unrestricted access to the computer or domain.
            BackupOperator	-> Backup operators can override security restrictions for the sole purpose of backing up or restoring files.
            Guest	        -> Guests are more restricted than users.
            PowerUser	    -> Power users possess most administrative permissions with some restrictions. Thus, power users can run legacy applications, in addition to certified applications.
            PrintOperator	-> Print operators can take control of a printer.
            Replicator	    -> Replicators support file replication in a domain.
            SystemOperator	-> System operators manage a particular computer.
            User            -> Users are prevented from making accidental or intentional system-wide changes. Thus, users can run certified applications, but not most legacy applications.
    RETURNVALUE
        9902 -> Not running with with proper rights
        3302 -> Script running with proper rights


#>
    [CmdletBinding()]
    param(
        [parameter(
            Position=0,
            Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [ValidateSet(   “AccountOperator",
                        "Administrator",
                        "BackupOperator",
                        "Guest",
                        "PowerUser",
                        "PrintOperator",
                        "Replicator",
                        "SystemOperator",
                        "User”)]
        [string]$role
          )    
    Write-Verbose "Creating object Security.Principal.WindowsIdentity from $user"
    $user = [Security.Principal.WindowsIdentity]::GetCurrent();
    if((New-Object Security.Principal.WindowsPrincipal $user).IsInRole([Security.Principal.WindowsBuiltinRole]::$role)){    
        Write-Verbose "User: $user is in role:<$role>"
        # 3302 -> Script running with proper rights
        $errorCode = 3302
        return $errorCode        
    }
    else{
        Write-Verbose "User: $user is not in role:<$role>"
        # 9902 -> Not running with with proper rights   
        $errorCode = 9902
        return $errorCode        
    }      
}

function Create-EventLog {
<# ====================================================================================================================
    SYNOPSIS: Creates an Event Log Source with $sourceName
    VALUES
        =>$sourcename  -> STRING            
    RETURNVALUE
        FALSE -> 5501 -> Unable to create EventLog Source
        TRUE  -> 3301 -> Eventlog Source Created

#>    
    [CmdletBinding()]
    param(
        [parameter(
            Position=0,
            Mandatory=$true
        )]
        [ValidateNotNullOrEmpty()]
        [string]$log,
        [parameter(
            Position=1,
            Mandatory=$true
        )]
        [ValidateNotNullOrEmpty()]
        [string]$source       
    )
    Write-Verbose "Checking if Log:<$log> and Source:<$source> exist"
    if (!(Get-Eventlog -LogName $log -source $source -ErrorAction SilentlyContinue)){
        Write-Verbose "Log:<$log> and Source:<$source> doesn't exist"
        try{
            Write-Verbose "Trying to create Log:<$log> and Source:<$source>"
            New-Eventlog -LogName $log -source $source -ErrorAction SilentlyContinue
            Write-Verbose "Log:<$log> and Source:<$source> created"
            # 3304 -> Created Eventlog Log and Source
            $errorCode = 3304
            return $errorCode
        }
        catch{
            Write-Verbose "Failed to create Log:<$log> and Source:<$source>"
            #5501 -> Unable to create EventLog Source
            $errorCode = 5501
            return $errorCode
        }
    }
    Write-Verbose "Log:<$log> and Source:<$source> exists"
    # 4402 -> Eventlog Source exists
    $errorCode = 5501
    return $errorCode       
}

function Write-CustomEventLog {   
<#  ===================================================================================================================
    SYNOPSIS: Writes to EventLog an Event Log Source with $sourceName
    VALUES
        $log     -> STRING 
        $source  -> STRING 
        $eventID -> STRING
        $type    -> STRING
        $message -> STRING
    RETURNVALUE
        FALSE -> 5502 -> Unable to write to  EventLog
        TRUE  -> 3303 -> Wrote to Eventlog
#> 
    [CmdletBinding()]
    param(
        [parameter(
            Position=0,
            Mandatory=$true
        )]
        [ValidateNotNullOrEmpty()]
        [string]$log,
        [parameter(
            Position=1,
            Mandatory=$true
        )]
        [ValidateNotNullOrEmpty()]
        [string]$source,
        [parameter(
            Position=2,
            Mandatory=$true
        )]
        [ValidateNotNullOrEmpty()]
        [string]$eventID,
        [parameter(
            Position=3,
            Mandatory=$true
        )]
        [ValidateNotNullOrEmpty()]
        [ValidateSet(   “SuccessAudit",
                        "Error",
                        "FailureAudit",
                        "Information",
                        "Warning")]
        [string]$type,
        [parameter(
            Position=4,
            Mandatory=$true
        )]
        [ValidateNotNullOrEmpty()]
        [string]$message      
    )
    Write-Verbose "Creating new Event"
    try{
        Write-EventLog -LogName $log -Source $source -EventID $eventID -EntryType $type -Message $message -ErrorAction SilentlyContinue
    }
    catch{
        # 5502 -> Unable to write to  EventLog
        Write-Verbose "Error while creating new Event"
        $errorCode = 5502
        return $errorCode 
    } 
    # 3303 -> Wrote to Eventlog
    $errorCode = 3303
    return $errorCode 
}

function Write-CustomScriptLog {
<#  ===================================================================================================================
    SYNOPSIS: Writes to log to Script
    VALUES
        $log     -> STRING 
        $source  -> STRING 
        $eventID -> STRING
        $type    -> STRING
        $message -> STRING
    RETURNVALUE
        FALSE -> 5502 -> Unable to write to scriptlog
        TRUE  -> 3303 -> Wrote to scriptlog
#> 
    [CmdletBinding()]
    param(
        [parameter(
            Position=0,
            Mandatory=$true
        )]
        [ValidateNotNullOrEmpty()]
        [string]$log,
        [parameter(
            Position=1,
            Mandatory=$true
        )]
        [ValidateNotNullOrEmpty()]
        [string]$source,
        [parameter(
            Position=2,
            Mandatory=$true
        )]
        [ValidateNotNullOrEmpty()]
        [string]$eventID,
        [parameter(
            Position=3,
            Mandatory=$true
        )]
        [ValidateNotNullOrEmpty()]
        [ValidateSet(   “SuccessAudit",
                        "Error",
                        "FailureAudit",
                        "Information",
                        "Warning")]
        [string]$type,
        [parameter(
            Position=4,
            Mandatory=$true
        )]
        [ValidateNotNullOrEmpty()]
        [string]$message,
        [parameter(
            Position=5
        )]
        [ValidateNotNullOrEmpty()]
        [string]$tabs      
    )
    $scriptFullPath = "C:\XOM\Utils\Logs\"+$scriptScope+$scriptPath+$scriptName+".log"
    Write-Verbose "Scriptlog Path: $scriptFullPath" 
    Test-Path -Path $scriptFullPath
    $logTime = Get-Date -Format "MM-dd-yyyy_hh-mm-ss"
    $output = "$logTime - $eventId - "
    foreach ($t in $tabs){
    $output=+"`t"
    }
    write-Output $output >> $scriptFullPath
    write-Verbose $output    
}


<#=========================================================#>
# Checking script rights
IF (!Check-Credentials("Administrator")){
    $exitError = 9902 # -> Not running with Admin Rights
    return $error
}

# Checking OS Info
$sOS =Get-WmiObject -class Win32_OperatingSystem
$sOS.OSArchitecture
$sOS.PSComputerName
$sOS.BuildNumber
$sos.InstallDate
$sos.OSType
$sos.SerialNumber
$sos.PSStatus


IF (Test-Path -Path "C:\Program Files (x86)"){
    $sysType="x64-based PC"
}
ELSEIF (Test-Path -Path "C:\Program Files") {
    $sysType="x86-based PC"
}
ELSE {
    $sysType="Unable to determine"
    # Error 9901 -> Unable to check System Type
}

<#DEFINED ProgramFiles(x86) SET Programs=%ProgramFiles(x86)%

IF NOT DEFINED ProgramFiles(x86) SET Programs=%ProgramFiles%

mkdir \a "%Programs%\CMTrace"
copy CMTrace.exe "%Programs%\CMTrace" /Y

IF DEFINED ProgramFiles(x86) regedit /s file_assoc_64_1.reg
IF DEFINED ProgramFiles(x86) regedit /s file_assoc_64_2.reg
IF DEFINED ProgramFiles(x86) regedit /s file_assoc_64_3.reg
IF DEFINED ProgramFiles(x86) regedit /s file_assoc_64_4.reg
IF DEFINED ProgramFiles(x86) regedit /s file_assoc_64_5.reg

IF NOT DEFINED ProgramFiles(x86) regedit /s file_assoc_32_1.reg
IF NOT DEFINED ProgramFiles(x86) regedit /s file_assoc_32_2.reg
IF NOT DEFINED ProgramFiles(x86) regedit /s file_assoc_32_3.reg
IF NOT DEFINED ProgramFiles(x86) regedit /s file_assoc_32_4.reg
IF NOT DEFINED ProgramFiles(x86) regedit /s file_assoc_32_5.reg

ASSOC .log=logfile
FTYPE logfile="%Programs%\CMTrace\CMTrace.exe"

ASSOC .log=Log.file
FTYPE Log.file="%Programs%\CMTrace\CMTrace.exe"#>