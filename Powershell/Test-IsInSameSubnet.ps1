function Get-BroadcastAddress {
    param (
        [IpAddress]$ip,
        [IpAddress]$Mask
    )
 
    $IpAddressBytes = $ip.GetAddressBytes()
    $SubnetMaskBytes = $Mask.GetAddressBytes()
 
    if ($IpAddressBytes.Length -ne $SubnetMaskBytes.Length) {
        throw "Lengths of IP address and subnet mask do not match."
        exit 0
    }
 
    $BroadcastAddress = @()
 
    for ($i=0;$i -le 3;$i++) {
        $a = $subnetMaskBytes[$i] -bxor 255
        if ($a -eq 0) {
            $BroadcastAddress += $ipAddressBytes[$i]
        }
        else {
            $BroadcastAddress += $a
        }
    }
 
    $BroadcastAddressString = $BroadcastAddress -Join "."
    return [IpAddress]$BroadcastAddressString
}
 
function Get-NetwotkAddress {
    param (
        [IpAddress]$ip,
        [IpAddress]$Mask
    )
 
    $IpAddressBytes = $ip.GetAddressBytes()
    $SubnetMaskBytes = $Mask.GetAddressBytes()
 
    if ($IpAddressBytes.Length -ne $SubnetMaskBytes.Length) {
        throw "Lengths of IP address and subnet mask do not match."
        exit 0
    }
 
    $BroadcastAddress = @()
 
    for ($i=0;$i -le 3;$i++) {
        $BroadcastAddress += $ipAddressBytes[$i]-band $subnetMaskBytes[$i]
 
    }
 
    $BroadcastAddressString = $BroadcastAddress -Join "."
    return [IpAddress]$BroadcastAddressString
}
 
function Test-IsInSameSubnet {
    param (
        [IpAddress]$ip1,
        [IpAddress]$ip2,
        [IpAddress]$mask
    )
 
    $Network1 = Get-NetwotkAddress -ip $ip1 -mask $mask
    $Network2 = Get-NetwotkAddress -ip $ip2 -mask $mask
 
    return $Network1.Equals($Network2)
}






Test-IsInSameSubnet -ip1 192.168.0.12 -ip2 172.16.0.234 -mask 255.255.255.0
Test-IsInSameSubnet -ip1 192.168.0.12 -ip2 192.168.0.13 -mask 255.255.255.128

