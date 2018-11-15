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
	    ## Setting pending values to false to cut down on the number of else statements
	    $PendFileRename = $false
       
	    ## Making registry connection to the local/remote computer
	    $HKLM = [UInt32] "0x80000002"
	    $WMI_Reg = [WMIClass] "\\$Computer\root\default:StdRegProv"
		
	    ## Query PendingFileRenameOperations from the registry
	    $RegSubKeySM = $WMI_Reg.GetMultiStringValue($HKLM,"SYSTEM\CurrentControlSet\Control\Session Manager\","PendingFileRenameOperations")
	    $RegValuePFRO = $RegSubKeySM.sValue
						
	    ## If PendingFileRenameOperations has a value set $RegValuePFRO variable to $true
	    If ($RegValuePFRO) {
		    $PendFileRename = $true
	    }

	    ## Creating Custom PSObject and Select-Object Splat
	    $SelectSplat = @{
	        Property=(	            
	            'PendFileRename',
	            'PendFileRenVal'	            
	        )}
	    New-Object -TypeName PSObject -Property @{	       
	        PendFileRename=$PendFileRename
	        PendFileRenVal=$RegValuePFRO	        
	    } | Select-Object @SelectSplat

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

return $status