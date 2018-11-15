#------------------------------------------------------------------------------
Function Set-PortNumberOnServicesFile()
{
    <#
    .SYNOPSIS
        Add or Replace an entry on C:\Windows\System32\drivers\etc\services

    .DESCRIPTION
        Checks if the provided port/protocol already exist replacing or adding a line on the 'services' file

	.PARAMETER ServiceName
        Name of the service

    .PARAMETER PortNumberAndProtocol
        Port number and protocol name

    .PARAMETER ServiceAliases
        Alias or aliases for the given service

    .PARAMETER Comments
        Comments related to the line to be added or replaced

    .PARAMETER sLogPath
        Path of the log file to write

    .PARAMETER sLogFileName
        Filename of log to write

    .INPUTS
        [-ServiceName] <string> Name of the service
        [-PortNumberAndProtocol] <string> Port number and protocol name
        [-ServiceAliases] <string> Alias or aliases for the given service
        [-Comments] <string> Comments related to the line to be added or replaced
        [-sLogPath] <String> Path of the Log File
        [-sLogFileName] <String> Name of local Log File

    .OUTPUTS
        <String> Performed action

    .EXAMPLE
        Set-PortNumberOnServicesFile -ServiceName "NewService" -PortNumberAndProtocol "99999/tcp" -ServiceAliases "GreatService BestService" -Comments "No Comments" -sLogPath "C:\XOM\EMGLogs" -sLogFileName "Set-PortNumberOnServicesFile.log"

	#>
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $True)]
		[ValidateNotNullOrEmpty()]
		[string]$ServiceName,
		[Parameter(Mandatory = $True)]
		[ValidateNotNullOrEmpty()]
		[string]$PortNumberAndProtocol,
		[Parameter(Mandatory = $False)]
		[string]$ServiceAliases,
		[Parameter(Mandatory = $False)]
		[string]$Comments,
		[Parameter(Mandatory = $true)]
		[string]$sLogPath,
		[Parameter(Mandatory = $true)]
		[string]$sLogFileName
	)
	#Which file will be manipulated
	$ServiceFile = "C:\Windows\System32\drivers\etc\services"
	
	Write-Log -sLogPath $sLogPath -sLogFileName $sLogFileName -sMessage "`r`n" -iTabs 0
	Write-Log -sLogPath $sLogPath -sLogFileName $sLogFileName -sMessage "============================================================" -iTabs 0
	Write-Log -sLogPath $sLogPath -sLogFileName $sLogFileName -sMessage "Updating $ServiceFile" -iTabs 0
	Write-Log -sLogPath $sLogPath -sLogFileName $sLogFileName -sMessage "============================================================" -iTabs 0
	
	Write-Log -sLogPath $sLogPath -sLogFileName $sLogFileName -sMessage "Port/Protocol = $PortNumberAndProtocol" -iTabs 1
	Write-Log -sLogPath $sLogPath -sLogFileName $sLogFileName -sMessage "Service Name  = $ServiceName" -iTabs 1
	Write-Log -sLogPath $sLogPath -sLogFileName $sLogFileName -sMessage "Alias(es)     = $ServiceAliases" -iTabs 1
	Write-Log -sLogPath $sLogPath -sLogFileName $sLogFileName -sMessage "Comments      = $Comments" -iTabs 1
	
	#What to look for
	$RegMatch = $("(.*)(\s* $PortNumberAndProtocol\s*)(.*)")
	#What will be added or replaced with
	If (15 - ($ServiceName).Length -gt 0) { $NewServiceName = $ServiceName + ' ' * (15 - $ServiceName.Length) }
	else { $NewServiceName = $ServiceName }
	If (12 - ($PortNumberAndProtocol).Length -gt 0) { $NewPortNumberAndProtocol = $PortNumberAndProtocol + ' ' * (12 - $PortNumberAndProtocol.Length) }
	else { $NewPortNumberAndProtocol = $PortNumberAndProtocol }
	If (22 - ($ServiceAliases).Length -gt 0) { $NewServiceAliases = $ServiceAliases + ' ' * (22 - $ServiceAliases.Length) }
	else { $NewServiceAliases = $ServiceAliases }
	If ([string]::IsNullOrWhitespace($Comments)) { $NewComments = "" }
	else { $NewComments = "#" + $Comments }
	$NewValue = "$NewServiceName $NewPortNumberAndProtocol $NewServiceAliases $NewComments"
	#Default return
	$PerformedAction = "Failed"
	
	Write-Log -sLogPath $sLogPath -sLogFileName $sLogFileName -sMessage "Checking if the port/protocol $PortNumberAndProtocol is present on $ServiceFile." -iTabs 1
	#Checks if RegMatch was found on ServiceFile
	If ((Get-Content $ServiceFile) -match $RegMatch)
	{
		#Replaces the entry on the file
		(Get-Content -Path $ServiceFile) | ForEach-Object { $_ -replace $RegMatch, $NewValue } | Set-Content $ServiceFile
		$PerformedAction = "Replaced"
	}
	else
	{
		#Adds the entry to the file
		Add-Content -Path $ServiceFile -Value $("`n`r$NewValue")
		$PerformedAction = "Added"
	}
	
	Write-Log -sLogPath $sLogPath -sLogFileName $sLogFileName -sMessage "$PerformedAction : ""$NewValue""" -iTabs 2
	Write-Log -sLogPath $sLogPath -sLogFileName $sLogFileName -sMessage "------------------------------------------------------------`r`n" -iTabs 0
	
	Return $PerformedAction
}
#------------------------------------------------------------------------------
