Get-NetAdapter -Name Ethernet | Rename-NetAdapter -NewName pLab
set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server'-name "fDenyTSConnections" -Value 0
Enable-NetFirewallRule -DisplayGroup "Remote Desktop"
set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -name "UserAuthentication" -Value 1   
New-NetFirewallRule -Name Allow_Ping -DisplayName "Allow Ping" -Description "Packet Internet Groper ICMPv4" -Protocol ICMPv4 -IcmpType 8 -Enabled True -Profile Domain -Action Allow
Disable-NetAdapterBinding -Name pLab -ComponentID ms_tcpip6
New-NetIPAddress 10.0.0.1 -InterfaceAlias "pLab" -PrefixLength 24 -DefaultGateway 10.0.0.2
Set-DnsClientServerAddress -InterfaceAlias "pLab" -ServerAddresses 10.0.0.1
Enable-NetAdapterIPsecOffload -Name pLab
Enable-NetAdapterRss -Name pLab
Rename-Computer -NewName DC01 -Restart