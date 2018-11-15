SELECT
	rsys.[Name0], 
	gscs.Model0,
	REPLACE(Right(LEFT(gsos.Caption0,21),12),'E','') OS, 
	gsos.InstallDate0 OS_Install,
	cm.Domain Domain,
	rsys.AD_Site_Name0 ADSite, 
	cm.SiteCode,  
	chcs.LastOnline,
	iif((gsscu.TopConsoleUser0 is null) OR (gsscu.TopConsoleUser0 like 'font driver host%'),
		rsys.User_Domain0+'\'+rsys.User_Name0,
		gsscu.TopConsoleUser0) TopConsoleUser,
	iif((gsscu.TopConsoleUser0 is null) OR (gsscu.TopConsoleUser0 like 'font driver host%'),
		ruserad.Mail0,
		rusersccm.mail0) Mail,
	iif((gsscu.TopConsoleUser0 is null) OR (gsscu.TopConsoleUser0 like 'font driver host%'),
		ruserad.department0,
		rusersccm.department0) Dept, 
	cia.[AssignmentName] SUG,
	ui.ArticleID,
	ui.Title KBTitle,
	CASE [Status]
		WHEN 0 THEN '0 - Detection state unknown'
		WHEN 1 THEN '1 - Update is not required'
		WHEN 2 THEN '2 - Update is required'
		WHEN 3 THEN '3 - Update is installed'	  
	END UpdateStatus,	
	[LastErrorCode] KBErrorCode,
	CASE Right(replace(ui.[ApplicabilityCondition],'</ProductId></ApplicabilityRule>',''),36)
		WHEN '041e4f9f-3a3d-4f58-8b2f-5e6fe95c4591' THEN 'Office 2007'
		WHEN '1403f223-a63f-f572-82ba-c92391218055' THEN 'Word Viewer'
		WHEN '25aed893-7c2d-4a31-ae22-28ff8ac150ed' THEN 'Office 2016'
		WHEN '56750722-19b4-4449-a547-5b68f19eee38' THEN 'SQL Server 2012'
		WHEN '5e870422-bd8f-4fd2-96d3-9c5d9aafda22' THEN 'Lync 2010'
		WHEN '60916385-7546-4e9b-836e-79d65e517bab' THEN 'SQL Server 2005'
		WHEN '6407468e-edc7-4ecd-8c32-521f64cee65e' THEN 'Windows 8.1'
		WHEN '704a0a4a-518f-4d69-9e03-10ba44198bd5' THEN 'Office 2013'
		WHEN '84f5f325-30d7-41c4-81d1-87a0e6535b66' THEN 'Office 2010'
		WHEN '9f3dd20a-1004-470e-ba65-3dc62d982958' THEN 'SilverLight'
		WHEN 'a3c2375d-0c8a-42f9-bce0-28333e198407' THEN 'Windows 10'
		WHEN 'bb7bc3a7-857b-49d4-8879-b639cf5e8c3c' THEN 'SQL Server 2008'
		WHEN 'bfe5b177-a086-47a0-b102-097e4fa1f807' THEN 'Windows 7'
		WHEN 'c5f0b23c-e990-4b71-9808-718d353f533a' THEN 'SQL Server 2008'
		WHEN 'caab596c-64f2-4aa9-bbe3-784c6e2ccf9c' THEN 'SQL Server 2014'
		WHEN 'cd8d80fe-5b55-48f1-b37a-96535dca6ae7' THEN 'TMG'
		ELSE '_'+Right(replace(ui.[ApplicabilityCondition],'</ProductId></ApplicabilityRule>',''),36)
	END ProductID,
	CASE [LastEnforcementMessageID]
		WHEN 1 THEN '1 - Enforcement started'
		WHEN 2 THEN '2 Enforcement waiting for content'
		WHEN 3 THEN '3 - Waiting for another installation to complete'
		WHEN 4 THEN '4 - Waiting for maintenance window before installing'
		WHEN 5 THEN '5 - Restart required before installing'
		WHEN 6 THEN '6 - General failure'
		WHEN 7 THEN '7 - Pending installation'
		WHEN 8 THEN '8 - Installing update'
		WHEN 9 THEN '9 - Pending system restart'
		WHEN 10 THEN '10 - Successfully installed update'
		WHEN 11 THEN '11 - Failed to install update'
		WHEN 12 THEN '12 - Downloading update'
		WHEN 13 THEN '13 - Downloaded update'
		WHEN 14 THEN '14 - Failed to Download update'
		ELSE '_Unknown ID - '+CONVERT(varchar,[LastEnforcementMessageID])
	END EnforcementMessage,	
	[LastEnforcementStatusMsgID]
FROM 
	[v_CIAssignment] cia
		INNER JOIN
	[v_CIAssignmentToCI] ciatci
		on ciatci.AssignmentID=cia.AssignmentID
		INNER JOIN
	[v_UpdateInfo] ui
		on ciatci.CI_ID=ui.CI_ID
		INNER JOIN
	[v_Update_ComplianceStatusAll] ucsa
		on ui.CI_ID=ucsa.CI_ID
		INNER JOIN
	[v_R_System] rsys
		on ucsa.ResourceID=rsys.ResourceID
		join
	[v_ActiveClients] act
		on act.MachineResourceID=rsys.ResourceID
		left join
	[v_CH_ClientSummary] chcs
		on act.MachineResourceID=chcs.ResourceID
		left join
	[v_ClientMachines] cm
		on rsys.ResourceID=cm.ResourceID
		left join
	[v_GS_COMPUTER_SYSTEM] gscs
		on rsys.ResourceID=gscs.ResourceID
		left join
	[v_GS_OPERATING_SYSTEM] gsos
		on rsys.ResourceID=gsos.ResourceID
		left join
	[v_GS_SYSTEM_CONSOLE_USAGE] gsscu
		on rsys.ResourceID=gsscu.ResourceID
		left join
	[v_R_User] rusersccm
		on gsscu.TopConsoleUser0=rusersccm.Unique_User_Name0 
		left join
	[v_R_User] ruserad
		on rsys.User_Domain0+'\'+rsys.User_Name0=ruserad.Unique_User_Name0
WHERE
	cia.[CollectionName] = 'WKS-SUP-DG4-COL' AND 
	ucsa.Status != 1 AND
	rsys.Is_Virtual_Machine0 = 0 AND
	gscs.Model0 != 'VMware Virtual Platform' AND
	rsys.Operating_System_Name_and0 like '%Workstation%' AND
	chcs.ClientActiveStatus = 1
  