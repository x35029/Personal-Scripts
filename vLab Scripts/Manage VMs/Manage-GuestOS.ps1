Param
(
    [Parameter(Mandatory=$true, 
                Position=0)]
    [ValidateNotNull()]
    [ValidateSet("start", "shutdown", "save")]
    $action
)

#Constants
    <#
    Set-Variable -name waitstart = 120  -Option Constant
    Set-Variable -name waitshutdown = 30 -Option Constant
    Set-Variable -name waitsave = 20 -Option Constant
    #>
    Set-Variable -name timeout -Option Constant



#global Variables
    Set-Variable -name guestList -Scope Global
    Set-Variable -name guestName -Scope Global

#functions

    Function Get-VMGuestList ($listpath) {        
        if($listpath -eq $Null) {
            Write-Host "Loading all Host Guest VMs"            
            return Get-VM | Select -ExpandProperty Name
        }
        elseif(test-path($listpath)){
            Write-Host "Reading file",$listpath               
            return get-content $listpath
            }    
        else {
            Write-Host "File path not valid"  
        }
    }
    
    function Wait-VM ($guestName){
        $counter=0        
        write-host "Action $action"
        
        switch ($action) {            
            START {
                while (((get-vm -name $guestName).heartbeat -ne "OkApplicationsHealthy") -and !($counter -eq $timeout)){ 
                    sleep -s 10
                    $counter += 10                    
                    $time = get-date -format hh:mm:ss
                    Write-host "$time -> $GuestName Heartbeat: $((get-vm -name $guestName).Heartbeat)"
                }
                if ($timeout -eq 120){
                    write-host -foregroundcolor RED "$guestName failed to start due to timeout"
                    return 1
                } 
                else {
                    write-host "    $guestName is started" -foregroundcolor green      
                    return 0                               
                }
            }
            SHUTDOWN {
                 while (((get-vm -name $guestName).heartbeat -ne "NoContact") -and !($counter -eq $timeout)){ 
                    sleep -s 10
                    $counter += 10
                    $time = get-date -format hh:mm:ss
                    Write-host "$time -> $GuestName Heartbeat: $((get-vm -name $guestName).Heartbeat)"
                }
                if ($timeout -eq 120){
                    write-host -foregroundcolor RED "$guestName failed to shutdown due to timeout"
                    return 1
                } 
                else {
                    write-host "    $guestName is started" -foregroundcolor green      
                    return 0                               
                }
            }
            SAVE {        
                while (((get-vm -name $guestName).heartbeat -ne "NoContact") -and !($counter -eq $timeout)){ 
                    sleep -s 10
                    $counter += 10
                    $time = get-date -format hh:mm:ss
                    Write-host "$time -> $GuestName Heartbeat: $((get-vm -name $guestName).Heartbeat)"
                }
                if ($timeout -eq 120){
                    write-host -foregroundcolor RED "$guestName failed to save due to timeout"
                    return 1
                } 
                else {
                    write-host "    $guestName is started" -foregroundcolor green      
                    return 0                               
                }
            }
            default {
                write-host -foregroundcolor RED "Action $action is not coded. No action taken on VM."
            }            
        }#>
    }
#cls
if ((get-vm).count -eq 0){ 
    Write-host 
    Write-host -foregroundcolor RED "Cannot Start VMs - Access Denied"     
    Write-host -foregroundcolor RED "     PowerShell is not Running with Elevated Credentials or there are no VMs in this Host" 
    Exit
}
else{
    write-host "Powershell running with elevated access and VMs were found to be managed."
    write-host "Proceeding..."
    #write-host "Arguments Count: ",$args.count
    <#if (($args.Count -lt 1) -or ($args.Count -gt 2)){
        Write-host 
        Write-host -foregroundcolor RED "USAGE:"
        Write-Host
        Write-host -foregroundcolor RED "./manageGuestOs.ps1 ACTION [VM_Order]"
        Write-Host
        Write-host -foregroundcolor RED "     ACTION ->"
        Write-host -foregroundcolor RED "          START -> Start VMs"
        Write-host -foregroundcolor RED "          SHUTDOWN -> Shutdowntart VMs"
        Write-host -foregroundcolor RED "          SAVE -> Save VMs"
        Write-Host
        Write-host -foregroundcolor RED "     [VM_Order] -> TXT File in the same folder as the ps1 script, with a list of VMs to be started in order"
        Write-Host
    } 
    else{#>
        Switch ($action){
            START {                
                $guestList = Get-VMGuestList                
                foreach ($guestName in $guestList) {                 
                    write-host "Checking VM: $guestName"   
                    Get-VM -name $guestName    
                    if (Get-VM -name $guestName){
                        Switch((get-vm -name $guestName).state){
                            Running {
                                write-host "    VM Status is Running"
                                write-host "    $guestName is already running" -foregroundcolor yellow
                                write-host
                            }
                            Starting { 
                                write-host "    VM Status is Starting"
                                write-host "    $guestName is starting" -foregroundcolor yellow 
                                write-host "    Please wait"
                                Wait-VM ($guestName,$action)
                            }
                            Saved {             
                                write-host "    VM Status is Saved"
                                write-host "    $guestName is Saved. Starting..."
                                Start-VM -name $guestName
                                $counter = 0
                                Wait-VM ($guestName,$action)
                            }
                            Off {             
                                write-host "    VM Status is Off"
                                write-host "    $guestName is Off. Starting..."
                                Start-VM -name $guestName
                                $counter = 0
                                Wait-VM ($guestName,$action)
                            write-host "" 
                            }
                            default{
                                write-host "default"
                                write-host "    Could not determine $guestName state" -foregroundcolor red
                                write-host "    No action was taken" -foregroundcolor red
                                write-host ""
                            }
                        }
                    } 
                    else { 
                        write-host "" 
                        write-host "    Unable to find $guestName" -foregroundcolor red 
                        write-host "" 
                    }
                }            
        }
            SHUTDOWN{ 
                $guestList = Get-VMGuestList 
                foreach ($guestName in $guestList) { 
                    write-host "Checking VM: $guestName"       
                    if (Get-VM -name $guestName){
                        Switch((get-vm -name $guestName).state){
                            Running {
                                write-host "$guestName is Running. Shutting Down..."
                                Stop-VM -name $guestName
                                Wait-VM ($guestName,$action)
                            }
                            Starting { 
                                write-host "$guestName is starting" -foregroundcolor yellow
                                write-host "Please wait start to complete before shutting down"
                                write-host ""                              
                            }
                            Saved {             
                                write-host "$guestName is already Saved"   
                                write-host "" 
                            }
                            Off {             
                                write-host "$guestName is already Off"   
                                write-host "" 
                            }
                            default{
                                write-host "Could not determine $guestName state" -foregroundcolor red
                                Write-Host ""
                            }
                        }
                    } 
                    else { 
                        write-host "" 
                        write-host "unable to find $guestName" -foregroundcolor red 
                        write-host "" 
                    }
                }    
            }
            SAVE { 
                $guestList = Get-VMGuestList 
                foreach ($guestName in $guestList) {                 
                    write-host "Checking $guestName"       
                    if (Get-VM -name $guestName){
                        Switch((get-vm -name $guestName).state){
                            Running {
                                write-host "$guestName is Running. Saving..."
                                Save-VM -name $guestName
                                Wait-VM ($guestName,$action)
                                write-host "" 
                            }
                            Starting { 
                                write-host "$guestName is starting" -foregroundcolor yellow
                                write-host "Please wait start to complete before saving"
                                write-host ""
                            }
                            Saved {             
                                write-host "$guestName is already Saved"   
                                write-host "" 
                            }
                            Off {             
                                write-host "$guestName is already Off"   
                                write-host "" 
                            }
                            default{
                                write-host "Could not determine $guestName state" -foregroundcolor red
                                Write-Host ""
                            }
                        }
                    } 
                    else { 
                        write-host "" 
                        write-host "unable to find $guestName" -foregroundcolor red 
                        write-host "" 
                    }
                }    
        }            
        }
    }
#}
#Pause