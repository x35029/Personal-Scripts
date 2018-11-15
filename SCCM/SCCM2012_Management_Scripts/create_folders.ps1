###########################################################
# AUTHOR  : Marius / Hican - http://www.hican.nl - @hicannl
# DATE    : 16-08-2012
# COMMENT : This script creates the Collection / Package /
#           Metering / Etc. Folders in SCCM 2012, based on
#           an input file.
###########################################################

#ERROR REPORTING ALL
Set-StrictMode -Version latest

$script_parent = Split-Path -Parent $MyInvocation.MyCommand.Definition
$csv_path      = $script_parent + "\create_folders.input"
$csv_import    = Import-Csv $csv_path
$sitecode      = "P01"
$siteserver    = "<SERVER>"

Write-Host "`r"

ForEach ($item In $csv_import)
{
  If ($item.FolderType.ToLower() -eq "package") { $objectType = "2" }
  If ($item.FolderType.ToLower() -eq "advertisement") { $objectType = "3" }
  If ($item.FolderType.ToLower() -eq "metering") { $objectType = "9" }
  If ($item.FolderType.ToLower() -eq "tasksequence") { $objectType = "20" }
  If ($item.FolderType.ToLower() -eq "driverpackage") { $objectType = "23" }
  If ($item.FolderType.ToLower() -eq "devicecollection") { $objectType = "5000" }
  If ($item.FolderType.ToLower() -eq "usercollection") { $objectType = "5001" }
  If ($item.FolderType.ToLower() -eq "application") { $objectType = "6000" }

  If ($item.Implement.ToLower() -eq "y")
  {
    Try
    {
      If ($item.FolderParent -eq "ROOT")
      {
        $parentID = "0"
      }
      Else
      {
        $folderParentID = GWMI -Namespace "ROOT\SMS\Site_$sitecode" -ComputerName $siteserver -Query "SELECT ContainerNodeID FROM SMS_ObjectContainerNode WHERE Name = '$($item.FolderParent)' AND ObjectType = '$objectType'"
        $parentID = $folderParentID.ContainerNodeID
      }

      $folderID = GWMI -Namespace "ROOT\SMS\Site_$sitecode" -ComputerName $siteserver -Query "SELECT ContainerNodeID FROM SMS_ObjectContainerNode WHERE Name = '$($item.FolderName)' AND ObjectType = '$objectType' AND ParentContainerNodeid = '$parentID'"

      If ($folderID -eq "" -Or $folderID -eq $Null)
      {
        $folderClass                     = [WMIClass] "\\$($siteserver)\ROOT\SMS\Site_$($sitecode):SMS_ObjectContainerNode"
        $newFolder                       = $folderClass.CreateInstance()
        $newFolder.Name                  = $item.FolderName
        $newFolder.ObjectType            = $objectType
        $newFolder.ParentContainerNodeid = $parentID

        $folderPath                      = $newFolder.Put()

        Write-Host "[INFO]`t[$($item.FolderType)] CollectionFolder [$($item.FolderName)] created" -foregroundcolor Green
      }
      Else
      {
        Write-Host "[ERROR]`t[$($item.FolderType)] Folder [$($item.FolderName)] already exists with ID [$($folderID.ContainerNodeID)]" -foregroundcolor Red
      }
    }
    Catch
    {
      Write-Host "[WARN]`tRoot folder [$($item.FolderParent)] couldn't be found" -foregroundcolor Red
    }
  }
  Else
  {
    Write-Host "[WARN]`tProcessing is disabled for [$($item.FolderType)] CollectionFolder [$($item.FolderName)]" -foregroundcolor Yellow
  }
}

Write-Host "`r"