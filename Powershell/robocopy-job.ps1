function robocopy-job  
{ 
    [CmdletBinding()] 
 
    param ( 
            [Parameter(Mandatory = $true)] 
            [string] $Source 
        , [Parameter(Mandatory = $true)] 
            [string] $Destination) 
 
    $robocopycmd = "robocopy ""$source"" ""$destination"" /mir /bytes" 
    $Staging = Invoke-Expression "$robocopycmd /l" 
    $totalnewfiles = $Staging -match 'new file' 
    $totalmodified = $Staging -match 'newer' 
    $totalfiles = $totalnewfiles + $totalmodified
    $TotalBytesarray = @()
    foreach ($file in $totalfiles)  
    { 
        if ($file.substring(13,13).trim().length -eq 9) {$TotalBytesarray+= $file.substring(13,15).trim() } 
        else {$TotalBytesarray+= $file.substring(13,13).trim()} 
    } 
    $totalbytes = (($TotalBytesarray | Measure-Object -Sum).sum)
 
    $robocopyjob = Start-Job -Name robocopy -ScriptBlock {param ($command) ; Invoke-Expression -Command $command} -ArgumentList $robocopycmd 
 
    while ($robocopyjob.State -eq 'running') 
    { 
        $progress = Receive-Job -Job $robocopyjob -Keep -ErrorAction SilentlyContinue
		if ($progress)
		{
			$copiedfiles = ($progress | Select-String -SimpleMatch 'new file', 'newer')
			if ($copiedfiles.count -le 0) { $TotalFilesCopied = $copiedfiles.Count }
			else { $TotalFilesCopied = $copiedfiles.Count - 1 }
			$FilesRemaining = ($totalfiles.count - $TotalFilesCopied)
			$Bytesarray = @()
			foreach ($Newfile in $copiedfiles)
			{
				if ($Newfile.tostring().substring(13, 13).trim().length -eq 9) { $Bytesarray += $Newfile.tostring().substring(13, 15).trim() }
				else { $Bytesarray += $Newfile.tostring().substring(13, 13).trim() }
			}
			$bytescopied = ([int64]$Bytesarray[-1] * ($Filepercentcomplete/100))
			$totalfilebytes = [int64]$Bytesarray[-1]
			$TotalBytesCopied = ((($Bytesarray | Measure-Object -Sum).sum) - $totalfilebytes) + $bytescopied
			$TotalBytesRemaining = ($totalbytes - $totalBytesCopied)
			if ($copiedfiles)
			{
				if ($copiedfiles[-1].tostring().substring(13, 13).trim().length -eq 9) { $currentfile = $copiedfiles[-1].tostring().substring(28).trim() }
				else { $currentfile = $copiedfiles[-1].tostring().substring(25).trim() }
			}
			$totalfilescount = $totalfiles.count
			if ($progress[-1] -match '%') { $Filepercentcomplete = $progress[-1].substring(0, 3).trim() }
			else { $Filepercentcomplete = 0 }
			$totalPercentcomplete = (($TotalBytesCopied/$totalbytes) * 100)
			if ($totalbytes -gt 2gb) { $BytesCopiedprogress = "{0:N2}" -f ($totalBytesCopied/1gb); $totalbytesprogress = "{0:N2}" -f ($totalbytes/1gb); $bytes = 'Gbytes' }
			else { $BytesCopiedprogress = "{0:N2}" -f ($totalBytesCopied/1mb); $totalbytesprogress = "{0:N2}" -f ($totalbytes/1mb); $bytes = 'Mbytes' }
			if ($totalfilebytes -gt 1gb) { $totalfilebytes = "{0:N2}" -f ($totalfilebytes/1gb); $bytescopied = "{0:N2}" -f ($bytescopied/1gb); $filebytes = 'Gbytes' }
			else { $totalfilebytes = "{0:N2}" -f ($totalfilebytes/1mb); $bytescopied = "{0:N2}" -f ($bytescopied/1mb); $filebytes = 'Mbytes' }
			
			Write-Progress -Id 1 -Activity "Copying files from $source to $destination, $totalfilescopied of $totalfilescount files copied" -Status "$bytescopiedprogress of $totalbytesprogress $bytes copied" -PercentComplete $totalPercentcomplete
			Write-Progress -Id 2 -Activity "$currentfile" -status "$bytescopied of $totalfilebytes $filebytes" -PercentComplete $Filepercentcomplete
		}
		
	}
	
	Write-Progress -Id 1 -Activity "Copying files from $source to $destination" -Status 'Completed' -Completed 
    Write-Progress -Id 2 -Activity 'Done' -Completed 
    $results = Receive-Job -Job $robocopyjob 
    Remove-Job $robocopyjob 
    $results[5] 
    $results[-13..-1] 
} 