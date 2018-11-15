SELECT
	SiteID CollectionID,
	CollectionName Name,
	CollectionComment Comment,
	CASE CollectionType
		WHEN 1 THEN 'UserCollection'
		WHEN 2 THEN 'DeviceCollection'
	END CollectionType,
	LimitToCollectionName,
	 CASE RefreshType
             WHEN 1 THEN 'Manual Update ONLY'
                WHEN 2 THEN 'Full Evaluation ONLY'
          WHEN 4 THEN 'Incremental Update ONLY'
          WHEN 6 THEN 'Incremental AND Full Evaluation'
          Else 'Unknown'
      End AS RefreshType,
	iif(IsBuiltin=1 or CollectionComment like '%Limit%',
		'Built-In Collection',
		iif(Left(CollectionName,4)='APP-' OR Left(CollectionName,2)='A-' OR CollectionComment like '%Packaging%' OR LimitToCollectionName like '%XTO Packaged%',
			'Pkg/ITAM',
			iif(CollectionName like '%VDS%' OR Left(CollectionName,9)='TS_AppDep' OR Left(CollectionName,6)='TS.GME',
				'TerminalServer',
				iif(LimitToCollectionName like '%PFE%',
					'PFE',
					iif(CollectionName like '%SPADE%' OR CollectionName like '%AUDI%' OR CollectionName like '%AWSM%' OR CollectionName like '%WASUP%' OR CollectionName like '%PowerEdge%' OR LimitToCollectionName like '%Server%' OR CollectionName like '%Server%',
						'SLE',
						iif(LimitToCollectionName like '%WKS%' OR LimitToCollectionName like '%Workstation%' Or CollectionName like '%Workstation%' Or CollectionName like '%GME %' OR LimitToCollectionName like '%GME %',
							'WDS',
							'Other'
						)
					)
				)
			)
		)
	) 'Owner'
FROM
	v_Collections
ORDER BY
	Owner,Name
