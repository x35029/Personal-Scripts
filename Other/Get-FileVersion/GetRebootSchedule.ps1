 Add-PSSnapIn citrix.xenapp.commands
 $servers =  get-Content -Path "C:\temp\Servers.txt" 
Get-XAServerConfiguration -Servername Daltss109
#foreach ($Computer in $Servers){
#    $result = Get-WmiObject -ComputerName $computer -Query "SELECT * FROM CIM_DataFile WHERE Drive ='C:' AND Path='\\Program Files\\Citrix\\System32\\' AND FileName='statui' AND Extension='dll'" | select Version
#    write-host $computer,$result
#    write-output "$computer,$result"  >> c:\temp\output.txt    
#}