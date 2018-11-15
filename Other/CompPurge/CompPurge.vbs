'
'  Script to clean up inactive computer accounts in the Active Directory environment
'
'  Usage: Cscript CompPurge.vbs </i:IniFileName> </d:DomainName> </l:LogFileName> </T> </?>
'        
'  Author:  Dennis Arvidson
'           ExxonMobil Global Services
'           22 March 2010
'
'  Changes: Date              Who       What 
'           ----------------- --------- ---------------------------------------------
'           3 Nov 2010        DWA       Updated LDAP Query to exclude DRAC and RIB
'           18 Oct 2012       DWA       Extended test mode into ADUpdate
'           2 Dec 2014        DWA       Updated to handle CNF objects
'           21 Dec 2015       DWA       Fixed handling of empty LastLogonTimeStamp
'           11 Feb 2016       DWA       Changed empty LastLogonTimeStamp check to only apply to CNF objects
'         
strVersion = "1.5"


'  File System Object

Const ForReading = 1
Const ForWriting = 2
Const ForAppending = 8
Const TristateUseDefault = -2
Const TristateTrue = -1
Const TristateFalse = 0

'  Global Variables
Dim INIContents, iCnt
Dim FolderName, ShareName, WorkingDC, WorkingGC
Dim InactiveMonths, strLogFileFolder, strLogFileFile
Dim strSeedFileFolder, strSeedFileFile, LogRetention
Dim strTSVFileFolder, strTSVFileFile, FSO, fIni, fs, ft
Dim dctInclusions, dctExclusions, dctGroups, dctFiles, OSVer, SeedValue
Dim InactivePeriod, LogFileFolder, LogFileName, SeedFileFolder, SeedFileName
Dim SelectedComputersFileFolder, SelectedComputersFileName, SelectedComputersPath
Dim SeedFilePath, SelectedComputersExtension, DisableFilePath, PurgeFilePath
Dim flgFirstRun, tmpInclusion, tmpExclusion, tmpFile, tmpGroup, tmpFolder
Dim numInclusions, numExclusions, numFiles, numGroups, tmpFilePath
Dim dctComputerExclusions, dctCandidates, CutoffDate, sDate, iDate, ws, CODYYMM
Dim arCandidates, ADUpdateDisableIniFilePath, strExcludedGroups, strCmd
Dim ADUpdateLogFilePath, ADUpdateIniFilePath, ADUpdateDisableLogFilePath
Dim ADUpdateFolder, ADUpdateDeleteIniFilePath, RetentionIncrement, ADUpdateDeleteLogFilePath
Dim flgTestMode, strScriptPath


'  Translation constants

Const ADS_NAME_TYPE_1779 = 1
Const ADS_NAME_TYPE_NT4 = 3
Const ADS_NAME_INITTYPE_DOMAIN = 1 
Const ADS_NAME_INITTYPE_SERVER = 2 
Const ADS_NAME_INITTYPE_GC = 3

'  Initialize variables

Set ws = WScript.CreateObject("WScript.Shell")
strScriptPath = Mid(WScript.ScriptFullName, 1, InStrRev(WScript.ScriptFullName, "\"))

flgTestMode = False
ComputerName = ws.ExpandEnvironmentStrings("%COMPUTERNAME%")
UserName = UCase(ws.ExpandEnvironmentStrings("%USERNAME%"))
EnvUserDomain = UCase(ws.ExpandEnvironmentStrings("%USERDOMAIN%"))
EnvUserDNSDomain = UCase(ws.ExpandEnvironmentStrings("%USERDNSDOMAIN%"))
SysRoot = ws.ExpandEnvironmentStrings("%SystemRoot%")
DomainLocalGroup = ADS_GROUP_TYPE_DOMAIN_LOCAL_GROUP Or ADS_GROUP_TYPE_SECURITY_ENABLED
GlobalGroup = ADS_GROUP_TYPE_GLOBAL_GROUP Or ADS_GROUP_TYPE_SECURITY_ENABLED
flgDebug = False
ProgramFIles = ws.ExpandEnvironmentStrings("%ProgramFiles%")
ServerName = ComputerName
INIFileName = strScriptPath & "CompPurge.ini"
PassedDomain = ""
LogFileName = ""
AAOutputFile = ""
flgFirstRun = True
' On Error Resume Next
OSVer = GetOSVer
Set objAD = CreateObject("ADSystemInfo")
ComputerDomain = objAD.DomainShortName
Set FSO = CreateObject("Scripting.FileSystemObject")

'  Check arguments

Set Args = WScript.Arguments
numArgs = Args.Count
For i = 0 to Args.Count - 1
   If Args(i) = "/?" or Args(i) = "?" Then Call DisplayUsage
   If LCase(Args(i)) = "/t" Then
      flgTestMode = True
   End If
   Select case Left(LCase(Args(i)),2)
      Case "/l"
         If Mid(Args(i),3,1) = ":" Then
            LogFileName = Trim(Mid(Args(i),4))
         End If
      Case "/i"
         If Mid(Args(i),3,1) = ":" Then
            IniFileName = Trim(Mid(Args(i),4))
         End If
      Case "/d"
         If Mid(Args(i),3,1) = ":" Then
            PassedDomain = Trim(Mid(Args(i),4))
         End If
      Case Else
   End Select
Next

'  Get contents of the INI file As a String
If Trim(IniFileName) <> "" Then
   INIContents = GetFile(IniFileName)
Else
'    WriteLogFileMsg "INI File missing from command line."
   WScript.Echo "IniFile missing from command line. No instructions for " & _
   WScript.ScriptName & " to carry out."
   WScript.Quit
End If

'  Read in the configuration from the Ini file

IniSection = "Configuration"
InactivePeriod = GetINIString(IniSection, "InactivePeriod", "6")
LogFileFolder = GetINIString(IniSection, "LogFileFolder", "")
LogFileFolder = Replace(LogFileFolder, "{", "<")
LogFileFolder = Replace(LogFileFolder, "}", ">")
LogFileName = GetINIString(IniSection, "LogFileName", "")
SeedFileFolder = GetINIString(IniSection, "SeedFileFolder", "")
SeedFileFolder = Replace(SeedFileFolder, "{", "<")
SeedFileFolder = Replace(SeedFileFolder, "}", ">")
SeedFileName = GetINIString(IniSection, "SeedFileName", "CompPurgeSeed.Txt")
SelectedComputersFileFolder = GetINIString(IniSection, "SelectedComputersFileFolder", "")
SelectedComputersFileFolder = Replace(SelectedComputersFileFolder, "{", "<")
SelectedComputersFileFolder = Replace(SelectedComputersFileFolder, "}", ">")
SelectedComputersFileName = GetINIString(IniSection, "SelectedComputersFileName", "")
SelectedComputersExtension = GetINIString(IniSection, "SelectedComputersExtension", "TSV")
ADUpdateFolder = GetINIString(IniSection, "ADUpdateFolder", "")
ADUpdateFolder = Replace(ADUpdateFolder, "{", "<")
ADUpdateFolder = Replace(ADUpdateFolder, "}", ">")
RetentionIncrement = GetINIString(IniSection, "FileRetention", "12")
strTestMode = GetINIString(IniSection, "TestMode", "")
If Not flgTestMode Then
   If UCase(Left(strTestMode, 1)) = "Y" Then
      flgTestMode = True
   End If
End If

If LogFileName <> "" Then
   If LogFileFolder <> "" And LogFileName <> "" Then
      If Right(LogFileFolder, 1) <> "\" Then
         LogFileFolder = LogFileFolder & "\"
      End If
      LogFileName = LogFileFolder & LogFileName 
   End If
End If

If SeedFileFolder = "" Or UCase(SeedFileFolder) = "<CURRENTFOLDER>" Then
   SeedFileFolder = strScriptPath
End If
If Right(SeedFileFolder, 1) <> "\" Then
   SeedFileFolder = SeedFileFolder & "\"
End If
If SeedFileName <> "" Then
   SeedFilePath = SeedFileFolder & SeedFileName
Else
   SeedFilePath = SeedFileFolder & "CompPurge.txt"
End If

If SelectedComputersFileFolder = "" Or UCase(SelectedComputersFileFolder) = "<CURRENTFOLDER>" Then
   SelectedComputersFileFolder = strScriptPath
End If
If Right(SelectedComputersFileFolder, 1) <> "\" Then
   SelectedComputersFileFolder = SelectedComputersFileFolder & "\"
End If
If SelectedComputersFileName <> "" Then
   SelectedComputersFilePath = SelectedComputersFileFolder & SelectedComputersFileName
Else
   SelectedComputersFilePath = SelectedComputersFileFolder & "CompPurge"
End If

If ADUpdateFolder = "" Or UCase(ADUpdateFolder) =  "<CURRENTFOLDER>" Then
   ADUpdateFolder = strScriptPath
End If
If Right(ADUpdateFolder, 1) <> "\" Then
   ADUpdateFolder = ADUpdateFolder & "\"
End If

If fso.FileExists(SeedFilePath) Then
   Set fs = FSO.OpenTextFile(SeedFilePath, ForReading)
   SeedValue = fs.ReadLine
   If SeedValue = "" Then
      SeedValue = 0
      flgFirstRun = True
   Else
      flgFirstRun = False
   End If
Else
   SeedValue = 0
End If

If flgFirstRun Then
   DisableFilePath = SelectedComputersFilePath & SeedValue & "." & SelectedComputersExtension
   LogQualifier = "0"
Else
   DisableFilePath = SelectedComputersFilePath & (SeedValue + 1) & "." & SelectedComputersExtension
   LogQualifier = (SeedValue + 1)
End If
PurgeFilePath = SelectedComputersFilePath & SeedValue & "." & SelectedComputersExtension

ADUpdateIniFilePath = Replace(DisableFilePath, "." & SelectedComputersExtension, ".Ini", _
   1, 1, 1)
ADUpdateDisableIniFilePath = Replace(ADUpdateIniFilePath, LogQualifier & ".Ini", _
   "ADUpdateDisables" & LogQualifier & ".Ini", 1, 1, 1)
ADUpdateDeleteIniFilePath = Replace(ADUpdateIniFilePath, LogQualifier & ".Ini", _
   "ADUpdateDeletes" & LogQualifier & ".Ini", 1, 1, 1)

Set objNet = CreateObject("WScript.Network")
strCurrentLoggedOnUser = objNet.UserName
strCurrentLoggedOnDomain = objNet.UserDomain

If LogFileName <> "" Then
   LogFileName = Replace(LogFileName, ".Log", LogQualifier & ".Log", 1, 1, 1)
   ADUpdateLogFilePath = Replace(LogFileName, LogQualifier & ".Log", _
      "ADUpdate" & LogQualifier & ".Log", 1, 1, 1)
   ADUpdateDisableLogFilePath = Replace(ADUpdateLogFilePath, LogQualifier & ".Log", _
      "ADUDisables" & LogQualifier & ".Log", 1, 1, 1)
   ADUpdateDeleteLogFilePath = Replace(ADUpdateLogFilePath, LogQualifier & ".Log", _
      "ADUDeletes" & LogQualifier & ".Log", 1, 1, 1)
   Err.Clear
   Set f = FSO.OpenTextFile(LogFileName, ForWriting, True)
   If Err.Number <> 0 Then
      WScript.Echo "Error " & Err.Number & " (" & Err.Description & _
         ") opening log file " & LogFileName & "."
      WScript.Quit
   End If
   flgDebug = True
End If
WriteLogFileMsg "===> Start of " & WScript.ScriptName & " Version " & strVersion & " <==="

If flgTestMode Then
   WriteLogFileMsg "   *** Running in Test Mode only ! ***"
End If
Set dctInclusions = CreateObject("Scripting.Dictionary")
Set dctExclusions = CreateObject("Scripting.Dictionary")
Set dctFiles = CreateObject("Scripting.Dictionary")
Set dctGroups = CreateObject("Scripting.Dictionary")

WriteLogFileMsg "   Disable File List " & Chr(34) & DisableFilePath & Chr(34) & "."
WriteLogFileMsg "   Purge File List " & Chr(34) & PurgeFilePath & Chr(34) & "."

'   Read in the OUs to include

IniSection = "Inclusions"
numInclusions = GetINIString(IniSection, "numInclusions", "0")
If numInclusions > 0 Then
   For iCnt = 1 To numInclusions
      tmpInclusion = GetINIString(IniSection, "Inclusion" & iCnt, "")
      If tmpInclusion = "" Then
         WriteLogFileMsg "   Inclusion" & iCnt & " variable missing from [" & _
            IniSection & "] of Ini file " & Chr(34) & IniFileName & Chr(34) & "."
      Else
         dctInclusions.Add iCnt, tmpInclusion
      End If
   Next
End If

'   Read in the OUs to exclude

IniSection = "Exclusions"
numExclusions = GetINIString(IniSection, "numExclusions", "0")
If numExclusions > 0 Then
   For iCnt = 1 To numExclusions
      tmpExclusion = GetINIString(IniSection, "Exclusion" & iCnt, "")
      If tmpExclusion = "" Then
         WriteLogFileMsg "   Exclusion" & iCnt & " variable missing from [" & _
            IniSection & "] of Ini file " & Chr(34) & IniFileName & Chr(34) & "."
      Else
         dctExclusions.Add iCnt, tmpExclusion
'          WriteLogFileMsg "Exclusion " & dctExclusions.Item(iCnt) & " added."
      End If
   Next
End If

'   Read in the Groups whose members are to be excluded

numGroups = GetINIString(IniSection, "numGroups", "0")
If numGroups > 0 Then
   For iCnt = 1 To numGroups
      tmpGroup = GetINIString(IniSection, "Group" & iCnt, "")
      If tmpGroup = "" Then
         WriteLogFileMsg "   Group" & iCnt & " variable missing from [" & _
            IniSection & "] of Ini file " & Chr(34) & IniFileName & Chr(34) & "."
      Else
         dctGroups.Add iCnt, tmpGroup
      End If
   Next
End If

'   Read in the Files whose members are to be excluded

numFiles = GetINIString(IniSection, "numFiles", "0")
If numFiles > 0 Then
   For iCnt = 1 To numFiles
      tmpFolder = GetINIString(IniSection, "Folder" & iCnt, "")
      tmpFile = GetINIString(IniSection, "File" & iCnt, "")
      WriteLogFileMsg "   tmpFolder:" & tmpFolder
      WriteLogFileMsg "   tmpFile:" & tmpFile
      If tmpFile = "" Then
         WriteLogFileMsg "   File" & iCnt & " variable missing from [" & _
            IniSection & "] of Ini file " & Chr(34) & IniFileName & Chr(34) & "."
      Else
         If tmpFolder = "" Or UCase(tmpFolder) = "<CURRENTFOLDER>" Then
            tmpFolder = Mid(WScript.ScriptFullName, 1, InStrRev(WScript.ScriptFullName, "\"))
         End If
         If Right(tmpFolder, 1) <> "\" Then
            tmpFolder = tmpFolder & "\"
         End If
         tmpFilePath = tmpFolder & tmpFile
         dctFiles.Add iCnt, tmpFilePath
      End If
   Next
End If

'   Calculate DNS name for short domain name if domain passed

If PassedDomain = "" Then
   PassedDomain = ComputerDomain
End If
If PassedDomain <> "" Then
   Err.Clear
   Set nto = CreateObject("NameTranslate")
   nto.Init ADS_NAME_INITTYPE_DOMAIN, PassedDomain
   nto.Set ADS_NAME_TYPE_NT4, PassedDomain & "\"
   User1779Name = nto.Get(ADS_NAME_TYPE_1779)
   UserDNSDomain = CVTADToDNS(User1779Name)
   UserDomain = PassedDomain
   If Err.Number <> 0 Then
      WScript.Echo ""
      WScript.Echo ""
      WScript.Echo "Can't resolve passed domain " & PassedDomain & ", Error:" & _
         Err.Number & " (" & Hex(Err.Number) & ")"
      WScript.Echo ""
      WScript.Echo ""
      WScript.Quit 0
   End If
Else
   UserDNSDomain = EnvUserDNSDomain
   UserDomain = EnvUserDomain
End If
Region = UserDomain

WriteLogFileMsg "   Working on domain: " & UserDNSDomain & "  Region: " & Region

On Error Resume Next

'  Create LDAP domain String

LDAPDomain = "dc="
For i = 1 To Len(UserDNSDomain)
   if Mid(UserDNSDomain, i, 1) = "." Then
      LDAPDomain = LDAPDomain & ",dc="
   Else
      LDAPDomain = LDAPDomain & Mid(UserDNSDomain, i, 1)
   End If
Next

WriteLogFileMsg "   LDAPDomain: " & LDAPDomain
WriteLogFileMsg "   User: " & strCurrentLoggedOnDomain & "\" & strCurrentLoggedOnUser

'  Get the nearest Domain Controller

If WorkingDC = "" Then
   WorkingDC = GetDC
End If

'  Get the nearest GC

If WorkingGC = "" Then
   WorkingGC = GetGC
End If

WriteLogFileMsg "   Operating System version " & OSVer
WriteLogFileMsg "   Working DC " & WorkingDC
WriteLogFileMsg "   Working GC " & WorkingGC


'   Populate the computer exemption list

Set dctComputerExclusions = CreateObject("Scripting.Dictionary")

'     Get each group member

WriteLogFileMsg "   Processing group members..."
If numGroups > 0 Then
   For iCnt = 1 To numGroups
      If dctGroups.Exists(iCnt) Then
         tmpGroup = dctGroups.Item(iCnt)
         GetGroupMembers tmpGroup, dctComputerExclusions
      End If
   Next
End If

'     Get each file member

WriteLogFileMsg "   Processing file members..."
If numFiles > 0 Then
   For iCnt = 1 To numFiles
      If dctGroups.Exists(iCnt) Then
         tmpFile = dctFiles.Item(iCnt)
         GetFileMembers tmpFile, dctComputerExclusions
      End If
   Next
End If

'     Calculate the "stale" Date

CutoffDate = DateAdd("m", -(InactivePeriod+1), Date)
CMonth = Month(CutoffDate)
If CMonth < 10 Then
   CMonth = "0" & Cmonth
End If
CYear = Year(CutoffDate)
CODYYMM = CYear & CMonth
sDate = ws.RegRead("HKCU\Control Panel\International\sDate")
iDate = ws.RegRead("HKCU\Control Panel\International\iDate")

WriteLogFileMsg "   Cutoff date:" &  CYear & Cmonth

'  Build the ini file and run ADUpdate for the delete process
'      Processing last months disabled list

If Not flgFirstRun And FSO.FileExists(PurgeFilePath) Then

'  Build the ini file and run ADUpdate for the purge process
'       Building ADUpdate ComputerDeletes section.
   WriteLogFileMsg "   Building and running ADUpdate for deletion process."
   Err.Clear
   Set fIni = FSO.OpenTextFile(ADUpdateDeleteIniFilePath, forwriting, True)
   If Err.Number <> 0 Then
      WriteLogFileMsg "Error " & Err.Number & " (" & Err.Description & _
         ") opening ADUpdate purge Ini file " & ADUpdatePurgeFilePath & "."
      WScript.Quit
   End If
   fIni.WriteLine "[DeleteComputers]"
   fIni.WriteLine "numDeletions=1"
   fIni.WriteLine "AccountList1=" & PurgeFilePath
   fIni.WriteLine "DisabledOnly1=y"
   fIni.WriteLine "CheckDate1=" & cMonth & "/01/" & cYear
   If flgTestMode Then
      fIni.WriteLine "Test1=Y"
   End If
   fIni.Close

'   Call ADUpdate to run the actual deletion processes

   strCmd = "cscript.exe " & ADUpdateFolder & "ADUpdate.vbs " & Chr(34) & "/I:" & _
      ADUpdateDeleteIniFilePath & _
      Chr(34) & " " & Chr(34) & "/L:" & ADUpdateDeleteLogFilePath & Chr(34)

   WriteLogFileMsg "Calling ADUpdate with " & strCmd
'   If Not flgTestMode Then
      RunAndLog strCmd
'   End If
Else
   WriteLogFileMsg "   There are no computer deletions to process."
End If



Set dctCandidates =  CreateObject("Scripting.Dictionary")

'     Process each OU from the inclusions list

For iCnt = 1 To numInclusions
   If dctInclusions.Exists(iCnt) Then
      ProcessOU dctInclusions.Item(iCnt), CutoffDate, dctCandidates
   End If
Next

'     Write this months TSV file

Set ft = FSO.OpenTextFile(DisableFilePath, ForWriting, True)
If Err.Number <> 0 Then
   WriteLogFileMsg "Error " & Err.Number & " (" & Err.Description & _
      ") opening Disable TSV file " & DisableFilePath & "."
   WScript.Quit
End If

arCandidates = dctCandidates.Items
For iCnt = 0 To UBound(arCandidates)
   ft.WriteLine Region & Chr(9) & arCandidates(iCnt)
Next
ft.Close

'     Process the results


WriteLogFileMsg "   Building ADUpdate Ini file " & Chr(34) & _
      ADUpdateIniFilePath & Chr(34) & "."

If UBound(arCandidates) = 0 And Trim(arCandidates(0)) = "" Then
   WriteLogFileMsg "   There were no computers selected for disabling."
   numDisabled = 0
Else

'  Build the ini file and run ADUpdate for the disable process

   WriteLogFileMsg "   Building and running ADUpdate for disable process."
   numDisabled = UBound(arCandidates) + 1
   Err.Clear
   Set fIni = FSO.OpenTextFile(ADUpdateDisableIniFilePath, ForWriting, True)
   If Err.Number <> 0 Then
      WriteLogFileMsg "Error " & Err.Number & " (" & Err.Description & _
         ") opening ADUpdate disable Ini file " & ADUpdateDisableIniFilePath & "."
      WScript.Quit
   End If
   fIni.WriteLine "[DisableAccounts]"
   fIni.WriteLine "numDisables=1"
   fIni.WriteLine "AccountList1=" & DisableFilePath
   fIni.WriteLine "AccountType1=computer"
   fIni.WriteLine "DateCheck1=" & cMonth & "/01/" & cYear
   If flgTestMode Then
      fIni.WriteLine "Test1=Y"
   End If
   If numGroups > 0 Then
      strExcludedGroups = "ExcludeGroups1="
      For iCnt = 1 To numGroups
         If iCnt > 1 Then
            strExcludedGroups = strExcludedGroups & ","
         End If
         strExcludedGroups = strExcludedGroups & dctGroups.Item(iCnt)
      Next
       fIni.WriteLine strExcludedGroups
   End If
   fIni.WriteLine " "
   fIni.Close

'   Call ADUpdate to run the actual disable and deletion processes

   strCmd = "cscript.exe " & ADUpdateFolder & "ADUpdate.vbs " & Chr(34) & "/I:" & _
      ADUpdateDisableIniFilePath & _
      Chr(34) & " " & Chr(34) & "/L:" & ADUpdateDisableLogFilePath & Chr(34)

   WriteLogFileMsg "Calling ADUpdate with " & strCmd
'   If Not flgTestMode Then
      RunAndLog strCmd
'   End If
End If

'  Update the Seed file

WriteLogFileMsg "   Update seed file " & SeedFilePath
Set fs = FSO.OpenTextFile(SeedFilePath, 2, True)
If flgFirstRun Then
   fs.WriteLine SeedValue
Else
   fs.WriteLine (SeedValue+1)
End If
fs.Close

'   Delete old TSV, Ini and Log files

If CInt(RetentionIncrement) > CInt(LogQualifier) Then
   WriteLogFileMsg "   No log or tsv file purge file candidates this period."
Else
   WriteLogFileMsg "   Purging..."
   PurgeOldFiles LogFileName, RetentionIncrement, LogQualifier
   PurgeOldFiles ADUpdateDisableLogFilePath, RetentionIncrement, LogQualifier
   PurgeOldFiles ADUpdateDeleteLogFilePath, RetentionIncrement, LogQualifier
   PurgeOldFiles ADUpdateDisableIniFilePath, RetentionIncrement, LogQualifier
   PurgeOldFiles ADUpdateDeleteIniFilePath, RetentionIncrement, LogQualifier
   PurgeOldFiles DisableFilePath, RetentionIncrement, LogQualifier
End If

WriteLogFileMsg "===> " & WScript.ScriptName & " done! <==="

WScript.Quit 0


'  Purge old Files

Sub PurgeOldFiles(strFile, Retention, Qualifier)

Dim nCurrent, strFileName, strFolder, strFilePattern
Dim strExt, iPtr, f, fc, f1, iTarget, flg

' WriteLogFileMsg "PurgeOldFiles---> " & strFile & "  Retention:" & Retention & "  Qual:" & Qualifier
On Error Resume Next

iTarget = Qualifier - Retention
strFolder = Mid(strFile, 1, InStrRev(strFile, "\"))
strExt = Mid(strFile, InStrRev(strFile, "."))
strFilePattern = Mid(strFile, Len(strFolder) + 1)
strFilePattern = Mid(strFilePattern, 1,  (Len(strFilePattern) - Len(Qualifier & strExt)))
If strFolder = "" Then
   WriteLogFileMsg "   Could not compute file path for purge of old files using " & _
      strFile & "."
   Exit Sub
End If

If strExt = "" Then
   WriteLogFileMsg "   Could not compute file extension for purge of old files using " & _
      strFile & "."
   Exit Sub
End If

If not FSO.FolderExists(strFolder) Then
   WriteLogFileMsg "   Folder " & strFolder & " does not exist. Old file purge not performed."
   Exit Sub
End If

Set f = FSO.GetFolder(strFolder)
Set fc = f.Files
For Each f1 In fc
   If UCase(Left(f1.Name, Len(strFilePattern))) = UCase(strFilePattern) Then
      If UCase(Right(f1.Name, Len(strExt))) = UCase(strExt) Then
         nCurrent = Mid(f1.Name, Len(strFilePattern) + 1, Len(f1.Name) - (Len(strFilePattern)+Len(strExt)))
         flg = IsNumeric(nCurrent)
         If flg Then
            If CInt(nCurrent) <= CInt(iTarget) Then
               Err.Clear
               If Not flgTestMode Then
                  FSO.DeleteFile(strFolder & f1.Name)
               End If
               If Err.Number = 0 Then
                  WriteLogFileMsg "   File " & strFolder & f1.Name & " has been deleted."
               Else
                  WriteLogFileMsg "   Error " & Err.Number & " (" & Hex(Err.Number) & _
                     " deleting file " & strFolder & f1.Name & "."
               End If
           End If
         End If
      End If
   End If
Next


End Sub


'  Process computer accounts in the specified OU/Container

Sub ProcessOU(OUName, CutoffDate, dctObject)


Dim strBase, strFilter, strAttrs, strScope, objectName
Dim objConn, objRS, objCmd, strComputer, iCnt, flgExclude
On Error Resume Next

If WorkingDC <> "" Then
   strBase = "<LDAP://" & WorkingDC & "/" & OUName & "," & LDAPDomain & ">;"
Else
   strBase = "<LDAP://" & OUName & "," & LDAPDomain & ">;"
End If


strFilter = "(&(objectclass=computer)(objectcategory=computer)(!(objectClass=hpqTarget)(objectClass=dellProduct)));"
strFilter = "(&(objectclass=computer)(!objectClass=hpqTarget)(!objectClass=dellProduct));"
strAttrs = "cn,samAccountName,DistinguishedName;"
strScope = "subtree"

Set objCon = CreateObject("ADODB.Connection")
objCon.Open "Provider=ADsDSOObject;"
Set objCmd = CreateObject("ADODB.Command")
objCmd.ActiveConnection = objCon
strQry = strBase & strFilter & strAttrs & strScope
objCmd.Properties("Size Limit") = 1000
objCmd.Properties("Page Size") = 1000
objCmd.CommandText = strQry
WriteLogFileMsg "Processing " & OUName & " ...."
Set objRS = objCmd.Execute
If Err.Number <> 0 Then
   If Err.Number = -2147217865 Then
      WriteLogFileMsg "OU " & OUName & " does not exist."
	  Exit Sub
   Else
      WriteLogFileMsg "Error " & Err.Number & " (" & Hex(Err.Number) & _
         ") querying OU with " & strQry & "."
      Exit Sub
   End If
End If

objRS.MoveFirst
While Not objRS.EOF
   Set objComputer = GetObject("LDAP://" & objRS.Fields("DistinguishedName"))
   
'   WriteLogFileMsg "Processing " & objRS.Fields("DistinguishedName")
   compDate = Trim(objComputer.PasswordLastChanged)
   compDate = Mid(compDate, 1, InStr(compDate, " ")-1)
   Dim compArray
   compArray = Split(compDate, sDate)
   Select Case iDate
      Case 1
         yy = compArray(2)
         dd = compArray(0)
         mm = compArray(1)
      Case 2
         yy = compArray(0)
         dd = compArray(2)
         mm = compArray(1)
      Case Else
         yy = compArray(2)
         dd = compArray(1)
         mm = compArray(0)
   End Select
   If Len(yy) = 2 Then
      yy = "20" & yy
   End If
   If Len(mm) < 2 Then mm = "0" & mm
   If Len(dd) < 2 Then dd = "0" & dd
   PasswordYYDD = yy & mm
'   WriteLogFileMsg "      PasswordLastChanged " & PasswordYYDD
'   WriteLogFileMsg "Processing LastLogonTimeStamp..."
   Err.Clear
   Set objLogonTS = objComputer.LastLogonTimeStamp
   If Err.Number <> 0 Then
      WriteLogFileMsg "    Account " & objRS.Fields("DistinguishedName") & " never logged on to.  Setting to 0."
      If InStr(objComputer.cn, "CNF:") > 0 Then
	     tmpLastLogonTS = 0
	  End If
   Else
'      WriteLogFileMsg "LastLogonTimeStamp.HighPart " & objLogonTS.HighPart
'      WriteLogFileMsg "LastLogonTimeStamp.LowPart " & objLogonTS.LowPart
      tmpLastLogonTS = ""
      tmpLastLogonTS = objLogonTS.HighPart * (2^32) + objLogonTS.LowPart
      tmpLastLogonTS = tmpLastLogonTS / (60 * 10000000)
      tmpLastLogonTS = tmpLastLogonTS / 1440
   End If
'    tmpLastLogonTS = tmpLastLogonTS + #1/1/1601#
   Select Case iDate
      Case 1
         tmpLastLogonTS = tmpLastLogonTS + #1/1/1601#
      Case 2
         tmpLastLogonTS = tmpLastLogonTS + #1601/1/1#
      Case  Else
         tmpLastLogonTS = tmpLastLogonTS + #1/1/1601#
   End Select
   tmpLastLogonTS = Mid(tmpLastLogonTS, 1, InStr(tmpLastLogonTS, " ")-1)
'   WriteLogFileMsg "      sDate:" & sDate
   WriteLogFileMsg "      LastLogonTimestamp:" & tmpLastLogonTS
   compArray = Split(tmpLastLogonTS, sDate)
   Select Case iDate
      Case 1
         yy = compArray(2)
         dd = compArray(0)
         mm = compArray(1)
      Case 2
         yy = compArray(0)
         dd = compArray(2)
         mm = compArray(1)
      Case Else
         yy = compArray(2)
         dd = compArray(1)
         mm = compArray(0)
   End Select
   If Len(yy) = 2 Then
      yy = "20" & yy
   End If
   If Len(mm) < 2 Then mm = "0" & mm
   If Len(dd) < 2 Then dd = "0" & dd
   LastLogonYYDD = yy & mm
    WriteLogFileMsg "      LastLogon " & yy & mm
    For i = 0 To UBound(dArray)
       WriteLogFileMsg "      dArray(" & i & ") " & dArray(i)
    Next
    WriteLogFileMsg "      LastLogonYYDD " & LastLogonYYDD
   
   
    WriteLogFileMsg "      " & objComputer.DistinguishedName
   objRS.MoveNext
'    WriteLogFileMsg objComputer.cn & "  CODYYMM:" & CODYYMM & _
'       "   pw:" & PasswordYYDD & "  Logon:" & LastLogonYYDD
   If PasswordYYDD <= CODYYMM And LastLogonYYDD <= CODYYMM Then
'       WriteLogFileMsg "      Candidate " & objComputer.DistinguishedName
      
'    Account is a candidate - process all exclusions

      If dctComputerExclusions.Exists(objComputer.cn) Then
         WriteLogFileMsg "      Computer " & dctComputerExclusions.Item(objComputer.cn) & _
            " is in the exclusions list."
      Else

'    Check exclusion by OU location

         flgExclude = False
         For iCnt = 1 To numExclusions
            If InStr(objComputer.DistinguishedName, dctExclusions.Item(iCnt)) > 0 And _
               Len(dctExclusions.Item(iCnt)) > 0 Then
'                WriteLogFileMsg "OU Exclusion " & objComputer.DistinguishedName & _
'                   "    OU:" & dctExclusions.Item(iCnt)
               flgExclude = True
            End If      
         Next
         If flgExclude Then
            WriteLogFileMsg "      Computer " & objComputer.cn & _
               " is in an excluded OU."
         Else
'
'   CNF Object fix (use samAccountNameinstead of cn)
'
            If InStr(objComputer.cn, "CNF:") > 0 Then
               If Left(objComputer.samAccountName, 1) = "$" Then
                  objectName = objComputer.samAccountName
               Else
                  objectName = Left(objComputer.samAccountName, (Len(objComputer.samAccountName)-1))
               End If
            Else
               objectName = Left(objComputer.samAccountName, (Len(objComputer.samAccountName)-1))
            End If
            dctObject.Add objComputer.cn, objectName
            WriteLogFileMsg "   Candidate " & objComputer.cn & _
               " (" & objectName & ") " & _
               "  PW: " & PasswordYYDD & "  LLogon:" & LastLogonYYDD
         End If
      End If
   Else
'       WriteLogFileMsg "      Current " & objComputer.DistinguishedName
'       WriteLogFileMsg "   Current " & objComputer.cn & _
'          "  PW: " & PasswordYYDD & "  LLogon:" & LastLogonYYDD
   End If
Wend
Err.Clear
objRS.Close

End Sub

'   Get each group member that is a computer and in the domain

Sub GetGroupMembers(GroupName, dctObject)

Dim objGroup
Dim tmpGrp, tLoc, tmpDom, strDomFQN
Dim objRS, objCon, objCmd

WriteLogFileMsg "      Processing exclusion group " & GroupName

strDomFQN = GetDomainFQN(Region)
Set objCon = CreateObject("ADODB.Connection")
objCon.Open "Provider=ADsDSOObject;"

Set objCmd = CreateObject("ADODB.Command")
objCmd.ActiveConnection = objCon

objCmd.CommandText = "<LDAP://" & WorkingDC & "/" & LDAPDomain & ">;" & _
   "(&(objectCategory=group)(cn="& GroupName & "));" & _
   "name,cn,samAccountName,DistinguishedName;subtree"

Set objRS = objCmd.Execute

If objRS.RecordCount = 0 Then
   WriteLogFileMsg "   Group " & GroupName & " does not exist."
   objRS.Close
   Exit Sub
End If

Set objGrp =  GetObject("LDAP://" & WorkingDC & "/" & objRS.Fields("DistinguishedName"))
If Err.Number <> 0 Then
   If Err.Number = -2147024843 Then
      WriteLogFileMsg "Group " & GroupName & " does not exist."
   Else
      WriteLogFileMsg "   Error " & Err.Number & " (" & Hex(Err.Number) & _
         ") binding to group " & GroupName
   End If
   objRS.Close
   Exit Sub
End If
objRS.Close

For Each objMember In objgrp.Members
   If UCase(LDAPDomain) = UCase(Right(objMember.DistinguishedName, Len(LDAPDomain))) Then
      If Not dctObject.Exists(objMember.cn) Then
         dctObject.Add objMember.cn, objMember.cn
'          WriteLogFileMsg objMember.cn & " added."
      End If
'       WriteLogFileMsg "      Member " & objMember.sAMAccountName
'       WriteLogFileMsg "      cn " & objMember.cn
'       WriteLogFileMsg "      DN " & objMember.DistinguishedName
   End If
Next

End Sub


'   Get each file member that is a computer and in the domain

Sub GetFileMembers(FileName, dctObject)

Dim ff, strBuffer, tmpDom, tmpComp, strArray

WriteLogFileMsg "      Processing exclusion file " & FileName
If FSO.FileExists(FileName) Then
   Set ff = FSO.OpenTextFile(FileName, ForReading)
   Do While ff.AtEndOfStream <> True
      strBuffer = ff.ReadLine
      strArray = Split(strBuffer, Chr(9))
      If UCase(strArray(0)) = UCase(Region) Then
         dctObject.Add strArray(1), strArray(1)
'          WriteLogFileMsg strArray(1) & " added."
      End If
   Loop
   ff.Close
Else
   WriteLogFileMsg "      Exclusion file " & FileName & " does not exist."
End If

End Sub


'  Retrieve the FQN format of the domain
Function GetDomainFQN(strDom)

Dim nto, Src1779

On Error Resume Next
Set nto = CreateObject("NameTranslate")
nto.Init ADS_NAME_INITTYPE_DOMAIN, strDom
If Err.Number <> 0 Then
   WriteLogFileMsg "   Error " & Err.Number & " (" & Hex(Err.Number) & _
      ") accessing domain " & strDom & "."
   GetDomainFQN = ""
   Exit Function
End If
nto.Set ADS_NAME_TYPE_NT4, strDom & "\"
Src1779 = nto.Get(ADS_NAME_TYPE_1779)
GetDomainFQN = Src1779

End Function




Function GetDC()

'  Find the nearest Domain Controller server in the domain

Dim ADDomain, DNSDomain, MyDC, iLoc 
Dim objIadsTools, verInfo, strCmd, strResults

On Error Resume Next

verInfo = Split(OSVer, ".")
If verInfo(0) > 5 Then
   strCmd = "nltest /dsgetdc:" & Region
   RunAndCapture strCmd, strResults
   iLoc = InStr(strResults, "\\")
   If iLoc > 0 Then
      strCmd = Mid(strResults, iLoc+2)
      iLoc = InStr(strCmd, " ")
      If iLoc > 0 Then
         MyDC = Mid(strCmd, 1, iLoc-3)
      Else
         MyDC = strCmd
      End If
      GetDC = MyDC
   Else
      GetDC = ""
   End If
Else
   Set objIadsTools = CreateObject("IADsTools.DCFunctions")
   Set nto = CreateObject("NameTranslate")
   nto.Init ADS_NAME_INITTYPE_DOMAIN, UserDomain
   nto.Set ADS_NAME_TYPE_NT4, UserDomain & "\"
   ADDomain = nto.Get(ADS_NAME_TYPE_1779)
  
   DNSDomain = CVTADToDNS(ADDomain)
   objIadsTools.EnableDebugLogging(3)

'  Get the nearest DC 

   objIadsTools.DsGetDCName CStr(DNSDomain)
   MyDC = objIadsTools.DCName
   iLoc = InStr(MyDC, ".")
   If iLoc > 1 Then
      GetDC = Mid(MyDC, 1, iLoc-1)
   Else
      GetDC = MyDC
   End If
End If

End Function


Function GetGC()

Dim objIadsTools, MyDC, iLoc, workDC
Dim verInfo, strCmd, strResults

On Error Resume Next

verInfo = Split(OSVer, ".")
If verInfo(0) > 5 Then
'   strCmd = "nltest /dsgetdc:" & strForestRootDomain & " /gc"
   strCmd = "nltest /dsgetdc: /gc"
   RunAndCapture strCmd, strResults
   iLoc = InStr(strResults, "\\")
   If iLoc > 0 Then
      strCmd = Mid(strResults, iLoc+2)
      iLoc = InStr(strCmd, " ")
      If iLoc > 0 Then
         MyDC = Mid(strCmd, 1, iLoc-3)
      Else
         MyDC = strCmd
      End If
      GetGC = MyDC
   Else
      GetGC = ""
   End If
Else

'  Find the nearest Global Catalog server in the domain
   
   Set objIadsTools = CreateObject("IADsTools.DCFunctions")

   objIadsTools.EnableDebugLogging(3)

'  Get the nearest DC first

   objIadsTools.DsGetDCName CStr(UserDNSDomain)
   workDC = objIadsTools.DCName

   objIadsTools.SetDsGetDcNameFlags = "DS_GC_SERVER_REQUIRED"
   objIadsTools.DsGetDcName "", Cstr(workDC), 1

   MyDC = objIadsTools.DCName
   iLoc = InStr(MyDC, ".")
   If iLoc > 1 Then
      GetGC = Mid(MyDC, 1, iLoc-1)
   Else
      GetGC = MyDC
   End If
End If
End Function



Function GetOSVer()

Dim strVer, objWMI, colItems, objItem

Set objWMI = GetObject("winmgmts:" _
    & "{impersonationLevel=impersonate}!\\.\root\cimv2")
Set colItems = objWMI.ExecQuery _
    ("Select * from Win32_OperatingSystem")

For Each objItem in colItems     
'    Wscript.Echo objItem.Caption    
   strVer = objItem.Version    
'    WScript.Echo "ServicePack " & objItem.ServicePackMajorVersion
Next
GetOSVer = strVer

End Function


'  Function to convert the AD domain name into a DNS domain name
'   eg.  DC=zeadev,dc=zxom,dc=com ---> zeadev.zxom.com

Function CVTADToDNS(InName)

Dim TempName, WorkName
Dim Loc, Prev

TempName = Mid(InName, 4)
WorkName = ""
Loc = 1
Prev = 0

Do While Loc > 0
   Loc = Instr(Loc, LCase(TempName), ",dc=")
   If Loc > 0 Then
      WorkName = Mid(TempName, 1, Loc - 1)
      If Len(TempName) > (Loc + 4) Then
         WorkName = WorkName & "." & Mid(TempName, Loc + 4)
      End If
      TempName = WorkName
   End If
Loop

CVTADToDNS = TempName

End Function



'  Processes requests into the INI file
Function GetINIString(Section, KeyName, Default)
  Dim PosSection, PosEndSection, sContents, Value, Found
  
'  WriteLogFileMsg "   ...Getting " & KeyName & " from section " & Section 
  'Find section
  PosSection = InStr(1, INIContents, "[" & Section & "]", vbTextCompare)
  
  If PosSection>0 Then
    'Section exists. Find end of section
    PosEndSection = InStr(PosSection, INIContents, vbCrLf & "[")
    '?Is this last section?
    If PosEndSection = 0 Then PosEndSection = Len(INIContents)+1
    
    'Separate section contents
    sContents = Mid(INIContents, PosSection, PosEndSection - PosSection)

    If InStr(1, sContents, vbCrLf & KeyName & "=", vbTextCompare)>0 Then
      Found = True
      'Separate value of a key.
      Value = SeparateField(sContents, vbCrLf & KeyName & "=", vbCrLf)
    End If
  End If
  If isempty(Found) Then Value = Default
'  WScript.Echo "   ...INI value for " & KeyName & " in section [" & Section & "] is " & Value
  GetINIString = Trim(Value)
End Function

'Separates one field between sStart And sEnd
Function SeparateField(ByVal sFrom, ByVal sStart, ByVal sEnd)
Dim PosB, PosE
  PosB = InStr(1, sFrom, sStart, 1)
  If PosB > 0 Then
    PosB = PosB + Len(sStart)
    PosE = InStr(PosB, sFrom, sEnd, 1)
    If PosE = 0 Then PosE = InStr(PosB, sFrom, vbCrLf, 1)
    If PosE = 0 Then PosE = Len(sFrom) + 1
    SeparateField = Mid(sFrom, PosB, PosE - PosB)
  End If
End Function

'Read the entire file into memory

Function GetFile(ByVal FileName)

Dim FS

' WriteLogFileMsg "   ...Read in INIFile " & FileName

Set FS = CreateObject("Scripting.FileSystemObject")
On Error Resume Next

GetFile = FS.OpenTextFile(FileName).ReadAll
If Err.Number <> 0 Then
   WScript.Echo "Error reading INI file " & FileName & " --> " & _
      Err.Number & " (" & Err.Description & ")"
   WScript.Quit
End If

End Function


Function ReportFileStatus(filespec)
   Dim retCode
   If (FSO.FileExists(filespec)) Then
      retCode = True
   Else
      retCode = False
   End If
   ReportFileStatus = retCode
End Function

Function ReportFolderStatus(folder)
   Dim retCode
   If (FSO.FolderExists(folder)) Then
      retCode = True
   Else
      retCode = False
   End If
   ReportFolderStatus = retCode
End Function


Sub RunAndCapture(strCmd, strBuffer)

strBuffer = ""

Set objExec = ws.Exec(strCmd)
Do While Not objExec.StdOut.AtEndOfStream
   strBuffer = strBuffer & objExec.StdOut.READ(1)
Loop

End Sub



Sub RunAndLog(strCmd)

Dim strBuffer
strBuffer = ""

Set objExec = ws.Exec(strCmd)
Do While Not objExec.StdOut.AtEndOfStream
   strBuffer = strBuffer & objExec.StdOut.READ(1)
Loop
WriteLogFileMsg strBuffer

End Sub



Sub WriteLogFileMsg(Msg)

If LogFileName <> "" Then
   f.WriteLine Now() & ": " & Msg
End If

End Sub

Sub DisplayUsage


    Wscript.Echo ""
    Wscript.Echo WScript.ScriptName & " - Version " & strVersion
    Wscript.Echo ""
    Wscript.Echo "This utility manages the automated disabling/deleting of"
    WScript.Echo "inactive computer accounts in Active Directory."
    Wscript.Echo ""
    Wscript.Echo "See DIR-O-XXXX for design and operation details."
    Wscript.Echo ""
    Wscript.Echo "SYNTAX:"
    Wscript.Echo "  Cscript " & WScript.ScriptName & " </L:[LogFileFullPathName]>"
    WScript.Echo "        </I:[IniFileFullPathName]> </D:[Domain]> </?>"
    Wscript.Echo ""
    Wscript.Echo "PARAMETERS:"
    Wscript.Echo "   DomainName          - The Name of the domain where the INI file requests"
    WScript.Echo "                         will be done. Entered in NetBIOS format. Default is"
    WScript.Echo "                         the current logged on domain."
    Wscript.Echo "   LogFileFullPathName - The full path and filename to save status information"
    Wscript.Echo "                         to. Default is C:\Windows\Temp\CompPurge.log"
    Wscript.Echo "   IniFileFullPathName - The full path and filename of the INI file containing"
    Wscript.Echo "                         the requests. Default is CompPurge.Ini"
    Wscript.Echo "   /?                  - Displays this screen."
    Wscript.Echo ""
    Wscript.Echo ""

WScript.Quit 0

End Sub
