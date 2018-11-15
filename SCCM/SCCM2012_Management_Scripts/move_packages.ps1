###########################################################
# AUTHOR  : Marius / Hican - http://www.hican.nl - @hicannl
# DATE    : 22-08-2012
# COMMENT : This script moves Packages in SCCM 2012 from
#           one Folder to another, based on an input file.
###########################################################

#ERROR REPORTING ALL
Set-StrictMode -Version latest

$script_parent = Split-Path -Parent $MyInvocation.MyCommand.Definition
$csv_path      = $script_parent + "\move_packages.input"
$csv_import    = Import-Csv $csv_path
$sitecode      = "P01"
$siteserver    = "<SERVER>"
$objectType    = "2"
$foldermembers = @()

Write-Host "`r"

ForEach ($item In $csv_import)
{
  If ($item.Implement.ToLower() -eq "y")
  {
    $packageID = GWMI -Namespace "ROOT\SMS\Site_$sitecode" -ComputerName $siteserver -Query `
    "SELECT PackageID FROM SMS_Package WHERE Name = '$($item.PackageName)'"

    If ($packageID -ne "" -And $packageID -ne $Null)
    {
      Try
      {
        $packageID = GWMI -Namespace "ROOT\SMS\Site_$sitecode" -ComputerName $siteserver -Query `
        "SELECT PackageID FROM SMS_Package WHERE Name = '$($item.PackageName)'"
        $method                         = "MoveMembers"
        $pkgClass                       = [WMIClass] "\\$($siteserver)\ROOT\SMS\Site_$($sitecode):SMS_ObjectContainerItem"
        $InParams                       = $pkgClass.psbase.GetMethodParameters($method)            
        $InParams.ContainerNodeID       = "0"
        $InParams.InstanceKeys          = $packageID.PackageID
        $InParams.ObjectType            = $objectType
        $targetContainerNodeID          = GWMI -Namespace "ROOT\SMS\Site_$sitecode" -ComputerName $siteserver -Query `
        "SELECT ContainerNodeID FROM SMS_ObjectContainerNode WHERE Name = '$($item.TargetFolder)' AND ObjectType = '$objectType'"
        $InParams.TargetContainerNodeID = $targetContainerNodeID.ContainerNodeID
        $moveObject                     = $pkgClass.psbase.InvokeMethod($method,$InParams,$Null)
      }
      Catch
      {
      }

      $foldermembers                    = GWMI -Namespace "ROOT\SMS\Site_$sitecode" -ComputerName $siteserver -Query `
      "SELECT ContainerNodeID FROM SMS_ObjectContainerNode WHERE ObjectType = '$objectType'"
      ForEach ($member In $foldermembers)
      {
        $i = 0
        Try
        {
          $packageID = GWMI -Namespace "ROOT\SMS\Site_$sitecode" -ComputerName $siteserver -Query `
          "SELECT PackageID FROM SMS_Package WHERE Name = '$($item.PackageName)'"
          $method                           = "MoveMembers"
          $pkgClass                         = [WMIClass] "\\$($siteserver)\ROOT\SMS\Site_$($sitecode):SMS_ObjectContainerItem"
          $InParams                         = $pkgClass.psbase.GetMethodParameters($method)
          $InParams.ContainerNodeID         = $member.ContainerNodeID
          $InParams.InstanceKeys            = $packageID.PackageID
          $InParams.ObjectType              = $objectType
          $targetContainerNodeID            = GWMI -Namespace "ROOT\SMS\Site_$sitecode" -ComputerName $siteserver -Query `
          "SELECT ContainerNodeID FROM SMS_ObjectContainerNode WHERE Name = '$($item.TargetFolder)' AND ObjectType = '$objectType'"
          If ($targetContainerNodeID -ne "" -And $targetContainerNodeID -ne $Null)
          {
            $InParams.TargetContainerNodeID = $targetContainerNodeID.ContainerNodeID
            $moveObject                     = $pkgClass.psbase.InvokeMethod($method,$InParams,$Null)
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
        Write-Host "[INFO]`tPackage [$($item.PackageName)] moved to Folder [$($item.TargetFolder)]" -foregroundcolor Green
      }
      Else
      {
        Write-Host "[ERROR]`tFolder [$($item.TargetFolder)] doesn't exist, Package [$($item.PackageName)] couldn't be moved" -foregroundcolor Red
      }
    }
    Else
    {
      Write-Host "[ERROR]`tPackage [$($item.PackageName)] doesn't exist" -foregroundcolor Red
    }
  }
  Else
  {
    Write-Host "[WARN]`tProcessing is disabled for Package [$($item.PackageName)]" -foregroundcolor Yellow
  }
}

Write-Host "`r"