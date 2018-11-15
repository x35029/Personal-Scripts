﻿#########################################################################################
# Get-dellwarranty ######################################################################
#########################################################################################

<#
.Synopsis
   Get Warranty Info for Dell Computer
.DESCRIPTION
   This takes a Computer Name, returns the ST of the computer,
   connects to Dell's SOAP Service and returns warranty info and
   related information. If computer is offline, no action performed.
   ST is pulled via WMI.
.EXAMPLE
   get-dellwarranty -Name bob, client1, client2 | ft -AutoSize
    WARNING: bob is offline

    ComputerName ServiceLevel  EndDate   StartDate DaysLeft ServiceTag Type                       Model ShipDate 
    ------------ ------------  -------   --------- -------- ---------- ----                       ----- -------- 
    client1      C, NBD ONSITE 2/22/2017 2/23/2014     1095 7GH6SX1    Dell Precision WorkStation T1650 2/22/2013
    client2      C, NBD ONSITE 7/16/2014 7/16/2011      334 74N5LV1    Dell Precision WorkStation T3500 7/15/2010
.EXAMPLE
    Get-ADComputer -Filter * -SearchBase "OU=Exchange 2010,OU=Member Servers,DC=Contoso,DC=com" | get-dellwarranty | ft -AutoSize

    ComputerName ServiceLevel            EndDate   StartDate DaysLeft ServiceTag Type      Model ShipDate 
    ------------ ------------            -------   --------- -------- ---------- ----      ----- -------- 
    MAIL02       P, Gold or ProMCritical 4/26/2016 4/25/2011      984 CGWRNQ1    PowerEdge M905  4/25/2011
    MAIL01       P, Gold or ProMCritical 4/26/2016 4/25/2011      984 DGWRNQ1    PowerEdge M905  4/25/2011
    DAG          P, Gold or ProMCritical 4/26/2016 4/25/2011      984 CGWRNQ1    PowerEdge M905  4/25/2011
    MAIL         P, Gold or ProMCritical 4/26/2016 4/25/2011      984 CGWRNQ1    PowerEdge M905  4/25/2011
.EXAMPLE
    get-dellwarranty -ServiceTag CGABCQ1,DGEFGQ1 | ft  -AutoSize

    ServiceLevel            EndDate   StartDate DaysLeft ServiceTag Type      Model ShipDate 
    ------------            -------   --------- -------- ---------- ----      ----- -------- 
    P, Gold or ProMCritical 4/26/2016 4/25/2011      984 CGABCQ1    PowerEdge M905  4/25/2011
    P, Gold or ProMCritical 4/26/2016 4/25/2011      984 DGEFGQ1    PowerEdge M905  4/25/201
.INPUTS
   Name(ComputerName), ServiceTag
.OUTPUTS
   System.Object
.NOTES
   General notes
#>
function Get-DellWarranty{
    [CmdletBinding()]
    [OutputType([System.Object])]
    Param(
        # Name should be a valid computer name or IP address.
        [Parameter(Mandatory=$False, 
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true, 
                   ValueFromRemainingArguments=$false)]
        
        [Alias('HostName', 'Identity', 'DNSHostName', 'ComputerName')]
        [string[]]$Name,
        
         # ServiceTag should be a valid Dell Service tag. Enter one or more values.
         [Parameter(Mandatory=$false, 
                    ValueFromPipeline=$false)]
         [string[]]$ServiceTag
         )

    Begin{
         }
    Process{
        if($ServiceTag -eq $Null){
            foreach($C in $Name){
                $test = Test-Connection -ComputerName $c -Count 1 -Quiet
                    if($test -eq $true){
                        $service = New-WebServiceProxy -Uri http://143.166.84.118/services/assetservice.asmx?WSDL
                        $system = Get-WmiObject -ComputerName $C win32_bios -ErrorAction SilentlyContinue
                        $serial =  $system.serialnumber
                        $guid = [guid]::NewGuid()
                        $info = $service.GetAssetInformation($guid,'check_warranty.ps1',$serial)
                        
                        $Result=@{
                        'ComputerName'=$c
                        'ServiceLevel'=$info[0].Entitlements[0].ServiceLevelDescription.ToString()
                        'EndDate'=$info[0].Entitlements[0].EndDate.ToShortDateString()
                        'StartDate'=$info[0].Entitlements[0].StartDate.ToShortDateString()
                        'DaysLeft'=$info[0].Entitlements[0].DaysLeft
                        'ServiceTag'=$info[0].AssetHeaderData.ServiceTag
                        'Type'=$info[0].AssetHeaderData.SystemType
                        'Model'=$info[0].AssetHeaderData.SystemModel
                        'ShipDate'=$info[0].AssetHeaderData.SystemShipDate.ToShortDateString()
                        }
                    
                        $obj = New-Object -TypeName psobject -Property $result
                        Write-Output $obj
                   
                        $Result=$Null
                        $system=$Null
                        $serial = $null
                        $guid=$Null
                        $service=$Null
                        $info=$Null
                        $test=$Null 
                        $c=$Null
                    } 
                    else{
                        Write-Warning "$c is offline"
                        $c=$Null
                        }        

                }
        }
        elseif($ServiceTag -ne $Null){
            foreach($s in $ServiceTag){
                        $service = New-WebServiceProxy -Uri http://143.166.84.118/services/assetservice.asmx?WSDL
                        $guid = [guid]::NewGuid()
                        $info = $service.GetAssetInformation($guid,'check_warranty.ps1',$S)
                        
                        if($info -ne $Null){
                        
                            $Result=@{
                            'ServiceLevel'=$info[0].Entitlements[0].ServiceLevelDescription.ToString()
                            'EndDate'=$info[0].Entitlements[0].EndDate.ToShortDateString()
                            'StartDate'=$info[0].Entitlements[0].StartDate.ToShortDateString()
                            'DaysLeft'=$info[0].Entitlements[0].DaysLeft
                            'ServiceTag'=$info[0].AssetHeaderData.ServiceTag
                            'Type'=$info[0].AssetHeaderData.SystemType
                            'Model'=$info[0].AssetHeaderData.SystemModel
                            'ShipDate'=$info[0].AssetHeaderData.SystemShipDate.ToShortDateString()
                            }
                        }
                        else{
                        Write-Warning "$S is not a valid Dell Service Tag."
                        }
                    
                        $obj = New-Object -TypeName psobject -Property $result
                        Write-Output $obj
                   
                        $Result=$Null
                        $system=$Null
                        $serial=$Null
                        $guid=$Null
                        $service=$Null
                        $s=$Null
                        $info=$Null
                        
                   }
            }
    }
    End
    {
    }
}
#______________________________________________________________________________________________________#