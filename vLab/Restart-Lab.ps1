$servers = @('DP01','W2K16','WEB01','SCCM01','SQL01','EDGE01','DC01')
foreach ($server in $servers){
    Restart-Computer -ComputerName $server -Force -Wait
}