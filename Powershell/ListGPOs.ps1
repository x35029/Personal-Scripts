Function ListUnlinkedGPOs
{
	param (
		[string]$domain,
		[string]$server
	)
	$FileDateTime = Get-Date -Format "yyyyMMdd HHmm"
	Write-Host -ForegroundColor Red "Writing: .\Unlinked GPOs - $domain $FileDateTime.log"
	Get-GPO -All -domain $domain -server $server |
	%{
		If ($_ | Get-GPOReport -domain $domain -server $server -ReportType XML | Select-String -NotMatch "<LinksTo>")
		{
			Write-Output $_.DisplayName | out-file ".\Unlinked GPOs-$domain $FileDateTime.log" -append
		}
	}
	Write-Host -ForegroundColor Red "Done!"
}
Function ListLinkedGPOs
{
	param (
		[string]$domain,
		[string]$server
	)
	$FileDateTime = Get-Date -Format "yyyyMMdd HHmm"
	Write-Host -ForegroundColor Yellow "Writing: .\Linked GPOs - $domain $FileDateTime.log"
	Get-GPO -All -domain $domain -server $server |
	%{
		If ($_ | Get-GPOReport -domain $domain -server $server -ReportType XML | Select-String -SimpleMatch "<LinksTo>")
		{
			Write-Output $_.DisplayName | out-file ".\Linked GPOs-$domain $FileDateTime.log" -append
		}
	}
	Write-Host -ForegroundColor Yellow "Done!"
}

ListLinkedGPOs "sa.xom.com" "DALADS07"
ListUnlinkedGPOs "sa.xom.com" "DALADS07"

ListLinkedGPOs "na.xom.com" "DALADS05"
ListUnlinkedGPOs "na.xom.com" "DALADS05"

ListLinkedGPOs "upstreamaccts.xom.com" "UPSADS02"
ListUnlinkedGPOs "upstreamaccts.xom.com" "UPSADS02"

ListLinkedGPOs "ea.xom.com" "DALADS20"
ListUnlinkedGPOs "ea.xom.com" "DALADS20"

ListLinkedGPOs "ap.xom.com" "GOPADS03"
ListUnlinkedGPOs "ap.xom.com" "GOPADS03"

ListLinkedGPOs "af.xom.com" "DALADS24"
ListUnlinkedGPOs "af.xom.com" "DALADS24"

ListLinkedGPOs "accpt.xom.com" "DACADS44"
ListUnlinkedGPOs "accpt.xom.com" "DACADS44"
