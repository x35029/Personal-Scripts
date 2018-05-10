$TimeStamp = Get-Date -UFormat "%Y-%m%-%d-%H-%M-%S"
$JOB = "InstalledHotFix"
$LOGLOCATION = "C:\Users\rodri\Dropbox\Dev\Logs\"
$LOG = $LOGLOCATION+$job+$TimeStamp+".log"

get-hotfix | Select HotfixID, Description,InstalledOn | Sort-Object -Property HotfixID >> $LOG