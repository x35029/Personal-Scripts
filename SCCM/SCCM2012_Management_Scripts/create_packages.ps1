###########################################################
# AUTHOR  : Marius / Hican - http://www.hican.nl - @hicannl
# DATE    : 21-08-2012
# COMMENT : This script creates the Packages in SCCM
#           2012, based on an input file.
###########################################################

#ERROR REPORTING ALL
Set-StrictMode -Version latest

$script_parent = Split-Path -Parent $MyInvocation.MyCommand.Definition
$csv_path      = $script_parent + "\create_packages.input"
$csv_import    = Import-Csv $csv_path
$sitecode      = "P01"
$siteserver    = "<SERVER>"
$objectType    = "2"

Write-Host "`r"

ForEach ($item In $csv_import)
{
  If ($item.Implement.ToLower() -eq "y")
  {
    $packageID = GWMI -Namespace "ROOT\SMS\Site_$sitecode" -ComputerName $siteserver -Query `
    "SELECT PackageID FROM SMS_Package WHERE Name = '$($item.PackageName)' AND Version = '$($item.PackageVersion)'"

    If ($packageID -eq "" -Or $packageID -eq $Null)
    {
      $pkgClass             = [WMIClass] "\\$($siteserver)\ROOT\SMS\Site_$($sitecode):SMS_Package"
      $newPkg               = $pkgClass.CreateInstance()
      $newPkg.Name          = $item.PackageName
      $newPkg.Manufacturer  = $item.PackageManufacturer
      $newPkg.Version       = $item.PackageVersion
      $newPkg.Language      = $item.PackageLanguage
      $newPkg.Description   = $item.PackageComment
      $newPkg.PackageType   = 0
      $newPkg.PkgSourceFlag = 2
      $newPkg.PkgSourcePath = $item.PackageSourcePath
      $newPkg.Priority      = 2
      $pkgPath              = $newPkg.Put()

      Write-Host "[INFO]`tPackage [$($item.PackageName)] created" -foregroundcolor Green

      Try
      {
        $packageID                      = GWMI -Namespace "ROOT\SMS\Site_$sitecode" -ComputerName $siteserver -Query `
        "SELECT PackageID FROM SMS_Package WHERE Name = '$($item.PackageName)' AND Version = '$($item.PackageVersion)'"
        $method                         = "MoveMembers"
        $pkgClass                       = [WMIClass] "\\$($siteserver)\ROOT\SMS\Site_$($sitecode):SMS_ObjectContainerItem"
        $InParams                       = $pkgClass.psbase.GetMethodParameters($method)            
        $InParams.ContainerNodeID       = "0"
        $InParams.InstanceKeys          = $packageID.PackageID
        $InParams.ObjectType            = $objectType
        $targetContainerNodeID          = GWMI -Namespace "ROOT\SMS\Site_$sitecode" -ComputerName $siteserver -Query `
        "SELECT ContainerNodeID FROM SMS_ObjectContainerNode WHERE Name = '$($item.PackageFolder)' AND ObjectType = '$objectType'"
        $InParams.TargetContainerNodeID = $targetContainerNodeID.ContainerNodeID
        $moveObject                     = $pkgClass.psbase.InvokeMethod($method,$InParams,$Null)

        Write-Host "[INFO]`tPackage [$($item.PackageName)] moved to Folder [$($item.PackageFolder)]" -foregroundcolor Green
      }
      Catch
      {
        Write-Host "[ERROR]`tFolder [$($item.PackageFolder)] doesn't exist, Package [$($item.PackageName)] couldn't be moved" -foregroundcolor Red
      }
    }
    Else
    {
      Write-Host "[ERROR]`tPackage [$($item.PackageName)] already exists with ID [$($packageID.PackageID)]" -foregroundcolor Red
    }
  }
  Else
  {
    Write-Host "[WARN]`tProcessing is disabled for Package [$($item.PackageName)]" -foregroundcolor Yellow
  }
}

Write-Host "`r"
