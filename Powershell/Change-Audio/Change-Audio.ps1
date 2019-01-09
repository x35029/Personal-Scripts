Import-Module AudioDeviceCmdlets
$audioDevices = Get-AudioDevice -List | Where-Object -Property Type -eq "Playback" 
$currentAudioDevice = $audioDevices | Where-Object -Property Default -eq True
$currentAudioDevice.Index
if ($currentAudioDevice.Index -eq 1){
    Set-AudioDevice -Index 2    
}
else{
    Set-AudioDevice -Index 1
}