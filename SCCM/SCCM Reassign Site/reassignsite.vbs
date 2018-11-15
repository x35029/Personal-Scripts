'--------------------------------------------------------------------------------------------
' Purpose: 	Re-Assigning SCCM Clients to new Primary Site
'		Arguments "SiteCode" and "FSP" are required.
'
'  	
' Dependencies: Script is meant to be advertised to Site Collection in SCCM
' Known Issues: Site Reassignments will cause full inventory of all clients to be run
'
' Arguments:		SiteCode, FSP
' Output:
'  
' Usage Example:	cscript reassignsite.vbs /SiteCode:<XYZ> /FSP:<DALFSP01.NA.XOM.COM>
' Revision History: 
'--------------------------------------------------------------------------------------------

'--------------------------------------------------------------------------------------------
' Variables and Constants Declared
'--------------------------------------------------------------------------------------------
On Error Resume Next
Const SCRIPT_TITLE = "ReAssignSite"
Const SCRIPT_VERSION = "2.0"
Const SCRIPT_WRITEN_BY = "ExxonMobil, EMIT"
Const ForReading = 1, ForWriting = 2, ForAppending = 8
Dim WshShell, sSMSPath, sRowPath, sStrPosition, sComputer
Dim oSMSClient, sMPServerName, LogFile, sArgSiteCode, sArgFSPRole
Set WshShell = WScript.CreateObject("WScript.Shell")

sRowPath = WshShell.RegRead("HKLM\SYSTEM\CurrentControlSet\Services\CcmExec\ImagePath")
sStrPosition = Len(sRowPath) - 11
sSMSPath = Mid(sRowPath,1, sStrPosition)
LogFileLoc = sSMSPath & "logs\ReAssignSite.log"
sArgSiteCode = WScript.Arguments.Named.Item("SiteCode")
sArgFSPRole = Wscript.Arguments.Named.Item("FSP")
sComputer = "."
sOSArchitecture = OSArchitecture

Set objFSO = CreateObject("Scripting.FileSystemObject")
Set LogFile = objFSO.OpenTextFile(logFileLoc, ForAppending,True)
Set objStream = objFSO.OpenTextFile(inputFile, 1)
Set oSMSClient = CreateObject ("Microsoft.SMS.Client")

'--------------------------------------------------------------------------------------------	
' Main Body
'--------------------------------------------------------------------------------------------
LogFile.WriteLine("Script: "& SCRIPT_TITLE & ", Script Version: " & SCRIPT_VERSION) & ", Script Writen by: " & SCRIPT_WRITEN_BY
LogFile.WriteLine("Assigning new SMS Site to SMS Client started: "& Date &" "& Time)
WScript.Echo "Assigning new SMS Site to SMS Client started: "& Date &" "& Time

wscript.echo "Assigned Site Code is : " & oSMSClient.GetAssignedSite

LogFile.WriteLine("Assigned Site Code is : " & oSMSClient.GetAssignedSite & " - " & Date &" "& Time)	

On Error Resume Next


if Err.Number <>0 then 

	wscript.echo "Could not create SMS Client Object - quitting"
	LogFile.WriteLine("Could not create SMS Client Object - quitting "& " - " & Date &" "& Time)
	LogFile.WriteLine("Error Code is: " & Err.Number & " - " & Date &" "& Time)
    wscript.quit
    
end if

oSMSClient.SetAssignedSite sArgSiteCode,0

wscript.echo "New Assigned Site Code is : " & oSMSClient.GetAssignedSite
LogFile.WriteLine("New Assigned Site Code is : " & oSMSClient.GetAssignedSite & " - " & Date &" "& Time)
LogFile.WriteLine("Assigned new Site Code: "& oSMSClient.GetAssignedSite & " is completed successfully" & " - " & Date &" "& Time)

Set oSMSClient=Nothing

wscript.echo "New Assigned FallBack Status Point is : " & sArgFSPRole
LogFile.WriteLine("New Assigned FallBack Status Point is : " & sArgFSPRole & " - " & Date &" "& Time)

IF sOSArchitecture = "x86" THEN
  WshShell.RegWrite("HKLM\Software\Microsoft\CCM\FSP\HostName"), sArgFSPRole
  wscript.echo "Successfully Assigned FallBack Status Point on x86 machine as : " & sArgFSPRole
  LogFile.WriteLine("Successfully Assigned FallBack Status Point on x86 machine as : " & sArgFSPRole & " - " & Date &" "& Time)
end if

IF sOSArchitecture = "x64" THEN
  WshShell.RegWrite("HKLM\Software\wow6432node\Microsoft\CCM\FSP\HostName"), sArgFSPRole
  wscript.echo "Successfully Assigned FallBack Status Point on x64 machine as : " & sArgFSPRole
  LogFile.WriteLine("Successfully Assigned FallBack Status Point on x64 machine as : " & sArgFSPRole & " - " & Date &" "& Time)
end if

IF sOSArchitecture = "Invalid OS Architecture" THEN
  wscript.echo "Could not determine OS Architecture Type.  FSP Assignment Failed"
  LogFile.WriteLine("Could not determine OS Architecture Type.  FSP Assignment Failed" & " - " & Date &" "& Time)
end if

wscript.echo "Script completed"
LogFile.WriteLine("Script completed.  End of log " & " - " & Date &" "& Time)
Logfile.Close
WScript.Quit

'--------------------------------------------------------------------------------------------	
' Functions
'--------------------------------------------------------------------------------------------

FUNCTION OSArchitecture
'  This function returns the architecture type of the machine (x86 or x64)
  
     SET objWMIService = GetObject("winmgmts:{Impersonationlevel=impersonate}!\\" & sComputer & "\root\cimv2")
     SET colProcessor = objWMIService.ExecQuery("Select * from Win32_Processor")

     FOR EACH objProcessor IN colProcessor

       SELECT CASE objProcessor.AddressWidth
         CASE "32"
           OSArchitecture = "x86" 
         CASE "64"
           OSArchitecture = "x64" 
         CASE ELSE
           OSArchitecture = "Invalid OS Architecture"
       END SELECT 

     NEXT

END FUNCTION 'OSArchitecture

'--------------------------------------------------------------------------------------------	
' End
'--------------------------------------------------------------------------------------------