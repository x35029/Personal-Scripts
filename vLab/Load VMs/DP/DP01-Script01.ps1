#format drives
Get-NetAdapter -Name Ethernet | Rename-NetAdapter -NewName pLab
New-NetIPAddress 10.0.0.6 -InterfaceAlias "pLab" -PrefixLength 24 -DefaultGateway 10.0.0.2 -AddressFamily IPv4
Set-DnsClientServerAddress -InterfaceAlias pLab -ServerAddresses 10.0.0.1
set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server'-name "fDenyTSConnections" -Value 0
Enable-NetFirewallRule -DisplayGroup "Remote Desktop"
set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -name "UserAuthentication" -Value 1   
New-NetFirewallRule -Name Allow_Ping -DisplayName "Allow Ping"  -Description "Packet Internet Groper ICMPv4" -Protocol ICMPv4 -IcmpType 8 -Enabled True -Profile Domain -Action Allow
Disable-NetAdapterBinding -Name pLab -ComponentID ms_tcpip6
Enable-NetAdapterIPsecOffload -Name pLab
Enable-NetAdapterRss -Name pLab
Install-WindowsFeature Net-Framework-Core -source D:\sources\sxs
Add-Computer -DomainName plab.varandas.com -Restart -NewName DP01