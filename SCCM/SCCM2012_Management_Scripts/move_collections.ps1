###########################################################
# AUTHOR  : Marius / Hican - http://www.hican.nl - @hicannl
# DATE    : 17-08-2012
# COMMENT : This script moves Collections in SCCM 2012 from
#           one Folder to another, based on an input file.
###########################################################

#ERROR REPORTING ALL
Set-StrictMode -Version latest

$script_parent = Split-Path -Parent $MyInvocation.MyCommand.Definition
$csv_path      = $script_parent + "\move_collections.input"
$csv_import    = Import-Csv $csv_path
$sitecode      = "P01"
$siteserver    = "<SERVER>"
$foldermembers = @()

Write-Host "`r"

ForEach ($item In $csv_import)
{
  If ($item.CollectionType.ToLower() -eq "device")
  {
    $collectionType = "2"
    $objectType     = "5000"
  }
  Else
  {
    $collectionType = "1"
    $objectType     = "5001"
  }

  If ($item.Implement.ToLower() -eq "y")
  {
    $collectionID                       = GWMI -Namespace "ROOT\SMS\Site_$sitecode" -ComputerName $siteserver -Query `
    "SELECT CollectionID FROM SMS_Collection WHERE Name = '$($item.CollectionName)' AND CollectionType = '$collectionType'"

    If ($collectionID -ne "" -And $collectionID -ne $Null)
    {
      Try
      {
        $collectionID                   = GWMI -Namespace "ROOT\SMS\Site_$sitecode" -ComputerName $siteserver -Query `
        "SELECT CollectionID FROM SMS_Collection WHERE Name = '$($item.CollectionName)' AND CollectionType = '$collectionType'"
        $method                         = "MoveMembers"
        $colClass                       = [WMIClass] "\\$($siteserver)\ROOT\SMS\Site_$($sitecode):SMS_ObjectContainerItem"
        $InParams                       = $colClass.psbase.GetMethodParameters($method)  
        $InParams.ContainerNodeID       = "0"
        $InParams.InstanceKeys          = $collectionID.CollectionID
        $InParams.ObjectType            = $objectType
        $targetContainerNodeID          = GWMI -Namespace "ROOT\SMS\Site_$sitecode" -ComputerName $siteserver -Query `
        "SELECT ContainerNodeID FROM SMS_ObjectContainerNode WHERE Name = '$($item.TargetFolder)' AND ObjectType = '$objectType'"
        $InParams.TargetContainerNodeID = $targetContainerNodeID.ContainerNodeID
        $moveObject                     = $colClass.psbase.InvokeMethod($method,$InParams,$Null)
      }
      Catch
      {
        Write-Host "[ERROR]`t$($_.Exception.Message)" -foregroundcolor Red
      }

      $foldermembers                    = GWMI -Namespace "ROOT\SMS\Site_$sitecode" -ComputerName $siteserver -Query `
      "SELECT ContainerNodeID FROM SMS_ObjectContainerNode WHERE ObjectType = '$objectType'"
      ForEach ($member In $foldermembers)
      {
        $i = 0
        Try
        {
          $collectionID                     = GWMI -Namespace "ROOT\SMS\Site_$sitecode" -ComputerName $siteserver -Query `
          "SELECT CollectionID FROM SMS_Collection WHERE Name = '$($item.CollectionName)' AND CollectionType = '$collectionType'"
          $method                           = "MoveMembers"
          $colClass                         = [WMIClass] "\\$($siteserver)\ROOT\SMS\Site_$($sitecode):SMS_ObjectContainerItem"
          $InParams                         = $colClass.psbase.GetMethodParameters($method)  
          $InParams.ContainerNodeID         = $member.ContainerNodeID
          $InParams.InstanceKeys            = $collectionID.CollectionID
          $InParams.ObjectType              = $objectType
          $targetContainerNodeID            = GWMI -Namespace "ROOT\SMS\Site_$sitecode" -ComputerName $siteserver -Query `
          "SELECT ContainerNodeID FROM SMS_ObjectContainerNode WHERE Name = '$($item.TargetFolder)' AND ObjectType = '$objectType'"
          If ($targetContainerNodeID -ne "" -And $targetContainerNodeID -ne $Null)
          {
            $InParams.TargetContainerNodeID = $targetContainerNodeID.ContainerNodeID
            $moveObject                     = $colClass.psbase.InvokeMethod($method,$InParams,$Null)
            $i = 1
		  }
        }
        Catch
        {
          Write-Host "[ERROR]`t$($_.Exception.Message)" -foregroundcolor Red
        }
      }
      If ($i -eq 1)
      {
        Write-Host "[INFO]`t[$($item.CollectionType)] Collection [$($item.CollectionName)] moved to Folder [$($item.TargetFolder)]" -foregroundcolor Green
      }
      Else
      {
        Write-Host "[ERROR]`tFolder [$($item.TargetFolder)] doesn't exist, [$($item.CollectionType)] Collection [$($item.CollectionName)] couldn't be moved" -foregroundcolor Red
      }
    }
    Else
    {
      Write-Host "[ERROR]`t[$($item.CollectionType)] Collection [$($item.CollectionName)] doesn't exist" -foregroundcolor Red
    }
  }
  Else
  {
    Write-Host "[WARN]`tProcessing is disabled for [$($item.CollectionType)] Collection [$($item.CollectionName)]" -foregroundcolor Yellow
  }
}

Write-Host "`r"