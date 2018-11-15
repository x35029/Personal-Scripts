$UserName = (Get-WmiObject Win32_Process | Where {$_.ProcessName -eq 'Explorer.exe'}).GetOwner().User
$UserDomain = (Get-WmiObject Win32_Process | Where {$_.ProcessName -eq 'Explorer.exe'}).GetOwner().Domain
$UserSID = (Get-WmiObject Win32_UserAccount -Filter "name = '$UserName' AND domain = '$UserDomain'").SID