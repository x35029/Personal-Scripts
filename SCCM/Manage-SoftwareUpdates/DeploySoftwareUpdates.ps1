# This script will read a file as input.  Each line of that file should contain the Software Update Group, a Deployment 
# Name and the target collection for the deployment.  These values should be seperated by a comma.  
# Example:  Update Group 1,Test Deployment 1,All Systems
# 
# The script will then build all deployments against the deployments groups configured in the file using the parameters
# for the deployment as detailed on the Start-CMSoftwareUpdateDeployment cmdlet.  
# NOTE 1:  It would be easy to allow user define settings for each Start-CMSoftwareUpdateDeployment parameter if desired.
# NOTE 2:  If an update group contains updates that are superseded or expired then deployments may fail to be created.
# Ensure that the update group being targeted for deployment is properly maintained either manually or using a seperate
# script.
# NOTE 3:  The script uses a text file as an input source.  The script could be modified to leverage whatever input source
# is preferred, such as an Excel spreadsheet, SharePoint list, web page, etc.

Param(
    [Parameter(Mandatory = $true)]
    $SiteServerName,
    [Parameter(Mandatory = $true)]
    $SiteCode
    )

Import-module ($Env:SMS_ADMIN_UI_PATH.Substring(0,$Env:SMS_ADMIN_UI_PATH.Length-5) + '\ConfigurationManager.psd1')

# Connect to discovered top level site
cd $SiteCode":"

# Get the details for the deployment from the text file.
$DeploymentDetail = Get-Content c:\UpdateControl.txt

# Process each line of the input file.
ForEach ($Detail in $DeploymentDetail)
{
    # Each item in the input file is separated by a comma.  Split those values into their corresponding intended variable
    # and use as options for Start-CMSoftwareUpdateDeployment.
    $split=$Detail.split(",")
    $UpdateGroupName = $Split[0]
    $DeploymentTitle = $Split[1]
    $TargetCollection = $Split[2]
    # The Start-CMSoftwareUpdateDeployment cmdlet creates the deployment based on a combination of static defaults configured
    # here and variables passed in from the text file.
    Start-CMSoftwareUpdateDeployment -SoftwareUpdateGroupName $UpdateGroupName -CollectionName $TargetCollection -DeploymentName $DeploymentTitle -Description "Deployment Created by Powershell" -DeploymentType Available -VerbosityLevel AllMessages -TimeBasedOn UTC -DeploymentAvailableDay 2014/1/1 -UserNotification DisplayAll -DownloadFromMicrosoftUpdate $True -AllowUseMeteredNetwork $False

}