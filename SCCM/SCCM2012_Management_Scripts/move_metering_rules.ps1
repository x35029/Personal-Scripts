###########################################################
# AUTHOR  : Marius / Hican - http://www.hican.nl - @hicannl
# DATE    : 17-08-2012
# COMMENT : This script moves Metering Rules in SCCM 2012 
#           from one Folder to another, based on an input 
#           file.
###########################################################

#ERROR REPORTING ALL
Set-StrictMode -Version latest

$script_parent = Split-Path -Parent $MyInvocation.MyCommand.Definition
$csv_path      = $script_parent + "\move_metering_rules.input"
$csv_import    = Import-Csv $csv_path
$sitecode      = "P01"
$siteserver    = "<SERVER>"
$objectType    = "9"
$foldermembers = @()

Write-Host "`r"

ForEach ($item In $csv_import)
{
  If ($item.Implement.ToLower() -eq "y")
  {
    $meteringID = GWMI -Namespace "ROOT\SMS\Site_$sitecode" -ComputerName $siteserver -Query `
    "SELECT * FROM SMS_MeteredProductRule WHERE ProductName = '$($item.ProductName)'"

    If ($meteringID -ne "" -And $meteringID -ne $Null)
    {
      Try
      {
        $meteringID = GWMI -Namespace "ROOT\SMS\Site_$sitecode" -ComputerName $siteserver -Query `
        "SELECT * FROM SMS_MeteredProductRule WHERE ProductName = '$($item.ProductName)'"
        $method                           = "MoveMembers"
        $mtrClass                         = [WMIClass] "\\$($siteserver)\ROOT\SMS\Site_$($sitecode):SMS_ObjectContainerItem"
        $InParams                         = $mtrClass.psbase.GetMethodParameters($method)
        $InParams.ContainerNodeID         = "0"
        $InParams.InstanceKeys            = $meteringID.SecurityKey
        $InParams.ObjectType              = $objectType
        $targetContainerNodeID            = GWMI -Namespace "ROOT\SMS\Site_$sitecode" -ComputerName $siteserver -Query `
        "SELECT ContainerNodeID FROM SMS_ObjectContainerNode WHERE Name = '$($item.TargetFolder)' AND ObjectType = '$objectType'"
        $InParams.TargetContainerNodeID   = $targetContainerNodeID.ContainerNodeID
        $moveObject                       = $mtrClass.psbase.InvokeMethod($method,$InParams,$Null)
      }
      Catch
      {
        Write-Host "[ERROR]`t$($_.Exception.Message)" -foregroundcolor Red
      }

      $foldermembers                      = GWMI -Namespace "ROOT\SMS\Site_$sitecode" -ComputerName $siteserver -Query `
      "SELECT ContainerNodeID FROM SMS_ObjectContainerNode WHERE ObjectType = '$objectType'"
      ForEach ($member In $foldermembers)
      {
        $i = 0
        Try
        {
          $meteringID = GWMI -Namespace "ROOT\SMS\Site_$sitecode" -ComputerName $siteserver -Query `
          "SELECT * FROM SMS_MeteredProductRule WHERE ProductName = '$($item.ProductName)'"
          $method                           = "MoveMembers"
          $mtrClass                         = [WMIClass] "\\$($siteserver)\ROOT\SMS\Site_$($sitecode):SMS_ObjectContainerItem"
          $InParams                         = $mtrClass.psbase.GetMethodParameters($method)
          $InParams.ContainerNodeID         = $member.ContainerNodeID
          $InParams.InstanceKeys            = $meteringID.SecurityKey
          $InParams.ObjectType              = $objectType
          $targetContainerNodeID            = GWMI -Namespace "ROOT\SMS\Site_$sitecode" -ComputerName $siteserver -Query `
          "SELECT ContainerNodeID FROM SMS_ObjectContainerNode WHERE Name = '$($item.TargetFolder)' AND ObjectType = '$objectType'"
          If ($targetContainerNodeID -ne "" -And $targetContainerNodeID -ne $Null)
          {
            $InParams.TargetContainerNodeID = $targetContainerNodeID.ContainerNodeID
            $moveObject                     = $mtrClass.psbase.InvokeMethod($method,$InParams,$Null)
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
        Write-Host "[INFO]`tMetering Rule [$($item.ProductName)] moved to Folder [$($item.TargetFolder)]" -foregroundcolor Green
      }
      Else
      {
        Write-Host "[ERROR]`tFolder [$($item.TargetFolder)] doesn't exist, Metering Rule [$($item.ProductName)] couldn't be moved" -foregroundcolor Red
      }
    }
    Else
    {
      Write-Host "[ERROR]`tMetering Rule [$($item.ProductName)] doesn't exist" -foregroundcolor Red
    }
  }
  Else
  {
    Write-Host "[WARN]`tProcessing is disabled for Metering Rule [$($item.ProductName)]" -foregroundcolor Yellow
  }
}

Write-Host "`r"