###########################################################
# AUTHOR  : Marius / Hican - http://www.hican.nl - @hicannl
# DATE    : 29-08-2012
# COMMENT : This script creates the Programs in SCCM
#           2012, based on an input file.
###########################################################

#ERROR REPORTING ALL
Set-StrictMode -Version latest

$script_parent = Split-Path -Parent $MyInvocation.MyCommand.Definition
$csv_path      = $script_parent + "\create_programs.input"
$csv_import    = Import-Csv $csv_path
$siteserver      = "P01"
$sccmserver    = "<SERVER>"

Write-Host "`r"

ForEach ($item In $csv_import)
{
  If ($item.Implement.ToLower() -eq "y")
  {
    $packageID = GWMI -Namespace "ROOT\SMS\Site_$sitecode" -ComputerName $siteserver -Query `
    "SELECT PackageID FROM SMS_Package WHERE Name = '$($item.PackageName)'"

    If ($packageID -ne "" -And $packageID -ne $Null)
    {
      $programID = GWMI -Namespace "ROOT\SMS\Site_$sitecode" -ComputerName $siteserver -Query `
      "SELECT * FROM SMS_Program WHERE PackageID = '$($packageID)' AND ProgramName = '$($item.ProgramName)'"

      If ($programID -eq "" -Or $programID -eq $Null)
      {
        Try
        {
          $prgClass                     = [WMIClass] "\\$($siteserver)\ROOT\SMS\Site_$($sitecode):SMS_Program"
          $newPrg                       = $prgClass.CreateInstance()
          $newPrg.ProgramName           = $item.ProgramName
          $newPrg.PackageID             = $packageID.PackageID
          $newPrg.CommandLine           = $item.CommandLine
          $newPrg.Comment               = $item.ProgramComment
          $newPrg.ProgramFlags          = $item.ProgramFlags
          $prgPath                      = $newPrg.Put()

          Write-Host "[INFO]`tProgram [$($item.ProgramName)] created" -foregroundcolor Green
        }
        Catch
        {
          Write-Host "[ERROR]`t$($_.Exception.Message)" -foregroundcolor Red
          Write-Host "[ERROR]`tProgram [$($item.ProgramName)] for Package [$($item.PackageName)] couldn't be created" -foregroundcolor Red
          Write-Host "[ERROR]`tDatabase contains stale records and need to be cleared, try again later" -foregroundcolor Red
        }
      }
      Else
      {
        Write-Host "[ERROR]`tProgram [$($item.ProgramName)] already exists for Package ID [$($packageID.PackageID)]" -foregroundcolor Red
      }
    }
    Else
    {
      Write-Host "[ERROR]`tPackage [$($item.PackageName)] doesn't exist, Program [$($item.ProgramName)] couldn't be created" -foregroundcolor Red
    }
  }
  Else
  {
    Write-Host "[WARN]`tProcessing is disabled for Program [$($item.ProgramName)]" -foregroundcolor Yellow
  }
}

Write-Host "`r"
