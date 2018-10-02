Install-WindowsFeature DHCP -IncludeManagementTools
Add-DhcpServerv4Scope -name "vLab" -StartRange 10.0.0.100 -EndRange 10.0.0.200 -SubnetMask 255.255.255.0
Set-DhcpServerv4OptionValue -DnsDomain vlab.varandas.com -DnsServer 10.0.0.1
Add-DhcpServerInDC -DnsName dc1.vlab.varandas.com
New-ADOrganizationalUnit -Name "Devices" -Path "DC=vlab,DC=varandas,DC=com" -ProtectedFromAccidentalDeletion $true
New-ADOrganizationalUnit -Name "StandardAccounts" -Path "DC=vlab,DC=varandas,DC=com" -ProtectedFromAccidentalDeletion $true
New-ADOrganizationalUnit -Name "PriviledgedAccounts" -Path "DC=vlab,DC=varandas,DC=com" -ProtectedFromAccidentalDeletion $true
New-ADOrganizationalUnit -Name "ServiceAccounts" -Path "DC=vlab,DC=varandas,DC=com" -ProtectedFromAccidentalDeletion $true
New-ADOrganizationalUnit -Name "SecurityGroups" -Path "DC=vlab,DC=varandas,DC=com" -ProtectedFromAccidentalDeletion $true
New-ADOrganizationalUnit -Name "Servers" -Path "OU=Devices,DC=vlab,DC=varandas,DC=com" -ProtectedFromAccidentalDeletion $true
New-ADOrganizationalUnit -Name "Workstations" -Path "OU=Devices,DC=vlab,DC=varandas,DC=com" -ProtectedFromAccidentalDeletion $true
New-ADUser -SamAccountName ADOps -AccountPassword (read-host "Set user password" -assecurestring) -name "ADOps" -enabled $true -PasswordNeverExpires $true -ChangePasswordAtLogon $false 
New-ADUser -SamAccountName xsDNS -AccountPassword (read-host "Set user password" -assecurestring) -name "xsDNS" -enabled $true -PasswordNeverExpires $true -ChangePasswordAtLogon $false 
New-ADUser -SamAccountName xsSQL1 -AccountPassword (read-host "Set user password" -assecurestring) -name "xsSQL1" -enabled $true -PasswordNeverExpires $true -ChangePasswordAtLogon $false 
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
New-ADGroup -Path "OU=SecurityGroups,DC=vlab,DC=varandas,DC=com" -Name "SCCM SiteServers" -GroupScope Global -GroupCategory Security
Move-ADObject -Identity "CN=ADOps,CN=Users,DC=vlab,DC=varandas,DC=com" -TargetPath "OU=PriviledgedAccounts,DC=vlab,DC=varandas,DC=com"
Move-ADObject -Identity "CN=xsDNS,CN=Users,DC=vlab,DC=varandas,DC=com" -TargetPath "OU=ServiceAccounts,DC=vlab,DC=varandas,DC=com"
Move-ADObject -Identity "CN=SrvOps,CN=Users,DC=vlab,DC=varandas,DC=com" -TargetPath "OU=PriviledgedAccounts,DC=vlab,DC=varandas,DC=com"
Move-ADObject -Identity "CN=SCCMOps,CN=Users,DC=vlab,DC=varandas,DC=com" -TargetPath "OU=PriviledgedAccounts,DC=vlab,DC=varandas,DC=com"
Move-ADObject -Identity "CN=SQLOps,CN=Users,DC=vlab,DC=varandas,DC=com" -TargetPath "OU=PriviledgedAccounts,DC=vlab,DC=varandas,DC=com"

Move-ADObject -Identity "CN=xsSCCM-DomainJoin,CN=Users,DC=vlab,DC=varandas,DC=com" -TargetPath "OU=PriviledgedAccounts,DC=vlab,DC=varandas,DC=com"
Move-ADObject -Identity "CN=xsSCCM-SQLRpt,CN=Users,DC=vlab,DC=varandas,DC=com" -TargetPath "OU=PriviledgedAccounts,DC=vlab,DC=varandas,DC=com"
Move-ADObject -Identity "CN=xsSCCM-CliPush,CN=Users,DC=vlab,DC=varandas,DC=com" -TargetPath "OU=PriviledgedAccounts,DC=vlab,DC=varandas,DC=com"
Move-ADObject -Identity "CN=xsSCCM-NAA,CN=Users,DC=vlab,DC=varandas,DC=com" -TargetPath "OU=PriviledgedAccounts,DC=vlab,DC=varandas,DC=com"
Move-ADObject -Identity "CN=xsSQL1,CN=Users,DC=vlab,DC=varandas,DC=com" -TargetPath "OU=PriviledgedAccounts,DC=vlab,DC=varandas,DC=com"

Move-ADObject -Identity "CN=User1,CN=Users,DC=vlab,DC=varandas,DC=com" -TargetPath "OU=StandardAccounts,DC=vlab,DC=varandas,DC=com"
Move-ADObject -Identity "CN=User2,CN=Users,DC=vlab,DC=varandas,DC=com" -TargetPath "OU=StandardAccounts,DC=vlab,DC=varandas,DC=com"
Move-ADObject -Identity "CN=User3,CN=Users,DC=vlab,DC=varandas,DC=com" -TargetPath "OU=StandardAccounts,DC=vlab,DC=varandas,DC=com"

New-ADGroup -Path "CN=Users,DC=vlab,DC=varandas,DC=com" -Name "SQL Admins" -GroupScope Global -GroupCategory Security
Add-ADPrincipalGroupMembership -Identity "CN=SQLOps,OU=PriviledgedAccounts,DC=vlab,DC=varandas,DC=com" -MemberOf "CN=SQL Admins,CN=Users,DC=vlab,DC=varandas,DC=com"
Move-ADObject -Identity "CN=SQL Admins,CN=Users,DC=vlab,DC=varandas,DC=com" -TargetPath "OU=SecurityGroups,DC=vlab,DC=varandas,DC=com"

New-ADGroup -Path "CN=Users,DC=vlab,DC=varandas,DC=com" -Name "SCCM Admins" -GroupScope Global -GroupCategory Security
Add-ADPrincipalGroupMembership -Identity "CN=SCCMOps,OU=PriviledgedAccounts,DC=vlab,DC=varandas,DC=com" -MemberOf "CN=SCCM Admins,CN=Users,DC=vlab,DC=varandas,DC=com"
Move-ADObject -Identity "CN=SCCM Admins,CN=Users,DC=vlab,DC=varandas,DC=com" -TargetPath "OU=SecurityGroups,DC=vlab,DC=varandas,DC=com"

Add-ADPrincipalGroupMembership -Identity "CN=ADOps,OU=PriviledgedAccounts,DC=vlab,DC=varandas,DC=com" -MemberOf "CN=Enterprise Admins,CN=Users,DC=vlab,DC=varandas,DC=com"
Add-ADPrincipalGroupMembership -Identity "CN=ADOps,OU=PriviledgedAccounts,DC=vlab,DC=varandas,DC=com" -MemberOf "CN=Domain Admins,CN=Users,DC=vlab,DC=varandas,DC=com"
Add-ADPrincipalGroupMembership -Identity "CN=ADOps,OU=PriviledgedAccounts,DC=vlab,DC=varandas,DC=com" -MemberOf "CN=Schema Admins,CN=Users,DC=vlab,DC=varandas,DC=com"

Get-ADOrganizationalUnit -filter * -Properties ProtectedFromAccidentalDeletion | where {$_.ProtectedFromAccidentalDeletion -eq $false} | Set-ADOrganizationalUnit -ProtectedFromAccidentalDeletion $true

Set-DhcpServerv4DnsSetting -DynamicUpdates Always -DeleteDnsRROnLeaseExpiry $true -UpdateDnsRRForOlderClients $true -DisableDnsPtrRRUpdate $false -NameProtection $false
#Set-DhcpServerDnsCredential
Set-DnsServerScavenging -ScavengingState $true

#load extadsch (SCCM AD SCHEMA) to DC

