# http://blogs.msdn.com/b/timid/archive/2013/04/23/certificate-chains.aspx

function Get-RemoteComputerCertificates { 
     <# 
     .synopsis 
     Return list of X.509 certificates on specified host. 
  
     .description 
     Uses .NET methods to open specified X.509 certificate store (specified by -store and -location) on a computer (specified by -ComputerName), then returns all certificates contained in that store as X509Certificate2 objects. 
  
     .parameter ComputerName 
     Computer from which to extract certificates.  Defaults to localhost. 
  
     .parameter store 
     X.509 certificate store.  Defaults to 'My'. 
  
     .parameter location 
     Location of X.509 certificate store.  Defaults to 'LocalComputer'.  Only other valid value is 'CurrentUser'. 
  
     .parameter help 
     Show this text and exit. 
  
     .Inputs 
     [String] Computername. 
  
     .Outputs 
     [X509Certificate2[]] X.509 certificates. 
  
     .Link 
     http://msdn.microsoft.com/en-us/library/system.security.cryptography.x509certificates.storename.aspx 
     http://msdn.microsoft.com/en-us/library/system.security.cryptography.x509certificates.storelocation.aspx 
     #> 
  
     param ( 
         [Parameter(ValueFromPipeline=$true,Position=0)][string[]]$ComputerName = $env:COMPUTERNAME, 
         [string]$store = 'My', 
         [string]$location = 'LocalMachine', 
         [switch]$help 
     ); 
  
     begin { 
         if ($help) { Get-Help Get-RemoteComputerCertificates -full | more; break; } 
     } 
     process { 
         try { 
             $ComputerName | % { 
                 $myComputer = $_; 
                 $x509Store = New-Object System.Security.Cryptography.X509Certificates.X509Store("\\$myComputer\$store", 
                     [System.Security.Cryptography.X509Certificates.StoreLocation]$location); 
      
                 if ($x509Store) { 
                     $x509Store.Open([System.Security.Cryptography.X509Certificates.OpenFlags]"ReadOnly"); 
                     $x509Store.Certificates |
                     % {
                         Add-Member -InputObject $_ -MemberType NoteProperty -Name ComputerName -Value $myComputer;
                         $_;
                     } 
                     $x509Store.Close(); 

                 } else { 
                     Write-Warning "Unable to get certificates from computer $myComputer."; 
                 } 
             } 
         } 
         catch [Exception] { 
             Write-Warning "Unable to open location '$location' on \\$myComputer\$store"; 
             #break; 
         } 
     } 
} 

function Get-CertificateTrustChain { 
     <# 
     .synopsis 
     Returns list of X.509 certificates for specified X.509 certificate and trust chain. 
  
     .description 
     Uses .NET methods to build a trust chain for the specified X.509 certificate.  The chain is returned as an array of certificates. The first element of the array is the specified X.509 certificate itself.  The last element is the root CA (e.g.: GTE CyberTrust) 
  
     .parameter certificate 
     Certificate for which to validate the trust chain.  The value can be either a path to a file, or an X509 object. 
  
     .parameter help 
     Show this text and exit. 
  
     .Inputs 
     [object] Certificate 
  
     .Outputs 
     [X509Certificate2[]] X.509 certificates. 
  
     .Link 
     http://msdn.microsoft.com/en-us/library/vstudio/system.security.cryptography.x509certificates.x509chain.build.aspx 
     http://msdn.microsoft.com/en-us/library/vstudio/system.security.cryptography.x509certificates.x509chain.chainelements.aspx 
     #> 
  
     param ( 
         [Parameter(ValueFromPipeline=$true,Position=0)][Object]$certificate, 
         [switch]$help 
     ); 
     begin { 
         if ($help) { Get-Help Get-CertificateTrustChain -Full | more; return; } 
         $chain = New-Object System.Security.Cryptography.X509Certificates.X509Chain; 
  
     } 
  
     process { 
         if ($certificate -is [System.Security.Cryptography.X509Certificates.X509Certificate2]) { 
             #noop 
         } elseif (Test-Path $certificate) { 
             try { 
                 $certificate = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2 $certificate; 
             } 
             catch [Exception]{ 
                 Write-Warning "Unable to cast path '$certificate' to X509Certificate2 object."; 
                 $cert = $null; 
             } 
         } 
         if ($certificate) { 
             Write-Progress -Activity "Building trust chain for" -Status ("$($certificate.Subject) ($($certificate.Thumbprint))"); 
             $chain.Build($certificate) | Out-Null; 
             if ( $chain.ChainElements ) { 
                 $chain.ChainElements | % { $_.Certificate; } 
             } else { 
                 Write-Warning "Unable to verify certificate chain for certificate with thumbprint $($certificate.Thumbprint)." 
             } 
         } 
     } 
} 
  
function Get-RemoteComputerCertificateRootCAs { 
     <# 
     .synopsis 
     Returns list of X.509 certificates for specified computer and the root CA for each. 
  
     .description 
     Uses .NET methods to open the LocalMachine Personal (a.k.a. 'My') X.509 certificate store, return each certificate's thumbprint, subject, and the issuing root CA (certificate authority). 
  
    .parameter ComputerName 
    Computer from which to extract certificates.  Defaults to localhost. 
  
    .parameter help 
    Show this text and exit. 
  
    .Inputs 
    [String] Computername. 
  
    .Outputs 
    [Selected...X509Certificate2[]] Contains only NoteProperty data for 
    Computer - Computer being inspected. 
    Thumbprint - Thumbprint of certificate found on computer. 
    Subject - Subject of certificate found on computer. 
    RootCA - Subject of Root CA for certificate found on computer. 
  
    .Link 
    http://msdn.microsoft.com/en-us/library/system.security.cryptography.x509certificates.storename.aspx 
    http://msdn.microsoft.com/en-us/library/system.security.cryptography.x509certificates.storelocation.aspx 
    http://msdn.microsoft.com/en-us/library/vstudio/system.security.cryptography.x509certificates.x509chain.build.aspx 
    http://msdn.microsoft.com/en-us/library/vstudio/system.security.cryptography.x509certificates.x509chain.chainelements.aspx 
    #> 
    param ( 
        [Parameter(ValueFromPipeline=$true,Position=0)][string[]]$ComputerName = $env:COMPUTERNAME, 
        [switch]$help 
    ); 
  
    begin { 
        if ($help) { Get-Help Get-RemoteComputerCertificates -full | more; break; } 
    } 
    process { 
        $ComputerName | % { 
            $myComputer = $_; 
            Get-RemoteComputerCertificates $myComputer | Select-Object -Property @{ 
                n = 'Computer'; 
                e = { $myComputer; } 
            }, Thumbprint, Subject, @{ 
                n = 'RootCA'; 
                 e = { 
                     [Object[]]$CAs = Get-CertificateTrustChain $_; 
                     if ($CAs) { 
                         if ($rootCA = $CAs[$CAs.Count - 1].Subject) { $rootCA; } else { "UNKNOWN"; } 
                     }  
                     else { 
                         "UNKNOWN"; 
                     } 
                 } 
             }  
         } 
     } 
}
