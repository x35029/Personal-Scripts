#	Script to create report of all Maintenace Windows configured for TS_AppDep collections
#	Works on SCCM 2007/2012
#	Use -Help for examples
#	Script created by Gilberto J Hepp
#	Version 1.0

Param(
    [Switch]$SCCM2007,
	[Switch]$SCCM2012,
    [Switch]$CSV,
    [Switch]$HTML,
	[Switch]$Help,
    [String]$OutPut
)

$HelpMessage = 'Create a report with Maintenance Window for TS_AppDep collections'
$Example1 = '.\Get-SCCMCollectionMaintenance2 -SCCM2007 -CSV -OutPut .\CSVReport'
$Example2 = '.\Get-SCCMCollectionMaintenance2 -SCCM2007 -HTML -OutPut .\HTMLReport'
$Example3 = '.\Get-SCCMCollectionMaintenance2 -SCCM2007 -CSV -HTML -OutPut .\Report'
$Example4 = '.\Get-SCCMCollectionMaintenance2 -SCCM2012 -CSV -OutPut .\CSVReport'
$Example5 = '.\Get-SCCMCollectionMaintenance2 -SCCM2012 -HTML -OutPut .\HTMLReport'
$Example6 = '.\Get-SCCMCollectionMaintenance2 -SCCM2012 -CSV -HTML -OutPut .\Report'
If (! $Help){
	If ($SCCM2007){
		$SiteCode = 'CEN'
		$SiteServer = 'DALSCC01'
	}
	If ($SCCM2012){
		$SiteCode = 'CAS'
		$SiteServer = 'DALCFG01'
	}
	If (! $SCCM2007 -and ! $SCCM2012){
		Write-Host -ForegroundColor Red "Specify SCCM environment. Use -SCCM 2007 or -SCCM2012"
		Exit
	}
	####
	$EmptyArray = @()
	$p = 1
	Write-Host "Getting TS_AppDep collections ID/Name..."
	$TSCollectionsIDName = Get-WMIObject -Computername $SiteServer -Namespace "root\sms\site_$SiteCode" -Class "SMS_Collection" -Filter "Name LIKE 'TS_AppDep%'" | Select-Object -Property CollectionID, Name | Sort-Object -Property Name
	Write-Host "$($TSCollectionsIDName.Count) collections found..."
	ForEach ($TSCollection in $TSCollectionsIDName){
		
		$ColName = $($TSCollection.Name)
		#Code to show progress bar
		$PercentComplete = ($p/$TSCollectionsIDName.Count*100)
		$PercentComplete = "{0:N0}" -f $PercentComplete
		Write-Progress -Activity "Getting TS_AppDep Collections Maintenance Window" -CurrentOperation "Processing collection $ColName" -Status "$PercentComplete% Complete" -PercentComplete ($p/$TSCollectionsIDName.Count*100)
		$p ++
		#End of Code to show progress bar
	
		$ColSettingsQuery = Get-WmiObject -ComputerName $SiteServer -Namespace "root\sms\site_$SiteCode" -Class "SMS_CollectionSettings" -Filter "CollectionID='$($TSCollection.CollectionID)'" -ErrorAction STOP 
		If (!$ColSettingsQuery){
			
			$DObject = New-Object PSObject
			$DObject | Add-Member -MemberType NoteProperty -Name "Collection Name" -Value $ColName
			$DObject | Add-Member -MemberType NoteProperty -Name "CollectionID" -Value $($Item.CollectionID)
			$DObject | Add-Member -MemberType NoteProperty -Name "Start Time" -Value "N/A"
			$DObject | Add-Member -MemberType NoteProperty -Name "Duration in minutes" -Value "N/A" 
			$DObject | Add-Member -MemberType NoteProperty -Name "Maintenance Window Name" -Value "N/A"
			$DObject | Add-Member -MemberType NoteProperty -Name "Maintenance Window Recurrence" -Value "N/A"
			$DObject | Add-Member -MemberType NoteProperty -Name "Enabled" -Value "N/A"
		
			$EmptyArray += $DObject
		}
		Else{
			Foreach($Item in $ColSettingsQuery)
			{
				$Item.Get()
				
					Foreach($MW in $Item.ServiceWindows)
					{
					
						$MWDescription = $($MW.Description) -replace "effective.*"
						if($MW.Count -ne 0){
							$DObject = New-Object PSObject
							$DObject | Add-Member -MemberType NoteProperty -Name "Collection Name" -Value $ColName
							$DObject | Add-Member -MemberType NoteProperty -Name "CollectionID" -Value $($Item.CollectionID)
							$DObject | Add-Member -MemberType NoteProperty -Name "Start Time" -Value (Get-Date ([System.Management.ManagementDateTimeConverter]::ToDateTime($MW.StartTime)) -UFormat %r)
							$DObject | Add-Member -MemberType NoteProperty -Name "Duration in minutes" -Value ($MW.Duration) 
							$DObject | Add-Member -MemberType NoteProperty -Name "Maintenance Window Name" -Value $($MW.Name)
							$DObject | Add-Member -MemberType NoteProperty -Name "Maintenance Window Recurrence" -Value $MWDescription
							$DObject | Add-Member -MemberType NoteProperty -Name "Enabled" -Value $($MW.IsEnabled)

							$EmptyArray += $DObject
						}
					}
			}
		}
	}
	#### 
	If($CSV){
		If ($SCCM2007){
				$OutPutCSV = $OutPut+'_SCCM2007.csv'
		}
		If ($SCCM2012){
				$OutPutCSV = $OutPut+'_SCCM2012.csv'
		}
		Try{
			Write-Host "Creating output file $OutPutCSV"
			$EmptyArray | Export-Csv $OutPutCSV -NoTypeInformation -ErrorAction Stop
		}
		Catch{
			Write-Host "Failed to export CSV to $OutPutCSV"
		}
	}

	If($HTML){
		If ($SCCM2007){
			$OutPutHTML = $OutPut+'_SCCM2007.html'
		}
		If ($SCCM2012){
			$OutPutHTML = $OutPut+'_SCCM2012.html'
		}
		
		$CurrentDate = Get-Date

		#HTML style
		$HeadStyle = "<style>"
		$HeadStyle = $HeadStyle + "BODY{background-color:peachpuff;}"
		$HeadStyle = $HeadStyle + "TABLE{border-width: 1px;border-style: solid;border-color: black;border-collapse: collapse;}"
		$HeadStyle = $HeadStyle + "TH{border-width: 1px;padding: 0px;border-style: solid;border-color: black;background-color:thistle}"
		$HeadStyle = $HeadStyle + "TD{border-width: 1px;padding: 0px;border-style: solid;border-color: black;background-color:palegoldenrod}"
		$HeadStyle = $HeadStyle + "</style>"   

		Try{
			Write-Host "Creating output file $OutPutHTML"
			$EmptyArray | ConvertTo-Html -Head $HeadStyle -Body "<h2>Maintenance Windows Date/Time Report: $CurrentDate</h2>" -ErrorAction STOP | Out-File $OutPutHTML
		}
		Catch{
			Write-Host "Failed to export HTML to $OutPutHTML"
		}
	}
}
Else{
	Write-Host -ForegroundColor Yellow "$HelpMessage`n$Example1`n$Example2`n$Example3`n$Example4`n$Example5`n$Example6"
}