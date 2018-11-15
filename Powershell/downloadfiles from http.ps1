function Save-TinyUrlFile
{
    PARAM (
        $TinyUrl="https://www.microsoft.com/en-us/learning/companion-moc.aspx",
        $DestinationFolder
    )

    $response = Invoke-WebRequest -URI $TinyUrl -UseBasicParsing
    $downloadlinks = $response.Links | Where {$_.href -like "*.zip" -and $_.href -like "*-ENU*"}
    $filename = [System.IO.Path]::GetFileName($response.BaseResponse.ResponseUri.OriginalString)
    $filepath = [System.IO.Path]::Combine($DestinationFolder, $filename)
    try
    {
        $filestream = [System.IO.File]::Create($filepath)
        $response.RawContentStream.WriteTo($filestream)
        $filestream.Close()
    }
    finally
    {
        if ($filestream)
        {
            $filestream.Dispose();
        }
    }
}

$TinyUrl="https://www.microsoft.com/en-us/learning/companion-moc.aspx"
$DestinationFolder = "C:\Users\rodri\Downloads\MSFT\"    
$response = Invoke-WebRequest -URI $TinyUrl -UseBasicParsing
$downloadlinks = $response.Links | Where {$_.href -like "*.zip" -and $_.href -like "*-ENU*"}
$content = $response.Content
foreach ($link in $downloadlinks){
    # courseID 
    try{
        $courseID = $($link.outerHTML).SubString(110,$($link.outerHTML).IndexOf("-ENU")-110)
        Write-Host "$courseID" -ForegroundColor Green
    }
    catch{
        Write-Host "$($link.outerHTML)" -ForegroundColor Yellow
    }        
    #download link
    $downloadpath = $($link.href)
    Write-Host "$($link.href)" -ForegroundColor Green
    #title
    $begin = $content.IndexOf("<p>$courseID</p></td><td><p>")+19+$courseID.Length    
    $end = $content.IndexOf("</p>",$begin)
    if($begin -gt 1000){
        $title = $($content.SubString($begin,$end-$begin))
        Write-Host "Title $title" -ForegroundColor Green
    }
    else{
        $title = "Unknown"
        Write-Host "Title $title" -ForegroundColor yellow
    }
    #$filepath = $DestinationFolder+$courseID+"-"+$title+".zip"    
    $filepath = $DestinationFolder+$courseid+"-"+$title+".zip"        
    $downloadpath = $($link.href) 
    $client = new-object System.Net.WebClient
    Write-Host $filepath -ForegroundColor Green
    try{
        $client.DownloadFile($downloadpath,$filepath)
        $client.Dispose
        
    }
    catch{
        Write-Host "Error Downloading" -ForegroundColor Red
    }
}