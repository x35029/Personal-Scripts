SELECT
	ucsa.[ResourceID]	
	,cia.AssignmentName,	
	uas.IsCompliant,
	CONVERT(DECIMAL(10,2),COUNT(iif(ucsa.[Status]=1 OR ucsa.[Status]=3,1,null))*1.0/COUNT(ucsa.[Status])*1.0) 'Rate',
	COUNT(iif(ucsa.[Status]=0,1,null)) 'KBs Unknown',
	COUNT(iif(ucsa.[Status]=1,1,null)) 'KBs Not Required',
	COUNT(iif(ucsa.[Status]=2,1,null)) 'KBs Required',
	COUNT(iif(ucsa.[Status]=3,1,null)) 'KBs Installed',
	COUNT(ucsa.[Status]) 'AllKBs',
	COUNT(iif(ucsa.[Status]=1 OR ucsa.[Status]=3,1,null)) 'CompleteKBs',
	COUNT(iif(ucsa.[Status]=0 OR ucsa.[Status]=2,1,null)) 'PendingKBs'
	
FROM 
	[v_Update_ComplianceStatusAll] ucsa
		INNER JOIN
	[v_CIAssignmentToCI] ciatci
		ON ucsa.CI_ID=ciatci.CI_ID
		INNER JOIN
	[v_CIAssignment] cia
		on cia.AssignmentID=ciatci.AssignmentID
		INNER JOIN
	[v_UpdateAssignmentStatus] uas
		on cia.AssignmentID=uas.AssignmentID and uas.ResourceID=ucsa.ResourceID
WHERE
	cia.AssignmentName like 'WKS-SecurityUpdate%'
		AND
	cia.CollectionName = 'WKS-SUP-DG4-COL'
	GROUP BY
	ucsa.[ResourceID]	
	,cia.AssignmentName,
	uas.IsCompliant
