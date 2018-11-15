###########################################################
# AUTHOR  : Marius / Hican - http://www.hican.nl - @hicannl
# DATE    : 17-08-2012
# COMMENT : This script creates the Software Metering Rules
#           in SCCM 2012, based on an input file.
###########################################################

#ERROR REPORTING ALL
Set-StrictMode -Version latest

$script_parent = Split-Path -Parent $MyInvocation.MyCommand.Definition
$csv_path      = $script_parent + "\create_metering_rules.input"
$csv_import    = Import-Csv $csv_path
$sitecode      = "P01"
$siteserver    = "<SERVER>"
$objectType    = "9"

Write-Host "`r"

ForEach ($item In $csv_import)
{
  If ($item.Implement.ToLower() -eq "y")
  {
    $meteringID = GWMI -Namespace "ROOT\SMS\Site_$sitecode" -ComputerName $siteserver -Query `
    "SELECT * FROM SMS_MeteredProductRule WHERE ProductName = '$($item.ProductName)'"

    If ($meteringID -eq "" -Or $meteringID -eq $Null)
    {
      $ruleClass                 = [WMIClass] "\\$($siteserver)\ROOT\SMS\Site_$($sitecode):SMS_MeteredProductRule"
      $newRule                   = $ruleClass.psbase.CreateInstance()
      $newRule.ProductName       = $item.ProductName
      $newRule.FileName          = $item.FileName
      $newRule.OriginalFileName  = $item.OriginalFileName
      $newRule.FileVersion       = $item.FileVersion
      ### 65535 = Any,                 2057  = English (United Kingdom), 1033  = English (United States)
      ### 1043  = Dutch (Netherlands), 1036  = French (France),          1031  = German (Germany)
      ### 1040  = Italian (Italy),     1041  = Japanese (Japan),         3082  = Spanish (Spain, International Sort)
      $newRule.LanguageID        = $item.LanguageID
      $newRule.SiteCode          = $item.SiteCode
      $newRule.ApplyToChildSites = $item.ApplyToChildSites
      $newRule.Enabled           = $item.Enabled
      $rulePath                  = $newRule.Put()

      Write-Host "[INFO]`tMetering Rule [$($item.ProductName)] created" -foregroundcolor Green

      Try
      {
        $meteringID = GWMI -Namespace "ROOT\SMS\Site_$sitecode" -ComputerName $siteserver -Query `
        "SELECT * FROM SMS_MeteredProductRule WHERE ProductName = '$($item.ProductName)'"
        $method                         = "MoveMembers"
        $colClass                       = [WMIClass] "\\$($siteserver)\ROOT\SMS\Site_$($sitecode):SMS_ObjectContainerItem"
        $InParams                       = $colClass.psbase.GetMethodParameters($method)            
        $InParams.ContainerNodeID       = "0"
        $InParams.InstanceKeys          = $meteringID.SecurityKey
        $InParams.ObjectType            = $objectType
        $targetContainerNodeID          = GWMI -Namespace "ROOT\SMS\Site_$sitecode" -ComputerName $siteserver -Query `
        "SELECT ContainerNodeID FROM SMS_ObjectContainerNode WHERE Name = '$($item.MeteringFolder)' AND ObjectType = '$objectType'"
        $InParams.TargetContainerNodeID = $targetContainerNodeID.ContainerNodeID
        $moveObject                     = $colClass.psbase.InvokeMethod($method,$InParams,$Null)

        Write-Host "[INFO]`tMetering Rule [$($item.ProductName)] moved to Folder [$($item.MeteringFolder)]" -foregroundcolor Green
      }
      Catch
      {
        Write-Host "[ERROR]`tFolder [$($item.MeteringFolder)] doesn't exist, Metering Rule [$($item.ProductName)] couldn't be moved" -foregroundcolor Red
      }
    }
    Else
    {
      Write-Host "[ERROR]`tMetering Rule [$($item.ProductName)] already exists with ID [$($meteringID.RuleID)]" -foregroundcolor Red
    }
  }
  Else
  {
    Write-Host "[WARN]`tProcessing is disabled for Metering Rule [$($item.ProductName)]" -foregroundcolor Yellow
  }
}

Write-Host "`r"