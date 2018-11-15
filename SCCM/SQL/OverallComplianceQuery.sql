select 
	sys.ResourceID [Resource ID],
	sys.name0 [Computer Name],
	CONVERT(DECIMAL(10,2),(count(iif(ucs.status=3,1,null))*1.0+count(iif(ucs.status=1,1,null)))*1.0/COUNT(ucs.Status)*100.0) Compliance,
	COUNT(ucs.Status) AllKBs,
	count(iif(ucs.status=0,1,null)) Unknown,
	count(iif(ucs.status=1,1,null)) NotRequired,
	count(iif(ucs.status=2,1,null)) Required,
	count(iif(ucs.status=3,1,null)) Installed,
	sys.User_Name0 [User Name], 	
	os.caption0 [OS],
	ws.lasthwscan  [LastHWScan],
	uss.lastscantime 'LastSUScanTime',
	sys.last_logon_timestamp0 'Last Logon Time',
	case when sys.client0='1' then 'Yes' else 'No' end as 'Client (Yes/No)'

From v_Update_ComplianceStatusAll UCS
left join v_r_system sys on ucs.resourceid=sys.resourceid and sys.Is_Virtual_Machine0 = 0 and sys.Operating_System_Name_and0 like '%Workstation%'
left join v_FullCollectionMembership fcm on sys.resourceid=fcm.resourceid
left join v_collection coll on coll.collectionid=fcm.collectionid
left join v_GS_OPERATING_SYSTEM os on ucs.resourceid=os.resourceid
left join v_gs_workstation_status ws on ucs.resourceid=ws.resourceid
left join v_updatescanstatus uss on ucs.ResourceId=uss.ResourceID
left join v_CIAssignmentToCI atci on atci.CI_ID=UCS.CI_ID
left join v_CIAssignment cia on cia.AssignmentID=atci.AssignmentID
where cia.AssignmentName like 'WKS-SecurityUpdate-ADR%' and coll.collectionID in ('CS20019E')--and ucs.status=@Status
group by sys.name0,sys.User_Name0,os.Caption0,ws.LastHWScan ,uss.LastScanTime,sys.Last_Logon_Timestamp0,sys.client0,sys.ResourceID
order by 2
