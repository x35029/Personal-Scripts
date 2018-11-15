# Created By: Andre Furtado
# Adapted by Leonardo Gargioni

Function Get-InstalledUpdatesFromLocalHost
{
	$Session = New-Object -ComObject Microsoft.Update.Session
	$Searcher = $Session.CreateUpdateSearcher()
	$HistoryCount = $Searcher.GetTotalHistoryCount()
	$Updates = $Searcher.QueryHistory(0, $HistoryCount)
	ForEach ($Update in $Updates)
	{
		[regex]::match($Update.Title, '(KB\d+)').value | Where-Object { $_ -ne "" } | foreach {
			$Object = New-Object -TypeName PSObject
			$Object | Add-Member -MemberType NoteProperty -Name KBid -Value $_
			$Object | Add-Member -MemberType NoteProperty -Name Description -Value $Update.Title
			$Object | Add-Member -MemberType NoteProperty -Name InstalledBy -Value $Update.ClientApplicationID
			$Object | Add-Member -MemberType NoteProperty -Name InstalledOn -Value $Update.Date
			$Object
		}
	}
	Select-Object KBid, Description, InstalledBy, InstalledOn
	$HotFixes = Get-HotFix | Select-Object HotFixID, Description, InstalledBy, InstalledOn
	ForEach ($HotFix in $HotFixes)
	{
		$Object = New-Object -TypeName PSObject
		$Object | Add-Member -MemberType NoteProperty -Name KBid -Value $HotFix.HotFixID
		$Object | Add-Member -MemberType NoteProperty -Name Description -Value $HotFix.Description
		$Object | Add-Member -MemberType NoteProperty -Name InstalledBy -Value $HotFix.InstalledBy
		$Object | Add-Member -MemberType NoteProperty -Name InstalledOn -Value $HotFix.InstalledOn
		$Object
	}
	Select-Object KBid, Description, InstalledBy, InstalledOn 
}

Write-Host Gathering Data...
Write-Host 
Write-Host After complete, hotfixes.csv will be placed on C:\xom\SPTTemp
Get-InstalledUpdatesFromLocalHost | Export-Csv -NoTypeInformation C:\xom\SPTTemp\hotfixes.csv



