Function ListLinkedGPOs
{
    param (
    [string] $domain,
    [string] $server
    )
    
        Get-GPO -All -domain $domain -server $server | 
        %{ 
            If ( $_ | Get-GPOReport -domain $domain -server $server -ReportType XML | Select-String -SimpleMatch "<LinksTo>" | Select-String -Pattern "GME-","WCL-" )
            {
                Write-Output $_.DisplayName | out-file .\$domain.log -append
            }
        }

} 

Write-Host -ForegroundColor Green "ACCPT"
ListLinkedGPOs "accpt.xom.com" "DACADS44"

Write-Host -ForegroundColor Green "AF"
ListLinkedGPOs "af.xom.com" "DALADS24"

Write-Host -ForegroundColor Green "AP"
ListLinkedGPOs "ap.xom.com" "GOPADS03"

Write-Host -ForegroundColor Green "EA"
ListLinkedGPOs "ea.xom.com" "DALADS20"

Write-Host -ForegroundColor Green "NA"
ListLinkedGPOs "na.xom.com" "DALADS05"

Write-Host -ForegroundColor Green "SA"
ListLinkedGPOs "sa.xom.com" "DALADS07"

Write-Host -ForegroundColor Green "UPS"
ListLinkedGPOs "upstreamaccts.xom.com" "UPSADS02"