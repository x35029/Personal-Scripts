#LogName
$logname = "Output"+$(Get-Date -UFormat %Y-%m-%d.%H.%M.%s)+".csv"

#Robocopy CSV files from Share
Start-Process -FilePath robocopy -ArgumentList "\\na.xom.com\DFS\HOE\WDS-Eng\Logs\NetlogonHotfix\CSV .\files /MIR /W:3 /R:3" -Wait

#loading file list
$fileList = Get-ChildItem .\files
#setting complied log header
"TimeStamp,Machine Name,OS Version,KB Number,Is Applicable,Is Patched,Able To Patch,WUSA Exit Code,Reboot Setup Code,Script Exit Code,Status,logtype,year,month,day" | Add-Content $logname

#setting $mustpause as false. $mustpause is used when a log string is found and its meaning is not coded
$mustpause=$false

$outterLoopSize = $fileList.Count
$outterLoopCounter = 0

foreach ($file in $fileList){
    #Progress for OutterLoop
    Write-Progress -Activity "Going through CSV files..." -Status 'Reading File' -PercentComplete $($outterLoopCounter/$outterLoopSize*100) -CurrentOperation $($file.Name)
    $outterLoopCounter++
    Write-Host ""
    Write-Host "========================================================================================="
    Write-Host ""
    Write-Host "    Processing $($file.Name)"
    $content = Get-Content .\files\$file        
    Write-Host "    Total Lines $($content.Count)"
    #Tracks number os usable lines in a CSV. Starts as ZERO
    $entries=0
    $lineCnt=0
    foreach ($line in $content){          
        #$record defines is a line will be stored after compile or not. Default is yes
        $record=$true     
        $lineCnt++           
        #Generic Try/Catch 
        try{ 
            #if line is not a header...
            if ( !($line.StartsWith("TimeStamp"))){            
                if( ($line.Contains("-2145124329")) -or ($line.Contains(",5004")) -or ($line.Contains("False,,,,,0")) ){
                    $line = $line+",Update Not Applicable"
                }                
                elseif($line.Contains(",53,")){
                    $line = $line+",Not Enough Storage"
                } 
                elseif (($line -eq $null) -or ($line -eq "")){
                    Write-Host "NULL log line" -ForegroundColor DarkRed
                    $record=$false
                }           
                elseif($line.Contains(",,,,,,,5002")){                    
                    $line = $line+",Device in Exception"
                }
                elseif($line.Contains(",,,,,,5002")){
                    $line = $line.Replace(",,5002",",,,5002")                    
                    $line = $line+",Device in Exception"
                }
                elseif($line.Contains(",1618")){
                    $line = $line+",Update Install Already in progress"
                }
                elseif($line.Contains(",59")){
                    $line = $line+",Unknown Error 59"
                }
                elseif($line.Contains(",64")){
                    $line = $line+",Unknown Error 64"
                }
                 elseif($line.Contains("True,False,True,3,,0")){
                    $line = $line+",Unknown Error 3"
                }
                elseif( ($line.Contains(",False,True,3010,0,0")) -or ($line.Contains(",False,True,3010,,0")) ){
                    $line = $line+",Update installed/Pending Reboot"
                }
                elseif($line.Contains(",True,False,True,0,,0")){
                    $line = $line+",Update installed"
                }
                elseif($line.Contains(",True,False,True,,,0")){
                    $line = $line+",Needs update/MissingWUSAExitCode"
                }
                elseif(($line.Contains(",True,True,,,0")) -or ($line.Contains(",True,True,True,")) -or ($line.Contains(",2359302,"))){
                    $line = $line+",Update Already Installed"
                }                
                else{
                    $line = $line+",NO STATUS"
                    $mustpause = $true
                }
                if($record){
                    $year = ","+$line.Substring(0,4)
                    $month = ","+$line.Substring(4,2)
                    $day = ","+$line.Substring(6,2)
                    if($lineCnt -eq $content.Count){                        
                        $line = $line+",LastStatus"+$year+$month+$day
                        Write-Host "$linecnt - $line" -ForegroundColor Yellow
                    }
                    elseif($lineCnt -eq 2){                        
                        $line = $line+",FirstStatus"+$year+$month+$day
                        Write-Host "$linecnt - $line" -ForegroundColor DarkYellow
                    }
                    else{                        
                        Write-Host "$linecnt - $line" -ForegroundColor DarkYellow
                        $line = $line+","+$year+$month+$day
                    }
                    $line | Add-Content $logname
                    $entries++
                }
            }            
        }
        catch{
            Write-Host "UNABLE TO PROCESS |$line|" -ForegroundColor DarkRed
            $mustpause=$true
        }
                     
    } 
        
    if($mustpause){
        pause
        $mustpause=$false
    }
    if($entries -eq 0){
                $line = ",$($file.BaseName),,,,,,,,,No Log Info"
                Write-Host $line -ForegroundColor Yellow
                $line | Add-Content $logname
            }
}