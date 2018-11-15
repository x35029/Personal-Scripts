    <#
    .SYNOPSIS
        Check for Idle or Disconnected sessions on specified systems, with processes using CPU

    .DESCRIPTION
        Check for Idle or Disconnected sessions on specified systems, with processes using CPU

        Requires PowerShell remoting to be enabled on remote systems

        This has been tested against Server 2008 R2 systems with Windows Management Framework.
        I tried to code for PowerShell version 2; you are more than welcome to test this.

        Expected output for matching processes:
            UserName       : User associated with the process
            IdleTime       : Idle time (timespan)
            State          : Session state (e.g. Disc, Active)
            Name           : Process name
            CPUUseMax      : Maximum PercentProcessorTime seen from this process
            CPUTime        : CPU property from Get-Process, truncated
            Handles        : Handles property from Get-Process
            WS (MB)        : WS property from Get-Process, in MB
            PM (MB)        : PM property from Get-Process, in MB
            ExitCode       : Exitcode from Get-Process
            StartTime      : StartTime from Get-Process
            StandardError  : StandardError from Get-Process
            Id             : Id from from Get-Process (Process ID)
            SessionId      : Session ID from Query User
            PSComputerName : Remote computer this was found on
            RunspaceId     : Remnant

    .PARAMETER ComputerName
        Specify one or more systems to query

        PowerShell remoting must be enabled on these systems

    .PARAMETER CPUThreshold
        Look for processes with PercentProcessorTime greater than or equal to this number.

    .PARAMETER ProcessName
        Look for processes matching this process name.  Use * as a wildcard.

    .PARAMETER IdleTime
        Look for sessions idle longer than this many minutes

        Note: There is a better way to handle this, but we ignore sessions idle longer than 12 hours
              Ctrl+F $erroneousIdleTime ...

    .PARAMETER WMIIterations
        To find processes with CPU use, we search Win32_PerfFormattedData_PerfProc_Process

        Iterate this query this many times to cover varying CPU use.  Delay between queries is hard coded at 2 seconds.

    .EXAMPLE
    
        Get-EvilProcess -ComputerName Server14 -CPUThreshold 5 -ProcessName * -IdleTime 10 -WMIIterations 5

        #Check server14 for any processes with cpu use greater than 5%, from disconnected or idle (10 minutes) sessions, checking cpu 5 times.

    .EXAMPLE
    
        Get-EvilProcess -ComputerName $Servers -CPUThreshold 25 -ProcessName EMR* -IdleTime 30 -WMIIterations 15

        #Check all computers in $servers for processes named EMR*, with cpu use greater than 25%, from disconnected or idle (30 minutes) sessions, checking cpu 15 times.
    
    .FUNCTIONALITY
        General Command

    #>
    [cmdletbinding()]
    param( 
        [Parameter( Position=0,
            Mandatory=$true,
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true,
            ValueFromRemainingArguments=$false)]
        [string[]]$ComputerName,

        [int]$CPUThreshold = 25,

        [string]$ProcessName = "*",

        [int]$IdleTime = 30,

        [int]$WMIIterations = 5
    )
Begin
{
    $Servers = @()
}
Process
{
    foreach($computer in $computername)
    {
        $Servers += $computer
    }
}
End
{
#use psremoting, throttle at 150 sessions
Invoke-Command -ComputerName $Servers -ThrottleLimit 150 -ArgumentList $CPUThreshold, $ProcessName, $IdleTime, $WMIIterations -ScriptBlock {
    param($CPUthreshold, $ProcessName, $IdleTime, $WMIIterations)

    #region functions

        #We use Get-UserSession to parse session details.
        function Get-UserSession {
        <#  
        .SYNOPSIS  
            Retrieves all user sessions from local or remote computers(s)

        .DESCRIPTION
            Retrieves all user sessions from local or remote computer(s).
    
            Note:   Requires query.exe in order to run
            Note:   This works against Windows Vista and later systems provided the following registry value is in place
                    HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Terminal Server\AllowRemoteRPC = 1
            Note:   If query.exe takes longer than 15 seconds to return, an error is thrown and the next computername is processed.  Suppress this with -erroraction silentlycontinue
            Note:   If $sessions is empty, we return a warning saying no users.  Suppress this with -warningaction silentlycontinue

        .PARAMETER computername
            Name of computer(s) to run session query against
              
        .parameter parseIdleTime
            Parse idle time into a timespan object

        .parameter timeout
            Seconds to wait before ending query.exe process.  Helpful in situations where query.exe hangs due to the state of the remote system.
                    
        .FUNCTIONALITY
            Computers

        .EXAMPLE
            Get-usersession -computername "server1"

            Query all current user sessions on 'server1'

        .EXAMPLE
            Get-UserSession -computername $servers -parseIdleTime | ?{$_.idletime -gt [timespan]"1:00"} | ft -AutoSize

            Query all servers in the array $servers, parse idle time, check for idle time greater than 1 hour.

        .NOTES
            Thanks to Boe Prox for the ideas - http://learn-powershell.net/2010/11/01/quick-hit-find-currently-logged-on-users/

        .LINK
            http://gallery.technet.microsoft.com/Get-UserSessions-Parse-b4c97837

        #> 
            [cmdletbinding()]
            Param(
                [Parameter(
                    Position = 0,
                    ValueFromPipeline = $True)]
                [string[]]$ComputerName = "localhost",

                [switch]$ParseIdleTime,

                [validaterange(0,120)]
                [int]$Timeout = 15
            )             
            Process
            {
                ForEach($computer in $ComputerName)
                {
        
                    #start query.exe using .net and cmd /c.  We do this to avoid cases where query.exe hangs

                        #build temp file to store results.  Loop until we see the file
                            Try
                            {
                                $Started = Get-Date
                                $tempFile = [System.IO.Path]::GetTempFileName()
                        
                                Do{
                                    start-sleep -Milliseconds 300
                            
                                    if( ((Get-Date) - $Started).totalseconds -gt 10)
                                    {
                                        Throw "Timed out waiting for temp file '$TempFile'"
                                    }
                                }
                                Until(Test-Path -Path $tempfile)
                            }
                            Catch
                            {
                                Write-Error "Error for '$Computer': $_"
                                Continue
                            }

                        #Record date.  Start process to run query in cmd.  I use starttime independently of process starttime due to a few issues we ran into
                            $Started = Get-Date
                            $p = Start-Process -FilePath C:\windows\system32\cmd.exe -ArgumentList "/c query user /server:$computer > $tempfile" -WindowStyle hidden -passthru

                        #we can't read in info or else it will freeze.  We cant run waitforexit until we read the standard output, or we run into issues...
                        #handle timeouts on our own by watching hasexited
                            $stopprocessing = $false
                            do
                            {
                    
                                #check if process has exited
                                    $hasExited = $p.HasExited
                
                                #check if there is still a record of the process
                                    Try
                                    {
                                        $proc = Get-Process -id $p.id -ErrorAction stop
                                    }
                                    Catch
                                    {
                                        $proc = $null
                                    }

                                #sleep a bit
                                    start-sleep -seconds .5

                                #If we timed out and the process has not exited, kill the process
                                    if( ( (Get-Date) - $Started ).totalseconds -gt $timeout -and -not $hasExited -and $proc)
                                    {
                                        $p.kill()
                                        $stopprocessing = $true
                                        Remove-Item $tempfile -force
                                        Write-Error "$computer`: Query.exe took longer than $timeout seconds to execute"
                                    }
                            }
                            until($hasexited -or $stopProcessing -or -not $proc)
                    
                            if($stopprocessing)
                            {
                                Continue
                            }

                            #if we are still processing, read the output!
                                try
                                {
                                    $sessions = Get-Content $tempfile -ErrorAction stop
                                    Remove-Item $tempfile -force
                                }
                                catch
                                {
                                    Write-Error "Could not process results for '$computer' in '$tempfile': $_"
                                    continue
                                }
        
                    #handle no results
                    if($sessions){

                        1..($sessions.count - 1) | Foreach-Object {
            
                            #Start to build the custom object
                            $temp = "" | Select ComputerName, Username, SessionName, Id, State, IdleTime, LogonTime
                            $temp.ComputerName = $computer

                            #The output of query.exe is dynamic. 
                            #strings should be 82 chars by default, but could reach higher depending on idle time.
                            #we use arrays to handle the latter.

                            if($sessions[$_].length -gt 5){
                        
                                #if the length is normal, parse substrings
                                if($sessions[$_].length -le 82){
                           
                                    $temp.Username = $sessions[$_].Substring(1,22).trim()
                                    $temp.SessionName = $sessions[$_].Substring(23,19).trim()
                                    $temp.Id = $sessions[$_].Substring(42,4).trim()
                                    $temp.State = $sessions[$_].Substring(46,8).trim()
                                    $temp.IdleTime = $sessions[$_].Substring(54,11).trim()
                                    $logonTimeLength = $sessions[$_].length - 65
                                    try{
                                        $temp.LogonTime = Get-Date $sessions[$_].Substring(65,$logonTimeLength).trim() -ErrorAction stop
                                    }
                                    catch{
                                        #Cleaning up code, investigate reason behind this.  Long way of saying $null....
                                        $temp.LogonTime = $sessions[$_].Substring(65,$logonTimeLength).trim() | Out-Null
                                    }

                                }
                        
                                #Otherwise, create array and parse
                                else{                                       
                                    $array = $sessions[$_] -replace "\s+", " " -split " "
                                    $temp.Username = $array[1]
                
                                    #in some cases the array will be missing the session name.  array indices change
                                    if($array.count -lt 9){
                                        $temp.SessionName = ""
                                        $temp.Id = $array[2]
                                        $temp.State = $array[3]
                                        $temp.IdleTime = $array[4]
                                        try
                                        {
                                            $temp.LogonTime = Get-Date $($array[5] + " " + $array[6] + " " + $array[7]) -ErrorAction stop
                                        }
                                        catch
                                        {
                                            $temp.LogonTime = ($array[5] + " " + $array[6] + " " + $array[7]).trim()
                                        }
                                    }
                                    else{
                                        $temp.SessionName = $array[2]
                                        $temp.Id = $array[3]
                                        $temp.State = $array[4]
                                        $temp.IdleTime = $array[5]
                                        try
                                        {
                                            $temp.LogonTime = Get-Date $($array[6] + " " + $array[7] + " " + $array[8]) -ErrorAction stop
                                        }
                                        catch
                                        {
                                            $temp.LogonTime = ($array[6] + " " + $array[7] + " " + $array[8]).trim()
                                        }
                                    }
                                }

                                #if specified, parse idle time to timespan
                                if($parseIdleTime){
                                    $string = $temp.idletime
                
                                    #quick function to handle minutes or hours:minutes
                                    function Convert-ShortIdle {
                                        param($string)
                                        if($string -match "\:"){
                                            [timespan]$string
                                        }
                                        else{
                                            New-TimeSpan -Minutes $string
                                        }
                                    }
                
                                    #to the left of + is days
                                    if($string -match "\+"){
                                        $days = New-TimeSpan -days ($string -split "\+")[0]
                                        $hourMin = Convert-ShortIdle ($string -split "\+")[1]
                                        $temp.idletime = $days + $hourMin
                                    }
                                    #. means less than a minute
                                    elseif($string -like "." -or $string -like "none"){
                                        $temp.idletime = [timespan]"0:00"
                                    }
                                    #hours and minutes
                                    else{
                                        $temp.idletime = Convert-ShortIdle $string
                                    }
                                }
                
                                #Output the result
                                $temp
                            }
                        }
                    }            
                    else
                    {
                        Write-Warning "'$computer': No sessions found"
                    }
                }
            }
        }
    
    #endregion functions

    #region init
        
        $idleTime = New-TimeSpan -Minutes $IdleTime
        $erroneousIdleTime = New-TimeSpan -Hours 12

    #endregion init
    
    if($allSessions = Get-UserSession -computer localhost -parseIdleTime){

            #Get disconnected sessions
                $discSessionIDs = $null
                $discSessionIDs = $allSessions |
                    Where-Object {$_.state -like "Disc*" -and $_.id -ne 0 -and $_.username} |
                    Select-Object -ExpandProperty ID

            #Get idle sessions.  Keep username, id and idletime for logging purposes
                $idleSessions = $null
                $idleSessions = $allSessions |
                    Where-Object{ $_.idletime -gt $idleTime -and $_.idletime -lt $erroneousIdleTime } |
                    Select-Object username, id, idletime
        
            #poll WMI for high CPU (over $cputhreshold).  Do it several times, as these numbers vary wildly...
                $highCPUProcesses = 1..$WMIIterations | ForEach-Object {
                    
                    ([wmisearcher]"SELECT name, idprocess, PercentProcessorTime FROM Win32_PerfFormattedData_PerfProc_Process WHERE Name LIKE '$($ProcessName.replace("*","%"))' AND PercentProcessorTime >= $CPUthreshold").get() |
                            Where-Object { $_.idprocess -ne 0 } |
                            Select-Object PercentProcessorTime, IDProcess
            
                    Start-Sleep -Seconds 2

                }

            #Get unique process IDs...
                $highCPUProcessIDs = $highCPUProcesses | Select-Object -ExpandProperty IDProcess | Sort -Unique

            #Get processes once...
                if($discSessionIDs -or $idleSessions)
                {
                    $GetProcess = Get-Process -name $ProcessName
                }

            #find processes for disconnected sessions matching sessionID and pid for high cpu.
                $DisconnectedResults = $null
                if($discSessionIDs){
                    $DisconnectedResults = $GetProcess |
                        Where-Object{ $discSessionIDs -contains $_.SessionId -and $highCPUProcessIDs -contains $_.id }
                }

            #find processes for idle sessions with CPU greater than configured
                $IdleResults = $null
                if($idleSessions){
                    #create array of ids
                    $idleSessionIDs = $idleSessions | select -ExpandProperty id
                    $IdleResults = $GetProcess |
                        Where-Object{ $idleSessionIDs -contains $_.SessionId -and $highCPUProcessIDs -contains $_.id }
                }

            #Combine idle and disconnected results... Yes, there is a better way to do this : )
                $AllResults = @( @( $IdleResults ) + @( $DisconnectedResults ) ) | Where-Object {$_}

            #run against disconnected sessions
            if($allResults){

                foreach($Result in $allResults){
            
                    #get and add user info
                        $userInfo = $allSessions | Where-Object{ $_.id -eq $result.sessionid }
                        
                        $result | Add-Member -MemberType NoteProperty -name UserName -Value $userInfo.username -force
                        $result | Add-Member -MemberType NoteProperty -name IdleTime -value $userInfo.idletime -force
                        $result | Add-Member -MemberType NoteProperty -name State -value $userInfo.state -force

                    #get max cpu found over the iterations for this process id.  Feel free to remove this, add the average, etc...
                        Try
                        {
                            $maximumCPU = $null
                            $maximumCPU = $highCPUProcesses |
                                Where-Object{ $_.idprocess -eq $result.id } |
                                Measure-Object -Property PercentProcessorTime -maximum -ErrorAction stop |
                                Select-Object -ExpandProperty Maximum -ErrorAction stop
                        }
                        Catch
                        {
                            $maximumCPU = $null
                        }
                    
                        $result | Add-Member -MemberType NoteProperty -name CPUUseMax -Value $maximumCPU -force
            
                }
            }
                                  
            
            #display the results
            if($allResults){
                
                #filter by unique pid
                    $allResultsPIDs = $allResults | select -ExpandProperty ID | Sort -Unique

                #only display first result matching this PID
                    foreach($ProcessID in $allResultsPIDs){
                        $result = $allresults | Where-Object {$_.id -eq $ProcessID} | Select-Object -first 1
                        $result |
                            select UserName,
                                Idletime,
                                State,
                                Name,
                                CPUUseMax,
                                @{ label="CPUTime"; expression={[math]::truncate($_.cpu)} },
                                handles,
                                @{ label="WS (MB)"; expression={[math]::round($_.ws / 1MB, 2)} },
                                @{ label="PM (MB)"; expression={[math]::round($_.pm / 1MB, 2)} },
                                ExitCode,
                                StartTime,
                                StandardError,
                                Id,
                                SessionId
                    }
            }
    }
}
}