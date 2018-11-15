SELECT   
 rsys.[Name0], 
 iif(cm.Domain='UPSTREAMACCTS','UPS',cm.Domain) Domain,
 rsys.AD_Site_Name0 ADSite, 
 iif((gsscu.TopConsoleUser0 is null) OR (gsscu.TopConsoleUser0 like 'font driver host%'),
  rsys.User_Domain0+'\'+rsys.User_Name0,
  gsscu.TopConsoleUser0) TopConsoleUser,
 iif((gsscu.TopConsoleUser0 is null) OR (gsscu.TopConsoleUser0 like 'font driver host%'),
  ruserad.Mail0,
  rusersccm.mail0) Mail,
 iif((gsscu.TopConsoleUser0 is null) OR (gsscu.TopConsoleUser0 like 'font driver host%'),
  ruserad.department0,
  rusersccm.department0) Dept,
 
 REPLACE(Right(LEFT(gsos.Caption0,21),12),'E','') OS, 
 cm.SiteCode, 
 chcs.LastMPServerName,
 chcs.LastOnline,
 gscs.Model0
FROM 
 [v_R_System] rsys
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
 rsys.Is_Virtual_Machine0 = 0
  AND
 gscs.Model0 != 'VMware Virtual Platform'
  AND
 rsys.Operating_System_Name_and0 like '%Workstation%' 