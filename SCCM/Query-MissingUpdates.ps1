Function Get-CMMissingSoftwareUpdates {
    Param(
        [switch]$ShowExcludeForStateReporting=$false
    )
if ($ShowExcludeForStateReporting){
    $Results = Get-WmiObject -Namespace ROOT\ccm\SoftwareUpdates\UpdatesStore -Query "Select * from CCM_UpdateStatus WHERE Status = 'Missing'" | Select Article,Title,ProductID,UniqueID,UpdateClassification | Sort UniqueID -Unique
}else{
    $Results = Get-WmiObject -Namespace ROOT\ccm\SoftwareUpdates\UpdatesStore -Query "Select * from CCM_UpdateStatus WHERE Status = 'Missing' AND ExcludeForStateReporting = 'false'" | Select Article,Title,ProductID,UniqueID,UpdateClassification | Sort UniqueID -Unique
}  
return $Results
}

Function Get-CMSoftwareUpdateGroupAssignement{
    Param(
        $ComputerName = $env:COMPUTERNAME,
        $GroupName
    )
    $NameSpace = "ROOT\ccm\Policy\Machine\RequestedConfig"
    if ($GroupName){
        $Query = "Select * FROM CCM_UpdateCIAssignment WHERE AssignmentName = '$GroupName'"        
    }else{
        $Query = "Select * FROM CCM_UpdateCIAssignment"
    }    
    $Results = Get-WmiObject -ComputerName $ComputerName -Namespace $NameSpace -query $Query    
    return $Results
}

Function Get-CMSoftwareUpdatesFromUpdateGroup{
    Param(
        [Parameter(Mandatory=$true)]$GroupName
    )
    $SofwareUpdateGroup = Get-CMSoftwareUpdateGroupAssignement -GroupName $GroupName
    $AssignedCIs = $SofwareUpdateGroup.AssignedCIs      
    $AllFoundUpdates = @()
    foreach ($Update in $AssignedCIs){       
       $UpdateObj=[pscustomobject]@{"Article"="";"Id"="";"ModelName"="";"Version"="";"CIVersion"="";"ApplicabilityCondition"="";"EnforcementEnabled"="";"DisplayName"="";"UpdateClassification"=""}
            [xml]$Ux = $Update
           $UpdateObj.Article = $Ux.ci.DisplayName | Select-String -Pattern 'KB\d*' -AllMatches | % { $_.Matches } | % {$_.value}
           $UpdateObj.id = $ux.ci.id
           $UpdateObj.ModelName = $Ux.ci.ModelName
           $UpdateObj.Version = $ux.ci.version
           $UpdateObj.CIVersion = $ux.ci.civersion
           $UpdateObj.ApplicabilityCondition = $ux.ci.ApplicabilityCondition
           $UpdateObj.EnforcementEnabled = $ux.ci.EnforcementEnabled
           $UpdateObj.DisplayName = $Ux.ci.DisplayName
           $UpdateObj.UpdateClassification = $ux.ci.UpdateClassification
        if ($UpdateObj -ne $null){
            $AllFoundUpdates += $UpdateObj
        }        
    }#end foreach
    return $AllFoundUpdates
}

function Scan-WSUSOnline{
    #Main Array
    $KBsMissingDeployed=@()
    #Missing Updates, from WMI
    $missingUpdates = Get-CMMissingSoftwareUpdates
    #collection all Software Updates Deployments received by this machine
    $SUGDeployments = Get-CMSoftwareUpdateGroupAssignement | Select AssignmentName
    #go through all SUG Deployments looking for missing KBs
    foreach ($SUGDeployment in $SUGDeployments){
        $deployedUpdates=@()
        $deployedUpdates = Get-CMSoftwareUpdatesFromUpdateGroup -GroupName $SUGDeployment.AssignmentName
        foreach ($update in $deployedUpdates){
            if ($missingUpdates.UniqueID -contains $update.id){
                $missingKB = [pscustomobject]@{"DateTime"="";"ComputerName"="";"Source"="";"Article"="";"Title"=""}
                $missingKB.DateTime = $(Get-Date -UFormat %Y%m%d_%H%M%S)
                $missingKB.ComputerName = $env:COMPUTERNAME
                $missingKB.Source = "WSUS"
                $missingKB.Article = $update.Article
                $missingKB.Title = $($update.DisplayName -split 'KB')[0].Substring(0,$($update.DisplayName -split 'KB')[0].Length-2)  
                $KBsMissingDeployed+=$missingKB
            }
                
        }
    }
    return $KBsMissingDeployed | Sort Article -Unique
}

function Scan-WSUSOffline{
    param(
        $CabPath=".\wsusscn2.cab"
    )

    #Using WUA to Scan for Updates Offline with PowerShell 
    #VBS version: https://docs.microsoft.com/en-us/previous-versions/windows/desktop/aa387290(v=vs.85) 
 
    $UpdateSession = New-Object -ComObject Microsoft.Update.Session 
    $UpdateServiceManager  = New-Object -ComObject Microsoft.Update.ServiceManager 
    $UpdateService = $UpdateServiceManager.AddScanPackageService("Offline Sync Service", $CabPath, 1) 
    $UpdateSearcher = $UpdateSession.CreateUpdateSearcher()  
 
    $UpdateSearcher.ServerSelection = 3 #ssOthers 
    $UpdateSearcher.ServiceID = [string]$UpdateService.ServiceID 
 
    $SearchResult = $UpdateSearcher.Search("IsInstalled=0") # or "IsInstalled=0 and IsInstalled=1" to also list the installed updates as MBSA did 
 
    $Updates = $SearchResult.Updates 
 
    if($Updates.Count -eq 0){ 
        return $null 
    } 
    $MissingUpdatesCab = @()
    foreach($Update in $Updates){     
        $missingKB = [pscustomobject]@{"DateTime"="";"ComputerName"="";"Source"="";"Article"="";"Title"=""}
        $partString = $Update.Title -split 'KB'     
        $missingKB.DateTime = $(Get-Date -UFormat %Y%m%d_%H%M%S)
        $missingKB.ComputerName =  $env:COMPUTERNAME
        $missingKB.Source = "MSFT"
        $missingKB.Article = "KB"+$partString[1].Substring(0,$partString[1].Length-1)     
        $missingKB.title = $partString[0].Substring(0,$partString[0].Length-2)  
        $MissingUpdatesCab+=$missingKB
    
    }
    return $MissingUpdatesCab

}

$cabPath = $MyInvocation.MyCommand.Path
$cabPath = Split-Path -Parent -Path $cabPath
$updatesMissingfromMSFT = Scan-WSUSOffline -CabPath "$cabPath\wsusscn2.cab"
$updatesMissingFromWSUS = Scan-WSUSOnline

$updatesMissingfromMSFT | Export-Csv -Path \\sccm01\Data\Config\Logs\SCCM\WSUS\MissingUpdates.log -NoTypeInformation -Append -NoClobber
$updatesMissingFromWSUS | Export-Csv -Path \\sccm01\Data\Config\Logs\SCCM\WSUS\MissingUpdates.log -NoTypeInformation -Append -NoClobber