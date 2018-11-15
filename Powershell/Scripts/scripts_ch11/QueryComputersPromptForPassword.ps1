# -----------------------------------------------------------------------------
# Script: QueryComputersPromptForPassword.ps1
# Author: ed wilson, msft
# Date: 09/06/2013 15:07:41
# Keywords: Input
# comments: Password Input
# Windows PowerShell 4.0 Best Practices, Microsoft Press, 2013
# Chapter 11
# -----------------------------------------------------------------------------
$strBase = "<LDAP://dc=nwtraders,dc=com>"
$strFilter = "(objectCategory=computer)"
$strAttributes = "name"
$strScope = "subtree"
$strQuery = "$strBase;$strFilter;$strAttributes;$strScope"
$strUser = "nwtraders\administrator"
$strPwd = Read-Host -prompt "Enter password to Connect to AD"

$objConnection = New-Object -comObject "ADODB.Connection"
$objConnection.provider = "ADsDSOObject"
$objConnection.properties.item("user ID") = $strUser
$objConnection.properties.item("Password") = $strPwd
$objConnection.open("modifiedConnection")
$objCommand = New-Object -comObject "ADODB.Command"

$objCommand.ActiveConnection = $objConnection
$objCommand.CommandText = $strQuery
$objRecordSet = $objCommand.Execute()

Do
{
    $objRecordSet.Fields.item("name") |Select-Object Name,Value 
    $objRecordSet.MoveNext()
}
Until ($objRecordSet.eof) 

$objConnection.Close()
