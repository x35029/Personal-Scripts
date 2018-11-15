# This script is designed to list all updates that are deployed to a specific collection.  The collection information
# is provided using a text file.  Multiple collections are supported for input.  A single collection ID is placed on each line.
# of the text file.  The script will evaluate each collection and list every update that is deployed t the collection along with
# the deployment name associated with the various updates.  This output is written to a file.  The script is also desigined to
# prevent duplicate output.  A specific scenario where this script is useful would be for environments where a different business
# unit has a need to know specifically what updates have been deployed to their systems.  In this case the deployments for the 
# business groups systems are broken down into 3 collections.  To provide the update information the scipt needs to examime all
# software update deployments against the specific collection and list out all updates that were in the software update groups
# and also avoid reporting deployment detail multiple times.

Param(
    [Parameter(Mandatory = $true)]
    $SiteProviderServerName,
    [Parameter(Mandatory = $true)]
    $SiteCode
    )

Import-module ($Env:SMS_ADMIN_UI_PATH.Substring(0,$Env:SMS_ADMIN_UI_PATH.Length-5) + '\ConfigurationManager.psd1')

# Connect to discovered top level site
cd $SiteCode":"

$UniqueUpdateGroups = @()

# Get the details for the deployment from the text file.
$CollectionDetail = Get-Content c:\HVDUpdateCollections.txt

# Loop through each collection
ForEach ($Collection in $CollectionDetail)
{   # Declare a variable to track whether we have a match meaning the script has already picked up a given 
    # deployment and won't process it again.
    $Match = $False    
    # Retrieve all software update deployments that have been created against the target collection.
    $UpdateAssignment = Get-WmiObject -ComputerName $SiteProviderServerName -Namespace root\sms\site_$($SiteCode) -Class SMS_UpdateGroupAssignment -filter "TargetCollectionID='$Collection'"
    # Loop through each deployment
    ForEach ($AssignmentItem in $UpdateAssignment)
    {
        # The UniqueUpdateGroups variable is an array.  If it currently has no elements that means this is the first pass
        # through the loop and the update group can be added to the array without further checking.
        if ($UniqueUpdateGroups.count -eq 0)
        {
           $UniqueUpdateGroups += $AssignmentItem.AssignedUpdateGroup
        }
        # Loop through all elements in the UniqueUpdateGroups array to see if the current update group is already stored
        # in the array.  If it is skip processing and loop but if it isn't continue processing.
        ForEach ($Item in $UniqueUpdateGroups)
        {
            If ($Item -eq $AssignmentItem.AssignedUpdateGroup)
            {
                 $Match = $True
            }
            If ($Match -eq $False)
            {
                $UniqueUpdateGroups += $AssignmentItem.AssignedUpdateGroup
            }
        }
    }
}

# If a historical update output file is present remove it.
If (Test-Path C:\updates.txt)
{
    remove-item c:\updates.txt
}

# Loop through each update group that is stored in the array
ForEach ($Assignment in $UniqueUpdateGroups)
{
    # Get the update group from WMI
    $SoftwareUpdateGroup=Get-WmiObject -ComputerName $SiteProviderServerName -Namespace root\sms\site_$($SiteCode) -Class SMS_AuthorizationList -filter "CI_ID='$Assignment'"
    # Get a list of all updates in the software update group
    $UpdatesinGroup=Get-CMSoftwareUpdate -UpdateGroupName $SoftwareUpdateGroup.LocalizedDisplayName
    $output = "Software Update Group: " + $softwareUpdateGroup.LocalizedDisplayName | out-file -append c:\updates.txt
    # Loop through the update group and output all updates that are contained in the group by name and KB
    ForEach($Update in $UpdatesinGroup)
    {
        $output= "Display Name: " + $Update.LocalizedDisplayName +"|||| KB" + $Update.ArticleID
        $output | out-file -append c:\updates.txt
    }
    $Output = "`r" | out-file -append c:\updates.txt
}