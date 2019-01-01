#get today's date
$date = Get-Date -UFormat %Y%m%d-%H%M%S

#set daily backup location
$backupFolder = "D:\Lab\Backup\"
#create folder for daily backup
New-Item -ItemType directory -Path $backupFolder$date | Out-Null

#getting VMs and exporting
$hostVMs = Get-VM
foreach ($vm in $hostVMs){
    Export-VM -Name $vm.Name -Path $backupFolder$date
    #New-Item -ItemType directory -Path $backupFolder$date\$($vm.Name) | Out-Null
}
#checking amount of daily backups. if more than a week, delete oldest
Write-Host "This is the Backup folder parent: $backupfolder"
$backupFolders = Get-ChildItem -Path $backupFolder | Sort -Property CreationTime
While ($backupFolders.count -gt 7){
    Remove-Item -Path $backupFolders[0].FullName -Recurse -Force
    #Write-Host $backupFolders[0].Name
    $backupFolders = Get-ChildItem -Path $backupFolder | Sort -Property CreationTime    
}
#if weekly backup
if ((Get-Date).DayOfWeek -eq "Sunday"){
    $backupFolder = "J:\Lab\Backup\"
    New-Item -ItemType directory -Path $backupFolder$date | Out-Null
    #getting VMs and exporting
    $hostVMs = Get-VM
    foreach ($vm in $hostVMs){
        Export-VM -Name $vm.Name -Path $backupFolder$date
        #New-Item -ItemType directory -Path $backupFolder$date\$($vm.Name) | Out-Null
    }
    $backupFolders = Get-ChildItem -Path $backupFolder | Sort -Property CreationTime
    While ($backupFolders.count -gt 8){
        Remove-Item -Path $backupFolders[0].FullName -Recurse -Force
        Write-Host $backupFolders[0].Name
        $backupFolders = Get-ChildItem -Path $backupFolder | Sort -Property CreationTime    
    }    
}
#Optimize Disks
$disks = Get-ChildItem L:\vDisks
foreach($disk in $disks){
    Optimize-VHD -Path $disk.FullName -Mode Full       
}