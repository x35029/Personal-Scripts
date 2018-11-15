. C:\Dev\Scripts\Powershell\DataFromSentinelOne\Write-ObjectToSQL.ps1

Function Invoke-SQL
{
    param(
        [Parameter(Mandatory=$true)]
        [string] $sqlCommand,
        [Parameter(Mandatory=$true)]
        [string] $server,
        [Parameter(Mandatory=$true)]
        [string] $database,
        [Parameter(Mandatory=$false)]
        [System.Management.Automation.PSCredential]$credential,
        [Parameter(Mandatory=$false)]
        [switch]$UseDefaultCredential
    )
    try {
        #Check if .Net 4.5 or greater is installed
        $InstalledDotNet = Get-ChildItem 'HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP' -recurse | Where-Object { $_.PSChildName -match '^(?!S)\p{L}'}
        $NetReleases = $InstalledDotNet | Get-ItemProperty -name Release -EA 0 | Select-Object -Property Release
        foreach ($version in $NetReleases.Release) {if ($version -ge 378389) {$DotNet = $True;break}}

        if ($UseDefaultCredential)
        {
            $ConnectionString = "Server=$server; Initial Catalog=$database; Integrated Security=SSPI;"
            $Connection = New-Object System.Data.SQLClient.SQLConnection($ConnectionString)
        }
        elseif ($DotNet){
            $credential.Password.MakeReadOnly()
            $sqlCred = New-Object System.Data.SqlClient.SqlCredential($credential.username,$credential.password)
            $ConnectionString = "Server=$server; Initial Catalog=$database;"
            $Connection = New-Object System.Data.SQLClient.SQLConnection($ConnectionString)
            $connection.Credential = $sqlCred
        } else {
            $dbuser = $credential.UserName
            $dbencpwd = $credential.Password
            $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($dbencpwd)
            $dbpw = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
            $ConnectionString = "Server=$server; Initial Catalog=$database; User ID=$dbuser; Password=$dbpw;"
            $Connection = New-Object System.Data.SQLClient.SQLConnection($ConnectionString)
        }

        $command = New-Object system.data.sqlclient.sqlcommand($sqlCommand,$connection)
        $connection.Open()

        $adapter = New-Object System.Data.sqlclient.sqlDataAdapter $command
        $dataset = New-Object System.Data.DataSet
        $adapter.Fill($dataSet) | Out-Null

        $connection.Close()
        if ($dataSet.Tables){
            $dataSet.Tables
        } else {
            $null
        }
    }
    catch {
        $exception = $_.Exception
        $exception.message
        throw $exception.message
    }

}


$apiToken = "397750545353785139LdsWzmfIut9nrrseioc66yrP3HFyMkEfQnOW32xB"
$groupID = "376752689713153413"
$mainApiURI = "https://susea-1-exxon-poc.sentinelone.net/web/api/v2.0/"

$filter = "agents?groupIds=" + $groupID
$header = @{"Authorization" = "ApiToken $apiToken"}

$results = @()
$cursor = $null
do
{
    if ($cursor -eq $null) {

        $consultURI = $mainApiURI + $filter
        $partialResult = Invoke-RestMethod -URI $consultURI -Method GET -Headers $header
        $results += $partialResult.data | Select computername, siteName, lastLoggedInUserName, groupName, domain, externalIp, agentversion, @{Name='lastActiveDate';Expression={[datetime]$_.lastActiveDate}}
    }
    else {
        $consultURI = $mainApiURI + $filter + "&cursor=" + $cursor
        $partialResult = Invoke-RestMethod -URI $consultURI -Method GET -Headers $header
        $results += $partialResult.data | Select computername, siteName, lastLoggedInUserName, groupName, domain, externalIp, agentversion, @{Name='lastActiveDate';Expression={[datetime]$_.lastActiveDate}}
    }
    $cursor = $partialResult.pagination.nextCursor
}
while ($cursor -ne $null)

Invoke-SQL -sqlCommand "DROP TABLE SentinelOne" -server DALSQL191 -database WDS_TS -UseDefaultCredential

$results | Write-ObjectToSQL -Server DALSQL191 -Database WDS_TS -TableName SentinelOne
Write-host "Done" 