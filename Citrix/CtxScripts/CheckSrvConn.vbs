'======================================================================================================================
' LANG    : VBScript
' NAME    : CheckSrvConn.vbs
' AUTHOR  : Kleber Carraro
' DATE    : 11:34 AM 07/26/2010
' KEYWORDS: WMI, TCP-IP, Server Connection
'======================================================================================================================

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

'Script Identification
Public strScriptName, dtStartTime
strScriptName = "CheckSrvConn"
dtStartTime = Date & " " & Time

'Constant, Variable Declaration
Const ARRAYSIZE = 2
Const FOR_APPENDING = 8
Const FOR_READING = 1
Public strScriptPath, strLogPath, strOutputFile, strOutPutList, strNextInputFile
Public objFSO, objShell, objInputFile, objOutPutFile, objExcel
Public ArrInputItems, ArrResultHeadings, ArrResultContents, intArrJust

'Class Declaration
Class ClServerConn
	Public Status
	Public IP
End Class

'Resize Data Arrays
ReDim ArrResultContents(ARRAYSIZE)
Redim ArrResultHeadings(ARRAYSIZE)

'Main Code Execution
WScript.StdOut.WriteLine("Processing Script: " & strScriptName)
WScript.StdOut.WriteLine("--------------------------------------------------")
WScript.StdOut.WriteLine("-> Press [CTRL] + Break to abort script execution.")
WScript.StdOut.WriteLine("--------------------------------------------------")

'Check OS Host Version
WScript.StdOut.WriteLine("Checking Host Operating System.")
strHostOSVersion = FnCheckHostOSVersion()
If InStr(strHostOSVersion, "Windows 2000") > 0 Or InStr(strHostOSVersion, "Windows NT") > 0 Then
	strMessage = "Error: This script should be not executed from a " & strHostOSVersion & " computer."
	WScript.StdOut.WriteLine(strMessage)
	MsgBox strMessage,16,"Host OS Not Supported"
	WScript.StdOut.WriteLine("Script execution has been aborted.")
	Wscript.Quit
End If

'Create Foundation Objects
Set objShell = WScript.CreateObject("WScript.Shell")
strScriptPath = objShell.CurrentDirectory
Set objFSO = CreateObject("Scripting.FileSystemObject")

'Check Input List File
WScript.StdOut.WriteLine("Checking Input File.")
Call FnOpenInputFile()

'Create Log File
WScript.StdOut.WriteLine("Creating Output File.")
Call FnCreateLog()

'Process Item List
WScript.StdOut.WriteLine("Processing Script. Please wait.")
WScript.StdOut.WriteBlankLines(1)
For Each strInputItem In ArrInputItems
	If strInputItem <> "" Then
		strComputer = UCase(strInputItem)
		Call SubArrayCleanup
		'-----------------------
		'Check Server Connection
		'-----------------------		
		Err.Clear
		strError = 0
		strInstance = "Server Connection"
		Set ColServerConnection = FnCheckServerConnection(strComputer, 1)
		If DEBUGMODE = True Then
			MsgBox(strInstance & vbCrlf & _
				ColServerConnection.Status & vbCrlf & _
				ColServerConnection.IP)
		End If
		'Populating ArrResultContents()
		ArrResultContents(0) = strComputer
		ArrResultContents(1) = ColServerConnection.Status
		ArrResultContents(2) = ColServerConnection.IP
		Call FnAppendLog(ArrResultContents)
		Call FnShowResults(ArrResultHeadings, ArrResultContents)
		Call SubArrayCleanup
	End If
	Set ColServerConnection = Nothing
	WScript.StdOut.WriteBlankLines(1)
Next

'Display Execution Summary
WScript.StdOut.WriteBlankLines(1)
WScript.StdOut.WriteLine("Script Execution Summary")
WScript.StdOut.WriteLine("Start Time.......: " & dtStartTime)
WScript.StdOut.WriteLine("End Time.........: " & Date & " " & Time)
WScript.StdOut.WriteLine("Log File Created.: " & strOutputFile & vbCrlf)

'Cleaunp Unused Objects
objOutPutFile.Close
Set objShell = Nothing
Set objFSO = Nothing
Set objInputFile = Nothing
Set objOutPutFile = Nothing

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
	If DEBUGMODE = True Then WScript.StdOut.WriteLine("Checkpoint: " & "FnCheckServerConnection" & " " & parComputer)
	Set FnCheckServerConnection = New ClServerConn
	strComputer = parComputer
	strCount = parCount
	Set objScriptExec = objShell.Exec("ping -n " & strCount & " " & strComputer & " -4")
	If DEBUGMODE = True Then WScript.StdOut.WriteLine("strComputer: " & strComputer)
	strPingResults = UCase(objScriptExec.StdOut.ReadAll)
	If InStr(1,UCase(strPingResults),"COULD NOT FIND HOST") > 0 Then
		FnCheckServerConnection.Status = "Host Not Found"
		FnCheckServerConnection.IP = ""
	ElseIf InStr(1,UCASE(strPingResults), "TTL=") > 0 Then
		FnCheckServerConnection.Status = "Connected"
		FnCheckServerConnection.IP = FnGetIPAddress(strPingResults) 
	Else
		FnCheckServerConnection.Status = "Not Connected"
		FnCheckServerConnection.IP = FnGetIPAddress(strPingResults) 
	End If
	Set objScriptExec = Nothing
End Function

'==========================================================
'Function FnGetIPAddress()
'==========================================================
Function FnGetIPAddress(parPingResults)
	arrIPAddress = Split(parPingResults,"[",-1,1)
	intIPAddress = UBound(arrIPAddress)
	strIPAddress = arrIPAddress(intIPAddress)
	arrIPAddress = Split(strIPAddress,"]",-1,1)
	intIPAddress = LBound(arrIPAddress)
	strIPAddress = arrIPAddress(intIPAddress)
	FnGetIPAddress = strIPAddress 
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
	ArrResultHeadings(1)  = "Conncetion Status"
	ArrResultHeadings(2)  = "IP Address"
	Call FnAppendLog(ArrResultHeadings)
	WScript.StdOut.Write("Log File Created: " & strOutputFile & vbCrlf)
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
Function FnShowResults(parArrResultHeadings, parArrResultContents)
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