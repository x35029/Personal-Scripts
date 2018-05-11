function Log {
<# 
 .Synopsis
  Function to log input string to file and display it to screen

 .Description
  Function to log input string to file and display it to screen. Log entries in the log file are time stamped. Function allows for displaying text to screen in different colors.

 .Parameter String
  The string to be displayed to the screen and saved to the log file

 .Parameter Color
  The color in which to display the input string on the screen
  Default is White
  Valid options are
    Black
    Blue
    Cyan
    DarkBlue
    DarkCyan
    DarkGray
    DarkGreen
    DarkMagenta
    DarkRed
    DarkYellow
    Gray
    Green
    Magenta
    Red
    White
    Yellow

 .Parameter LogFile
  Path to the file where the input string should be saved.
  Example: c:\log.txt
  If absent, the input string will be displayed to the screen only and not saved to log file

 .Example
  Log -String "Hello World" -Color Yellow -LogFile c:\log.txt
  This example displays the "Hello World" string to the console in yellow, and adds it as a new line to the file c:\log.txt
  If c:\log.txt does not exist it will be created.
  Log entries in the log file are time stamped. Sample output:
    2014.08.06 06:52:17 AM: Hello World

 .Example
  Log "$((Get-Location).Path)" Cyan
  This example displays current path in Cyan, and does not log the displayed text to log file.

 .Example 
  "Java process ID is $((Get-Process -Name java).id )" | log -color Yellow
  Sample output of this example:
    "Java process ID is 4492" in yellow

 .Example
  "Drive 'd' on VM 'CM01' is on VHDX file '$((Get-SBVHD CM01 d).VHDPath)'" | log -color Green -LogFile D:\Sandbox\Serverlog.txt
  Sample output of this example:
    Drive 'd' on VM 'CM01' is on VHDX file 'D:\VMs\Virtual Hard Disks\CM01_D1.VHDX'
  and the same is logged to file D:\Sandbox\Serverlog.txt as in:
    2014.08.06 07:28:59 AM: Drive 'd' on VM 'CM01' is on VHDX file 'D:\VMs\Virtual Hard Disks\CM01_D1.VHDX'

 .Link
  https://superwidgets.wordpress.com/category/powershell/

 .Notes
  Function by Sam Boutros
  v1.0 - 08/06/2014

#>

    [CmdletBinding(SupportsShouldProcess=$true,ConfirmImpact='Low')] 
    Param(
        [Parameter(Mandatory=$true,
                   ValueFromPipeLine=$true,
                   ValueFromPipeLineByPropertyName=$true,
                   Position=0)]
            [String]$String, 
        [Parameter(Mandatory=$false,
                   Position=1)]
            [ValidateSet("Black","Blue","Cyan","DarkBlue","DarkCyan","DarkGray","DarkGreen","DarkMagenta","DarkRed","DarkYellow","Gray","Green","Magenta","Red","White","Yellow")]
            [String]$Color = "White", 
        [Parameter(Mandatory=$false,
                   Position=2)]
            [String]$LogFile
    )

    write-host $String -foregroundcolor $Color 
    if ($LogFile.Length -gt 2) {
        ((Get-Date -format "yyyy.MM.dd hh:mm:ss tt") + ": " + $String) | out-file -Filepath $Logfile -append
    } else {
        Write-Verbose "Log: Missing -LogFile parameter. Will not save input string to log file.."
    }
}

function Compact-VHDX {
<# 
 .Synopsis
  Function to remove unused space in Dynamic VHDX file

 .Description
  Function is designed to work on Dynamic VHDX files - not Fixed.
  
  To reduce size of Fixed VHDX file convert it to dynamic first then use this function.
  For example:
    Dismount-VHD -DiskNumber 13 -Confirm:$false
    Convert-VHD -Path 'd:\Fixed1.vhdx' -DestinationPath 'd:\Dynamic2.vhdx' -VHDType Dynamic 
  Where '13' is the disk number as shown in Disk Management/Computer Management.

  Before using this script, empty space on the VHDX disk first by deleting un-needed and
  temporary files, and emptying the recycle bin
  
 .Parameter VHDXPath
  Path to VHDX file
  
 .Parameter SDelete
  Path to the SDelete.exe tool.
  The tool is bundled with this script for ease of use. It can be downloaded from
  http://technet.microsoft.com/en-us/sysinternals/bb897443.aspx

 .Example
  Compact-VHDX -VHDXPath D:\Dynamic1.vhdx -SDelete .\sdelete.exe

 .Link
  https://superwidgets.wordpress.com/category/powershell/

 .Notes
  Function by Sam Boutros
  v1.0 - 10/12/2014

#>

    [CmdletBinding(SupportsShouldProcess=$true,ConfirmImpact='High')] 
    Param(
        [Parameter(Mandatory=$true,
                   ValueFromPipeLine=$true,
                   ValueFromPipeLineByPropertyName=$true,
                   Position=0)]
            [ValidateScript({ Test-Path $_ })]
            [String]$VHDXPath, 
        [Parameter(Mandatory=$true,
                   Position=1)]
            [ValidateScript({ Test-Path $_ })]
            [String]$SDelete = ".\SDelete.exe",
        [Parameter(Mandatory=$false,
                   Position=2)]
            [String]$LogFile = ".\Compact-VHDX-$(Get-Date -format yyyyMMdd_hhmmsstt).txt"
    )
    
    Begin {
        $StartFileSize = (Get-Item -Path $VHDXPath).Length/1MB
        Log "Starting to compact file $VHDXPath - Size on disk: $StartFileSize MB" Green $LogFile
    }

    Process {
        try {
            log "Mounting disk $VHDXPath" Green $LogFile
            $Disk = Mount-VHD -Path $VHDXPath -Passthru -ErrorAction Stop
            Get-disk -Number $Disk.Number | Get-Partition | % {
                if ($_.DriveLetter) {
                    if (Test-Path -Path $SDelete) {
                        Log "Zero out unused space on drive $($_.DriveLetter):" Green $LogFile
                        & $SDelete -z -c "$($_.DriveLetter):"
                    } else {
                        log "$SDelete not found.. stopping" Magenta $LogFile
                    }
                }
            }
            log "Dismounting disk $VHDXPath" Green $LogFile
            Dismount-VHD -DiskNumber $Disk.Number -Confirm:$false
            log "Compacting disk $VHDXPath" Green $LogFile
            Optimize-VHD -Path $VHDXPath -Mode Full
        } catch {
            log "Unable to mount disk $VHDXPath.. stopping" Magenta $LogFile
        }
    }

    End {
        $EndFileSize = (Get-Item -Path $VHDXPath).Length/1MB
        Log "Finished compacting file $VHDXPath - New size on disk: $EndFileSize MB" Green $LogFile
        if ($EndFileSize -lt $StartFileSize) {
            log "File $VHDXPath reduced by $($StartFileSize - $EndFileSize) MB" Green $LogFile
        }
    }
}