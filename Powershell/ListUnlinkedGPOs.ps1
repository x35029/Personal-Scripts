Function ListUnlinkedGPOs
{
    param (
    [string] $domain,
    [string] $server
    )
    
        Get-GPO -All -domain $domain -server $server | 
        %{ 
            If ( $_ | Get-GPOReport -domain $domain -server $server -ReportType XML | Select-String -NotMatch "<LinksTo>" | Select-String -Pattern "GME-","WCL-","XME-" )
            {
                Write-Output $_.DisplayName | out-file .\$domain.log -append
            }
        }

} 

Write-Host -ForegroundColor Green "ACCPT"
ListUnlinkedGPOs "accpt.xom.com" "DACADS44"

Write-Host -ForegroundColor Green "AF"
ListUnlinkedGPOs "af.xom.com" "DALADS24"

Write-Host -ForegroundColor Green "AP"
ListUnlinkedGPOs "ap.xom.com" "GOPADS03"

Write-Host -ForegroundColor Green "EA"
ListUnlinkedGPOs "ea.xom.com" "DALADS20"

Write-Host -ForegroundColor Green "NA"
ListUnlinkedGPOs "na.xom.com" "DALADS05"

Write-Host -ForegroundColor Green "SA"
ListUnlinkedGPOs "sa.xom.com" "DALADS07"

Write-Host -ForegroundColor Green "UPS"
ListUnlinkedGPOs "upstreamaccts.xom.com" "UPSADS02"