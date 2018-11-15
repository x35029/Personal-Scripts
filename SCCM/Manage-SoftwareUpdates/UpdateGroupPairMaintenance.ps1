# This script is designed to automate the routine maintenance of software update group pairs.
# Specifically, the script will take two software update groups as input - one that contains
# the most recent set of updates for deployment and another that represents the group of persistent
# updates being deployed.  The idea is that the first group will contain the current month or quarter
# of updates while the persistent group will contain those updates that need to remain deployed to 
# the environment in case unpatched systems are brought online.  The expectation though is the majority
# of the environment will already have received the updates in the persistent group.  
# This script will optionally handle scanning of both groups to remove expired or superseded patches 
# and will scan the recent, or current, update group to identify updates over the age threshold that 
# may should be moved to the persistend update group.  If the script is configured to handle aged updates
# but no age threshold is specified then 90 days will be used.

Param(
    [Parameter(Mandatory = $true)]
    $SiteProviderServerName,
    [Parameter(Mandatory = $true)]
    $SiteCode,
    [Parameter(Mandatory = $true)]
    $CurrentUpdateGroup,
    [Parameter(Mandatory = $true)]
    $PersistentUpdateGroup,
    [Parameter(Mandatory = $false)]  
    $HandleAgedUpdates=$true,
    [Parameter(Mandatory = $false)]  
    $NumberofDaystoKeep=1,
    [Parameter(Mandatory = $false)]
    $PurgeExpired=$true
    )

Import-module ($Env:SMS_ADMIN_UI_PATH.Substring(0,$Env:SMS_ADMIN_UI_PATH.Length-5) + '\ConfigurationManager.psd1')

If ($CurrentUpdateGroup -eq $PersistentUpdateGroup)
{
write-host ("The Current and Persistent update groups are the same group.  This is not allowed.  Exiting")
exit
}

# Connect to discovered top level site
cd $SiteCode":"

# Credit to Tevor Sullivan for this function.  Modified from his original for use here.
# http://trevorsullivan.net/2011/11/29/configmgr-cleanup-software-updates-objects/
Function Test-SccmUpdateExpired{
    param(
        [Parameter(Mandatory = $true)]
        $UpdateId,
        [Parameter(Mandatory = $true)]
        $TakeAction
    )

    #Test to see if we should purge expired updates based on input.  If not, return false
    If ($TakeAction -eq $false){
        write-host ("Configured to not evaluate update expired function")
        return $false
     }

    # Find update that is expired with the specified CI_ID (unique ID) value
    $ExpiredUpdateQuery = "select * from SMS_SoftwareUpdate where IsExpired = 'true' and CI_ID = '$UpdateId'"
    $Update = @(Get-WmiObject -ComputerName $SiteProviderServerName -Namespace root\sms\site_$($SiteCode) -Query $ExpiredUpdateQuery)
  
    # If the WMI query returns more than 0 instances (should NEVER be more than 1 at most), then the update is expired.
    if ($Update.Count -gt 0){
        Write-host ("Cleaned expired software update with title: " + $Update[0].LocalizedDisplayName )
        return $true
    }
    else{
        #write-host ("Returning False from update expired function")
        return $false
    }
}
Function Test-SccmUpdateSuperseded{
    param(
        [Parameter(Mandatory = $true)]
        $UpdateId,
        [Parameter(Mandatory = $true)]
        $TakeAction
    )

    #Test to see if we should purge superseded updates based on input.  If not, return false
    If ($TakeAction -eq $false)
        {
        write-host ("Configured to not evaluate update supersedence function")
        return $false
        }

    # Find update that is superseded with the specified CI_ID (unique ID) value
    # Changing the format of Get-WmiObject because for some reason trying to pull
    # IsSuperseded information using the same query format as is used for checking
    # Expired updates fails here
    $Update = Get-WmiObject -ComputerName $SiteProviderServerName -Namespace root\sms\site_$($SiteCode) -Class SMS_SoftwareUpdate -filter "CI_ID='$UpdateID'"
        
    # If the WMI query returns more than 0 instances (should NEVER be more than 1 at most), then the update is expired.
    If ($Update.IsSuperseded -eq "True")
        {
        Write-host ("Cleaned superseded software update with title: " + $Update.LocalizedDisplayName)
        return $true
        }
    else
        {
        return $false
        }
}
Function Test-SCCMUpdateAge{
    param(
        [Parameter(Mandatory = $true)]
        $UpdateId,
        [Parameter(Mandatory = $true)]
        $AgeThreshold,
        [Parameter(Mandatory = $true)]
        $TakeAction,
        [Parameter(Mandatory = $true)]
        $PersistentGroup
    )

    #Test to see if we should handle aged updates based on input.  If not, return false
    If ($TakeAction -eq $false)
        {
        write-host ("Configured to not evaluate update age function")
        return $false
        }

    # Find update that is older than the specified threshold.  This will be done
    # by first pulling each update remaining in the list and querying the DateLastModified
    # property from WMI.  This property will then be converted to a proper datetime format
    # and then simple mathmatical comparison can be done to test the age.  If the update age
    # is outside of the threshold remove from the current update group and store for later
    # move into persistent update group.
    $AgedUpdateQuery = "select * from SMS_SoftwareUpdate where CI_ID = '$UpdateId'"
    $Update = @(Get-WmiObject -ComputerName $SiteProviderServerName -Namespace root\sms\site_$($SiteCode) -Query $AgedUpdateQuery)
    $UpdateDate = [System.Management.ManagementDateTimeConverter]::ToDateTime($Update.DateLastModified)
    
    if ($UpdateDate -lt $AgeThreshold)
        {
        Write-host ("Cleaned a software update older than age threshold with title: " + $Update[0].LocalizedDisplayName)
        Write-host ("Cleaned software update moved to persistent software update group: " + $PersistentGroup)
        Add-CMSoftwareUpdateToGroup -SoftwareUpdateGroupName "$PersistentGroup" -SoftwareUpdateID $Update.CI_ID
        return $true
        }
    else
        {
        #write-host ("Returning False from update age function")
        return $false
        }
}

# Get current date and calculate the aged update threshold based on either 90
# days or the value passed in.
$CurrentDate=Get-Date  
$CurrentDateLessKeepThreshold=$CurrentDate.AddDays(-$NumberofDaystoKeep)

# Retrieve the update group that was passed in as the current update group.
# These are the update groups where we will be performing maintenance.
$CurrentUpdateList = Get-WmiObject -Namespace root\sms\site_$($SiteCode) -Class SMS_AuthorizationList -ComputerName $SiteProviderServerName -filter "localizeddisplayname = '$CurrentUpdateGroup'"
$PersistentUpdateList = Get-WmiObject -Namespace root\sms\site_$($SiteCode) -Class SMS_AuthorizationList -ComputerName $SiteProviderServerName -filter "localizeddisplayname = '$PersistentUpdateGroup'"

#Process the Current Update Group 
$CurrentUpdateList = [wmi]"$($CurrentUpdateList.__PATH)" #There is a double _ in front of PATH
write-host "$($CurrentUpdateList.localizeddisplayname) has $($CurrentUpdateList.Updates.Count) updates in it"

# Loop through each update in the current update group handling expired, superseded or age threshold per
# configuration.
ForEach ($UpdateID in $CurrentUpdateList.Updates)
{
If ((Test-SccmUpdateExpired -UpdateID $UpdateID -TakeAction $PurgeExpired) -or (Test-SCCMUpdateSuperseded -UpdateID $UpdateID -TakeAction $PurgeSuperseded) -or (Test-SCCMUpdateAge -UpdateID $UpdateID -AgeThreshold $CurrentDateLessKeepThreshold -TakeAction $HandleAgedUpdates -PersistentGroup $PersistentUpdateGroup)){
    $CurrentUpdateList.Updates = @($CurrentUpdateList.Updates | ? {$_ -ne $UpdateID})
    }
}

# Operation on update group is complete, write results to WMI.
$CurrentUpdateList.Put()

# Process the Persistent Update Group
# Processing for this group will only handle superseded or expired updates
# It would be easy to also add processing for aged updates over a certain threshold for the persistent 
# updates if desired.
$PersistentUpdateList = [wmi]"$($PersistentUpdateList.__PATH)" #There is a double _ in front of PATH
write-host "$($PersistentUpdateList.localizeddisplayname) has $($PersistentUpdateList.Updates.Count) updates in it"

ForEach ($UpdateID in $PersistentUpdateList.Updates)
{
If ((Test-SccmUpdateExpired -UpdateID $UpdateID -TakeAction $PurgeExpired) -or (Test-SCCMUpdateSuperseded -UpdateID $UpdateID -TakeAction $PurgeSuperseded))
    {
    $PersistentUpdateList.Updates = @($PersistentUpdateList.Updates | ? {$_ -ne $UpdateID})
    }
}

# Operation on update group is complete, write results to WMI.
$PersistentUpdateList.Put()