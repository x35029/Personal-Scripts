Select 
	rsys.Name0,
	cm.SiteCode,
	rsys.Resource_Domain_OR_Workgr0,
	rsys.AD_Site_Name0
from
	v_R_System rsys
		INNER JOIN
	v_ClientMachines cm
		on rsys.ResourceID=cm.ResourceID
where
	rsys.Operating_System_Name_and0 like '%Workstation%'
		AND
	cm.SiteCode != 'AP1'
		AND
	(
		rsys.Resource_Domain_OR_Workgr0 in ('AP')
			or
		(
			rsys.Resource_Domain_OR_Workgr0 ='upstreamaccts'
				and
			rsys.AD_Site_Name0 in (
				'A03','ACB','AKL','ARS','AST','ATK','ATR','BAA','BBM','BEJ','BJU','BK2','BK3','BK4','BK5','BKJ',
				'BKK','BLP','BLR','BLU','BMA','BMB','BTO','CBA','CBJ','CCT','CDM','CEP','CHE','CLP','CSO','DAA',
				'DHA','DML','DUC','DUN','DZA','EPF','EPI','ESH','FLA','FTA','FWS','GDT','GGN','GLK','GMK','GRI',
				'GTX','GUA','GUB','GUC','GUD','GUZ','GZD','GZL','HBA','HBF','HCM','HCU','HHI','HKG','HNI','HRI',
				'HTC','IBA','INR','ITP','JAB','JAK','JBC','JEA','JMG','JMT','JNZ','JTC','JTE','KAC','KAW','KCN',
				'KFA','KFB','KGH','KHG','KHI','KID','KL1','KLD','KLE','KLH','KLI','KLM','KLS','KMR','KNS','KOX',
				'KRK','KSB','KTH','KUL','KUV','KWH','LAE','LDO','LFD','LIP','LLK','LMG','LPG','LRA','LSK','LST',
				'LWA','LYT','MAK','MAL','MDG','MEL','MGE','MGT','MIG','MKA','MKL','MLA','MN2','MNA','MNL','MRO',
				'MRP','MSO','MTM','MTW','MUM','NDH','NEB','NEL','NGY','NOI','NOU','NPO','NPT','NSO','NTA','NTB',
				'ONJ','PAA','PCF','PCP','PFC','PGC','PHG','PIT','PJS','PKC','PKF','PKO','PLN','PMV','PNH','POM',
				'POU','PRT','PSG','PSL','PSP','PYU','QCD','QCE','QCT','QHL','QOA','QTB','RGI','RMZ','RON','RTC',
				'RYB','SAC','SAE','SBK','SBY','SCU','SDE','SEE','SEF','SEG','SGC','SGU','SHA','SHG','SIG','SKB',
				'SKJ','SLQ','SLS','SMB','SMC','SNG','SOP','SOX','SPL','SPN','SPX','SQK','SRA','SRJ','SRT','ST1',
				'STA','STP','SUK','SUV','SVW','TAA','TAC','TAD','TAE','TAI','TAQ','TBH','TCG','TCO','TEA','TEB',
				'THT','TIC','TJM','TKY','TNA','TNJ','TOK','TPA','TPL','TPP','TPR','TRM','TST','TUA','TUB','TWD',
				'TYC','TYT','ULS','VAA','VBT','VFA','VFG','VK1','VKL','VLC','VOB','VPH','VS1','VSI','VT1','VTB',
				'VTT','VUD','WAL','WEA','WIR','WKF','WLE','WOA','WOL','WPA','WPB','WPF','WPL','XAD')
		)
	)
ORDER BY
	rsys.AD_Site_Name0	,	rsys.Name0