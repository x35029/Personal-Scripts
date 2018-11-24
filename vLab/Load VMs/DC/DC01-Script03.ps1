Install-WindowsFeature DHCP -IncludeManagementTools 
Add-DhcpServerv4Scope -name "pLab" -StartRange 10.0.0.100 -EndRange 10.0.0.200 -SubnetMask 255.255.255.0
Set-DhcpServerv4OptionValue -DnsDomain pLab.varandas.com -DnsServer 10.0.0.1
Add-DhcpServerInDC -DnsName dc01.pLab.varandas.com
Set-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\ServerManager\Roles\12 -Name ConfigurationState -Value 2;
Restart-Service DHCPServer

New-ADOrganizationalUnit -Name "Devices" -Path "DC=pLab,DC=varandas,DC=com" -ProtectedFromAccidentalDeletion $true
New-ADOrganizationalUnit -Name "Servers" -Path "OU=Devices,DC=pLab,DC=varandas,DC=com" -ProtectedFromAccidentalDeletion $true
New-ADOrganizationalUnit -Name "Workstations" -Path "OU=Devices,DC=pLab,DC=varandas,DC=com" -ProtectedFromAccidentalDeletion $true
New-ADOrganizationalUnit -Name "SQL" -Path "OU=Servers,OU=Devices,DC=pLab,DC=varandas,DC=com" -ProtectedFromAccidentalDeletion $true
New-ADOrganizationalUnit -Name "RDS" -Path "OU=Servers,OU=Devices,DC=pLab,DC=varandas,DC=com" -ProtectedFromAccidentalDeletion $true
New-ADOrganizationalUnit -Name "Web" -Path "OU=Servers,OU=Devices,DC=pLab,DC=varandas,DC=com" -ProtectedFromAccidentalDeletion $true
New-ADOrganizationalUnit -Name "Internet" -Path "OU=Web,OU=Servers,OU=Devices,DC=pLab,DC=varandas,DC=com" -ProtectedFromAccidentalDeletion $true
New-ADOrganizationalUnit -Name "Intranet" -Path "OU=Web,OU=Servers,OU=Devices,DC=pLab,DC=varandas,DC=com" -ProtectedFromAccidentalDeletion $true
New-ADOrganizationalUnit -Name "File" -Path "OU=Servers,OU=Devices,DC=pLab,DC=varandas,DC=com" -ProtectedFromAccidentalDeletion $true
New-ADOrganizationalUnit -Name "Virtual" -Path "OU=Workstations,OU=Devices,DC=pLab,DC=varandas,DC=com" -ProtectedFromAccidentalDeletion $true
New-ADOrganizationalUnit -Name "Physical" -Path "OU=Workstations,OU=Devices,DC=pLab,DC=varandas,DC=com" -ProtectedFromAccidentalDeletion $true
New-ADOrganizationalUnit -Name "StandardAccounts" -Path "DC=pLab,DC=varandas,DC=com" -ProtectedFromAccidentalDeletion $true
New-ADOrganizationalUnit -Name "PriviledgedAccounts" -Path "DC=pLab,DC=varandas,DC=com" -ProtectedFromAccidentalDeletion $true
New-ADOrganizationalUnit -Name "ServiceAccounts" -Path "DC=pLab,DC=varandas,DC=com" -ProtectedFromAccidentalDeletion $true
New-ADOrganizationalUnit -Name "SecurityGroups" -Path "DC=pLab,DC=varandas,DC=com" -ProtectedFromAccidentalDeletion $true

New-ADUser -SamAccountName ADOps -AccountPassword (ConvertTo-SecureString -AsPlainText 'pLabPa$$w0rd' -Force) -name "ADOps" -enabled $true -PasswordNeverExpires $true -ChangePasswordAtLogon $false -Path "OU=PriviledgedAccounts,DC=pLab,DC=varandas,DC=com"
New-ADUser -SamAccountName SrvOps -AccountPassword (ConvertTo-SecureString -AsPlainText 'pLabPa$$w0rd' -Force) -name "SrvOps" -enabled $true -PasswordNeverExpires $true -ChangePasswordAtLogon $false -Path "OU=PriviledgedAccounts,DC=pLab,DC=varandas,DC=com"
New-ADUser -SamAccountName SCCMOps -AccountPassword (ConvertTo-SecureString -AsPlainText 'pLabPa$$w0rd' -Force) -name "SCCMOps" -enabled $true -PasswordNeverExpires $true -ChangePasswordAtLogon $false -Path "OU=PriviledgedAccounts,DC=pLab,DC=varandas,DC=com"
New-ADUser -SamAccountName SQLOps -AccountPassword (ConvertTo-SecureString -AsPlainText 'pLabPa$$w0rd' -Force) -name "SQLOps" -enabled $true -PasswordNeverExpires $true -ChangePasswordAtLogon $false -Path "OU=PriviledgedAccounts,DC=pLab,DC=varandas,DC=com"
New-ADUser -SamAccountName BackupOps -AccountPassword (ConvertTo-SecureString -AsPlainText 'pLabPa$$w0rd' -Force) -name "BackupOps" -enabled $true -PasswordNeverExpires $true -ChangePasswordAtLogon $false -Path "OU=PriviledgedAccounts,DC=pLab,DC=varandas,DC=com"
New-ADUser -SamAccountName NetworkOps -AccountPassword (ConvertTo-SecureString -AsPlainText 'pLabPa$$w0rd' -Force) -name "NetworkOps" -enabled $true -PasswordNeverExpires $true -ChangePasswordAtLogon $false -Path "OU=PriviledgedAccounts,DC=pLab,DC=varandas,DC=com"
New-ADUser -SamAccountName xsSCCM-NAA -AccountPassword (ConvertTo-SecureString -AsPlainText 'pLabPa$$w0rd' -Force) -name "xsSCCM-NAA" -enabled $true -PasswordNeverExpires $true -ChangePasswordAtLogon $false -Path "OU=ServiceAccounts,DC=pLab,DC=varandas,DC=com"
New-ADUser -SamAccountName xsSCCM-CliPush -AccountPassword (ConvertTo-SecureString -AsPlainText 'pLabPa$$w0rd' -Force) -name "xsSCCM-CliPush" -enabled $true -PasswordNeverExpires $true -ChangePasswordAtLogon $false -Path "OU=ServiceAccounts,DC=pLab,DC=varandas,DC=com"
New-ADUser -SamAccountName xsSCCM-SQLRpt -AccountPassword (ConvertTo-SecureString -AsPlainText 'pLabPa$$w0rd' -Force) -name "xsSCCM-SQLRpt" -enabled $true -PasswordNeverExpires $true -ChangePasswordAtLogon $false -Path "OU=ServiceAccounts,DC=pLab,DC=varandas,DC=com"
New-ADUser -SamAccountName xsSCCM-DomainJoin -AccountPassword (ConvertTo-SecureString -AsPlainText 'pLabPa$$w0rd' -Force) -name "xsSCCM-DomainJoin" -enabled $true -PasswordNeverExpires $true -ChangePasswordAtLogon $false -Path "OU=ServiceAccounts,DC=pLab,DC=varandas,DC=com"
New-ADUser -SamAccountName xsDNS -AccountPassword (ConvertTo-SecureString -AsPlainText 'pLabPa$$w0rd' -Force) -name "xsDNS" -enabled $true -PasswordNeverExpires $true -ChangePasswordAtLogon $false -Path "OU=ServiceAccounts,DC=pLab,DC=varandas,DC=com"
New-ADUser -SamAccountName xsDHCP -AccountPassword (ConvertTo-SecureString -AsPlainText 'pLabPa$$w0rd' -Force) -name "xsDHCP" -enabled $true -PasswordNeverExpires $true -ChangePasswordAtLogon $false -Path "OU=ServiceAccounts,DC=pLab,DC=varandas,DC=com"
New-ADUser -SamAccountName xsSQL01 -AccountPassword (ConvertTo-SecureString -AsPlainText 'pLabPa$$w0rd' -Force) -name "xsSQL1" -enabled $true -PasswordNeverExpires $true -ChangePasswordAtLogon $false -Path "OU=ServiceAccounts,DC=pLab,DC=varandas,DC=com"

Add-ADPrincipalGroupMembership -Identity "CN=SrvOps,OU=PriviledgedAccounts,DC=pLab,DC=varandas,DC=com" -MemberOf "CN=Server Operators,CN=Builtin,DC=pLab,DC=varandas,DC=com"
Add-ADPrincipalGroupMembership -Identity "CN=BackupOps,OU=PriviledgedAccounts,DC=pLab,DC=varandas,DC=com" -MemberOf "CN=Backup Operators,CN=Builtin,DC=pLab,DC=varandas,DC=com"

New-ADGroup -Path "OU=SecurityGroups,DC=pLab,DC=varandas,DC=com" -Name "Network Admins" -GroupScope Global -GroupCategory Security
Add-ADPrincipalGroupMembership -Identity "CN=NetworkOps,OU=PriviledgedAccounts,DC=pLab,DC=varandas,DC=com" -MemberOf "CN=Network Admins,OU=SecurityGroups,DC=pLab,DC=varandas,DC=com"
Add-ADPrincipalGroupMembership -Identity "CN=NetworkOps,OU=PriviledgedAccounts,DC=pLab,DC=varandas,DC=com" -MemberOf "CN=RAS and IAS Servers,CN=Users,DC=pLab,DC=varandas,DC=com"
Add-ADPrincipalGroupMembership -Identity "CN=NetworkOps,OU=PriviledgedAccounts,DC=pLab,DC=varandas,DC=com" -MemberOf "CN=Network Configuration Operators,CN=Builtin,DC=pLab,DC=varandas,DC=com"

New-ADGroup -Path "OU=SecurityGroups,DC=pLab,DC=varandas,DC=com" -Name "SQL Admins" -GroupScope Global -GroupCategory Security
New-ADGroup -Path "OU=SecurityGroups,DC=pLab,DC=varandas,DC=com" -Name "SCCM SiteServers" -GroupScope Global -GroupCategory Security
Add-ADPrincipalGroupMembership -Identity "CN=SQLOps,OU=PriviledgedAccounts,DC=pLab,DC=varandas,DC=com" -MemberOf "CN=SQL Admins,OU=SecurityGroups,DC=pLab,DC=varandas,DC=com"

New-ADGroup -Path "OU=SecurityGroups,DC=pLab,DC=varandas,DC=com" -Name "SCCM Admins" -GroupScope Global -GroupCategory Security
Add-ADPrincipalGroupMembership -Identity "CN=SCCMOps,OU=PriviledgedAccounts,DC=pLab,DC=varandas,DC=com" -MemberOf "CN=SCCM Admins,OU=SecurityGroups,DC=pLab,DC=varandas,DC=com"

Add-ADPrincipalGroupMembership -Identity "CN=ADOps,OU=PriviledgedAccounts,DC=pLab,DC=varandas,DC=com" -MemberOf "CN=Enterprise Admins,CN=Users,DC=pLab,DC=varandas,DC=com"
Add-ADPrincipalGroupMembership -Identity "CN=ADOps,OU=PriviledgedAccounts,DC=pLab,DC=varandas,DC=com" -MemberOf "CN=Domain Admins,CN=Users,DC=pLab,DC=varandas,DC=com"
Add-ADPrincipalGroupMembership -Identity "CN=ADOps,OU=PriviledgedAccounts,DC=pLab,DC=varandas,DC=com" -MemberOf "CN=Schema Admins,CN=Users,DC=pLab,DC=varandas,DC=com"
Add-ADPrincipalGroupMembership -Identity "CN=ADOps,OU=PriviledgedAccounts,DC=pLab,DC=varandas,DC=com" -MemberOf "CN=Cert Publishers,CN=Users,DC=pLab,DC=varandas,DC=com"
Add-ADPrincipalGroupMembership -Identity "CN=xsDNS,OU=ServiceAccounts,DC=pLab,DC=varandas,DC=com" -MemberOf "CN=DNSAdmins,CN=Users,DC=pLab,DC=varandas,DC=com"

Get-ADOrganizationalUnit -filter * -Properties ProtectedFromAccidentalDeletion | where {$_.ProtectedFromAccidentalDeletion -eq $false} | Set-ADOrganizationalUnit -ProtectedFromAccidentalDeletion $true

Set-DhcpServerv4DnsSetting -DynamicUpdates Always -DeleteDnsRROnLeaseExpiry $true -UpdateDnsRRForOlderClients $true -DisableDnsPtrRRUpdate $false -NameProtection $false
#Set-DhcpServerDnsCredential
Set-DnsServerScavenging -ScavengingState $true -ApplyOnAllZones
Add-DnsServerForwarder -IPAddress 8.8.4.4
Add-DnsServerForwarder -IPAddress 8.8.8.8
Add-DnsServerForwarder -IPAddress 1.1.1.1
#load extadsch (SCCM AD SCHEMA) to DC
