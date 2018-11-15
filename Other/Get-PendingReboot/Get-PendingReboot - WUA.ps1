Function Get-PendingReboot{
[CmdletBinding()]
param(
	[Parameter(Position=0,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
	[Alias("CN","Computer")]
	[String[]]$ComputerName="$env:COMPUTERNAME",
	[String]$ErrorLog
	)

Begin {  }## End Begin Script Block
Process {
  Foreach ($Computer in $ComputerName) {
	Try {
	    ## Making registry connection to the local/remote computer
	    $HKLM = [UInt32] "0x80000002"
	    $WMI_Reg = [WMIClass] "\\$Computer\root\default:StdRegProv"

	    					
	    ## Query WUAU from the registry
	    $RegWUAURebootReq = $WMI_Reg.EnumKey($HKLM,"SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\")
	    $WUAURebootReq = $RegWUAURebootReq.sNames -contains "RebootRequired"
						
	    Return $WUAURebootReq

	} Catch {
	    Write-Warning "$Computer`: $_"
	    ## If $ErrorLog, log the file to a user specified location/path
	    If ($ErrorLog) {
	        Out-File -InputObject "$Computer`,$_" -FilePath $ErrorLog -Append
	    }				
	}			
  }## End Foreach ($Computer in $ComputerName)			
}## End Process

End {  }## End End

}## End Function Get-PendingReboot

$status = Get-PendingReboot
<##Setting initial value for prime number multiplication
$reboot=0
#Standard Reboot Reasons
if ($status.CBServicing){
    #Write-Host "Installing WindowsComponents or Updates"
    $reboot*=3
}
if ($status.WindowsUpdate){
    #Write-Host "Updates Installed and waiting reboot to apply"
    $reboot*=5
}
if ($status.CCMSDK){
    #Write-Host "SCCM Client was updated and requires a reboot to resume functionality"
    $reboot*=7
}
if ($status.PendComputerRename){
    #Write-Host "Device had a rename and is waiting for a reboot to commit"
    $reboot*=11
}
if (($status.PendFileRename) -and ($status.PendFileRenVal.Count -gt 2)){
    #Write-Host "Device has file pending renaming."
    $reboot*=13
}

#Known Environment Issues
if (($status.PendFileRename) -and ($status.PendFileRenVal -like "*optibot*") -and - ($status.PendFileRenVal.Count -eq 2) -and ($reboot -eq 1)){
    #Write-Host "False Positive caused by ITAssist. No other Reboot reason found"
    $reboot*=17
}
if ($status.RebootPending){
    #Write-Host "Machine is Pending Reboot"
    #$reboot=$true
    #$uptime = Get-Uptime
    #$reboot = $reboot.ToString()+"#"+$uptime
}
else{
    $reboot=0
}#>
return $status