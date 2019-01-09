cls

#Dumps Microsoft Security Update Info

$currentSecUpdate = Get-MsrcSecurityUpdate | select -Last 1

<#
ID                 : 2019-Jan
Alias              : 2019-Jan
DocumentTitle      : January 2019 Security Updates
Severity           : 
InitialReleaseDate : 2019-01-08T16:00:00Z
CurrentReleaseDate : 2019-01-08T16:00:00Z
CvrfUrl            : https://api.msrc.microsoft.com/cvrf/2019-Jan?api-Version=2016-08-01
#>

Write-Host "Security Buletin Title       : "$currentSecUpdate.DocumentTitle
Write-Host "Security Buletin ID          : "$currentSecUpdate.ID
Write-Host "Security Buletin Release Date: "$currentSecUpdate.InitialReleaseDate
Write-Host "Security Buletin URL         : "$currentSecUpdate.CvrfUrl

$currentBulletin = Get-MsrcCvrfDocument -ID $currentSecUpdate.ID

<#
DocumentTitle     : @{Value=January 2019 Security Updates}
DocumentType      : @{Value=Security Update}
DocumentPublisher : @{ContactDetails=; IssuingAuthority=; Type=0}
DocumentTracking  : @{Identification=; Status=2; Version=1.0; RevisionHistory=System.Object[]; InitialReleaseDate=2019-01-08T08:00:00; 
                    CurrentReleaseDate=2019-01-08T08:00:00}
DocumentNotes     : {@{Title=Release Notes; Audience=Public; Type=1; Ordinal=1; Value=<p>The January security release consists of security updates for the following 
                    software:</p>
                    <ul>
                    <li>Adobe Flash Player</li>
                    <li>Internet Explorer</li>
                    <li>Microsoft Edge</li>
                    <li>Microsoft Windows</li>
                    <li>Microsoft Office and Microsoft Office Services and Web Apps</li>
                    <li>ChakraCore</li>
                    <li>.NET Framework</li>
                    <li>ASP.NET</li>
                    <li>Microsoft Exchange Server</li>
                    <li>Microsoft Visual Studio</li>
                    </ul>
                    <p>Please note the following information regarding the security updates:</p>
                    <ul>
                    <li>A list of the latest servicing stack updates for each operating system can be found in <a 
                    href="https://portal.msrc.microsoft.com/en-us/security-guidance/advisory/ADV990001">ADV990001</a>. This list will be updated whenever a new 
                    servicing stack update is released. It is important to install the latest servicing stack update.</li>
                    <li>Windows 10 updates are cumulative. The monthly security release includes all security fixes for vulnerabilities that affect Windows 10, in 
                    addition to non-security updates. The updates are available via the <a href="http://catalog.update.microsoft.com/v7/site/Home.aspx">Microsoft 
                    Update Catalog</a>.</li>
                    <li>Updates for Windows RT 8.1 and Microsoft Office RT software are only available via <a 
                    href="http://go.microsoft.com/fwlink/?LinkId=21130">Windows Update</a>.</li>
                    <li>For information on lifecycle and support dates for Windows 10 operating systems, please see <a 
                    href="https://support.microsoft.com/en-us/help/13853/windows-lifecycle-fact-sheet">Windows Lifecycle Facts Sheet</a>.</li>
                    <li>In addition to security changes for the vulnerabilities, updates include defense-in-depth updates to help improve security-related 
                    features.</li>
                    </ul>
                    <p><strong>The following CVEs have FAQs with additional information and may include * further steps to take after installing the 
                    updates.</strong></p>
                    <ul>
                    <li><a href="https://portal.msrc.microsoft.com/en-us/security-guidance/advisory/ADV190001">ADV190001</a></li>
                    <li><a href="https://portal.msrc.microsoft.com/en-us/security-guidance/advisory/CVE-2019-0536">CVE-2019-0536</a></li>
                    <li><a href="https://portal.msrc.microsoft.com/en-us/security-guidance/advisory/CVE-2019-0537">CVE-2019-0537</a></li>
                    <li><a href="https://portal.msrc.microsoft.com/en-us/security-guidance/advisory/CVE-2019-0545">CVE-2019-0545</a></li>
                    <li><a href="https://portal.msrc.microsoft.com/en-us/security-guidance/advisory/CVE-2019-0549">CVE-2019-0549</a></li>
                    <li><a href="https://portal.msrc.microsoft.com/en-us/security-guidance/advisory/CVE-2019-0553">CVE-2019-0553</a></li>
                    <li><a href="https://portal.msrc.microsoft.com/en-us/security-guidance/advisory/CVE-2019-0554">CVE-2019-0554</a></li>
                    <li><a href="https://portal.msrc.microsoft.com/en-us/security-guidance/advisory/CVE-2019-0559">CVE-2019-0559</a></li>
                    <li><a href="https://portal.msrc.microsoft.com/en-us/security-guidance/advisory/CVE-2019-0560">CVE-2019-0560</a></li>
                    <li><a href="https://portal.msrc.microsoft.com/en-us/security-guidance/advisory/CVE-2019-0561">CVE-2019-0561</a></li>
                    <li><a href="https://portal.msrc.microsoft.com/en-us/security-guidance/advisory/CVE-2019-0569">CVE-2019-0569</a></li>
                    <li><a href="https://portal.msrc.microsoft.com/en-us/security-guidance/advisory/CVE-2019-0585">CVE-2019-0585</a></li>
                    <li><a href="https://portal.msrc.microsoft.com/en-us/security-guidance/advisory/CVE-2019-0588">CVE-2019-0588</a></li>
                    </ul>
                    <p><strong>Known Issues</strong></p>
                    <ul>
                    <li><a href="https://support.microsoft.com/en-us/help/4480961">4480961</a></li>
                    <li><a href="https://support.microsoft.com/en-us/help/4480973">4480973</a></li>
                    <li><a href="https://support.microsoft.com/en-us/help/4480978">4480978</a></li>
                    <li><a href="https://support.microsoft.com/en-us/help/4480966">4480966</a></li>
                    <li><a href="https://support.microsoft.com/en-us/help/4480970">4480970</a></li>
                    <li><a href="https://support.microsoft.com/en-us/help/4480116">4480116</a></li>
                    <li><a href="https://support.microsoft.com/en-us/help/4480962">4480962</a></li>
                    <li><a href="https://support.microsoft.com/en-us/help/4480963">4480963</a></li>
                    <li><a href="https://support.microsoft.com/en-us/help/4480975">4480975</a></li>
                    <li><a href="https://support.microsoft.com/en-us/help/4468742">4468742</a></li>
                    <li><a href="https://support.microsoft.com/en-us/help/4471389">4471389</a></li>
                    </ul>
                    }, @{Title=Legal Disclaimer; Audience=Public; Type=5; Ordinal=2; Value=The information provided in the Microsoft Knowledge Base is provided "as is" 
                    without warranty of any kind. Microsoft disclaims all warranties, either express or implied, including the warranties of merchantability and 
                    fitness for a particular purpose. In no event shall Microsoft Corporation or its suppliers be liable for any damages whatsoever including direct, 
                    indirect, incidental, consequential, loss of business profits or special damages, even if Microsoft Corporation or its suppliers have been advised 
                    of the possibility of such damages. Some states do not allow the exclusion or limitation of liability for consequential or incidental damages so 
                    the foregoing limitation may not apply.}}
ProductTree       : @{Branch=System.Object[]; FullProductName=System.Object[]}
Vulnerability     : {@{Title=; Notes=System.Object[]; DiscoveryDateSpecified=False; ReleaseDateSpecified=False; CVE=CVE-2019-0538; ProductStatuses=System.Object[]; 
                    Threats=System.Object[]; CVSSScoreSets=System.Object[]; Remediations=System.Object[]; Acknowledgments=System.Object[]; Ordinal=1; 
                    RevisionHistory=System.Object[]}, @{Title=; Notes=System.Object[]; DiscoveryDateSpecified=False; ReleaseDateSpecified=False; CVE=CVE-2019-0536; 
                    ProductStatuses=System.Object[]; Threats=System.Object[]; CVSSScoreSets=System.Object[]; Remediations=System.Object[]; 
                    Acknowledgments=System.Object[]; Ordinal=2; RevisionHistory=System.Object[]}, @{Title=; Notes=System.Object[]; DiscoveryDateSpecified=False; 
                    ReleaseDateSpecified=False; CVE=CVE-2019-0585; ProductStatuses=System.Object[]; Threats=System.Object[]; CVSSScoreSets=System.Object[]; 
                    Remediations=System.Object[]; Acknowledgments=System.Object[]; Ordinal=3; RevisionHistory=System.Object[]}, @{Title=; Notes=System.Object[]; 
                    DiscoveryDateSpecified=False; ReleaseDateSpecified=False; CVE=ADV990001; ProductStatuses=System.Object[]; Threats=System.Object[]; 
                    CVSSScoreSets=System.Object[]; Remediations=System.Object[]; Acknowledgments=System.Object[]; Ordinal=4; RevisionHistory=System.Object[]}...}
#>

($currentBulletin | Select -ExpandProperty DocumentNotes).Value
cls
# Categories and Products
$catAndProd = ($currentBulletin | Select -ExpandProperty ProductTree | Select -ExpandProperty Branch| Select -ExpandProperty Items) 
$aCategoryAndProducts = @()
foreach ($cat in $catAndProd){
    foreach ($prod in $cat.Items){
        $oCatAndProd = New-Object psobject
        Add-Member -InputObject $oCatAndProd -MemberType NoteProperty -Name Category -Value $cat.Name
        Add-Member -InputObject $oCatAndProd -MemberType NoteProperty -Name ProductID -Value $prod.ProductID
        Add-Member -InputObject $oCatAndProd -MemberType NoteProperty -Name ProductName -Value $prod.Value
        if (($cat.Name -ne "Exchange Server") -and
            ($prod.Value  -notlike "*ARM*")  -and
            ($prod.Value  -notlike "*Server*")   -and
            ($prod.Value  -notlike "*Windows RT*") -and
            ($prod.Value  -notlike "*Sharepoint*")  -and
            ($prod.Value  -notlike "*2013 RT*") -and
            ($prod.Value  -notlike "*for Mac*") -and
            ($prod.Value  -notlike "*Windows 10 for*") -and
            ($prod.Value  -notlike "*Core*") -and
            ($prod.Value  -notlike "*32-bit Systems") -and
            ($prod.Value  -notlike "*Android*") 
           ){        
            $aCategoryAndProducts += $oCatAndProd
        }
    }
}
#$aCategoryAndProducts | Sort Category,ProductName
$vulnerabilities = $currentBulletin | Select -ExpandProperty Vulnerability
foreach ($vulnerability in $vulnerabilities){    
    Write-Host "============================================================================================================"
    $vulnerability
    Write-Host "Title......: " $vulnerability.Title.Value
    $vulDescription = ((($vulnerability.Notes | Where-Object {$_.Title -eq "Description"}).Value) -replace "<p>","") -replace "</p>","`n"
    Write-Host "Description: " $vulDescription
    Write-Host "CVE........: " $vulnerability.CVE
    Write-Host "Max CVSS Score:"($vulnerability.CVSSScoreSets.BaseScore | Measure-Object -Maximum).Maximum
    foreach ($remediation in $vulnerability.Remediations){
        foreach ($prodID in ($vulnerability.ProductStatuses).ProductID){
            foreach ($obj in $aCategoryAndProducts){
                if ($obj.ProductID -eq $remediation.ProductID){
                    Write-Host "$($obj.Category) - $($obj.ProductName) - $($remediation.Description.Value) - $($remediation.URL)"
                }
            }
        }
    }
    Write-Host "Impacted Products:"

    foreach ($prodID in ($vulnerability.ProductStatuses).ProductID){
        foreach ($obj in $aCategoryAndProducts){
            if ($obj.ProductID -eq $prodID){
                Write-Host "$($obj.Category) - $($obj.ProductName)"
            }
        }
    }
    Write-Host
    Write-Host
    pause
}