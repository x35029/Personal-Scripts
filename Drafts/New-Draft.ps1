#get-childitem -Path "M:\Lab\Hyper-V\vDisks\" | Where-Object -Property Name -like *SQL*
#$date = Get-Date -UFormat %Y%m%d-%H%m%S
#$backupFolder = "D:\Lab\Backup\$date"
#New-Item -ItemType directory -Path $backupFolder
(Get-Date).DayOfWeek