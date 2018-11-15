$logShare = "ConfigMgr-Logs"
$logGroup = "NA\SCCMINFRA-LOGS.UG"
$adminGroup = "NA\SCCM-ADMINS.UG"
$LogPath = Get-ChildItem -Path HKLM:\Software\Microsoft\SMS\Tracing\
$LogPath = $logpath[0].GetValue('Tracefilename')
$logFolder = $LogPath.Substring(0,$LogPath.LastIndexOf('\')+1)
$sharevalid=$false
Write-Verbose "Log Folder: $logFolder"
Write-Verbose "Share Name: $logShare"
Write-Verbose "Log Group: $logGroup"
Write-Verbose "Admin Group Folder: $adminGroup"

$shares = gwmi -Class win32_share | Where {$_.Name -eq $logShare}| select -ExpandProperty Name  

if ($shares.count -eq 0){
    Write-Verbose "Share does not exist. Flagging for creation"
    return 1
}
if($shares.count -gt 1){
    Write-Verbose "Multiple Shares found. Aborting Script"
    return 3
}
Write-Verbose "Single Share found. Checking its settings."
foreach ($share in $shares) { 
    $acl = $null     
    $objShareSec = Get-WMIObject -Class Win32_LogicalShareSecuritySetting -Filter "name='$Share'" 
    try { 
        $SD = $objShareSec.GetSecurityDescriptor().Descriptor           
        foreach($ace in $SD.DACL){  
            $UserName = $ace.Trustee.Name                 
            If ($ace.Trustee.Domain -ne $Null) {$UserName = "$($ace.Trustee.Domain)\$UserName"}   
            If ($ace.Trustee.Name -eq $Null) {$UserName = $ace.Trustee.SIDString }     
            [Array]$ACL += New-Object Security.AccessControl.FileSystemAccessRule($UserName, $ace.AccessMask, $ace.AceType) 
            } #end foreach ACE           
        } # end try 
    catch { 
        #Write-Host "Unable to obtain permissions for $share" 
        return 1
    } 
    Write-Verbose "Loaded Share permissions. Looking for required perm."    
    foreach ($perm in $acl){        
        if (($perm.IdentityReference -eq $logGroup) -and ($perm.FileSystemRights -like "*ReadAndExecute*")){
            Write-Verbose "Required perms were found in share."    
            $sharevalid=$true
        }
    }    
}

Write-Verbose "Checking NTFS Perms"
$ntfsPerm = Get-ACL $logFolder
$ntfsValid=$false
foreach ($obj in $ntfsPerm.Access){    
    If (($obj.IdentityReference -eq $logGroup) -and ($obj.FileSystemRights -like "*ReadAndExecute*")){
        Write-Verbose "Required NTFS perms were found in folder."    
        $ntfsValid=$true            
    }        
}

if($sharevalid -and $ntfsValid){
    Write-Verbose "Log Share valid"
    return 0
}
else{
    Write-Verbose "NTFS or Share not compliant. Flagging for recreation"
    return 1
}