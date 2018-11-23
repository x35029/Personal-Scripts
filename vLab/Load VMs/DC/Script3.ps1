Install-WindowsFeature DHCP -IncludeManagementTools 
Add-DhcpServerv4Scope -name "pLab" -StartRange 10.0.0.100 -EndRange 10.0.0.200 -SubnetMask 255.255.255.0
Set-DhcpServerv4OptionValue -DnsDomain pLab.varandas.com -DnsServer 10.0.0.1
Add-DhcpServerInDC -DnsName dc01.pLab.varandas.com

New-ADOrganizationalUnit -Name "Devices" -Path "DC=pLab,DC=varandas,DC=com" -ProtectedFromAccidentalDeletion $true
New-ADOrganizationalUnit -Name "Servers" -Path "CN=Devices,DC=pLab,DC=varandas,DC=com" -ProtectedFromAccidentalDeletion $true
New-ADOrganizationalUnit -Name "SQL" -Path "CN=Servers,CN=Devices,DC=pLab,DC=varandas,DC=com" -ProtectedFromAccidentalDeletion $true
New-ADOrganizationalUnit -Name "RDS" -Path "CN=Servers,CN=Devices,DC=pLab,DC=varandas,DC=com" -ProtectedFromAccidentalDeletion $true
New-ADOrganizationalUnit -Name "Web" -Path "CN=Servers,CN=Devices,DC=pLab,DC=varandas,DC=com" -ProtectedFromAccidentalDeletion $true
New-ADOrganizationalUnit -Name "Internet" -Path "CN=Web,CN=Servers,CN=Devices,DC=pLab,DC=varandas,DC=com" -ProtectedFromAccidentalDeletion $true
New-ADOrganizationalUnit -Name "Intranet" -Path "CN=Web,CN=Servers,CN=Devices,DC=pLab,DC=varandas,DC=com" -ProtectedFromAccidentalDeletion $true
New-ADOrganizationalUnit -Name "File" -Path "CN=Servers,CN=Devices,DC=pLab,DC=varandas,DC=com" -ProtectedFromAccidentalDeletion $true
New-ADOrganizationalUnit -Name "Workstations" -Path "CN=Devices,DC=pLab,DC=varandas,DC=com" -ProtectedFromAccidentalDeletion $true
New-ADOrganizationalUnit -Name "Virtual" -Path "CN=Workstations,CN=Devices,DC=pLab,DC=varandas,DC=com" -ProtectedFromAccidentalDeletion $true
New-ADOrganizationalUnit -Name "Physical" -Path "CN=Workstations,CN=Devices,DC=pLab,DC=varandas,DC=com" -ProtectedFromAccidentalDeletion $true
New-ADOrganizationalUnit -Name "StandardAccounts" -Path "DC=pLab,DC=varandas,DC=com" -ProtectedFromAccidentalDeletion $true
New-ADOrganizationalUnit -Name "PriviledgedAccounts" -Path "DC=pLab,DC=varandas,DC=com" -ProtectedFromAccidentalDeletion $true
New-ADOrganizationalUnit -Name "ServiceAccounts" -Path "DC=pLab,DC=varandas,DC=com" -ProtectedFromAccidentalDeletion $true
New-ADOrganizationalUnit -Name "SecurityGroups" -Path "DC=pLab,DC=varandas,DC=com" -ProtectedFromAccidentalDeletion $true
New-ADOrganizationalUnit -Name "Servers" -Path "OU=Devices,DC=pLab,DC=varandas,DC=com" -ProtectedFromAccidentalDeletion $true
New-ADOrganizationalUnit -Name "Workstations" -Path "OU=Devices,DC=pLab,DC=varandas,DC=com" -ProtectedFromAccidentalDeletion $true
New-ADUser -SamAccountName ADOps -AccountPassword (read-host "Set user password" -assecurestring) -name "ADOps" -enabled $true -PasswordNeverExpires $true -ChangePasswordAtLogon $false -Path "OU=PriviledgedAccounts,DC=pLab,DC=varandas,DC=com"
New-ADUser -SamAccountName SrvOps -AccountPassword (read-host "Set user password" -assecurestring) -name "SrvOps" -enabled $true -PasswordNeverExpires $true -ChangePasswordAtLogon $false -Path "OU=PriviledgedAccounts,DC=pLab,DC=varandas,DC=com"
New-ADUser -SamAccountName SCCMOps -AccountPassword (read-host "Set user password" -assecurestring) -name "SCCMOps" -enabled $true -PasswordNeverExpires $true -ChangePasswordAtLogon $false -Path "OU=PriviledgedAccounts,DC=pLab,DC=varandas,DC=com"
New-ADUser -SamAccountName SQLOps -AccountPassword (read-host "Set user password" -assecurestring) -name "SQLOps" -enabled $true -PasswordNeverExpires $true -ChangePasswordAtLogon $false -Path "OU=PriviledgedAccounts,DC=pLab,DC=varandas,DC=com"
New-ADUser -SamAccountName BackupOps -AccountPassword (read-host "Set user password" -assecurestring) -name "BackupOps" -enabled $true -PasswordNeverExpires $true -ChangePasswordAtLogon $false -Path "OU=PriviledgedAccounts,DC=pLab,DC=varandas,DC=com"
New-ADUser -SamAccountName xsSCCM-NAA -AccountPassword (read-host "Set user password" -assecurestring) -name "xsSCCM-NAA" -enabled $true -PasswordNeverExpires $true -ChangePasswordAtLogon $false -Path "OU=ServiceAccounts,DC=pLab,DC=varandas,DC=com"
New-ADUser -SamAccountName xsSCCM-CliPush -AccountPassword (read-host "Set user password" -assecurestring) -name "xsSCCM-CliPush" -enabled $true -PasswordNeverExpires $true -ChangePasswordAtLogon $false -Path "OU=ServiceAccounts,DC=pLab,DC=varandas,DC=com"
New-ADUser -SamAccountName xsSCCM-SQLRpt -AccountPassword (read-host "Set user password" -assecurestring) -name "xsSCCM-SQLRpt" -enabled $true -PasswordNeverExpires $true -ChangePasswordAtLogon $false -Path "OU=ServiceAccounts,DC=pLab,DC=varandas,DC=com"
New-ADUser -SamAccountName xsSCCM-DomainJoin -AccountPassword (read-host "Set user password" -assecurestring) -name "xsSCCM-DomainJoin" -enabled $true -PasswordNeverExpires $true -ChangePasswordAtLogon $false -Path "OU=ServiceAccounts,DC=pLab,DC=varandas,DC=com"
New-ADUser -SamAccountName xsDNS -AccountPassword (read-host "Set user password" -assecurestring) -name "xsDNS" -enabled $true -PasswordNeverExpires $true -ChangePasswordAtLogon $false -Path "OU=ServiceAccounts,DC=pLab,DC=varandas,DC=com"
New-ADUser -SamAccountName xsDHCP -AccountPassword (read-host "Set user password" -assecurestring) -name "xsDHCP" -enabled $true -PasswordNeverExpires $true -ChangePasswordAtLogon $false -Path "OU=ServiceAccounts,DC=pLab,DC=varandas,DC=com"
New-ADUser -SamAccountName xsSQL01 -AccountPassword (read-host "Set user password" -assecurestring) -name "xsSQL1" -enabled $true -PasswordNeverExpires $true -ChangePasswordAtLogon $false -Path "OU=ServiceAccounts,DC=pLab,DC=varandas,DC=com"

Add-ADPrincipalGroupMembership -Identity "CN=SrvOps,OU=PriviledgedAccounts,DC=pLab,DC=varandas,DC=com" -MemberOf "CN=Server Operators,CN=Builtin,DC=pLab,DC=varandas,DC=com"
Add-ADPrincipalGroupMembership -Identity "CN=BackupOps,OU=PriviledgedAccounts,DC=pLab,DC=varandas,DC=com" -MemberOf "CN=Backup Operators,CN=Builtin,DC=pLab,DC=varandas,DC=com"

New-ADGroup -Path "OU=SecurityGroups,DC=pLab,DC=varandas,DC=com" -Name "Network Admins" -GroupScope Global -GroupCategory Security
Add-ADPrincipalGroupMembership -Identity "CN=NetworkOps,OU=PriviledgedAccounts,DC=pLab,DC=varandas,DC=com" -MemberOf "CN=Network Admins,CN=Users,DC=pLab,DC=varandas,DC=com"
Add-ADPrincipalGroupMembership -Identity "CN=RAS and IAS Servers,CN=Users,DC=pLab,DC=varandas,DC=com" -MemberOf "CN=Network Admins,CN=Users,DC=pLab,DC=varandas,DC=com"
Add-ADPrincipalGroupMembership -Identity "CN=Network Configuration Operators,CN=Builtin,DC=pLab,DC=varandas,DC=com" -MemberOf "CN=Network Admins,CN=Users,DC=pLab,DC=varandas,DC=com"

New-ADGroup -Path "OU=SecurityGroups,DC=pLab,DC=varandas,DC=com" -Name "SQL Admins" -GroupScope Global -GroupCategory Security
New-ADGroup -Path "OU=SecurityGroups,DC=pLab,DC=varandas,DC=com" -Name "SCCM SiteServers" -GroupScope Global -GroupCategory Security
Add-ADPrincipalGroupMembership -Identity "CN=SQLOps,OU=PriviledgedAccounts,DC=pLab,DC=varandas,DC=com" -MemberOf "CN=SQL Admins,CN=Users,DC=pLab,DC=varandas,DC=com"

New-ADGroup -Path "OU=SecurityGroups,DC=pLab,DC=varandas,DC=com" -Name "SCCM Admins" -GroupScope Global -GroupCategory Security
Add-ADPrincipalGroupMembership -Identity "CN=SCCMOps,OU=PriviledgedAccounts,DC=pLab,DC=varandas,DC=com" -MemberOf "CN=SCCM Admins,CN=Users,DC=pLab,DC=varandas,DC=com"

Add-ADPrincipalGroupMembership -Identity "CN=ADOps,OU=PriviledgedAccounts,DC=pLab,DC=varandas,DC=com" -MemberOf "CN=Enterprise Admins,CN=Users,DC=pLab,DC=varandas,DC=com"
Add-ADPrincipalGroupMembership -Identity "CN=ADOps,OU=PriviledgedAccounts,DC=pLab,DC=varandas,DC=com" -MemberOf "CN=Domain Admins,CN=Users,DC=pLab,DC=varandas,DC=com"
Add-ADPrincipalGroupMembership -Identity "CN=ADOps,OU=PriviledgedAccounts,DC=pLab,DC=varandas,DC=com" -MemberOf "CN=Schema Admins,CN=Users,DC=pLab,DC=varandas,DC=com"
Add-ADPrincipalGroupMembership -Identity "CN=ADOps,OU=PriviledgedAccounts,DC=pLab,DC=varandas,DC=com" -MemberOf "CN=Cert Publishers,CN=Users,DC=pLab,DC=varandas,DC=com"
Add-ADPrincipalGroupMembership -Identity "CN=xsDNS,OU=ServiceAccounts,DC=pLab,DC=varandas,DC=com" -MemberOf "CN=DNSAdmins,CN=Users,DC=pLab,DC=varandas,DC=com"

Get-ADOrganizationalUnit -filter * -Properties ProtectedFromAccidentalDeletion | where {$_.ProtectedFromAccidentalDeletion -eq $false} | Set-ADOrganizationalUnit -ProtectedFromAccidentalDeletion $true

Set-DhcpServerv4DnsSetting -DynamicUpdates Always -DeleteDnsRROnLeaseExpiry $true -UpdateDnsRRForOlderClients $true -DisableDnsPtrRRUpdate $false -NameProtection $false
#Set-DhcpServerDnsCredential
Set-DnsServerScavenging -ScavengingState $true -ApplyOnAllZones

#load extadsch (SCCM AD SCHEMA) to DC

