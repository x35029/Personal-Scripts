 $servers =  get-Content -Path "C:\temp\Servers.txt" 
 $filePath = 'D:\PMT\Update.txt'

foreach ($Computer in $Servers){
    $result = Get-WmiObject -ComputerName $computer -Query "SELECT * FROM CIM_DataFile WHERE Drive ='D:' AND Path='\\PMT\\' AND FileName='Update' AND Extension='txt'" | select LastModified
    $goFlagInfo = Get-Content "\\$computer\D$\PMT\goflag.txt"
    $goBackInfo = Get-Content "\\$computer\D$\PMT\goback.txt"
    write-host $computer,",",$result,",",$goFlagInfo,",",$goBackInfo
    write-output "$computer,$result,$goFlagInfo,$goBackInfo"  >> c:\temp\outputXme.txt    
}