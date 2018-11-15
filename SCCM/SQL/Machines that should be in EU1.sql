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
	cm.SiteCode != 'EU1'
		AND
	(
		rsys.Resource_Domain_OR_Workgr0 in ('EA','AF')
			or
		(
			rsys.Resource_Domain_OR_Workgr0 ='upstreamaccts'
				and
			rsys.AD_Site_Name0 in (
				'ABD','ABO','ABU','ACG','ACO','ADD','ADN','AFT','AGA','AGD','AGP','AIB','ALD','ALE','ALG',
				'ALT','AM3','AMP','ANT','AOR','APA','APL','APP','ARL','ARN','ASD','ASG','ASM','ASS','ATC',
				'ATH','ATO','ATY','AUA','AUD','AUG','AUO','AVO','AVP','AVR','AWO','AZW','BAC','BAD','BAG',
				'BAU','BBY','BCE','BCP','BDP','BDR','BER','BGO','BIA','BIC','BIM','BIT','BKR','BLC','BLO',
				'BNB','BOA','BOD','BOE','BOL','BOT','BOU','BPL','BPO','BRA','BRE','BRG','BRI','BRT','BSL',
				'BSR','BTG','BTL','BTP','BUC','BUS','BVV','CAA','CAF','CAI','CAP','CAS','CAT','CDA','CDI',
				'CDP','CFM','CGL','CHI','CLZ','CMB','CMG','COA','COD','COI','COL','COR','CPB','CPS','CRE',
				'CRP','CRR','CRT','CSM','CTE','CTF','CVO','D01','DA8','DAP','DBC','DEK','DES','DJI','DKQ',
				'DLA','DMA','DND','DNZ','DOB','DOC','DOH','DOU','DRL','DRM','DRT','DS7','DS8','DTL','DUA',
				'DUB','DUS','DUV','DZB','EAP','EDO','EDU','EGJ','EIC','EKB','EKP','EKT','ELG','EMF','EMI',
				'ERB','ERH','EST','ETI','EUR','FAW','FCO','FDW','FEP','FIR','FIU','FLH','FMF','FMK','FOR',
				'FOS','FRK','FRS','FSO','FWI','GAT','GCC','GEN','GET','GEV','GHM','GKN','GOA','GOB','GOT',
				'GOU','GRO','GRT','GRV','GUE','GUN','GVR','GWB','HAA','HAM','HAW','HCS','HEM','HGE','HGR',
				'HHC','HLI','HNO','HRN','HSF','HUD','HYT','IAB','ICP','IDO','IIS','IKI','IKJ','INI','IRS',
				'IST','ITT','IZM','JCB','JEB','JEC','JER','JTN','JUB','KAL','KAP','KHT','KIE','KMA','KME',
				'KOA','KP1','KP2','KPL','KRA','KRT','KSF','KTK','KWA','KWC','KZA','KZB','KZM','KZS','KZZ',
				'LAG','LAJ','LAR','LBC','LDN','LDQ','LEB','LGW','LHD','LHI','LHR','LID','LIG','LIO','LKA',
				'LOM','LOP','LOX','LSB','LSC','LSN','LTP','LUA','LUB','LUT','LUX','LVA','LVS','LYF','LYO',
				'MAC','MAD','MAE','MAN','MAO','MAP','MBC','MCS','MDM','MDR','MEX','MGB','MGD','MGS','MHE',
				'MHM','MIA','MII','MIK','MIL','MLB','MNR','MNV','MON','MPI','MPP','MRD','MRE','MRM','MSC',
				'MSW','MTT','NAA','NAO','NAP','NDG','NDJ','NEP','NHG','NIC','NIG','NOD','NOG','NOR','NOV',
				'NRS','OBU','ODL','ODT','OLB','OPO','ORL','OS5','OSL','OSO','OSW','PAD','PAO','PAR','PCW',
				'PDN','PER','PES','PFR','PFT','PGE','PHC','PHH','PIS','PJE','PJR','PLM','PLO','PMA','PNT',
				'POS','POW','PRB','PRF','PRG','PRS','PS1','PS2','PS3','PTD','PTR','PUR','QIT','RAP','RAV',
				'RFR','RIH','RLN','RMD','RME','RMN','RMR','RNO','RO2','ROM','ROP','ROT','RPI','RUE','RYD',
				'SAT','SBA','SBM','SBN','SBS','SEC','SED','SER','SFT','SHB','SHE','SHI','SHR','SID','SIK',
				'SJA','SJB','SJO','SJU','SKG','SKH','SKT','SLA','SMN','SOE','SOG','SOU','SPG','SPM','SRE',
				'SRP','STB','STF','STV','SUM','SUZ','SXA','TAB','TAG','TAN','TAR','TCR','TDI','TEM','THS',
				'TID','TOI','TOT','TOU','TRB','TRE','TRH','TRO','TRP','TRT','TSC','TTC','TUN','TUR','UBI',
				'UDA','UDD','UFA','ULO','USN','USP','UST','UTU','VA1','VAD','VAR','VCK','VCO','VIB','VIL',
				'VIR','VL1','VLD','VLH','VLI','VLP','VLY','VMP','VNS','VOG','VPR','VQ1','VSB','WAW','WBT',
				'WBX','WCA','WCS','WDJ','WGE','WLL','WLR','WLT','WMF','WNN','WOK','WOR','WPO','WSO','WTA',
				'WTO','WUB','XIK','YDE','YFS','YOH','YPP','YUZ','ZAH','ZAR','ZBA','ZBB','ZBD','ZBI','ZBP',
				'ZFQ','ZLD','ZLQ','ZOL','ZPR')
		)
	)
ORDER BY
	rsys.AD_Site_Name0	,	rsys.Name0