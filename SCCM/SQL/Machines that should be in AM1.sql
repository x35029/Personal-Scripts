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
	cm.SiteCode != 'AM1'
		AND
	(
		rsys.Resource_Domain_OR_Workgr0 in ('NA','SA')
			or
		(
			rsys.Resource_Domain_OR_Workgr0 ='upstreamaccts'
				and
			rsys.AD_Site_Name0 in (
				'AAC','ABA','ABB','ABM','ABP','ABS','ACT','ADP','AGB','AGL','AGS','AHC','AHI','AKO','AKR','ALB',
				'ALM','ALN','ALP','AMC','AME','AMH','AMS','ANC','ANG','ANM','ANS','APD','ARB','ART','ASC','ATL',
				'ATW','BAL','BAQ','BAR','BAV','BAW','BAY','BBG','BBS','BBW','BCN','BCS','BCT','BDE','BDG','BDL',
				'BDW','BEL','BEN','BET','BEV','BFP','BGP','BGR','BHL','BIG','BIR','BIS','BKC','BLS','BLV','BLZ',
				'BMC','BMP','BMR','BMT','BOG','BOP','BOZ','BPC','BPE','BPM','BPP','BPS','BRC','BRF','BRH','BRK',
				'BRL','BRM','BRO','BRP','BRR','BSC','BSN','BTA','BTC','BTN','BTR','BUE','BUG','BUL','BVA','BWC',
				'C1W','CAL','CAM','CAR','CBI','CBP','CBS','CBW','CCA','CCO','CDC','CDS','CDT','CEN','CFA','CFP',
				'CGY','CHH','CHL','CHM','CHR','CHS','CHT','CIC','CIN','CLC','CLD','CLM','CLN','CLT','CLU','CLW',
				'CMS','COB','CON','COS','COT','CPC','CPW','CQP','CRB','CRC','CRH','CRL','CSD','CSS','CSX','CTB',
				'CTC','CTD','CTG','CTL','CTR','CTT','CTX','CVL','CWP','CXI','CXM','CXO','CXP','CXW','CYP','CYR',
				'DAC','DAL','DAR','DDR','DDZ','DEN','DEV','DGB','DGL','DHE','DHS','DIA','DID','DIS','DLH','DLI',
				'DLO','DLU','DOX','DSB','DSF','DSP','DST','DTC','DUL','EAG','EBR','ECD','EDS','EDT','EFT','EGS',
				'EJA','ELK','ELT','EMB','EMC','EMD','EMO','EMP','EMX','EPD','EPE','EQU','ERR','ETG','EVR','EWD',
				'EXL','FAC','FAP','FBT','FCH','FDR','FFX','FLD','FLI','FLR','FMI','FNY','FOU','FRA','FRH','FRI',
				'FRW','FSJ','FTL','FTO','FTR','FTW','FUB','FUG','FWA','FWD','FWT','FXE','FXH','GA2','GBG','GBO',
				'GDI','GDP','GEY','GGB','GGW','GLD','GLH','GLW','GND','GNQ','GOP','GP4','GP6','GP8','GPG','GPH',
				'GPL','GPS','GQA','GRB','GRE','GRF','GRR','GRW','GRY','GSV','GTA','GTC','GTN','GW3','GWD','GYG',
				'HAC','HAL','HAP','HAY','HB1','HB2','HB3','HB4','HB5','HB6','HBC','HBH','HBR','HBT','HBY','HCA',
				'HCF','HCN','HCO','HDR','HDT','HDV','HDZ','HEH','HER','HEW','HFB','HFX','HGP','HGS','HIA','HIB',
				'HID','HIL','HIS','HKB','HLA','HLN','HMA','HMD','HNA','HNL','HNP','HNS','HNT','HOE','HOL','HON',
				'HOO','HOP','HOT','HPA','HRC','HRM','HRP','HRS','HSM','HTN','HTS','HUL','HWK','HWT','IAC','IAH',
				'IAP','IAT','ICO','IET','IML','IMP','IMT','IND','INF','INT','INU','IOC','IOL','IRV','ITC','JOL',
				'KBC','KBR','KCM','KEN','KFY','KGP','KIS','KLR','KMZ','KNX','KRG','KRL','KRP','LAM','LAS','LBS',
				'LCP','LDE','LDM','LER','LGV','LIB','LIM','LIS','LNP','LNV','LOC','LOS','LTF','LUP','LVF','LWC',
				'MAR','MB7','MBB','MBM','MBP','MC2','MCC','MCK','MCP','MCR','MDH','MDL','MDV','MEE','MEP','MET',
				'MFD','MID','MKP','MKV','MLF','MLN','MLS','MLT','MLY','MMI','MNC','MNN','MOB','MPS','MQG','MRC',
				'MRK','MRX','MSQ','MTB','MTR','MWT','MXC','MXP','MXT','MYX','NAN','NBF','NBG','NBL','NBY','NEK',
				'NEV','NIB','NLE','NLN','NLR','NLS','NMO','NQC','NQN','NQO','NRW','NSH','NTN','NTR','NWK','NWT',
				'OAP','OKC','OLA','OLS','OSR','OTF','OTT','PAB','PAC','PAL','PAM','PAS','PAT','PAU','PCB','PCC',
				'PCH','PCR','PCV','PCY','PE2','PEI','PEP','PGO','PHI','PHK','PHW','PIC','PKG','PKL','PLA','PLT',
				'PMK','PNS','PPS','PSA','PSJ','PST','PTC','PTO','PTP','PUA','PYO','QAT','QSP','QUE','QUT','RAC',
				'RAY','RBC','RBF','RDD','RDT','REP','RFD','RFH','RHD','RHM','RHV','RIO','RLM','RMH','ROA','ROC',
				'RRT','RSP','RSQ','RTD','RWI','RYM','SAF','SAR','SBD','SBL','SCC','SCH','SCO','SCS','SDG','SDT',
				'SEL','SEW','SFC','SGF','SGI','SHC','SHD','SHL','SHU','SIL','SJH','SJJ','SJM','SJN','SKN','SLL',
				'SLM','SMD','SME','SNC','SNL','SNP','SOR','SPC','SPR','SRD','SRH','SRS','SRV','SS7','SSA','SSM',
				'STC','STE','STH','STJ','STM','STN','STS','STT','STY','SUD','SUG','SUN','SVN','SWI','SWR','SWT',
				'SYB','SYC','SYD','SYE','SYF','SYG','SYH','SYL','SYN','SYP','SYT','SYU','TAF','TAM','TBD','TCK',
				'TCS','TDO','TFT','TGR','TIP','TLC','TLO','TLS','TMI','TMW','TND','TNP','TOC','TOL','TOP','TOR',
				'TPC','TRC','TRG','TRW','TSE','TSJ','TUX','TWA','TWB','TWC','TWE','TWG','TWH','TWQ','TYL','UAB',
				'UAC','UDR','UET','ULE','UPI','UPS','USR','VBR','VC1','VCG','VD1','VDL','VDN','VEG','VEN','VER',
				'VH1','VHS','VIK','VIS','VLE','VOD','VOP','VPK','VTN','VVO','WAC','WAD','WAP','WAS','WBD','WBP',
				'WDC','WDH','WDL','WDR','WDS','WGM','WGR','WHC','WLV','WLW','WMI','WNG','WNP','WOD','WPC','WQA',
				'WWH','WYN','YEL','YMB','YMD','YOR','ZAC','ZLF')
		)
	)
ORDER BY
	rsys.AD_Site_Name0	,	rsys.Name0