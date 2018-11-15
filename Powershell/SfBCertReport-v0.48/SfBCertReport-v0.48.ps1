<#  
.SYNOPSIS  
	This script shows Lync/SfB assigned certificates information and provide details for expired certificates

.EXAMPLE
    .\LyncCertReport-v0.48.ps1 -outputDirectory c:\Temp

    Puts the output into the C:\Temp directory instead of the user's Temp

.EXAMPLE
    .\LyncCertReport-v0.48.ps1 -OWASCertificates -PSTNGatewayCertificates

    Gets the Front End Server certs, as well as Office Web Apps and PSTN
    Gateways, but not Edge Server Certs.

.NOTES  
  Version      				: 0.48
  Rights Required			: Local admin
  Lync Version				: 2013 (Tested on CU January 2016)
  SfB Version				: 2015 (Tested on CU March 2016)
  Authors       			: Guy Bachar, Yoav Barzilay
  Last Update               : 27-April-2016
  Twitter/Blog	            : @GuyBachar, http://guybachar.wordpress.com
  Twitter/Blog	            : @y0avb, http://y0av.me


.VERSION
  0.1 - Initial Version for connecting Internal Lync Servers
  0.2 - With the help of Anthony Caragol we were able to pull out exact assignment information using PSRemoting
  0.3 - Retrieving  Information on assigned certificates
  0.4 - Adding support for SFB and EDGE Servers, Fixing Connectivity issues and adding support for test-connection prior to the connectiviy
  0.45 - Fixing OWAS Certificates infromation from multiple servers
  0.46 - Fixing OWAS Certificates infromation and HTML Display
  0.47 - Fixed SYNOPSIS information
  0.48 - Amanda Debler added the part that gets the Gateway certificates (tested with AudioCodes, no idea about others)
	
#>

param(
[Parameter(Position=0, Mandatory=$False) ][ValidateNotNullorEmpty()][switch] $EdgeCertificates,
[Parameter(Position=1, Mandatory=$False) ][ValidateNotNullorEmpty()][switch] $OWASCertificates,
[Parameter(Position=2, Mandatory=$False) ][ValidateNotNullorEmpty()][switch] $PSTNGatewayCertificates,
[Parameter(Position=3, Mandatory=$False) ][ValidateNotNullorEmpty()][string] $FEPool,
[Parameter(Position=4, Mandatory=$False) ][string]$outputDirectory = $env:TEMP

)

#region Script Information
Clear-Host
Write-Host "--------------------------------------------------------------" -BackgroundColor DarkGreen
Write-Host
Write-Host "Skype for Business / Lync Certificates Reporter" -ForegroundColor Green
Write-Host "Version: 0.48" -ForegroundColor Green
Write-Host "May 2016" -ForegroundColor Green
Write-Host 
Write-Host "Authors:" -ForegroundColor Green
Write-Host " Guy Bachar       | @GuyBachar        | http://guybachar.us" -ForegroundColor Green
Write-Host " Yoav Barzilay    | @y0avb            | http://y0av.me" -ForegroundColor Green
Write-Host " Anthony Caragol  | @CAnthonyCaragol  | http://www.lyncfix.com" -ForegroundColor Green
Write-Host " Amanda Debler    | @texmandie        | http://mandie.net" -ForegroundColor Green
Write-host
Write-Host "--------------------------------------------------------------" -BackgroundColor DarkGreen
Write-Host
#endregion

#region Verifying Administrator Elevation
Write-Host Verifying User permissions... -ForegroundColor Yellow -NoNewline
#Start-Sleep -Seconds 2
#Verify if the Script is running under Admin privileges
If (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(`
  [Security.Principal.WindowsBuiltInRole] "Administrator")) 
{
  Write-Warning "You do not have Administrator rights to run this script.`nPlease re-run this script as an Administrator!"
  Write-Host 
  Break
}
else
{
    Write-Host " Done!" -ForegroundColor Green
}
#endregion

#region Import Lync / SfB Module
Write-Host
Write-Host "Please wait while we're loading SfB / Lync PowerShell Modules..." -ForegroundColor Yellow -NoNewline
  if(-not ((Get-Module -Name "Lync")) -or (Get-Module -Name "SkypeforBusiness")){
    if(Get-Module -Name "Lync" -ListAvailable){
      Import-Module -Name "Lync";
    }
    elseif (Get-Module -Name "SkypeforBusiness" -ListAvailable){
      Import-Module -Name "SkypeforBusiness";
    }
    else{
      Write-Host Lync/SfB Modules are not exist on this computer, please verify the Lync Admin tools installed -ForegroundColor Red
      exit;   
    }    
  }
Write-Host -NoNewline    
Write-Host " Done!" -ForegroundColor Green
#endregion

#
# Setting Parameters
#
if ($FEPool.Length -eq 0) {$Poollist = Get-CsPool | Where-Object {(($_.Services -like "*Registrar*") -OR ($_.Services -like "*MediationServer*")) -and ($_.Site -ne "Site:BackCompatSite")}}
else {$Poollist = Get-CsPool | Where-Object {(($_.Services -like "*Registrar*") -OR ($_.Services -like "*MediationServer*")) -AND ($_.Identity -eq $FEPool)}}
$EDGElist = Get-CsPool | Where-Object {($_.Services -like "*EDGE*") -and ($_.Site -ne "Site:BackCompatSite")}
$OWASList = Get-CsPool | Where-Object {($_.Services -like "*WAC*")}
$FEServerList=$Poollist.Computers
$EDGEServerList=$EDGElist.Computers
$OWASServerList=$OWASList.Computers

#Setting the culture so weird stuff doesn't happen with the dates when run on a non en-US system - @texmandie
$oldCulture = Get-Culture
if ([Environment]::OSVersion.Version -ge (new-object 'Version' 6,2))
{
    Set-Culture -CultureInfo en-US
    $CultureChanged = $true
}

#
# Generic Parameters
#
$ServerVersion = Get-CsServerVersion
$PSRemoteConnectionPort = "80"

#
# Building HTML File
#
function CreateHtmFile
{
    $FileDate = "{0:yyyy_MM_dd-HH_mm}" -f (get-date)
    $ServicesFileName = $outputDirectory+"\SfBCertReport-"+$FileDate+".htm"
    $HTMLFile = New-Item -ItemType file $ServicesFileName -Force
    return $HTMLFile
}

Function writeHtmlHeader
{
param($fileName)
$date = ( get-date ).ToString('MM/dd/yyyy')
Add-Content $fileName "<html>"
Add-Content $fileName "<head>"
Add-Content $fileName "<meta http-equiv='Content-Type' content='text/html; charset=iso-8859-1'>"
Add-Content $fileName '<title>Lync Certificates Report</title>'
add-content $fileName '<STYLE TYPE="text/css">'
add-content $fileName  "<!--"
add-content $fileName  "td {"
add-content $fileName  "font-family: Segoe UI;"
add-content $fileName  "font-size: 11px;"
add-content $fileName  "border-top: 1px solid #1E90FF;"
add-content $fileName  "border-right: 1px solid #1E90FF;"
add-content $fileName  "border-bottom: 1px solid #1E90FF;"
add-content $fileName  "border-left: 1px solid #1E90FF;"
add-content $fileName  "padding-top: 0px;"
add-content $fileName  "padding-right: 0px;"
add-content $fileName  "padding-bottom: 0px;"
add-content $fileName  "padding-left: 0px;"
add-content $fileName  "}"
add-content $fileName  "body {"
add-content $fileName  "margin-left: 5px;"
add-content $fileName  "margin-top: 5px;"
add-content $fileName  "margin-right: 0px;"
add-content $fileName  "margin-bottom: 10px;"
add-content $fileName  ""
add-content $fileName  "table {"
add-content $fileName  "border: thin solid #000000;"
add-content $fileName  "}"
add-content $fileName  "-->"
add-content $fileName  "</style>"
add-content $fileName  "</head>"
add-content $fileName  "<body>"
add-content $fileName  "<table width='100%'>"
add-content $fileName  "<tr bgcolor='#336699 '>"
add-content $fileName  "<td colspan='7' height='25' align='center'>"
add-content $fileName  "<font face='Segoe UI' color='#FFFFFF' size='4'><strong>Certificate Report - $date</strong><BR>Server Version: $ServerVersion </font>"
add-content $fileName  "</td>"
add-content $fileName  "</tr>"
add-content $fileName  "</table>"
}

Function writeTableHeader
{
param($fileName)
Add-Content $fileName "<tr bgcolor=#0099CC>"
Add-Content $fileName "<td width='12%' align='center'><font color=#FFFFFF>Friendly Name / Usage</font></td>"
Add-Content $fileName "<td width='12%' align='center'><font color=#FFFFFF>Issuer</font></td>"
Add-Content $fileName "<td width='18%' align='center'><font color=#FFFFFF>Thumbprint</font></td>"
Add-Content $fileName "<td width='28%' align='center'><font color=#FFFFFF>Subject Name</font></td>"
Add-Content $fileName "<td width='10%' align='center'><font color=#FFFFFF>Issue Date</font></td>"
Add-Content $fileName "<td width='10%' align='center'><font color=#FFFFFF>Expiration Date</font></td>"
Add-Content $fileName "<td width='10%' align='center'><font color=#FFFFFF>Expires In</font></td>"
Add-Content $fileName "</tr>"
}

Function writeHtmlFooter
{
param($fileName)
Add-Content $fileName "</body>"
Add-Content $fileName "</html>"
}

Function writeServiceInfo
{
param($fileName,$FriendlyName,$Issuer,$Subject,$Thumbprint,$NotBefore,$NotAfter)
$TimeDiff = New-TimeSpan (Get-Date) $NotAfter
$DaysDiff = $TimeDiff.Days

 if ($NotAfter -gt (Get-date).AddDays(60))
 {
 Add-Content $fileName "<tr>"
 Add-Content $fileName "<td>$FriendlyName</td>"
 Add-Content $fileName "<td>$Issuer</td>"
 Add-Content $fileName "<td>$Subject</td>"
 Add-Content $fileName "<td>$Thumbprint</td>"
 Add-Content $fileName "<td align='center'>$NotBefore</td>"
 Add-Content $fileName "<td align='center'>$NotAfter</td>"
 Add-Content $fileName "<td bgcolor='#00FF00' align=center>$DaysDiff days</td>"
 Add-Content $fileName "</tr>"
 }
 elseif ($NotAfter -lt (Get-date).AddDays(30))
 {
 Add-Content $fileName "<tr>"
 Add-Content $fileName "<td>$FriendlyName</td>"
 Add-Content $fileName "<td>$Issuer</td>"
 Add-Content $fileName "<td>$Subject</td>"
 Add-Content $fileName "<td>$Thumbprint</td>"
 Add-Content $fileName "<td align='center'>$NotBefore</td>"
 Add-Content $fileName "<td align='center'>$NotAfter</td>"
 Add-Content $fileName "<td bgcolor='#FF0000' align=center>$DaysDiff days</td>"
 Add-Content $fileName "</tr>"
 }
 else
 {
 Add-Content $fileName "<tr>"
 Add-Content $fileName "<td>$FriendlyName</td>"
 Add-Content $fileName "<td>$Issuer</td>"
 Add-Content $fileName "<td>$Subject</td>"
 Add-Content $fileName "<td>$Thumbprint</td>"
 Add-Content $fileName "<td align='center'>$NotBefore</td>"
 Add-Content $fileName "<td align='center'>$NotAfter</td>"
 Add-Content $fileName "<td bgcolor='#FBB917' align=center>$DaysDiff days</td>"
 Add-Content $fileName "</tr>"
 }
}

Function sendEmail
{ param($from,$to,$subject,$smtphost,$htmlFileName)
$body = Get-Content $htmlFileName
$smtp= New-Object System.Net.Mail.SmtpClient $smtphost
$msg = New-Object System.Net.Mail.MailMessage $from, $to, $subject, $body
$msg.isBodyhtml = $true
$smtp.send($msg)
}

Function TestServersConnectivity
{ param($ServersArray)
    $TestedServers = @()
    foreach ($Computer in $ServersArray)
    {
        if (Test-Connection -ComputerName $Computer -Count 2 -Quiet)
        {
            Write-Host $Computer -ForegroundColor Green -NoNewline; Write-Host " - is accessible and will be tested for certificate expiration"
            $TestedServers += $Computer
        } 
        else
        {
            Write-Host $Computer -ForegroundColor Red -NoNewline; Write-Host " - is not accessible and will be removed from the list"
        }
    }
    return $TestedServers
}

# @texmandie
# From Alex Limousin - https://gallery.technet.microsoft.com/scriptcenter/Convert-String-To-Date-6c35e7ff
# Needed to deal with [DateTime] type accelerator not playing nice with non en-US date formats

function Convert-StringToDateTime
{
    param
    (
		[Parameter(Mandatory = $true)]
        [String] $DateTimeStr
    )
	
	$DateTimeParts = $DateTimeStr -split ' '
	
	$DateParts = $DateTimeParts[0] -split '/|-|\.'

	$DateFormatParts = (Get-Culture).DateTimeFormat.ShortDatePattern -split '/|-|\.'
    $Month_Index = ($DateFormatParts | Select-String -Pattern 'M').LineNumber - 1
    $Day_Index = ($DateFormatParts | Select-String -Pattern 'd').LineNumber - 1
    $Year_Index = ($DateFormatParts | Select-String -Pattern 'y').LineNumber - 1	
	
	$TimeParts = $DateTimeParts[1..$($DateTimeParts.Count - 1)]
	
	if (@($TimeParts).Count -eq 2)
	{
		$TimeFormatParts = (Get-Culture).DateTimeFormat.ShortTimePattern -split ' '
	
		$TT_Index = ($TimeFormatParts | Select-String -Pattern 't').LineNumber - 1
		$Time_Index = 1 - $TT_Index
		
		$Time = $TimeParts[$Time_Index,$TT_Index] -join ' '
	}
	else
	{
		$Time = $TimeParts
	}
	
	$DateTime = [DateTime] $($($DateParts[$Month_Index,$Day_Index,$Year_Index] -join '/') + ' ' + $Time)

    return $DateTime
}

# From https://github.com/JustinGrote/Scripts/blob/master/Get-SSLCertificate.ps1
# Who got the idea from http://blogs.technet.com/b/parallel_universe_-_ms_tech_blog/archive/2014/06/26/reading-a-certificate-off-a-remote-ssl-server-for-troubleshooting-with-powershell.aspx
# Output object modified to fit @guybachar and @y0av's existing work and uses Alex Limousin's Convert-StringToDateTime

Function Get-SSLCertificate {
[CmdletBinding()]
param(
        [parameter(Mandatory,ValueFromPipeline)][string[]]$ComputerName,
        [int]$TCPPort=443,
        [int]$Timeoutms=3000
)


process { foreach ($computer in $computerName) {
    $port = $TCPPort
    write-verbose "$computer`: Connecting on port $port"
    [Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}
    $req = [Net.HttpWebRequest]::Create("https://$computer`:$port/")
    $req.Timeout = $Timeoutms
    try {$req.GetResponse() | Out-Null} catch {write-error "Couldn't connect to $computer on port $port"; continue}
    if (!($req.ServicePoint.Certificate)) {write-error "No Certificate returned on $computer"; continue}
    $certinfo = $req.ServicePoint.Certificate

    $returnobj = [ordered]@{
        ComputerName = $computer;
        Port = $port;
        Subject = $certinfo.Subject;
        Thumbprint = $certinfo.GetCertHashString();
        Issuer = $certinfo.Issuer;
        SerialNumber = $certinfo.GetSerialNumberString();
        NotBefore = Convert-StringToDateTime $certinfo.GetEffectiveDateString();
        NotAfter = Convert-StringToDateTime $certinfo.GetExpirationDateString();
    }

    new-object PSCustomObject -Property $returnobj
} 
}
}

#
# Main Script
#
$ServicesFileName = CreateHtmFile
writeHtmlHeader $ServicesFileName

#Front Ends Certificate list
try
{
    #Cleaning Servers that are not reachable   
    Write-Host "`nTesting Front End Registrars Connectivity:" -ForegroundColor Yellow
    $FETestedServerList = TestServersConnectivity ($FEServerList)

    Write-Host "`nRetrieving Certificate information from the Front End Servers..." -ForegroundColor Yellow
    $RemoteFECertList = Invoke-Command -ComputerName $FETestedServerList -ScriptBlock {Get-CsCertificate -ErrorAction SilentlyContinue}
}
catch
{
    Write-Host
    Write-Host "Error Connecting to local server $FETestedServerList, Please verify connectivity and permissions" -ForegroundColor Red
    Continue
}

# EDGE Certificates list
if ($EdgeCertificates.IsPresent)
{
    try
    {
    
    #EDGE Certificates List
    Write-Host "`nTesting EDGE Connectivity:" -ForegroundColor Yellow
    $EDGETestedServerList = TestServersConnectivity ($EDGEServerList)
    
    }
    catch
    {
        Write-Host
        Write-Host "Error Connecting to local server $EDGEServer, Please verify connectivity and permissions" -ForegroundColor Red
    Continue
    }

      
    #Validating EDGE Connectivity
    Write-Host "`nVerifying EDGE Servers are configured as Trusted Hosts..." -ForegroundColor Yellow
    $TrustedHosts = Get-Item WSMan:\localhost\Client\TrustedHosts
    if ($TrustedHosts.Value -eq "*")
    {
       Write-Host "`nThe following Trusted Hosts are configured:`n" -ForegroundColor Yellow -NoNewline; Write-Host $TrustedHosts.Value
    }
    else
    {
        Write-Host "`nConfiguring the following Trusted Hosts:" -ForegroundColor Yellow -NoNewline; Write-Host " *" -ForegroundColor Green
        Set-Item WSMan:\localhost\Client\TrustedHosts -Value "*" -Force
    }

    
    $RemoteEdgeCertList = @()
    Write-Host "`nRetrieving Certificate information from the EDGE Servers..." -ForegroundColor Yellow

    foreach ($EDGEServer in $EDGETestedServerList)
    {
        try
        {
        $S = New-PSSession -ComputerName $EDGEServer -Port $PSRemoteConnectionPort -Credential (Get-Credential -Message "Please enter your Edge Server's credentials" $EDGEServer\administrator) -ErrorAction Ignore
        $RemoteEDGEServerCertList = Invoke-Command -Session $S -Scriptblock {Get-CsCertificate} -ErrorAction Ignore
        Remove-PSSession $S
        }
        catch
        {
          Write-Host "Error Connecting to local server $EDGEServer, Please verify connectivity and permissions" -ForegroundColor Red  
        }

        $RemoteEdgeCertList += $RemoteEDGEServerCertList
    }
}


#Office Web Apps Certificate List
if ($OWASCertificates.IsPresent)
{
    #Cleaning Servers that are not reachable   
    Write-Host "`nTesting Office Web Apps Connectivity:" -ForegroundColor Yellow
    $OWASTestedServerList = TestServersConnectivity ($OWASServerList)

    Write-Host "`nRetrieving Certificate information from the Office Web Apps Servers..." -ForegroundColor Yellow
        
    foreach ($OWASServer in $OWASTestedServerList)
    {
        try 
        {
            $Store = New-Object System.Security.Cryptography.X509Certificates.X509Store("$OWASServer\MY","LocalMachine") -ErrorAction Ignore
            $Store.Open("ReadOnly")
            $RemoteOWASCertList += $store.Certificates | Select-Object *,@{Name="PSComputerName";Expression={$OWASServer}} 

            #$TestCsAVConferenceObject = $Results_TestCsAVConference | Select-Object *,@{Name="TimeStamp";Expression={Get-Date -Format g}} 
        }
    # @debleaan - fixed the try/catch to be effective on each individual server, not to throw on the whole block if one server is not reachable
        catch
        {
            Write-Host
            Write-Host "Error Connecting to local server $OWASServer, Please verify connectivity and permissions" -ForegroundColor Red
            #Continue
        }
    }
}



#PSTN Gateways Cerificate List
if ($PSTNGatewayCertificates.IsPresent)
{

    $PSTNGatewaysList = Get-CsPool | where { $_.Services -like "*PstnGateway*" }
    Write-Host "`nRetrieving Certificate information from the PSTN Gateways..." -ForegroundColor Yellow
    # Not bothering to do any pre-checking, because this is really fast anyway
    $PSTNGatewaysCertList = $PSTNGatewaysList.identity | foreach { Get-SSLCertificate -ComputerName $_ -TCPPort 443 -ErrorAction SilentlyContinue }

}

#Setting Array for Uniqe Server Lists
#Yes, we really spelled it that way
#No, we will not change it
$UniqeFEServersList = @()
$UniqeEDGEServersList = @()
$UniqeOWASServersList = @()


foreach ($FEItem in $RemoteFECertList)
{
    $UniqeFEServersList += $FEItem.PSComputerName
}

foreach ($EdgeItem in $RemoteEdgeCertList)
{
    $UniqeEDGEServersList += $EdgeItem.PSComputerName
}

foreach ($OWASItem in $RemoteOWASCertList)
{
    $UniqeOWASServersList += $OWASItem.PSComputerName
}

$UniqeFEServersList = $UniqeFEServersList | Sort-Object -Unique
foreach ($Server in $UniqeFEServersList)
{       
        Add-Content $ServicesFileName "<table width='100%'><tbody>"
        Add-Content $ServicesFileName "<tr bgcolor='#0080FF'>"
        Add-Content $ServicesFileName "<td width='100%' align='center' colSpan=7><font face='segoe ui' color='#FFFFFF' size='2'><strong>$Server (Front End)</strong></font></td>"
        Add-Content $ServicesFileName "</tr>"
        WriteTableHeader $ServicesFileName
        foreach ($item in $RemoteFECertList)
        {
	      if ($item.PSComputerName -eq $Server)
            {
                writeServiceInfo $ServicesFileName $item.Use $item.Issuer $item.Thumbprint $item.Subject $item.NotBefore $item.NotAfter
            }
        }
}

$UniqeEDGEServersList = $UniqeEDGEServersList | Sort-Object -Unique
foreach ($EDGEServer in $UniqeEDGEServersList)
{       
        Add-Content $ServicesFileName "<table width='100%'><tbody>"
        Add-Content $ServicesFileName "<tr bgcolor='#0080FF'>"
        Add-Content $ServicesFileName "<td width='100%' align='center' colSpan=7><font face='segoe ui' color='#FFFFFF' size='2'><strong>$EDGEServer (EDGE)</strong></font></td>"
        Add-Content $ServicesFileName "</tr>"
        WriteTableHeader $ServicesFileName
        foreach ($item in $RemoteEdgeCertList)
        {
	      if ($item.PSComputerName -eq $EDGEServer)
            {
                writeServiceInfo $ServicesFileName $item.Use $item.Issuer $item.Thumbprint $item.Subject $item.NotBefore $item.NotAfter
            }
        }
}

$UniqeOWASServersList = $UniqeOWASServersList | Sort-Object -Unique
foreach ($Server in $UniqeOWASServersList)
{
        $OWASServerName = $Server.PSComputerName
        Add-Content $ServicesFileName "<table width='100%'><tbody>"
        Add-Content $ServicesFileName "<tr bgcolor='#0080FF'>"
        Add-Content $ServicesFileName "<td width='100%' align='center' colSpan=7><font face='segoe ui' color='#FFFFFF' size='2'><strong>$Server (Office Web Apps Server)</strong></font></td>"
        Add-Content $ServicesFileName "</tr>"
        WriteTableHeader $ServicesFileName

        foreach ($item in $RemoteOWASCertList)
        {
            if ($item.PSComputerName -eq $Server)
                {
                    writeServiceInfo $ServicesFileName $item.FriendlyName $item.Issuer $item.Thumbprint $item.Subject $item.NotBefore $item.NotAfter
                }
        }
}


foreach ($Cert in $PSTNGatewaysCertList)
{
        $Server = $Cert.ComputerName
        Add-Content $ServicesFileName "<table width='100%'><tbody>"
        Add-Content $ServicesFileName "<tr bgcolor='#0080FF'>"
        Add-Content $ServicesFileName "<td width='100%' align='center' colSpan=7><font face='segoe ui' color='#FFFFFF' size='2'><strong>$Server (PSTN Gateway)</strong></font></td>"
        Add-Content $ServicesFileName "</tr>"
        WriteTableHeader $ServicesFileName

        writeServiceInfo $ServicesFileName "Unfriendly Gateway" $Cert.Issuer $Cert.Thumbprint $Cert.Subject $Cert.NotBefore $Cert.NotAfter
}

#Adding Twitter Account for Feedback
Add-Content $ServicesFileName "</table>"
Add-Content $ServicesFileName "<table width='100%'><tbody>"		
Add-Content $ServicesFileName "<tr bgcolor='#D8D8D8'>"		
Add-Content $ServicesFileName "<td width='100%' align='center' colSpan=7><font face='segoe ui' color='#848484' size='1'>Script by <a href=https://twitter.com/guybachar target=_blank>Guy Bachar</a> and <a href=https://twitter.com/y0avb target=_blank>Yoav Barzilay</a></font></td>"		
Add-Content $ServicesFileName "</tr>"
Add-Content $ServicesFileName "</table>"

writeHtmlFooter $ServicesFileName

### Configuring Email Parameters
#sendEmail from@domain.com to@domain.com "Services State Report - $Date" SMTPS_ERVER $ServicesFileName

#Closing HTML
writeHtmlFooter $ServicesFileName

#Putting your old culture back - @texmandie
if ($CultureChanged)
{
    Set-Culture -CultureInfo $oldCulture.Name
}

Write-Host "`n`nThe File was generated at the following location: $ServicesFileName" -NoNewline; Write-Host "`nOpening file..." -ForegroundColor Cyan
Invoke-Item $ServicesFileName