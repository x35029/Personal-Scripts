# -----------------------------------------------------------------------------
# Script: Get-OutlookCalendar.ps1
# Author: ed wilson, msft
# Date: 05/10/2011 08:34:36
# Keywords: Microsoft Outlook, Office
# comments:
# reference to HSG-1-29-09
# HSG-5-24-11
# -----------------------------------------------------------------------------
Function Get-OutlookCalendar
{
  <#
   .Synopsis
    This function returns appointment items from default Outlook profile
   .Description
    This function returns appointment items from default Outlook profile. It
    uses the Outlook interop assembly to use the olFolderCalendar enumeration.
    It creates a custom object consisting of Subject, Start, Duration, Location
    for each appointment item. 
   .Example
    Get-OutlookCalendar | 
    where-object { $_.start -gt [datetime]"5/10/2011" -AND $_.start -lt `
    [datetime]"5/17/2011" } | sort-object Duration
    Displays subject, start, duration and location for all appointments that
    occur between 5/10/11 and 5/17/11 and sorts by duration of the appointment.
    The sort is shortest appointment on top. 
   .Notes
    NAME:  Get-OutlookCalendar
    AUTHOR: ed wilson, msft
    LASTEDIT: 05/10/2011 08:36:42
    KEYWORDS: Microsoft Outlook, Office
    HSG: HSG-05-24-2011
   .Link
     Http://www.ScriptingGuys.com/blog
 #Requires -Version 2.0
 #>
 Add-type -assembly "Microsoft.Office.Interop.Outlook" | out-null
 $olFolders = "Microsoft.Office.Interop.Outlook.OlDefaultFolders" -as [type] 
 $outlook = new-object -comobject outlook.application
 $namespace = $outlook.GetNameSpace("MAPI")
 $folder = $namespace.getDefaultFolder($olFolders::olFolderCalendar)
 $folder.items |
 Select-Object -Property Subject, Start, Duration, Location
} #end function Get-OutlookCalendar


Get-OutlookCalendar | where-object { $_.start -gt [datetime]"6/1/2013" -AND $_.start -lt [datetime]"6/30/2013" } | sort-object Duration

Get-OutlookCalendar | Group-Object -Property Location | Sort-Object count –Descending