#format drives
Get-NetAdapter -Name Ethernet | Rename-NetAdapter -NewName vLab
New-NetIPAddress 10.0.0.3 -InterfaceAlias "vLab" -PrefixLength 24 -DefaultGateway 10.0.0.2 -AddressFamily IPv4
set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server'-name "fDenyTSConnections" -Value 0
Install-WindowsFeature Net-Framework-Core -source D:\sources\sxs