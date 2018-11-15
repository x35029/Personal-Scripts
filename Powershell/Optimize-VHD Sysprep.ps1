$vhdlist = get-childitem -path D:\Lab\VHD\Sysprep
foreach ($vhd in $vhdlist.name){
    write-host "D:\Lab\VHD\Sysprep\$vhd"
    optimize-vhd -path D:\Lab\VHD\Sysprep\$vhd -mode full
}