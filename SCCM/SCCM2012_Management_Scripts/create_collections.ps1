###########################################################
# AUTHOR  : Marius / Hican - http://www.hican.nl - @hicannl
# DATE    : 17-08-2012
# EDIT    : 03-02-2015
# COMMENT : This script creates the Collections in SCCM
#           2012, based on an input file.
###########################################################

#ERROR REPORTING ALL
Set-StrictMode -Version latest

$script_parent     = Split-Path -Parent $MyInvocation.MyCommand.Definition
$csv_path          = $script_parent + "\create_collections.input"
$script:csv_import = Import-Csv $csv_path
$script:sitecode   = "<SITECODE>"
$script:siteserver = "<SERVER>"
$script:output     = $script_parent + "\create_collections.output"

Function Start-Process
{
  Create-Collection
}

Function Create-Collection
{
  ForEach ($item In $csv_import)
  {
    $refresh = $item.RefreshSchedule
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
      $collectionID = GWMI -ComputerName $siteserver -Namespace "ROOT\SMS\Site_$sitecode" -Query "SELECT CollectionID FROM SMS_Collection WHERE Name = '$($item.CollectionName)' AND CollectionType = '$collectionType'"

      If ($collectionID -eq "" -Or $collectionID -eq $Null)
      {
        $colClass                     = [WMIClass] "\\$($siteserver)\ROOT\SMS\Site_$($sitecode):SMS_Collection"
        $newCol                       = $colClass.CreateInstance()
        $newCol.Name                  = $item.CollectionName
        $newCol.Comment               = $item.CollectionComment
        $newCol.CollectionType        = $collectionType

        $collectionLimitID = GWMI -ComputerName $siteserver -Namespace "ROOT\SMS\Site_$sitecode" -Query "SELECT CollectionID FROM SMS_Collection WHERE Name = '$($item.CollectionLimit)'"

        If ($collectionLimitID -eq "" -Or $collectionLimitID -eq $Null)
        {
          $newCol.LimitToCollectionID = "SMS00001"
        }
        Else
        {
          $newCol.LimitToCollectionID = $collectionLimitID.CollectionID
        }

        If ($refresh -ne "")
        {
          If ($refresh.Length -ge 2)
          {
            $schClass               = [WMIClass] "\\$($siteserver)\ROOT\SMS\Site_$($sitecode):SMS_ST_RecurInterval"
            $newSch                 = $schClass.CreateInstance()
            $refreshCheck           = $refresh.SubString(0,1)
            $refreshInterval        = $refresh.Length - $refreshCheck.Length
            $refreshTime            = $refresh.SubString($refresh.Length - $refreshInterval, $refreshInterval)

            If ($refreshCheck.ToLower() -eq "m")
            {
              If ($refreshTime -match "^([1-9]|[1-5][0-9])$")
              {
                $newSch.MinuteSpan = [int]$refreshTime
              }
              Else
              {
                $newSch.MinuteSpan  = 59;WriteToLog "[INFO]`tNo valid time entered, RefreshSchedule has been set to 59 minutes"
              }
            }
            ElseIf ($refreshCheck.ToLower() -eq "h")
            {
              If ($refreshTime -match "^([1-9]|1[0-9]|2[0-3])$")
              {
                $newSch.HourSpan = [int]$refreshTime
              }
              Else
              {
                $newSch.HourSpan  = 3;WriteToLog "[INFO]`tNo valid time entered, RefreshSchedule has been set to 3 hours"
              }
            }
            ElseIf ($refreshCheck.ToLower() -eq "d")
            {
              If ($refreshTime -match "^([1-9]|[12][0-9]|3[01])$")
              {
                $newSch.DaySpan = [int]$refreshTime
              }
              Else
              {
                $newSch.DaySpan  = 1;WriteToLog "[INFO]`tNo valid time entered, RefreshSchedule has been set to 1 day"
              }
            }
            Else
            {
              $newSch.DaySpan  = 1;WriteToLog "[INFO]`tNo valid time entered, RefreshSchedule has been set to 1 day"
            }
            $newSch.StartTime       = (Get-Date -Format "yyyyMMddhhmmss")+".000000+***"
            $newCol.RefreshSchedule = $newSch
            $newCol.RefreshType     = 2
          }
          Else
          {
            WriteToLog "[ERROR]`tRefreshSchedule should be 2 characters long and in the format of <letter><number>"
          }
        }
        Else
        {
          #$newSch.DaySpan         = 7;WriteToLog "[INFO]`tNo valid time entered, RefreshSchedule has been set to 7 days"
          #$newSch.StartTime       = (Get-Date -Format "yyyyMMddhhmmss")+".000000+***"
          #$newCol.RefreshSchedule = $newSch
          $newCol.RefreshType     = 4 # Use Incremental Updates
        }

        $colPath  = $newCol.Put()

        WriteToLog "[INFO]`t[$($item.CollectionType)] Collection [$($item.CollectionName)] created"

        If ($item.CollectionFolder -ne "")
        {
          Try
          {
            $collectionID                   = GWMI -ComputerName $siteserver -Namespace "ROOT\SMS\Site_$sitecode" -Query "SELECT CollectionID FROM SMS_Collection WHERE Name = '$($item.CollectionName)' AND CollectionType = '$collectionType'"
            $method                         = "MoveMembers"
            $colClass                       = [WMIClass] "\\$($siteserver)\ROOT\SMS\Site_$($sitecode):SMS_ObjectContainerItem"
            $InParams                       = $colClass.psbase.GetMethodParameters($method)            
            $InParams.ContainerNodeID       = "0"
            $InParams.InstanceKeys          = $collectionID.CollectionID
            $InParams.ObjectType            = $objectType
            $targetContainerNodeID          = GWMI -ComputerName $siteserver -Namespace "ROOT\SMS\Site_$sitecode" -Query "SELECT ContainerNodeID FROM SMS_ObjectContainerNode WHERE Name = '$($item.CollectionFolder)' AND ObjectType = '$objectType'"
            $InParams.TargetContainerNodeID = $targetContainerNodeID.ContainerNodeID
            $moveObject                     = $colClass.psbase.InvokeMethod($method,$InParams,$Null)

            WriteToLog "[INFO]`t[$($item.CollectionType)] Collection [$($item.CollectionName)] moved to Folder [$($item.CollectionFolder)]"
          }
          Catch
          {
            WriteToLog "[ERROR]`tFolder [$($item.CollectionFolder)] doesn't exist, [$($item.CollectionType)] Collection [$($item.CollectionName)] couldn't be moved"
          }
        }

        If ($item.RuleQuery -ne "" -And $item.RuleQuery -ne $Null)
        {
          $col    = GWMI -ComputerName $siteserver -Namespace "ROOT\SMS\Site_$sitecode" -Class SMS_Collection -Filter "Name = '$($item.CollectionName)' And CollectionType = '$collectionType'"

          If ($item.RuleType -eq "Query")
          {
            Try
            {
              $colQry = $item.RuleQuery
              $valQry = Invoke-WmiMethod -ComputerName $siteserver -Namespace "ROOT\SMS\Site_$sitecode" -Class SMS_CollectionRuleQuery -Name ValidateQuery -ArgumentList $colQry
     
              If($valQry.ReturnValue -eq $True)
              {
                $col.Get()

                #Create new rule
                $qryRule                 = ([WMIClass] "\\$($siteserver)\ROOT\SMS\Site_$($sitecode):SMS_CollectionRuleQuery").CreateInstance()
                $qryRule.QueryExpression = $colQry
                If ($item.RuleName -ne "")
                {
                  $qryRule.RuleName      = $item.RuleName
                }
                Else
                {
                  $qryRule.RuleName      = $item.CollectionName
                }

                $col.CollectionRules    += $qryRule.psobject.baseobject
                #$col.RefreshType         = 6 # Enables Incremental updates
                $put                     = $col.Put()
                $refresh                 = $col.RequestRefresh()

                WriteToLog "[INFO]`tCollection Query Rule for [$($item.CollectionName)] created"
              }
              Else
              {
                WriteToLog "[ERROR]`tCollection Query isn't a valid SQL Query. Rule couldn't be created"
              }
            }
            Catch
            {
              WriteToLog "[ERROR]`tCollection Rule couldn't be created"
            }
          }
          Else
          {
            $col.Get()
            $colQry = @()
            $colQry = ($item.RuleQuery).Split(";")

            ForEach ($machine In $colQry)
            {
              $resourceID                  = ""
              #Get Resource ID
              $resourceID                  = GWMI -ComputerName $siteserver -Namespace "ROOT\SMS\Site_$sitecode" -Class SMS_R_System -Filter "Name = '$machine'"

              If ($resourceID)
              {
                #Create new rule
                $qryRule                   = ([WMIClass] "\\$($siteserver)\ROOT\SMS\Site_$($sitecode):SMS_CollectionRuleDirect").CreateInstance()
                $qryRule.ResourceClassName = "SMS_R_System"
                $qryRule.ResourceID        = $resourceID.ResourceID
                $qryRule.RuleName          = $machine

                $col.CollectionRules      += $qryRule.psobject.baseobject
                $put                       = $col.Put()
                $refresh                   = $col.RequestRefresh()

                WriteToLog "[INFO]`tDirect Rule created for [$($machine)] in [$($item.CollectionName)]"
              }
              Else
              {
                WriteToLog "[ERROR]`tCouldn't create a Direct Rule for [$($machine)] in [$($item.CollectionName)]"
              }
            }
          }
        }
      }
      Else
      {
        WriteToLog "[ERROR]`t[$($item.CollectionType)] Collection [$($item.CollectionName)] already exists with ID [$($collectionID.CollectionID)]"
      }
    }
    Else
    {
      WriteToLog "[WARN]`tProcessing is disabled for [$($item.CollectionType)] Collection [$($item.CollectionName)]"
    }
  }
}

Function WriteToLog
{
  Param ($message)

  If ($message.contains("[INFO]")) { Write-Host $message -foregroundcolor Green }
  ElseIf ($message.contains("[WARN]")) { Write-Host $message -foregroundcolor Yellow }
  ElseIf ($message.contains("[ERROR]")) { Write-Host $message -foregroundcolor Red }
  ElseIf ($message.contains("[STARTED]"))
  {
    $logdate = (Get-Date).ToString("dd-MM-yyyy HH:mm:ss")
    $message = "[$($logdate)]`t--- Started Script Execution ---"
    Write-Host $message -foregroundcolor White
  }
  ElseIf ($message.contains("[STOPPED]"))
  {
    $logdate = (Get-Date).ToString("dd-MM-yyyy HH:mm:ss")
    $message = "[$($logdate)]`t--- Stopped Script Execution ---`r"
    Write-Host $message -foregroundcolor White
  }
  Else { Write-Host $message -foregroundcolor White }

  $script:logdate = (Get-Date).ToString("dd-MM-yyyy HH:mm:ss")
  $message | Out-File $output -Append
}

WriteToLog "[STARTED]"
Start-Process
WriteToLog "[STOPPED]"