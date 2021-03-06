﻿Get-NetAdapter -Name Ethernet | Rename-NetAdapter -NewName vLab
Get-NetAdapter -Name "Ethernet 2" | Rename-NetAdapter -NewName External
New-NetIPAddress 10.0.0.2 -InterfaceAlias "pLab" -PrefixLength 24 -DefaultGateway 10.0.0.2
set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server'-name "fDenyTSConnections" -Value 0
Enable-NetFirewallRule -DisplayGroup "Remote Desktop"
set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -name "UserAuthentication" -Value 1   
New-NetFirewallRule -Name Allow_Ping -DisplayName "Allow Ping"  -Description "Packet Internet Groper ICMPv4" -Protocol ICMPv4 -IcmpType 8 -Enabled True -Profile Domain -Action Allow
Disable-NetAdapterBinding -Name vLab -ComponentID ms_tcpip6
Disable-NetAdapterBinding -Name External -ComponentID ms_tcpip6
Enable-NetAdapterIPsecOffload -Name vLab
Enable-NetAdapterIPsecOffload -Name External
Enable-NetAdapterRss -Name vLab
Enable-NetAdapterRss -Name External
Add-Computer -DomainName vlab.varandas.com -Restart -NewName EDGE01

#Install Configure Remote Access and Routing
Install-WindowsFeature -Name RemoteAccess
Install-WindowsFeature -Name Routing

#Install and Configure DNS, join to DC DNS setup forward to Google