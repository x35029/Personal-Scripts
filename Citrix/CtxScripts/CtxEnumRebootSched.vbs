Set xaFarm = CreateObject("MetaFrameCOM.MetaFrameFarm")

xaFarm.Initialize 1
for each server in xaFarm.Servers
	Set srvRS = server.RebootSchedule
	srvRS.LoadData
	wscript.echo server.ServerName & " : " & srvRS.Enable & vbTab & _
				" Restart Frequency : " & srvRS.Frequency & _
				" Restart Date Time : " & srvrs.starttime.day & _
				"/" & srvrs.starttime.month & _
				"/" & srvrs.starttime.year & _
				" " & srvrs.starttime.hour & _
				":" & srvrs.starttime.minute & _
				":" & srvrs.starttime.second
'	MsgBox(server.ServerName)
next

Set srvRS = Nothing
set xaFarm = nothing 