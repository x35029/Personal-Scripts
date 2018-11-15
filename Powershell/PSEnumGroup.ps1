# PSEnumGroup.ps1
# PowerShell script to document members of a group.
# Reveals nested group and primary group membership.
#
# ----------------------------------------------------------------------
# Copyright (c) 2011 Richard L. Mueller
# Hilltop Lab web site - http://www.rlmueller.net
# Version 1.0 - March 26, 2011
# Version 1.1 - June 24, 2011 - Escape any "/" characters in DN's.
#
# You have a royalty-free right to use, modify, reproduce, and
# distribute this script file in any way you find useful, provided that
# you agree that the copyright owner above has no warranty, obligations,
# or liability for such use.

# Read group DN from command line or prompt for value.
Param ($DN)
If ($DN -eq $Null)
{
    $DN = Read-Host "Group Distinguished Name"
}

Trap {"Error: $_"; Break;}
# Set-StrictMode -Version Latest

Function EnumGroup ($ADGroup, $Offset)
{
    # Recursive method to enumerate group membership.
    # $MemberList is a hash table with script scope.
    # $ADGroup is a group object bound with the LDAP provider.
    # This function outputs a list of group members, one member
    # per line. Nested group members are included. Membes are also
    # included if the primary group is $ADGroup. $MemberList
    # prevents an infinite loop of nested groups are circular.

    # Retrieve objectSID of group.
    $SID = $ADGroup.objectSID

    # Calculate RID, which will be primaryGroupToken of the group,
    # from the last 4 bytes of objectSID.
    $arrSID = ($SID.ToString()).Split()
    $k = $arrSID.Count
    $RID = [Int32]$arrSID[$k - 4] `
        + (256 * [int32]$arrSID[$k - 3]) `
        + (256 * 256 * [Int32]$arrSID[$k - 2]) `
        + (256 * 256 * 256 * [Int32]$arrSID[$k - 1])

    # Search for objects whose primaryGroupID matches the
    # group primaryGroupToken.
    $Searcher.Filter = "(primaryGroupID=$RID)"
    $Results = $Searcher.FindAll()
    ForEach ($Result In $Results)
    {
        $Name = $Result.Properties.Item("distinguishedName")
        # Convert value to string so Hash table recognizes duplicates.
        $Name = $($Name).ToString()
        If ($Script:MemberList.ContainsKey($Name) -eq $False)
        {
            $Script:MemberList.Add($Name, $True)
            "$Offset$Name (Primary)"
        }
        Else
        {
            "$Offset$Name (Primary, Duplicate)"
        }
    }
    ForEach ($MemberDN In $ADGroup.member)
    {
        $MemberDN = $MemberDN.Replace("/", "\/")
        $Member = [ADSI]"LDAP://$MemberDN"
        $Class = $Member.Class
        # Convert value to string so Hash table recognizes duplicates.
        $Name = ($Member.distinguishedName).ToString()
        If ($Script:MemberList.ContainsKey($Name) -eq $True)
        {
            "$OffSet$Name ($Class Duplicate)"
        }
        Else
        {
            $Script:MemberList.Add($Name, $True)
            "$Offset$Name ($Class)"
            If ($Class -eq "group")
            {
                EnumGroup $Member "$Offset  "
            }
        }
    }
}

# Bind to group object.
$DN = $DN.Replace("/", "\/")
$Group = [ADSI]"LDAP://$DN"
"Members of Group $DN"

$D = [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain()
$Domain = [ADSI]"LDAP://$D"
$Searcher = New-Object System.DirectoryServices.DirectorySearcher
$Searcher.PageSize = 200
$Searcher.SearchScope = "subtree"
$Searcher.PropertiesToLoad.Add("distinguishedName") < $Null
$Searcher.SearchRoot = "LDAP://" + $Domain.distinguishedName

# Hash table to track group memberships.
$Script:MemberList = @{}

# Enumerate group memberships.
EnumGroup $Group ""