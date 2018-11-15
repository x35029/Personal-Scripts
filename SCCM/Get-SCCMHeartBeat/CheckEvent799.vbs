'======================================================================================================================
' LANG.....: VBScript
' NAME.....: CheckEvent799.vbs
' AUTHOR...: Kleber Carraro
' DATE.....: 12/23/2010
' KEYWORDS.: Eventvwr, Event Viewer, SCCM, SMS, WASUP, Heartbeat
' REF......: http://msdn.microsoft.com/en-us/library/aa394226(v=vs.85).aspx
'			 http://www.activexperts.com/activmonitor/windowsmanagement/adminscripts/logs/eventlogs/
'======================================================================================================================

'Script Identification
Public Const strScriptName = "CheckEvent799"

'Debug Handler - Ref: http://technet.microsoft.com/en-us/library/ee156618.aspx
Public DEBUGMODE
If WScript.Arguments.Count = 1 Then
	If WScript.Arguments.Item(0) = "" OR UCASE(WScript.Arguments.Item(0)) <> "DEBUG" Then
		DEBUGMODE = False
	ElseIf UCase(WScript.Arguments.Item(0)) = "DEBUG" Then
		WScript.Arguments.Item(0) 
		DEBUGMODE = True
	End If
Else
	DEBUGMODE = False
End If
WScript.StdOut.WriteLine("Debug Mode: " & DEBUGMODE)
If DEBUGMODE = False Then
	On Error Resume Next
End If

'Constant, Variable Declaration
Const ARRAYSIZE = 6
Const FOR_APPENDING = 8
Const FOR_READING = 1
Public strScriptPath, strLogPath, strOutputFile, strOutPutList, strNextInputFile
Public intLine
Public objFSO, objShell, objInputFile, objOutPutFile, objExcel, objWMIService, objSWbemLocator
Public ArrInputItems, ArrResultHeadings, ArrResultContents, intArrJust

Class ClEventViewer
	Public Found
	Public Message
	Public LastEventDate
	Public LastEventOffset
	Public TimeWritten
End Class

'Resizing Data Arrays
ReDim ArrResultContents(ARRAYSIZE)
Redim ArrResultHeadings(ARRAYSIZE)

'Abort Popup
WScript.StdOut.WriteLine("Processing Script: " & strScriptName)
WScript.StdOut.WriteLine("--------------------------------------------------")
WScript.StdOut.WriteLine("-> Press [CTRL] + Break to abort script execution.")
WScript.StdOut.WriteLine("--------------------------------------------------")
WScript.StdOut.WriteBlankLines(1)

'Check OS Host Version
WScript.StdOut.WriteLine("Checking Host Operating System.")
strHostOSVersion = FnCheckHostOSVersion()
WScript.StdOut.WriteLine("Host Operating System: " & strHostOSVersion)
If InStr(strHostOSVersion, "Windows 2000") > 0 Or InStr(strHostOSVersion, "Windows NT") > 0 Then
	strMessage = "Error: This script should be not executed from a " & strHostOSVersion & " computer."
	WScript.StdOut.WriteLine(strMessage)
	MsgBox strMessage,16,"Host OS Not Supported"
	WScript.StdOut.WriteLine("Script execution has been aborted.")
	Wscript.Quit
End If
WScript.StdOut.WriteBlankLines(1)

'Create Foundation Objects
Set objShell = WScript.CreateObject("WScript.Shell")
strScriptPath = objShell.CurrentDirectory
Set objFSO = CreateObject("Scripting.FileSystemObject")

'Create Input List File
WScript.StdOut.WriteLine("Create Input File.")
Call FnOpenInputFile()
WScript.StdOut.WriteBlankLines(1)

'Create Log File
WScript.StdOut.WriteLine("Creating Output File.")
Call FnCreateLog()
WScript.StdOut.WriteBlankLines(1)

'Remove Duplicated Entries
Set objDictUnique = CreateObject("Scripting.Dictionary")
WScript.StdOut.WriteLine("Removing Duplicated Entries.")
intDupli = 0
For intIndex = 0 To UBound(ArrInputItems)
	If ArrInputItems(intIndex) <> "" Then
		If Not objDictUnique.Exists(ArrInputItems(intIndex)) Then
			objDictUnique.Add ArrInputItems(intIndex),""
		Else
			intDupli = intDupli + 1
		End If
	End If
	WScript.StdOut.Write(".")
Next
WScript.StdOut.WriteBlankLines(1)

'Populate Arrays With Dictionary Elements
ArrUniqueItems = objDictUnique.Keys
Set objDictUnique = Nothing

'Popup Parse Results
WScript.StdOut.WriteLine("Unique Items        : " & UBound(ArrUniqueItems) + 1)
WScript.StdOut.WriteLine("Duplicated Items    : " & intDupli)
WScript.StdOut.WriteBlankLines(1)

'Main Code Execution
dtStartTime = Date & " " & Time
Set objDictDupli = CreateObject("Scripting.Dictionary")

'Process Item List
WScript.StdOut.WriteLine("Processing Script. Please wait.")
For Each strItem In ArrUniqueItems
	If strItem <> "" Then
		strComputer = UCase(strItem)
		ArrResultContents(0) = strComputer
		'-----------------------
		'Check Server Connection
		'-----------------------
		Err.Clear
		strError = 0
		strServerConn = FnCheckServerConnection(strComputer, 1)
		If strServerConn = False Then
			strError = "Error: " & "Server Unreachable"
			ArrResultContents(1) = strError
			Call FnAppendLog(ArrResultContents)
			Call FnShowResults(ArrResultHeadings, ArrResultContents)
			Call SubArrayCleanup
		Else
			'------------------------------
			'Create WMI (root\cimv2) Object
			'------------------------------
			Err.Clear
			strError = 0
			strWMIService = FnCreateWMIService(strComputer)
			If Err.Number <> 0 Then
				strError = "Error: " & "WMI Service root\cimv2" & " " & Err.Number & " " & Err.Description
				ArrResultContents(1) = strError
				Call FnAppendLog(ArrResultContents)
				Call FnShowResults(ArrResultHeadings, ArrResultContents)
	       		Call SubArrayCleanup
        		Err.Clear
			ElseIf strWMIService = False Then
				strError = "Error: " & "WMI Service Unavailable: root\cimv2"
				ArrResultContents(1) = strError
				Call FnAppendLog(ArrResultContents)
				Call FnShowResults(ArrResultHeadings, ArrResultContents)
				Call SubArrayCleanup
			Else
				'----------------------------------
				'Check Event Viewer - Id 799
				'----------------------------------
				Err.Clear
				Set ColEventViewerInfo = FnCheckEventViewer(strComputer)
				If Err.number <> 0 Then
					strError = "Error: " & "Event Viewer" & " " & Err.Number & " " & Err.Description
					ArrResultContents(1) = strError
					Call FnAppendLog(ArrResultContents)
					Call FnShowResults(ArrResultHeadings, ArrResultContents)
					Call SubArrayCleanup
				Else
					If DEBUGMODE = True Then
						MsgBox(ColEventViewerInfo.Found & vbCrlf & _
						        ColEventViewerInfo.Message & vbCrlf & _
							ColEventViewerInfo.LastEventDate & vbCrlf & _
							ColEventViewerInfo.LastEventOffset & vbCrlf & _
							ColEventViewerInfo.TimeWritten)
					End If
					'------------------------------
					'Populating ArrResultContents()
					'------------------------------
					ArrResultContents(1) = strError
					ArrResultContents(2) = ColEventViewerInfo.Found
					ArrResultContents(3) = ColEventViewerInfo.Message					
					ArrResultContents(4) = ColEventViewerInfo.LastEventDate
					ArrResultContents(5) = ColEventViewerInfo.LastEventOffset
					ArrResultContents(6) = ColEventViewerInfo.TimeWritten
					'Checking Excel Limits 
					IntLine = IntLine + 1
					If IntLine > 65500 Then
						strMsgText = "Output file exceeded maximum number of Excel supported lines: " & intLine & vbCrLf &_
						"A new output file has been created to support new records."
						WScript.StdOut.Write(strMsgText & vbCrLf)
						Wscript.Sleep(100)
						IntLine = 0
						'Create a NEW Log File
						Set OutPutFile = Nothing
						Call FnCreateLog()
					End If
					Call FnAppendLog(ArrResultContents)
					Call FnShowResults(ArrResultHeadings, ArrResultContents)
					Call SubArrayCleanup
				End If
			End If
		End	If
	End If
	Set ColEventViewerInfo = Nothing
	WScript.StdOut.WriteBlankLines(1)
Next

'Display Execution Summary
WScript.StdOut.WriteLine("Script Execution Done.")
'Display Elapsed Time
If DateDiff("n",dtStartTime,Now()) > 1 Then
	WScript.StdOut.WriteLine("Elapsed Time: " & DateDiff("n",dtStartTime,Now()) & " minutes.")
Else
	WScript.StdOut.WriteLine("Elapsed Time: " & DateDiff("s",dtStartTime,Now()) & " seconds.")
End If

'Cleaunp Unused Objects
objOutPutFile.Close
Set objShell = Nothing
Set objFSO = Nothing
Set objInputFile = Nothing
Set objOutPutFile = Nothing

'View Output File in Excel
On Error Resume Next
Err.Clear
Set objExcel = CreateObject("Excel.Application")
If Err.Number = 0 Then
	strMessage = "Ouput File: " & strOutputFile & vbCrLf & vbCrLf & _
				 "Do you want to view the results in Excel?"
	intReturn = MsgBox(strMessage,36,"View Results in Excel")
	If intReturn = 6 Then
		'Checking Output files
		ArrOutPutList = Split(strOutPutList,",")
		For Each strOutPutItem In ArrOutPutList
			If strOutPutItem <> "" Then
				WScript.StdOut.WriteLine("Output File Created.: " & strOutPutItem)
				WScript.StdOut.WriteLine("Launching Excel.")
				Call FnViewInExcel(strOutPutItem)
			End If
		Next
	Else
		'Checking Output files
		ArrOutPutList = Split(strOutPutList,",")
		For Each strOutPutItem In ArrOutPutList
			If strOutPutItem <> "" Then
				WScript.StdOut.Write("Output File Created.: " & strOutPutItem)
			End If
		Next
	End If
End If

'Finishing Script Execution
Wscript.Quit

'==========================================================
'Function FnCheckHostOSVersion()
'==========================================================
Function FnCheckHostOSVersion()
	If DEBUGMODE = True Then
		WScript.StdOut.WriteLine("Checkpoint: " & "FnCheckHostOSVersion")
	End If
	strHostComputer = "."
	Set objWMIService = GetObject("winmgmts:\\" & strHostComputer & "\root\cimv2")
	Set colItems = objWMIService.ExecQuery("SELECT Caption FROM Win32_OperatingSystem")
	For Each objItem in colItems
		FnCheckHostOSVersion = objItem.Caption
	Next
	Set objItem = Nothing
	Set colItems = Nothing
	Set objWMIService = Nothing
End Function

'==========================================================
'Function FnCheckServerConnection()
'==========================================================
Function FnCheckServerConnection(parComputer, parCount)
	If DEBUGMODE = True Then
		WScript.StdOut.WriteLine("Checkpoint: " & "FnCheckServerConnection" & " " & parComputer)
	End If
	strComputer = parComputer
	strCount = parCount
	Set objShell = CreateObject("WScript.Shell")
	Set objScriptExec = objShell.Exec("ping -n " & strCount & " " & strComputer & " -4")
	strPingResults = UCase(objScriptExec.StdOut.ReadAll)
	If InStr(strPingResults, "TTL=") Then
    	FnCheckServerConnection = True
	Else
        FnCheckServerConnection = False
	End If
	Set objShell = Nothing
	Set objScriptExec = Nothing
End Function

'==========================================================
'Function FnCreateWMIService()
'==========================================================
Function FnCreateWMIService(parComputer)
	'On Error Resume Next
	If DEBUGMODE = True Then
		WScript.StdOut.WriteLine("Checkpoint: " & "FnCreateWMIService" & " " & parComputer)
	End If
	Err.Clear
	Set objSWbemLocator = CreateObject("WbemScripting.SWbemLocator") 
	Set objWMIService = objSWbemLocator.ConnectServer(parComputer,"root\cimv2","","","MS_409","",&H80)
	If Err.Number <> 0 Then
		FnCreateWMIService = False
	Else
		FnCreateWMIService = True
	End If
	'On Error Goto 0
End Function

'==========================================================
'Function FnCheckEventViewer()
'==========================================================
Function FnCheckEventViewer(parComputer)
	If DEBUGMODE = True Then
		WScript.StdOut.WriteLine("Checkpoint: " & "FnCheckEventViewer" & " " & parComputer)
	End If
	'Create SWBem Date Time Objects
	'Ref: http://msdn.microsoft.com/en-us/library/aa393687(v=vs.85).aspx
	Set dtmStartDate = CreateObject("WbemScripting.SWbemDateTime")
	'Set Initial Date Interval: Current Date - 6 Days.
	DateToCheck = Date - 6
	dtmStartDate.SetVarDate DateToCheck, False
	'Create the Function as a Class
	Set FnCheckEventViewer = New ClEventViewer
	'Select Last Event 799 with TimeWritten > 6 days in the past.
	'Ref: http://msdn.microsoft.com/en-us/library/aa394226(v=vs.85).aspx
	Set colLoggedEvents = objWMIService.ExecQuery _
        ( _
            "SELECT * FROM Win32_NTLogEvent " & _
            "WHERE TimeWritten > '" & dtmStartDate & "'" & _            
            "       AND Logfile = 'Application' " & _ 
            "		AND SourceName = 'SCCM' " & _ 
            "		AND EventCode = '799'" _ 
        )
	If colLoggedEvents.Count = 0 Then
		WScript.Stdout.WriteLine("Event Not Found")
		FnCheckEventViewer.Found = False
	Else
		For Each objEvent In colLoggedEvents
			With objEvent
				If DEBUGMODE = True Then
					WScript.Stdout.WriteLine(.GetObjectText_)
				End If
                FnCheckEventViewer.Found = True
                If IsArray(.InsertionStrings) Then 
                    FnCheckEventViewer.Message = .InsertionStrings(0)
                End If                    
                FnCheckEventViewer.LastEventDate = FnWMIDateToDate(.TimeWritten)
                FnCheckEventViewer.LastEventOffset = DateDiff("d", FnCheckEventViewer.LastEventDate, Now)
                FnCheckEventViewer.TimeWritten = .TimeWritten
			End With
		Next 
	End If
	Set dtmStartDate = Nothing
	Set objEvent = Nothing
	Set colLoggedEvents = Nothing
End Function

'==========================================================
'Function FnWMIDateToDate()
'==========================================================
Function FnWMIDateToDate(parDate)
	If DEBUGMODE = True Then
		WScript.StdOut.WriteLine("Checkpoint: " & "FnWMIDateToDate" & " " & parDate)
	End If
	strDate = parDate
	FnWMIDateToDate = CDate(Mid(strDate, 5, 2) & "/" _
	  & Mid(strDate, 7, 2) & "/" & Left(strDate, 4) & " " _
	  & Mid (strDate, 9, 2) & ":" & Mid(strDate, 11, 2) & ":" & Mid(strDate,13, 2))
	If DEBUGMODE = True Then
		MsgBox(FnWMIDateToDate)
	End If
End Function 


'======================================================================================================================
'FnOpenInputFile() - Check Input List File <SCRIPTNAME>.lst. If exists save a copy if not create a new one.
'======================================================================================================================
Function FnOpenInputFile()
	If DEBUGMODE = True Then
		WScript.StdOut.WriteLine("Checkpoint: " & "FnOpenInputFile")
	End If
	strCheckRoot = Right(strScriptPath,1)
	If strCheckRoot = "\" Then
		strInputPath = strScriptPath
	Else
		strInputPath = strScriptPath & "\"
	End If
	strInputPath = strInputPath & "Input\"
	strInputFile = strInputPath & strScriptName & ".lst"
	If Not objFSO.FolderExists(strInputPath) Then
		objFSO.CreateFolder(strInputPath)
		WScript.StdOut.WriteLine("Input Folder Created: " & strInputPath)
	End If
	If Not objFSO.FileExists(strInputFile) Then
		WScript.StdOut.WriteLine("Input File does not exist, creating file: " & strInputFile)
		objFSO.CreateTextFile(strInputFile)
	End If
	Set objInputFile = objFSO.OpenTextFile(strInputFile, FOR_READING)
	If Not objInputFile.AtEndOfStream Then
		strNewInputFile = strInputPath & strScriptName & "_" & FnConvertDateTimeToString() & ".lst"
		objFSO.CopyFile strInputFile,strNewInputFile,1
		WScript.StdOut.WriteLine("Input File Saved As: " & strNewInputFile)
	End If
	strOpenInputFileAction = FnOpenInputFilePopup(strInputFile)
	If strOpenInputFileAction = 6 Then
		WScript.StdOut.WriteLine("Lauching Notepad.")
		Set objExec = objShell.Exec("Notepad.exe " & strInputFile)
		Do While objExec.Status = 0 
			WScript.Sleep 100
		Loop 
		WScript.StdOut.WriteLine("Notepad has been closed.")
		strMessage = "Input File: " & strInputFile & " has been loaded." & vbCrLf & vbCrLf & _
					 "Do you want to proceed?"
		intReturn = MsgBox(strMessage,36,"Input File Load Confirmation")
		If intReturn <> 6 Then
			WScript.StdOut.WriteLine("Input File Rejected. Script execution has been aborted.")
			Wscript.Quit
		Else
			WScript.StdOut.WriteLine("Input File Accepted.")
		End If
	Else
		WScript.StdOut.WriteLine("Script execution has been aborted.")
		Wscript.Quit
	End If
	Set objInputFile = objFSO.OpenTextFile(strInputFile, FOR_READING)
	If objInputFile.AtEndOfStream Then
		WScript.StdOut.WriteLine("Empty Input List File: " & strInputFile)
		WScript.StdOut.WriteLine("Calling Input File Selection.")
		Call FnOpenInputFile()
	Else
		strInputItems = objInputFile.ReadAll
		ArrInputItems = Split(strInputItems, vbNewLine)
		objInputFile.Close
	End If
	Set objInputFile = Nothing
End Function

'======================================================================================================================
'Function FnOpenInputFilePopup() - Popup message to inform Input File is required.
'======================================================================================================================
Function FnOpenInputFilePopup(parInputFile)
	If DEBUGMODE = True Then
		WScript.StdOut.WriteLine("Checkpoint: " & "FnOpenInputFilePopup" & " " & parInputFile)
	End If
	strMessage = "This script is able to run against a list of items." & vbCrLf & vbCrLf & _
				 "In order to continue these items must be provided. " & _
				 "These input items will be stored in:" & vbCrLf & _
				 parInputFile  & vbCrLf & vbCrLf & _
				 "Do you want to proceed?"  & vbCrLf & vbCrLf & _
				 "    Click [Yes] to proceed." & vbCrLf & _
				 "          1.A Notepad will be launched to enable input file edition." & vbCrLf & _
				 "          2.Edit the file by including / excluding the desired input items." & vbCrLf & _
				 "          3.The items should be placed in a list format:" & vbCrLf & _
				 "                Item1" & vbCrLf & _
				 "                Item2" & vbCrLf & _
				 "                ItemN" & vbCrLf & _
				 "          4.Save the file (Don't change name / path)." & vbCrLf & _
				 "          5.Close Notepad." & vbCrLf & _
				 "          The script will collect input file items and will process them."  & vbCrLf & vbCrLf & _
				 "    Click [No] to abort."
	intReturn = MsgBox(strMessage,36,"Input File Information")
	FnOpenInputFilePopup = intReturn
End Function

'======================================================================================================================
'Function FnCreateLog() - Create Output Log File
'======================================================================================================================
Function FnCreateLog() 
	If DEBUGMODE = True Then
		WScript.StdOut.WriteLine("Checkpoint: " & "FnCreateLog")
	End If
	strLogDtTm = FnConvertDateTimeToString()
	strLogFolder = "\Output\"
	strLogPath = strScriptPath & strLogFolder
	strLogName = strScriptName & "_" & strLogDtTm & ".csv"
	strOutputFile = strLogPath & strLogName
	If Not objFSO.FolderExists(strLogPath) Then
		objFSO.CreateFolder(strLogPath)
	End If 
	objFSO.CreateTextFile strLogPath & strLogName
	Set objOutPutFile = objFSO.OpenTextFile(strLogPath & strLogName, FOR_APPENDING)
	ArrResultHeadings(0)  = "Server Name"
	ArrResultHeadings(1)  = "EH"
	ArrResultHeadings(2)  = "799 Found"
	ArrResultHeadings(3)  = "799 Message"
	ArrResultHeadings(4)  = "799 Last Date"
	ArrResultHeadings(5)  = "799 Offset"
	ArrResultHeadings(6)  = "799 TimeWritten"
	Call FnAppendLog(ArrResultHeadings)
	WScript.StdOut.Write("Log File Created: " & strOutputFile & vbCrlf)
	strOutPutList = strOutputFile & "," & strOutPutList
End Function

'======================================================================================================================
'Function FnAppendLog() - Append Output Log File
'======================================================================================================================
Function FnAppendLog(ArrAppendLog)
	If DEBUGMODE = True Then
		WScript.StdOut.WriteLine("Checkpoint: " & "FnAppendLog")
	End If
	intCount = 0
	Do While IntCount <= UBound(ArrAppendLog)
		If intCount = UBound(ArrAppendLog) Then
			strArrAppendLog = strArrAppendLog & ArrAppendLog(intCount)
		Else
			strArrAppendLog = strArrAppendLog & ArrAppendLog(intCount) & ","
		End If
		IntCount = IntCount + 1
	Loop
	objOutPutFile.WriteLine strArrAppendLog
End Function

'======================================================================================================================
'Function FnShowResults() - Show the results on the screen
'======================================================================================================================
Function FnShowResults(parArrResultHeadings, parArrResultContents )
	If DEBUGMODE = True Then
		WScript.StdOut.WriteLine("Checkpoint: " & "FnShowResults")
	End If
	intArrLine = 0
	intArrJust = 25
	Do While intArrLine <= UBound(parArrResultHeadings)
		strResultJustify = String(intArrJust - Len(parArrResultHeadings(intArrLine)), ".")
		WScript.StdOut.WriteLine(parArrResultHeadings(intArrLine) & _
					 strResultJustify & ": " & _
					 parArrResultContents(intArrLine))
		intArrLine = intArrLine + 1
	Loop
End Function

'======================================================================================================================
' Sub SubArrayCleanup()
'======================================================================================================================
Sub SubArrayCleanup()
	If DEBUGMODE = True Then
		WScript.StdOut.WriteLine("Checkpoint: " & "SubArrayCleanup")
	End If
	IntResult = 0
	Do While IntResult <= UBound(ArrResultContents)
		ArrResultContents(IntResult) = Empty
		IntResult = IntResult + 1
	Loop
End Sub

'======================================================================================================================
'Function FnViewInExcel() - View Output Log file in Excel
'======================================================================================================================
Function FnViewInExcel(parOutputItem)
	If DEBUGMODE = True Then
		WScript.StdOut.WriteLine("Checkpoint: " & "FnViewInExcel" & " " & parOutputItem)
	End If
	objExcel.DisplayAlerts = False
	objExcel.Visible = False
	Set objWorkbook = objExcel.Workbooks.Open(parOutputItem)
	Set objSheet = objExcel.ActiveWorkbook.Worksheets(1)
	With objSheet
		.Name = strScriptName
		.Usedrange.Font.Name = "MS Sans Serif"
		.Usedrange.Font.Size = 8.5
	End With
	Set objRange = objExcel.Range("A1")
	With objRange
		.Activate
		.AutoFilter
	End With
	Set objRange = objExcel.Range("A1", "Z1")
	With objRange
		.Activate
		.Font.Bold = True
		.Columns.AutoFit
		.Rows.AutoFit
		.Range("B2").Select
		objExcel.ActiveWindow.FreezePanes = "True"
	End With
	objExcel.Visible = True
	'Save File as Excel (.xls)
	strExcelFile = Replace(parOutputItem,".csv",".xls")
	strExcelVersion = objExcel.Version
	If strExcelVersion = "11.0" Then
		objExcel.ActiveWorkbook.SaveAs strExcelFile, 43 'Office 2003
	Else
		objExcel.ActiveWorkbook.SaveAs strExcelFile, 56 'Office 2007
	End If
	objExcel.ActiveWorkbook.Saved = True
	objExcel.UserControl = True
	WScript.StdOut.WriteLine("Output File Saved As: " & strExcelFile)
	Set objRange = Nothing
	Set objWorkbook = Nothing
	Set objExcel = Nothing
End Function

'======================================================================================================================
' Function FnConvertDateTimeToString() - Convert Date and Time in a file name compatible format.
'======================================================================================================================
Function FnConvertDateTimeToString()
	If DEBUGMODE = True Then
		WScript.StdOut.WriteLine("Checkpoint: " & "FnConvertDateTimeToString")
	End If
	strDateTime = Date & "_" & Time
	strDateTime = Replace(strDateTime, "/", "-")
	strDateTime = Replace(strDateTime, ":", "-")    
	strDateTime = Replace(strDateTime, "PM", "")
	strDateTime = Replace(strDateTime, "AM", "")
	strDateTime = Trim(strDateTime)
	FnConvertDateTimeToString = strDateTime
End Function