function Get-RemoteApplication {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true,
            Position=1
        )]
        [string[]]$ComputerName = $env:COMPUTERNAME
    )
    begin {
        $RegistryPath = 'SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\',
                            'SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\'
    } process {
        foreach ($Computer in $ComputerName) {
            $Registry = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey([Microsoft.Win32.RegistryHive]::LocalMachine,$Computer)
            foreach ($RegPath in $RegistryPath) {
                ($Registry.OpenSubKey($RegPath)) | foreach {
                    $_.GetSubKeyNames() | ForEach-Object {
                        $ApplicationName = ($Registry.OpenSubKey("$RegPath$_")).GetValue('DisplayName')
                        $ApplicationVersion  = ($Registry.OpenSubKey("$RegPath$_")).GetValue('DisplayVersion')
                        $installDate = ($Registry.OpenSubKey("$RegPath$_")).GetValue('InstallDate')
                        $installPath = ($Registry.OpenSubKey("$RegPath$_")).GetValue('InstallLocation')
                        if ([bool]$ApplicationName) {
                            New-Object -TypeName PSCustomObject -Property @{
                                'ComputerName' = $Computer
                                'Application' = $ApplicationName
                                'Version' = $ApplicationVersion
                                'InstallDate' = $installDate
                                'InstallPath'= $installPath
                                'RunDate'= Get-Date -UFormat "%Y-%m%-%d-%H-%M-%S"
                            }
                        }
                    }
                }
            }
        }
    }
}
$TimeStamp = Get-Date -UFormat "%Y-%m%-%d-%H-%M-%S"
$JOB = "InstalledApps"
$LOGLOCATION = "C:\Users\rodri\Dropbox\Dev\Logs\"
$LOG = $LOGLOCATION+$job+$timestamp+".log"
Get-RemoteApplication | Export-Csv -Append -path $LOG