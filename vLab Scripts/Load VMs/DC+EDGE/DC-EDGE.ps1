dism /online /set-edition:ServerStandard /productkey:key /accepteula

Create DC+EDGE
dism /online /set-edition:ServerStandard /productkey:DNWWK-BRWPV-RR8GX-39X7P-2DMKR /accepteula
diskpart
list disk
select disk 1
online disk
attributes disk clear readonly
create partition primary
select partition 1
active
format FS=NTFS label=DC-Data
assign letter=E
exit
Get-NetAdapter -Name Ethernet | Rename-NetAdapter -NewName vLab
Get-NetAdapter -Name "Ethernet 2" | Rename-NetAdapter -NewName External
set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server'-name "fDenyTSConnections" -Value 0
Enable-NetFirewallRule -DisplayGroup "Remote Desktop"
set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -name "UserAuthentication" -Value 1   
New-NetFirewallRule -Name Allow_Ping -DisplayName “Allow Ping”  -Description “Packet Internet Groper ICMPv4” -Protocol ICMPv4 -IcmpType 8 -Enabled True -Profile Domain -Action Allow
Disable-NetAdapterBinding -Name vLab -ComponentID ms_tcpip6
Disable-NetAdapterBinding -Name External -ComponentID ms_tcpip6
Rename-Computer -NewName DC01 -Restart
New-NetIPAddress 10.0.0.1 -InterfaceAlias "vLab" -PrefixLength 24 -DefaultGateway 10.0.0.1
New-NetIPAddress 192.168.0.149 -InterfaceAlias "External" -PrefixLength 24 -DefaultGateway 192.168.0.1
Set-DnsClientServerAddress -InterfaceAlias "vLab" -ServerAddresses 10.0.0.1
Set-DnsClientServerAddress -InterfaceAlias "External" -ServerAddresses 192.168.0.1
Enable-NetAdapterIPsecOffload -Name vLab
Enable-NetAdapterIPsecOffload -Name External
Enable-NetAdapterRss -Name vLab
Enable-NetAdapterRss -Name External
Install-WindowsFeature AD-Domain-Services -IncludeManagementTools
Install-ADDSForest -DomainName vlab.varandas.com -DomainMode Win2012R2 -ForestMode Win2012R2 -DatabasePath "E:\NTDS" -SysvolPath "E:\SYSVOL" -LogPath "E:\Logs" -InstallDNS -DomainNetbiosName VLAB
Pa$$w0rd
Pa$$w0rd
Y

Install-WindowsFeature DHCP -IncludeManagementTools
Add-DhcpServerv4Scope -name "vLab" -StartRange 10.0.0.100 -EndRange 10.0.0.200 -SubnetMask 255.255.255.0
Set-DhcpServerv4OptionValue -DnsDomain vlab.varandas.com -DnsServer 10.0.0.1
Add-DhcpServerInDC -DnsName dc01.vlab.varandas.com
New-ADOrganizationalUnit -Name "Devices" -Path "DC=vlab,DC=varandas,DC=com" -ProtectedFromAccidentalDeletion $true
New-ADOrganizationalUnit -Name "StandardAccounts" -Path "DC=vlab,DC=varandas,DC=com" -ProtectedFromAccidentalDeletion $true
New-ADOrganizationalUnit -Name "PriviledgedAccounts" -Path "DC=vlab,DC=varandas,DC=com" -ProtectedFromAccidentalDeletion $true
New-ADOrganizationalUnit -Name "ServiceAccounts" -Path "DC=vlab,DC=varandas,DC=com" -ProtectedFromAccidentalDeletion $true
New-ADOrganizationalUnit -Name "SecurityGroups" -Path "DC=vlab,DC=varandas,DC=com" -ProtectedFromAccidentalDeletion $true
New-ADOrganizationalUnit -Name "Servers" -Path "CN=Devices,DC=vlab,DC=varandas,DC=com" -ProtectedFromAccidentalDeletion $true
New-ADOrganizationalUnit -Name "Workstations" -Path "CN=Devices,DC=vlab,DC=varandas,DC=com" -ProtectedFromAccidentalDeletion $true
New-ADUser -SamAccountName ADOps -AccountPassword (read-host "Set user password" -assecurestring) -name "ADOps" -enabled $true -PasswordNeverExpires $true -ChangePasswordAtLogon $false 
New-ADUser -SamAccountName xsDNS -AccountPassword (read-host "Set user password" -assecurestring) -name "xsDNS" -enabled $true -PasswordNeverExpires $true -ChangePasswordAtLogon $false 
New-ADUser -SamAccountName xsSQL03 -AccountPassword (read-host "Set user password" -assecurestring) -name "xsSQL03" -enabled $true -PasswordNeverExpires $true -ChangePasswordAtLogon $false 
New-ADUser -SamAccountName SrvOps -AccountPassword (read-host "Set user password" -assecurestring) -name "SrvOps" -enabled $true -PasswordNeverExpires $true -ChangePasswordAtLogon $false 
New-ADUser -SamAccountName SCCMOps -AccountPassword (read-host "Set user password" -assecurestring) -name "SCCMOps" -enabled $true -PasswordNeverExpires $true -ChangePasswordAtLogon $false 
New-ADUser -SamAccountName SQLOps -AccountPassword (read-host "Set user password" -assecurestring) -name "SQLOps" -enabled $true -PasswordNeverExpires $true -ChangePasswordAtLogon $false 
New-ADUser -SamAccountName User1 -AccountPassword (read-host "Set user password" -assecurestring) -name "User1" -enabled $true -PasswordNeverExpires $true -ChangePasswordAtLogon $false 
New-ADUser -SamAccountName User2 -AccountPassword (read-host "Set user password" -assecurestring) -name "User2" -enabled $true -PasswordNeverExpires $true -ChangePasswordAtLogon $false 
New-ADUser -SamAccountName User3 -AccountPassword (read-host "Set user password" -assecurestring) -name "User3" -enabled $true -PasswordNeverExpires $true -ChangePasswordAtLogon $false 
New-ADUser -SamAccountName xsSCCM-NAA -AccountPassword (read-host "Set user password" -assecurestring) -name "xsSCCM-NAA" -enabled $true -PasswordNeverExpires $true -ChangePasswordAtLogon $false 
New-ADUser -SamAccountName xsSCCM-CliPush -AccountPassword (read-host "Set user password" -assecurestring) -name "xsSCCM-CliPush" -enabled $true -PasswordNeverExpires $true -ChangePasswordAtLogon $false 
New-ADUser -SamAccountName xsSCCM-SQLRpt -AccountPassword (read-host "Set user password" -assecurestring) -name "xsSCCM-SQLRpt" -enabled $true -PasswordNeverExpires $true -ChangePasswordAtLogon $false 
New-ADUser -SamAccountName xsSCCM-DomainJoin -AccountPassword (read-host "Set user password" -assecurestring) -name "xsSCCM-DomainJoin" -enabled $true -PasswordNeverExpires $true -ChangePasswordAtLogon $false 
New-ADGroup -Path "CN=SecurityGroups,DC=vlab,DC=varandas,DC=com" -Name "SCCM SiteServers" -GroupScope Global -GroupCategory Security
Move-ADObject -Identity "CN=ADOps,CN=Users,DC=vlab,DC=varandas,DC=com" -TargetPath "CN=PriviledgedAccounts,DC=vlab,DC=varandas,DC=com"
Move-ADObject -Identity "CN=xsDNS,CN=PriviledgedAccounts,DC=vlab,DC=varandas,DC=com" -TargetPath "CN=ServiceAccounts,DC=vlab,DC=varandas,DC=com"
Move-ADObject -Identity "CN=SrvOps,CN=Users,DC=vlab,DC=varandas,DC=com" -TargetPath "CN=PriviledgedAccounts,DC=vlab,DC=varandas,DC=com"
Move-ADObject -Identity "CN=SCCMOps,CN=Users,DC=vlab,DC=varandas,DC=com" -TargetPath "CN=PriviledgedAccounts,DC=vlab,DC=varandas,DC=com"
Move-ADObject -Identity "CN=SQLOps,CN=Users,DC=vlab,DC=varandas,DC=com" -TargetPath "CN=PriviledgedAccounts,DC=vlab,DC=varandas,DC=com"
Move-ADObject -Identity "CN=User1,CN=Users,DC=vlab,DC=varandas,DC=com" -TargetPath "CN=StandardAccounts,DC=vlab,DC=varandas,DC=com"
Move-ADObject -Identity "CN=User2,CN=Users,DC=vlab,DC=varandas,DC=com" -TargetPath "CN=StandardAccounts,DC=vlab,DC=varandas,DC=com"
Move-ADObject -Identity "CN=User3,CN=Users,DC=vlab,DC=varandas,DC=com" -TargetPath "CN=StandardAccounts,DC=vlab,DC=varandas,DC=com"
New-ADGroup -Path "CN=Users,DC=vlab,DC=varandas,DC=com" -Name "SQL Admins" -GroupScope Global -GroupCategory Security
Add-ADPrincipalGroupMembership -Identity "CN=SQLOps,CN=Users,DC=vlab,DC=varandas,DC=com" -MemberOf "CN=SQL Admins,CN=Users,DC=vlab,DC=varandas,DC=com"
New-ADGroup -Path "CN=Users,DC=vlab,DC=varandas,DC=com" -Name "SCCM Admins" -GroupScope Global -GroupCategory Security
Add-ADPrincipalGroupMembership -Identity "CN=SCCMOps,CN=Users,DC=vlab,DC=varandas,DC=com" -MemberOf "CN=SCCM Admins,CN=Users,DC=vlab,DC=varandas,DC=com"
Add-ADPrincipalGroupMembership -Identity "CN=ADOps,CN=Users,DC=vlab,DC=varandas,DC=com" -MemberOf "CN=Enterprise Admins,CN=Users,DC=vlab,DC=varandas,DC=com"
Add-ADPrincipalGroupMembership -Identity "CN=ADOps,CN=Users,DC=vlab,DC=varandas,DC=com" -MemberOf "CN=Domain Admins,CN=Users,DC=vlab,DC=varandas,DC=com"
Get-ADOrganizationalUnit -filter * -Properties ProtectedFromAccidentalDeletion | where {$_.ProtectedFromAccidentalDeletion -eq $false} | Set-ADOrganizationalUnit -ProtectedFromAccidentalDeletion $true
Install-WindowsFeature -Name Routing -IncludeManagementTools
cmd
w32tm /config /computer:DC01.vlab.varandas.com /manualpeerlist:time.windows.com /syncfromflags:manual /update
sc config srv start=demand
powershell




Set-DhcpServerv4DnsSetting -DynamicUpdates Always -DeleteDnsRROnLeaseExpiry $true -UpdateDnsRRForOlderClients $true -DisableDnsPtrRRUpdate $false -NameProtection $false
Set-DhcpServerDnsCredential
Set-DnsServerScavenging -ScavengingState $true
=============================
Use 'Routing and Remote Access' in Server Manager to enable 'IPv4 Remote access server', 'IPv6 Remote access server', or both, on the Routing and Remote Access Properties page, as required by your network.
=========================
Restart-Computer




Add Machine with Fixed IP
Get-NetAdapter -Name Ethernet | Rename-NetAdapter -NewName vLab
New-NetIPAddress 10.0.0.XXX -InterfaceAlias "vLab" -PrefixLength 24
Set-DnsClientServerAddress -InterfaceAlias "vLab" -ServerAddresses 10.0.0.1 -DefaultGateway 10.0.0.1
Add-Computer -NewName ##MACH_NAME## -DomainName vlab.varandas.com
Restart-Computer

SCCM
dism /online /set-edition:ServerStandard /productkey:YNVH8-87QXH-JCRT8-WVQ84-F62G4 /accepteula
Get-NetAdapter -Name Ethernet | Rename-NetAdapter -NewName vLab
New-NetIPAddress 10.0.0.5 -InterfaceAlias "vLab" -PrefixLength 24 -DefaultGateway 10.0.0.1
Set-DnsClientServerAddress -InterfaceAlias "vLab" -ServerAddresses 10.0.0.1
Disable-NetAdapterBinding -Name vLab -ComponentID ms_tcpip6
set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server'-name "fDenyTSConnections" -Value 0
Enable-NetFirewallRule -DisplayGroup "Remote Desktop"
set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -name "UserAuthentication" -Value 1   
New-NetFirewallRule -Name Allow_Ping -DisplayName “Allow Ping”  -Description “Packet Internet Groper ICMPv4” -Protocol ICMPv4 -IcmpType 8 -Enabled True -Profile Domain -Action Allow
Install-WindowsFeature Net-Framework-Core -source d:\sources\sxs
Install-WindowsFeature BITS -source d:\sources\sxs
Install-WindowsFeature GPMC -source d:\sources\sxs
Install-WindowsFeature RDC -source d:\sources\sxs
Install-WindowsFeature RSAT -source d:\sources\sxs
Install-WindowsFeature Web-Windows-Auth -source d:\sources\sxs
Install-WindowsFeature Web-ISAPI-Ext -source d:\sources\sxs
Install-WindowsFeature Web-Metabase -source d:\sources\sxs
Install-WindowsFeature Web-WMI -source d:\sources\sxs
Install-WindowsFeature NET-Framework-Features -source d:\sources\sxs
Install-WindowsFeature Web-Asp-Net -source d:\sources\sxs
Install-WindowsFeature Web-Asp-Net45 -source d:\sources\sxs
Install-WindowsFeature NET-HTTP-Activation -source d:\sources\sxs
Install-WindowsFeature NET-Non-HTTP-Activ -source d:\sources\sxs
Add-Computer -NewName SCCM01 -DomainName vlab.varandas.com
Restart-Computer
SCCM Key BXH69-M62YX-QQD6R-3GPWX-8WMFY

SQL
dism /online /set-edition:ServerStandard /productkey:P7FGP-PNG3M-62KR9-TKC9T-VCF64 /accepteula
Get-NetAdapter -Name Ethernet | Rename-NetAdapter -NewName vLab
New-NetIPAddress 10.0.0.6 -InterfaceAlias "vLab" -PrefixLength 24 -DefaultGateway 10.0.0.1
Set-DnsClientServerAddress -InterfaceAlias "vLab" -ServerAddresses 10.0.0.1
Disable-NetAdapterBinding -Name vLab -ComponentID ms_tcpip6
set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server'-name "fDenyTSConnections" -Value 0
Enable-NetFirewallRule -DisplayGroup "Remote Desktop"
set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -name "UserAuthentication" -Value 1   
New-NetFirewallRule -Name Allow_Ping -DisplayName “Allow Ping”  -Description “Packet Internet Groper ICMPv4” -Protocol ICMPv4 -IcmpType 8 -Enabled True -Profile Domain -Action Allow
Add-Computer -NewName SQL01 -DomainName vlab.varandas.com
New-NetFirewallRule -DisplayName “SQL Server” -Direction Inbound –Protocol TCP –LocalPort 1433 -Action allow
New-NetFirewallRule -DisplayName “SQL Admin Connection” -Direction Inbound –Protocol TCP –LocalPort 1434 -Action allow
New-NetFirewallRule -DisplayName “SQL Service Broker” -Direction Inbound –Protocol TCP –LocalPort 4022 -Action allow
New-NetFirewallRule -DisplayName “SQL Debugger/RPC” -Direction Inbound –Protocol TCP –LocalPort 135 -Action allow
New-NetFirewallRule -DisplayName “SQL Browser” -Direction Inbound –Protocol TCP –LocalPort 2382 -Action allow
New-NetFirewallRule -DisplayName “SQL Analysis Services” -Direction Inbound –Protocol TCP –LocalPort 2383 -Action allow
New-NetFirewallRule -DisplayName “HTTP” -Direction Inbound –Protocol TCP –LocalPort 80 -Action allow
New-NetFirewallRule -DisplayName “SSL” -Direction Inbound –Protocol TCP –LocalPort 443 -Action allow
New-NetFirewallRule -DisplayName “SQL Database Management” -Direction Inbound –Protocol UDP –LocalPort 1434 -Action allow
New-NetFirewallRule -DisplayName “SQL Server Browse Button Service” -Direction Inbound –Protocol UDP –LocalPort 1433 -Action allow
SQL KEy MDCJV-3YX8N-WG89M-KV443-G8249
setspn -A MSSQLSvc/SQL01:1433 vlab\xsSQL01
setspn -A MSSQLSvc/SQL01.vlab.varandas.com:1433 vlab\xsSQL01


