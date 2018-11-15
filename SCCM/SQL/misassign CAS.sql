SELECT DISTINCT 
	rsys.ResourceID,
	rsys.Name0 DeviceName,
	cm.SiteCode SCCMSite,
	rsys.AD_Site_Name0 AD_Site,
	rsys.Creation_Date0 ADOBjCreation,
	rsys.Distinguished_Name0 AD_DN,
	rsys.Full_Domain_Name0 Domain,
	rsys.User_Domain0+'\'+rsys.User_Name0 ADUser,
	chcs.LastActiveTime SCCMLastActive,
	chcs.ClientState SCCMClientState,
	gscs.Model0 Model,
	os.InstallDate0 OS_Install,
	uss.[LastWUAVersion] WUAVer,
	iif((con.TopConsoleUser0 is null) or (con.TopConsoleUser0 like 'font driver host%'),
	ruser2.Unique_User_Name0,
	ruser.Unique_User_Name0) UserID,
	iif((con.TopConsoleUser0 is null) or (con.TopConsoleUser0 like 'font driver host%'),
	ruser2.Mail0,
	ruser.Mail0) UserMail,
	iif((con.TopConsoleUser0 is null) or (con.TopConsoleUser0 like 'font driver host%'),
	ruser2.department0,
	ruser.department0) UserDept,
	rsys.Is_Virtual_Machine0,
	os.Caption0
FROM
	[v_R_System] rsys
		INNER JOIN
	[v_CH_ClientSummary] chcs
		on rsys.ResourceID=chcs.ResourceID
		INNER JOIN
	[v_ClientMachines] cm
		on rsys.ResourceID=cm.ResourceID
		INNER JOIN
	[v_GS_COMPUTER_SYSTEM] gscs
		on rsys.ResourceID=gscs.ResourceID
		INNER JOIN
	[v_GS_OPERATING_SYSTEM] OS
		on rsys.ResourceID=os.ResourceID
		INNER JOIN
	[v_UpdateScanStatus] uss
		on rsys.ResourceID=uss.ResourceID
		INNER JOIN
	(
		SELECT ResourceID,MAX(TimeStamp) TimeStamp
		FROM [v_GS_OPERATING_SYSTEM]
		GROUP BY ResourceID
	) OS2
		on os.ResourceID=os2.ResourceID and os.TimeStamp=os2.TimeStamp
		LEFT JOIN
	[v_GS_SYSTEM_CONSOLE_USAGE] con
		on rsys.ResourceID=con.ResourceID
		LEFT JOIN
	[v_R_User] ruser
		ON con.TopConsoleUser0=ruser.Unique_User_Name0
		LEFT JOIN
	[v_R_User] ruser2
		ON rsys.User_Domain0+'\'+rsys.User_Name0=ruser2.Unique_User_Name0
WHERE
	chcs.ClientActiveStatus = 1
		and
	rsys.Operating_System_Name_and0 like '%Workstation%'
		AND	
	(		
		(	cm.SiteCode = 'AM1'
				AND
			(
				rsys.Full_Domain_Name0 not in ('SA.XOM.COM','NA.XOM.COM','CPE.COPEC','ACCPT.XOM.COM')
					AND
				rsys.AD_Site_Name0 not in ('AAC','ABA','ABB','ABM','ANM','BAQ','BBG','BBS','BBW','BIG','BOG','BPM','BUE','BUG','CAR','CBP','CLC','CLU','CTB','CTC','CTG','CTX','GTC','GYG','HNA','HNS','LAM','LER','LIM','MAR','MLN','MNC','MQG','MXC','MXP','MXT','NEV','NQC','NQN','NQO','PAM','PTC','PUA','QUT','RIO','SPC','STT','TUX','UAB','VPK','YMB','ZAC','ABP','ABS','ACT','ADP','AGB','AGL','AGS','AHC','AHI','AKO','AKR','ALB','ALM','ALN','ALP','AMC','AME','AMH','AMS','ANC','ANG','ANS','APD','ARB','ART','ASC','ATL','ATW','BAL','BAR','BAV','BAW','BAY','BCN','BCS','BCT','BDE','BDG','BDL','BDW','BEL','BEN','BET','BEV','BFP','BGP','BGR','BHL','BIR','BIS','BKC','BLS','BLV','BLZ','BMC','BMP','BMR','BMT','BOP','BOZ','BPC','BPE','BPP','BPS','BRC','BRF','BRH','BRK','BRL','BRM','BRO','BRP','BRR','BSC','BSN','BTA','BTC','BTN','BTR','BUL','BVA','BWC','C1W','CAL','CAM','CBI','CBS','CBW','CCA','CCO','CDC','CDS','CDT','CEN','CFA','CFP','CGY','CHH','CHL','CHM','CHR','CHS','CHT','CIC','CIN','CLD','CLM','CLN','CLT','CLW','CMS','COB','CON','COS','COT','CPC','CPW','CQP','CRB','CRC','CRH','CRL','CSD','CSS','CSX','CTD','CTL','CTR','CTT','CVL','CWP','CXI','CXM','CXO','CXP','CXW','CYP','CYR','DAC','DAL','DAR','DDR','DDZ','DEN','DEV','DGB','DGL','DHE','DHS','DIA','DID','DIS','DLH','DLI','DLO','DLU','DOX','DSB','DSF','DSP','DST','DTC','DUL','EAG','EBR','ECD','EDS','EDT','EFT','EGS','EJA','ELK','ELT','EMB','EMC','EMD','EMO','EMP','EMX','EPD','EPE','EQU','ERR','ETG','EVR','EWD','EXL','FAC','FAP','FBT','FCH','FDR','FFX','FLD','FLI','FLR','FMI','FNY','FOU','FRA','FRH','FRI','FRW','FSJ','FTL','FTO','FTR','FTW','FUB','FUG','FWA','FWD','FWT','FXE','FXH','GA2','GBG','GBO','GDI','GDP','GEY','GGB','GGW','GLD','GLH','GLW','GND','GNQ','GOP','GP4','GP6','GP8','GPG','GPH','GPL','GPS','GQA','GRB','GRE','GRF','GRR','GRW','GRY','GSV','GTA','GTN','GW3','GWD','HAC','HAL','HAP','HAY','HB1','HB2','HB3','HB4','HB5','HB6','HBC','HBH','HBR','HBT','HBY','HCA','HCF','HCN','HCO','HDR','HDT','HDV','HDZ','HEH','HER','HEW','HFB','HFX','HGP','HGS','HIA','HIB','HID','HIL','HIS','HKB','HLA','HLN','HMA','HMD','HNL','HNP','HNT','HOE','HOL','HON','HOO','HOP','HOT','HPA','HRC','HRM','HRP','HRS','HSM','HTN','HTS','HUL','HWK','HWT','IAC','IAH','IAP','IAT','ICO','IET','IML','IMP','IMT','IND','INF','INT','INU','IOC','IOL','IRV','ITC','JOL','KBC','KBR','KCM','KEN','KFY','KGP','KIS','KLR','KMZ','KNX','KRG','KRL','KRP','LAS','LBS','LCP','LDE','LDM','LGV','LIB','LIS','LNP','LNV','LOC','LOS','LTF','LUP','LVF','LWC','MB7','MBB','MBM','MBP','MC2','MCC','MCK','MCP','MCR','MDH','MDL','MDV','MEE','MEP','MET','MFD','MID','MKP','MKV','MLF','MLS','MLT','MLY','MMI','MNN','MOB','MPS','MRC','MRK','MRX','MSQ','MTB','MTR','MWT','MYX','NAN','NBF','NBG','NBL','NBY','NEK','NIB','NLE','NLN','NLR','NLS','NMO','NRW','NSH','NTN','NTR','NWK','NWT','OAP','OKC','OLA','OLS','OSR','OTF','OTT','PAB','PAC','PAL','PAS','PAT','PAU','PCB','PCC','PCH','PCR','PCV','PCY','PE2','PEI','PEP','PGO','PHI','PHK','PHW','PIC','PKG','PKL','PLA','PLT','PMK','PNS','PPS','PSA','PSJ','PST','PTO','PTP','PYO','QAT','QSP','QUE','RAC','RAY','RBC','RBF','RDD','RDT','REP','RFD','RFH','RHD','RHM','RHV','RLM','RMH','ROA','ROC','RRT','RSP','RSQ','RTD','RWI','RYM','SAF','SAR','SBD','SBL','SCC','SCH','SCO','SCS','SDG','SDT','SEL','SEW','SFC','SGF','SGI','SHC','SHD','SHL','SHU','SIL','SJH','SJJ','SJM','SJN','SKN','SLL','SLM','SMD','SME','SNC','SNL','SNP','SOR','SPR','SRD','SRH','SRS','SRV','SS7','SSA','SSM','STC','STE','STH','STJ','STM','STN','STS','STY','SUD','SUG','SUN','SVN','SWI','SWR','SWT','SYB','SYC','SYD','SYE','SYF','SYG','SYH','SYL','SYN','SYP','SYT','SYU','TAF','TAM','TBD','TCK','TCS','TDO','TFT','TGR','TIP','TLC','TLO','TLS','TMI','TMW','TND','TNP','TOC','TOL','TOP','TOR','TPC','TRC','TRG','TRW','TSE','TSJ','TWA','TWB','TWC','TWE','TWG','TWH','TWQ','TYL','UAC','UDR','UET','ULE','UPI','UPS','USR','VBR','VC1','VCG','VD1','VDL','VDN','VEG','VEN','VER','VH1','VHS','VIK','VIS','VLE','VOD','VOP','VTN','VVO','WAC','WAD','WAP','WAS','WBD','WBP','WDC','WDH','WDL','WDR','WDS','WGM','WGR','WHC','WLV','WLW','WMI','WNG','WNP','WOD','WPC','WQA','WWH','WYN','YEL','YMD','YOR','ZLF')
			)
	OR
		(	cm.SiteCode = 'EU1'
			AND
			rsys.Full_Domain_Name0 not in ('EA.XOM.COM','AF.XOM.COM')
				AND
			rsys.AD_Site_Name0 not in ('ABD','ABO','ACG','ACO','AFT','AIB','ALG','ALT','AM3','AMP','ANT','APL','APP','ARL','ARN','ATC','ATH','AUD','AUG','AUO','AVO','AVP','AVR','AWO','AZW','BAC','BAD','BAG','BAU','BBY','BCE','BDP','BDR','BER','BGO','BIA','BIC','BIM','BIT','BKR','BNB','BOA','BOD','BOL','BOT','BOU','BPO','BRA','BRE','BRG','BRI','BSL','BTG','BTL','BTP','BUC','BVV','CAF','CAT','CFM','CGL','CHI','CLZ','CMG','COA','COD','COI','COL','COR','CPB','CRE','CRP','CRR','CRT','CSM','CTE','CVO','DAP','DEK','DES','DKQ','DND','DNZ','DRL','DRM','DRT','DTL','DUB','DUS','DZB','EIC','EKB','ELG','EMI','EST','EUR','FAW','FCO','FDW','FEP','FIR','FIU','FLH','FMK','FOR','FOS','FRK','FRS','FWI','GAT','GCC','GEN','GET','GEV','GKN','GOB','GOT','GRO','GRT','GRV','GUE','GVR','GWB','HAA','HAM','HAW','HCS','HEM','HGE','HGR','HHC','HLI','HNO','HRN','HSF','HUD','HYT','IAB','IIS','JCB','JER','JTN','KAL','KIE','KPL','KRA','KSF','KTK','LAJ','LAR','LBC','LDN','LDQ','LEB','LGW','LHD','LHR','LID','LIG','LIO','LOX','LSB','LSC','LSN','LTP','LUT','LUX','LVA','LVS','LYF','LYO','MAC','MAD','MAE','MAN','MAO','MAP','MCS','MDR','MGB','MGD','MIA','MII','MIL','MNV','MPI','MPP','MSC','MSW','MTT','NAA','NAO','NAP','NDG','NEP','NHG','NIC','NOD','NOG','NOR','NOV','NRS','ODL','ODT','OLB','OPO','ORL','OS5','OSL','OSW','PAD','PAO','PAR','PDN','PER','PES','PFR','PFT','PHH','PIS','PJE','PJR','PLM','PLO','PMA','PNT','PRB','PRF','PRG','PTD','PTR','PUR','RAP','RAV','RFR','RIH','RLN','RME','RMR','RO2','ROM','ROP','ROT','RPI','RUE','SAT','SBA','SBS','SEC','SED','SHE','SHI','SHR','SID','SJA','SJB','SJO','SJU','SKG','SLA','SOE','SOG','SOU','SPG','SPM','SRE','STB','STF','STV','TAG','TAR','THS','TID','TOI','TOU','TRB','TRE','TRH','TRO','TRT','TSC','TUR','UDA','UDD','UFA','UST','VAD','VAR','VCK','VCO','VIB','VIL','VIR','VL1','VLD','VLH','VLI','VLP','VLY','VNS','VOG','VPR','VSB','WAW','WBT','WBX','WCA','WCS','WDJ','WGE','WLL','WLR','WLT','WNN','WOK','WOR','WPO','WSO','WTA','WTO','WUB','YUZ','ZBA','ZBB','ZBD','ZBI','ZBP','ZFQ','ZLD','ZLQ','ZOL','ABU','ADD','ADN','AGA','AGD','AGP','ALD','ALE','AOR','APA','ASD','ASG','ASM','ASS','ATO','ATY','AUA','BCP','BLC','BLO','BOE','BPL','BRT','BSR','BUS','CAA','CAI','CAP','CAS','CDA','CDI','CDP','CMB','CPS','CTF','D01','DA8','DBC','DJI','DLA','DMA','DOB','DOC','DOH','DOU','DS7','DS8','DUA','DUV','EAP','EDO','EDU','EGJ','EKP','EKT','EMF','ERB','ERH','ETI','FMF','FSO','GHM','GOA','GOU','GUN','ICP','IDO','IKI','IKJ','INI','IRS','IST','ITT','IZM','JEB','JEC','JUB','KAP','KHT','KMA','KME','KOA','KP1','KP2','KRT','KWA','KWC','KZA','KZB','KZM','KZS','KZZ','LAG','LHI','LKA','LOM','LOP','LUA','LUB','MBC','MDM','MEX','MGS','MHE','MHM','MIK','MLB','MNR','MON','MRD','MRE','MRM','NDJ','NIG','OBU','OSO','PCW','PGE','PHC','POS','POW','PRS','PS1','PS2','PS3','QIT','RMD','RMN','RNO','RYD','SBM','SBN','SER','SFT','SHB','SIK','SKH','SKT','SMN','SRP','SUM','SUZ','SXA','TAB','TAN','TCR','TDI','TEM','TOT','TRP','TTC','TUN','UBI','ULO','USN','USP','UTU','VA1','VMP','VQ1','WMF','XIK','YDE','YFS','YOH','YPP','ZAH','ZAR','ZPR')
		)
	OR
		(	cm.SiteCode = 'AP1'
				AND			
			rsys.Full_Domain_Name0 <> 'AP.XOM.COM'
				AND
			rsys.AD_Site_Name0 not in ('A03','ACB','AKL','ARS','AST','ATK','ATR','BAA','BBM','BEJ','BJU','BK2','BK3','BK4','BK5','BKJ','BKK','BLP','BLR','BLU','BMA','BMB','BTO','CBA','CBJ','CCT','CDM','CEP','CHE','CLP','CSO','DAA','DHA','DML','DUC','DUN','DZA','EPF','EPI','ESH','FLA','FTA','FWS','GDT','GGN','GLK','GMK','GRI','GTX','GUA','GUB','GUC','GUD','GUZ','GZD','GZL','HBA','HBF','HCM','HCU','HHI','HKG','HNI','HRI','HTC','IBA','INR','ITP','JAB','JAK','JBC','JEA','JMG','JMT','JNZ','JTC','JTE','KAC','KAW','KCN','KFA','KFB','KGH','KHG','KHI','KID','KL1','KLD','KLE','KLH','KLI','KLM','KLS','KMR','KNS','KOX','KRK','KSB','KTH','KUL','KUV','KWH','LAE','LDO','LFD','LIP','LLK','LMG','LPG','LRA','LSK','LST','LWA','LYT','MAK','MAL','MDG','MEL','MGE','MGT','MIG','MKA','MKL','MLA','MN2','MNA','MNL','MRO','MRP','MSO','MTM','MTW','MUM','NDH','NEB','NEL','NGY','NOI','NOU','NPO','NPT','NSO','NTA','NTB','ONJ','PAA','PCF','PCP','PFC','PGC','PHG','PIT','PJS','PKC','PKF','PKO','PLN','PMV','PNH','POM','POU','PRT','PSG','PSL','PSP','PYU','QCD','QCE','QCT','QHL','QOA','QTB','RGI','RMZ','RON','RTC','RYB','SAC','SAE','SBK','SBY','SCU','SDE','SEE','SEF','SEG','SGC','SGU','SHA','SHG','SIG','SKB','SKJ','SLQ','SLS','SMB','SMC','SNG','SOP','SOX','SPL','SPN','SPX','SQK','SRA','SRJ','SRT','ST1','STA','STP','SUK','SUV','SVW','TAA','TAC','TAD','TAE','TAI','TAQ','TBH','TCG','TCO','TEA','TEB','THT','TIC','TJM','TKY','TNA','TNJ','TOK','TPA','TPL','TPP','TPR','TRM','TST','TUA','TUB','TWD','TYC','TYT','ULS','VAA','VBT','VFA','VFG','VK1','VKL','VLC','VOB','VPH','VS1','VSI','VT1','VTB','VTT','VUD','WAL','WEA','WIR','WKF','WLE','WOA','WOL','WPA','WPB','WPF','WPL','XAD')
		)
	OR
		(	cm.SiteCode = 'XT1'
				AND
			rsys.Full_Domain_Name0 <> 'XTONET.COM')
	)
)
