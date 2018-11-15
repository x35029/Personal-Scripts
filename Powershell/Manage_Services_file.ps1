############################################################################################
###Script Title: Manage_Service_file.ps1
###Script Function: To add/replace or remove to/from Services file
###                 Services file = C:\Windows\System32\drivers\etc\services
###
###Script Author: Andre Furtado (EMIT WDS)
###Script Version: 1.0
###Script Update: Initial Version
############################################################################################

##################################################
#
# Begin Parameters From Published Data
#
##################################################

###### Place Variables from SCOrch Published Data Here ######
###### You will always need a $SiteServer variable to tell PowerShell which ConfigMgr Server to connect to ###### 
###### Typically this variable will come from a global variable defined in System Center Orchestrator (SCOrch) ######
$ScriptMode = "\`d.T.~Ed/{0731AF1D-E945-4116-8B64-976368E69663}.{33946DF7-4342-450A-A8FC-C4769CFFEE86}\`d.T.~Ed/" #Add|Replace|Remove
$ComputerFQDN = "\`d.T.~Ed/{0731AF1D-E945-4116-8B64-976368E69663}.{183D598B-ED66-4B85-AD57-CF4AA1CAE0D9}\`d.T.~Ed/"
$ReferenceFile = "\`d.T.~Ed/{0731AF1D-E945-4116-8B64-976368E69663}.{4F5BE8DB-18DA-4F8E-9838-71B034C22E96}\`d.T.~Ed/" #Text file with a list of IPs and Host Names
$EMGSharePath = "\`d.T.~Vb/{3AFDD87B-1AC2-46A7-9019-BA2C97358B48}\`d.T.~Vb/"

###### Found in Common Published Data ######
$RunbookName = "\`d.T.~Ed/{0731AF1D-E945-4116-8B64-976368E69663}.Policy.Name\`d.T.~Ed/"

##################################################
#
# Begin Functions
#
##################################################

### No Current Functions

##################################################
#
# Begin Main
#
##################################################

###### Setting Variables ######
$RemoveEmptyLines = $true
$SourceFile = $sLogFile = Join-Path -path $EMGSharePath -childpath $ReferenceFile

###### Setting Error State Variables ######
###### This data becomes SCOrch Published Data ######
$ErrorState = 0
$ErrorMessage = ""
$Trace = @()
$Error.Clear()
$Action = "Setting Global Parameters"

###### Validating input parameters ######
###### Put in logic to validate the variables defined in the SCOrch Published Data Section ######

###### Setting Parameters for the Remote PowerShell Session ######
###### You need to set these variables 
Try
{
	###### You must set the parameters that you set above. ######
	###### This allows Powershell to send these parameters to the remote session ######
	$Parameters = @{
		"RunbookName" = $RunbookName;
		"ScriptMode" = $ScriptMode;
		"SourceFile" = $SourceFile;
		"ComputerFQDN" = $ComputerFQDN;
		"RemoveEmptyLines" = $RemoveEmptyLines;
	}
	
	###### Creating the Remote PowerShell Session ######
	###### This line should never be changed ######
	$SSPSSession = New-PSSession -ComputerName $ComputerFQDN -ConfigurationName ADMTAutomation
	if (!$SSPSSession)
	{
		$ErrorMessage = $Error[0]
		$Trace += "Could not create PSSession on $ComputerFQDN`r`n"
		$ErrorState = 2
	}
	Else
	{
		###### If the remote session was created this piece of the script will run ######
		###### This command sends the scriptblock to the remote PowerShell Session ######
		###### $ReturnArray is used to store data that will be passed back to the SCOrch Data Bus ######
		$ReturnArray = Invoke-Command -Session $SSPSSession -ArgumentList $Parameters -ScriptBlock {
			Param ($Parameters)
			$Action = "Connected to Remote PowerShell Session on the $ComputerFQDN workstation"
			$Trace += "Beginning remote action '$Action' `r`n"
			$Trace += "Parameters:`r`n"
			###### Adding the Params to Trace so that they are logged in the SCOrch Data Bus ######
			foreach ($key in $Parameters.Keys) { $Trace += [System.String]::Format("  {0}:  {1} `r`n", $key, $Parameters[$key]) }
			
			###### Set the Parameters here that were set on line 50 ######
			###### Make sure to set all the necessary params as your script will error out if you don't ######
			$RunbookName = $Parameters.RunbookName
			$ScriptMode = $Parameters.ScriptMode
			$SourceFile = $Parameters.SourceFile
			$ComputerFQDN = $Parameters.ComputerFQDN
			$RemoveEmptyLines = $Parameters.RemoveEmptyLines
			
			####################### BEGIN IMPORTANT INFO! #############################
			###### This should be the only Try statement used within this script ######
			###### The reason for this is that if you get an errorstate you must ######
			###### Set the proper ErrorState so that Orchestrator Knows an Error ######
			###### Occurred. If you are prossessing Arrays in foreach loops you  ######
			###### must use Try/Catch Blocks within those loops and set          ######
			###### ErrorState to a value of 1 so that you know you have warnings ######
			####################### END IMPORTANT INFO! ###############################
			Try
			{
				$Action = "Loading EMGFunctions PS Module"
				$Trace += "$Action`r`n"
				### Load EMG Module Here ###
				$EMGModule = Import-Module "C:\XOM\EMGScripts\EMGFunctions.psm1"
				$sComputer = "."
				$sComputerName = $env:computername
				$Date = Get-Date -Format MMddyyhhmm
				$sLogPath = "C:\XOM\EMGLogs"
				$sLogFileName = "$RunbookName-$sComputerName-$Date.log"
				$sLogFile = Join-Path -path $slogpath -childpath $sLogFileName
				$sHeader = ""
				$iLogFileSize = 1024000
				$ErrorState = 0
				
				###### Insert the ConfigMgr commandlets and additional PowerShell logic below to execute the required task ######
				###### Limit the amount of ConfigMgr Activities in this section as System Center Orchestrator (SCOrch) is handling the chaining of events ######
				Try
				{
					$sHeader = CheckLogFile $sLogPath $sLogFilename
					#Write default log file information to the log file
					#$MyLog = Write-Log -sLogPath $sLogPath -sLogFilename $sLogFilename -sMessage $sHeader -iTabs 0  
					$MyLog = Write-Log -sLogPath $sLogPath -sLogFilename $sLogFilename -sMessage "============================================================" -iTabs 0
					$MyLog = Write-Log -sLogPath $sLogPath -sLogFilename $sLogFilename -sMessage "$RunbookName" -iTabs 0
					$MyLog = Write-Log -sLogPath $sLogPath -sLogFilename $sLogFilename -sMessage "============================================================" -iTabs 0
					$MyLog = Write-Log -sLogPath $sLogPath -sLogFilename $sLogFilename -sMessage "Script Started at $(Get-Date)" -iTabs 0
					$MyLog = Write-Log -sLogPath $sLogPath -sLogFilename $sLogFilename -sMessage "Log File = $sLogFile" -iTabs 1
					
					#Get OS Acrhicture
					$Trace += "Determining the OS Processor Architecture...`r`n"
					$OSType = GetOSArchitecture -sLogPath $sLogPath -sLogFileName $sLogFileName
					If ($OSType.Contains("64-bit")) { $global:bIs32Bit = $false }
					Else { $global:bIs32Bit = $true }
					$Trace += "The OS Type for the $sComputerName Computer is $OSType.`r`n"
					$MyLog = Write-Log -sLogPath $sLogPath -sLogFilename $sLogFilename -sMessage "bIs32Bit = $global:bIs32Bit" -iTabs 1
					
					#try to open the xml file.  Check to see if the file name was passed. If not, don't try to open
					# if it was passed, and open failed, exit script with error
					if (($XMLFile -ne "") -and ($XMLFile -ne $null))
					{
						$Trace += "Getting XML Data...`r`n"
						#clear any errors 
						$error.clear()
						[xml]$fXML = Get-Content $XMLFile
						#Since Get-Content doesn't get caught by Try\Catch in all cases, check the status of the last command
						if (!($?))
						{
							$Trace += "Error opening XML file: $($error[0]) `r`n"
							$MyLog = Write-Log -sLogPath $sLogPath -sLogFilename $sLogFilename -sMessage "Error opening XML file: $($error[0])" -iTabs 0
							$error.clear()
							$ErrorState = 2
						}
					} # end that the file wasn't passed as an argument
				}
				Catch
				{
					# Log a general exception error
					$Trace += "Error running $($RunbookName): $_ `r`n"
					$MyLog = Write-Log -sLogPath $sLogPath -sLogFilename $sLogFilename -sMessage "Error running $($RunbookName): $_" -iTabs 0
					$ErrorState = 2
				}
				
				##############################################################
				# Start code modifications here and before writing to AD Mig database
				##############################################################
				
				###### Insert the ConfigMgr commandlets and additional PowerShell logic below to execute the required task ######
				###### Limit the amount of ConfigMgr Activities in this section as System Center Orchestrator (SCOrch) is handling the chaining of events ######
				Try
				{
					$Trace += "============================================================ `r`n"
					$MyLog = Write-Log -sLogPath $sLogPath -sLogFilename $sLogFilename -sMessage "============================================================" -iTabs 0
					$Trace += "Modifying SERVICES file :`r`n"
					$MyLog = Write-Log -sLogPath $sLogPath -sLogFilename $sLogFilename -sMessage "Modifying SERVICES file" -iTabs 0
					$Trace += "============================================================ `r`n"
					$MyLog = Write-Log -sLogPath $sLogPath -sLogFilename $sLogFilename -sMessage "============================================================" -iTabs 0
					
					$Action = "Processing file $SourceFile :"
					$Trace += "$Action`r`n"
					$CheckFile = Test-Path -Path $SourceFile
					If ($CheckFile)
					{
						$SourceData = Get-Content $SourceFile | Where { $_ -match '^\S+' }
						ForEach ($DataLine In $SourceData)
						{
							# <service name>  <port number>/<protocol>  [aliases...]   [#<comment>]
							$ServiceName, $PortAndProtocol, $Aliases, $Comments = (($DataLine.Trim() -replace ' +', "`t") -replace "`t+", "`t").Split("`t", 4)
							$Aliases = $Aliases -replace "`t+", ' '
							$Comment = $Comment -replace "`t+", ' '
							If ($ScriptMode -eq "Remove")
							{
								$RemovePortFromServicesFile = Remove-PortNumberOnServicesFile -ServiceName $ServiceName -PortNumberAndProtocol $PortAndProtocol -RemoveEmptyLines:$RemoveEmptyLines -sLogPath $sLogPath -sLogFilename $sLogFilename
								$Trace += " $RemovePortFromServicesFile : $ServiceName`t$PortAndProtocol`r`n"
								$MyLog = Write-Log -sLogPath $sLogPath -sLogFilename $sLogFilename -sMessage "$RemovePortFromServicesFile : $ServiceName `t $PortAndProtocol" -iTabs 1
							}
							else
							{
								$SetPortOnServicesFile = Set-PortNumberOnServicesFile -ServiceName $ServiceName -PortNumberAndProtocol $PortAndProtocol -ServiceAliases $Aliases -Comments $Comments -RemoveEmptyLines:$RemoveEmptyLines -sLogPath $sLogPath -sLogFilename $sLogFilename
								$Trace += " $SetPortOnServicesFile : $ServiceName`t$PortAndProtocol`r`n"
								$MyLog = Write-Log -sLogPath $sLogPath -sLogFilename $sLogFilename -sMessage "$SetPortOnServicesFile : $ServiceName `t $PortAndProtocol" -iTabs 1
							}
						}
					}
					Else
					{
						$Trace += "- File ""$SourceFile"" NOT found"
						$MyLog = Write-Log -sLogPath $sLogPath -sLogFilename $sLogFilename -sMessage "ERROR: File ""$SourceFile"" NOT found" -iTabs 1
						$ErrorState = 2
					}
					$Action = "Finishing script"
					$Trace += "============================================================ `r`n"
					$MyLog = Write-Log -sLogPath $sLogPath -sLogFilename $sLogFilename -sMessage "============================================================" -iTabs 0
				}
				Catch
				{
					$Trace += "Exception caught in  action '$Action'... `r`n"
					$ErrorState = 2
					$isSuccessful = $false
					$ErrorMessage = $Error[0].Exception.tostring()
				}
			}
			Catch
			{
				$Trace += "Exception caught in  action '$Action'... `r`n"
				$ErrorState = 2
				$isSuccessful = $false
				$ErrorMessage = $Error[0].Exception.tostring()
			}
			Finally
			{
				$Trace += "Completing Remote Session `r`n"
				$Trace += "Exiting  action '$Action' `r`n"
				$Trace += "ErrorState:   $ErrorState`r`n"
				$Trace += "ErrorMessage: $ErrorMessage`r`n"
			}
			###### Any Properties you want to put back into the SCOrch Data Bus must be added to the pscustomobject ######
			New-Object pscustomobject –property @{
				Trace = $Trace
				ErrorState = $ErrorState
				ErrorMessage = $ErrorMessage
				Action = $Action
			}
		}
		###### The Properties that have been created with the #####
		###### pscustomobject must be redifined in the local ######
		###### PowerShell Session from the ReturnArray ######
		$ErrorState = $ReturnArray.ErrorState
		$ErrorMessage += $ReturnArray.ErrorMessage
		$Trace = $ReturnArray.Trace
		$Action = $ReturnArray.Action
		
		###### Make Sure to remove the PSSession so others can use it ######
		Remove-PSSession -Session $SSPSSession
	}
}
###### Final Error Handling ######
Catch
{
	$Trace += "Exception caught in remote action '$Action'... `r`n"
	$ErrorState = 2
	$ErrorMessage = $error[0].Exception.tostring()
}
Finally
{
	$Trace += "Exiting $RunbookName"
}