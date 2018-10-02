﻿Get-NetAdapter -Name Ethernet | Rename-NetAdapter -NewName vLab
Get-NetAdapter -Name "Ethernet 2" | Rename-NetAdapter -NewName External
New-NetIPAddress 10.0.0.2 -InterfaceAlias "vLab" -PrefixLength 24 -DefaultGateway 10.0.0.2
set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server'-name "fDenyTSConnections" -Value 0