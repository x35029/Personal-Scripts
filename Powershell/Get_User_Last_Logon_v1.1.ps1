###############################################################
# Get_User Last_Logon_v1.1.ps1
# Version 1.1
# Changelog : n/a
# MALEK Ahmed - 17 / 03 / 2013
###################

##################
#--------Config
##################

$domain = "contoso.msft"

##################
#--------Main
##################

import-module activedirectory
cls
"The domain is " + $domain
$samaccountname = Read-Host 'What is the User samaccountname?'
"Processing the checks ..."
$myForest = [System.DirectoryServices.ActiveDirectory.Forest]::GetCurrentForest()
$domaincontrollers = $myforest.Sites | % { $_.Servers } | Select Name
$RealUserLastLogon = $null
$LastusedDC = $null
$domainsuffix = "*."+$domain
foreach ($DomainController in $DomainControllers) 
{
	if ($DomainController.Name -like $domainsuffix )
	{
		$UserLastlogon = Get-ADUser -Identity $samaccountname -Properties LastLogon -Server $DomainController.Name
		if ($RealUserLastLogon -le [DateTime]::FromFileTime($UserLastlogon.LastLogon))
		{
			$RealUserLastLogon = [DateTime]::FromFileTime($UserLastlogon.LastLogon)
			$LastusedDC =  $DomainController.Name
		}
	}
}
"The last logon occured the " + $RealUserLastLogon + ""
"It was done against " + $LastusedDC + ""
$mesage = "............."
$exit = Read-Host $mesage