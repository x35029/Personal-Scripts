$waitstart = 60 
$waitshutdown = 60
cls
if ((get-vm).count -eq 0){ 
    Write-host 
    Write-host -foregroundcolor RED "Cannot Start VMs"     
    Write-host -foregroundcolor RED "PowerShell is not Running with Elevated Credentials" 
    Write-Host 
    Exit
} 
if ($args[1] -match "start") { 
    $inputfile=get-content $args[0] 
    foreach ($guest in $inputfile) { 
        write-host "Checking $guest"       
        if (Get-VM -name $guest){
            Switch((get-vm -name $guest).state){
                Running {
                    write-host "$guest is already running" -foregroundcolor yellow 
                }
                Starting { 
                    write-host "$guest is starting" -foregroundcolor yellow 
                    write-host "Please wait"
                    start-sleep -s $waitstart
                }
                Off {             
                    write-host "$Guest is Off. Starting..."
                    Start-VM -name $guest
                    start-sleep -s $waitstart 
                    write-host ""
                    if((get-vm -name $guest).state -eq 'Running'){
                        write-host "$guest is started" -foregroundcolor green
                    }
                    else{
                        write-host "$guest could not be started" -foregroundcolor red
                    }
                write-host "" 
                }
                default{
                    write-host "Could not determine $guest state" -foregroundcolor red
                }
            }
        } 
        else { 
            write-host "" 
            write-host "unable to find $guest" -foregroundcolor red 
            write-host "" 
        }
    }
    Exit
}
if ($args[1] -match "shutdown") { 
    $inputfile=get-content $args[0] 
    foreach ($guest in $inputfile) { 
        write-host "Shutting $guest down"       
        if (Get-VM -name $guest){
            Switch((get-vm -name $guest).state){
                Running {
                    write-host "$guest is Running. Shutting Down..."
                    Stop-VM -name $guest
                    start-sleep -s $waitshutdown 
                    write-host ""
                    if((get-vm -name $guest).state -eq 'Off'){
                        write-host "$guest is stopped" -foregroundcolor green
                    }
                    else{
                        write-host "$guest could not be stopped" -foregroundcolor red
                    }
                write-host "" 
                }
                Starting { 
                    write-host "$guest is starting" -foregroundcolor yellow
                    write-host "Please wait"
                    start-sleep -s $waitstart 
                }
                Off {             
                    
                }
                default{
                    write-host "Could not determine $guest state" -foregroundcolor red
                }
            }
        } 
        else { 
            write-host "" 
            write-host "unable to find $guest" -foregroundcolor red 
            write-host "" 
        }
    }
    Exit
}
else { 
    write-host "USAGE: to shutdown VMs," -nonewline; write-host ".\manageGuests.ps1 c:\guestList.txt shutdown" -foregroundcolor yellow 
    write-host "USAGE: to start VMs," -nonewline; write-host ".\manageGuests.ps1 c:\guestList.txt start" -foregroundcolor yellow 
    Exit
}