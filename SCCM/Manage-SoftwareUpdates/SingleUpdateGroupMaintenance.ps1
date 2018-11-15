# This script is designed to handle maintenance of software update groups individually.
# Maintenance options include scanning for and removing superseded, expired or aged updates.
# NOTE 1:  If removing aged updates this script simply removes them without adding them to another update 
# group.  A separate script is available that will handle moving updates to another update group 
# if needed.  When the script is used to purge aged updates the assumption is that this operation will be
# done on the persistent update group.  Accordingly and unless otherwise specified, the default threshold for
# update age is 1 year.
# NOTE 2:  This script does not handle purging updates from the deployment packages.  A separate script is 
# available for that.
Function SingleUpdateGroupMaintenance{
    Param(
        [Parameter(Mandatory = $true)]
        $SiteProviderServerName,
        [Parameter(Mandatory = $true)]
        $SiteCode,
        [Parameter(Mandatory = $true)]
        $ManagedUpdateGroup,
        [Parameter(Mandatory = $false)][boolean]
        $HandleAgedUpdates,
        [Parameter(Mandatory = $false)]
        $NumberofDaystoKeep,
        [Parameter(Mandatory = $false)][boolean]
        $PurgeSuperseded,
        [Parameter(Mandatory = $false)][boolean]
        $PurgeExpired
        )

    Import-module ($Env:SMS_ADMIN_UI_PATH.Substring(0,$Env:SMS_ADMIN_UI_PATH.Length-5) + '\ConfigurationManager.psd1')

    # Connect to discovered top level site
    cd $SiteCode":"

    # The following parameters are not required.  Set default value to True when no value is passed in.
    If (!$PurgeExpired){
        $PurgeExpired="True"
    }

    If (!$PurgeSuperseded){
        $PurgeSuperseded="True"
    }

    # If the option to Handle Aged Updates is enabled but no specific threshold is specified for the number of days
    # to keep the update then set to 360 days.
    If (($HandleAgedUpdates) -and ($NumberofDaystoKeep -eq $Null)){
        $NumberofDaystoKeep = 360
    }

    # Credit to Tevor Sullivan for this function.  Modified from his original for use here.
    # http://trevorsullivan.net/2011/11/29/configmgr-cleanup-software-updates-objects/
    Function Test-SccmUpdateExpired{
        param(
            [Parameter(Mandatory = $true)]
            $UpdateId,
            [Parameter(Mandatory = $true)]
            $TakeAction
        )

        #Test to see if script should purge expired updates based on input.  If not, return false.
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
    
        #Test to see if script should purge superseded updates based on input.  If not, return false
        If ($TakeAction -eq $false){
            write-host ("Configured to not evaluate update supersedence function")
            return $false
        }

        # Find update that is superseded with the specified CI_ID (unique ID) value
        # Changing the format of Get-WmiObject because for some reason trying to pull
        # IsSuperseded information using the same query format as is used for checking
        # Expired updates fails here.
        $Update = Get-WmiObject -ComputerName $SiteProviderServerName -Namespace root\sms\site_$($SiteCode) -Class SMS_SoftwareUpdate -filter "CI_ID='$UpdateID'"
        
        # If the WMI query returns more than 0 instances (should NEVER be more than 1 at most), then the update is expired.
        If ($Update.IsSuperseded -eq "True"){
            Write-host ("Cleaned superseded software update with title: " + $Update.LocalizedDisplayName)
            return $true
        }
        else{
            #write-host ("Returning False from update supersedence function")
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
            $TakeAction
        )

        #Test to see if script should handle aged updates based on input.  If not, return false
        If ($TakeAction -eq $false){
            write-host ("Configured to not evaluate update age function")
            return $false
        }

        # Find updates that are older than the specified threshold.  This will be done
        # by first pulling each update remaining in the list and querying the DateLastModified
        # property from WMI.  This property will then be converted to a proper datetime format
        # and then simple mathmatical comparison can be done to test the age.  If the update age
        # is outside of the threshold remove from the update group.
        $AgedUpdateQuery = "select * from SMS_SoftwareUpdate where CI_ID = '$UpdateId'"
        $Update = @(Get-WmiObject -ComputerName $SiteProviderServerName -Namespace root\sms\site_$($SiteCode) -Query $AgedUpdateQuery)
        $UpdateDate = [System.Management.ManagementDateTimeConverter]::ToDateTime($Update.DateLastModified)
    
        if ($UpdateDate -lt $AgeThreshold){
            Write-host ("Cleaned a software update older than age threshold with title: " + $Update[0].LocalizedDisplayName)
            return $true
        }
        else{
            return $false
        }
    }

    # Get current date and calculate the aged update threshold based on either 360
    # days or the value specified.
    $CurrentDate = Get-Date  
    $CurrentDateLessKeepThreshold = $CurrentDate.AddDays(-$NumberofDaystoKeep)

    # Retrieve the update group that was passed in as the managed update group.
    # This is the update group where maintenance will be performed.
    $MaintenanceUpdateList = Get-WmiObject -Namespace root\sms\site_$($SiteCode) -Class SMS_AuthorizationList -ComputerName $SiteProviderServerName -filter "localizeddisplayname = '$ManagedUpdateGroup'"

    #Process the Current Update Group 
    $MaintenanceUpdateList = [wmi]"$($MaintenanceUpdateList.__PATH)" #There is a double _ in front of PATH
    write-host "$($MaintenanceUpdateList.localizeddisplayname) has $($MaintenanceUpdateList.Updates.Count) updates in it"

    # Loop through each update in the update group.  Depending on parameters test update to see if it is expired, superseded
    # or past the age threshold.  Remove from the update group according to configuration and findings.
    ForEach ($UpdateID in $MaintenanceUpdateList.Updates){
        If ((Test-SccmUpdateExpired -UpdateID $UpdateID -TakeAction $PurgeExpired) -or (Test-SCCMUpdateSuperseded -UpdateID $UpdateID -TakeAction $PurgeSuperseded) -or (Test-SCCMUpdateAge -UpdateID $UpdateID -AgeThreshold $CurrentDateLessKeepThreshold -TakeAction $HandleAgedUpdates)){
            $MaintenanceUpdateList.Updates = @($MaintenanceUpdateList.Updates | ? {$_ -ne $UpdateID})
        }
    }

    # Finished evaluating and changing the update group, write the modifications to WMI.
    $MaintenanceUpdateList.Put()
}
