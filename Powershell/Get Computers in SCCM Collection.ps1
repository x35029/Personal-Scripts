$SiteServer = 'SERVER NAME 
$SiteCode = 'SITE CODE' 
$CollectionName = 'NAME OF COLLECTION' 
$cred = Get-credential 
#Retrieve SCCM collection by name 
$Collection = get-wmiobject -ComputerName $siteServer -NameSpace "ROOT\SMS\site_$SiteCode" -Class SMS_Collection -Credential $cred  | where {$_.Name -eq "$CollectionName"} 
#Retrieve members of collection 
$SMSMemebers = Get-WmiObject -ComputerName $SiteServer -Credential $cred -Namespace  "ROOT\SMS\site_$SiteCode" -Query "SELECT * FROM SMS_FullCollectionMembership WHERE CollectionID='$($Collection.CollectionID)' order by name" | select Name