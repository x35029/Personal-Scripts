$SiteServer = 'DALSCC01' 
$SiteCode = 'CEN' 
$CollectionArray = get-Content -Path "C:\Users\JRVARAN\collections.txt"
$outputFile = "c:\users\jrvaran\colOutputFile_"
$count = 0
#Retrieve SCCM collection by name 
foreach ($CollectionName in $CollectionArray) {
    $count++
    #write-host $count
    write-host $CollectionName
    $Collection= get-wmiobject -ComputerName $siteServer -NameSpace "ROOT\SMS\site_$SiteCode" -Class SMS_Collection | where {$_.Name -eq "$CollectionName"} 
    $output = $outputfile+"_"+$count+"_"+$Collection.Name+".csv"
    write-host $output," - ",$Collection.Name," - ",$Collection.CollectionID
    write-output $Collection.Name >> $output
    #Retrieve members of collection 
    $SMSMemebers = Get-WmiObject -ComputerName $SiteServer -Namespace  "ROOT\SMS\site_$SiteCode" -Query "SELECT * FROM SMS_FullCollectionMembership WHERE CollectionID='$($Collection.CollectionID)' order by name" | select Name
    write-output $SMSMemebers >> $output
    #write-host $SMSMemebers
}