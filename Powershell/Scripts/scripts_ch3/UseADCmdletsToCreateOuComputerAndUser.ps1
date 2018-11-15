# -----------------------------------------------------------------------------
# Script: UseADCmdletsToCreateOuComputerAndUser.ps1
# Author: ed wilson, msft
# Date: 09/09/2013 16:38:01
# Keywords: AD
# comments: AD
# Windows PowerShell 4.0 Best Practices, Microsoft Press, 2013
# Chapter 3
# -----------------------------------------------------------------------------
Import-Module -Name ActiveDirectory
$Name = "ScriptTest"
$DomainName = "dc=nwtraders,dc=com"
$OUPath = "ou={0},{1}" -f $Name, $DomainName

New-ADOrganizationalUnit -Name $Name -Path $DomainName -ProtectedFromAccidentalDeletion $false

For($you = 0; $you -le 5; $you++)
{
 New-ADOrganizationalUnit -Name $Name$you -Path $OUPath -ProtectedFromAccidentalDeletion $false
}

For($you = 0 ; $you -le 5; $you++)
{
 New-ADComputer -Name  "TestComputer$you" -Path $OUPath
 New-ADUser -Name "TestUser$you" -Path $OUPath
}
