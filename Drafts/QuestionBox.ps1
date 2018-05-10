Add-Type -AssemblyName PresentationCore,PresentationFramework
$ButtonType = [System.Windows.MessageBoxButton]::YesNoCancel# OK // OKCancel // YesNo // YesNoCancel
$MessageIcon = [System.Windows.MessageBoxImage]::Stop # Asterisk // Error // Exclamation // Hand // Information	// None	// Question	// Stop	//Warning
$MessageBody = "Are you sure you want to delete the log file?"
$MessageTitle = "Confirm Deletion"
 
$Result = [System.Windows.MessageBox]::Show($MessageBody,$MessageTitle,$ButtonType,$MessageIcon) # https://msdn.microsoft.com/en-us/library/system.windows.messagebox(v=vs.110).aspx?cs-save-lang=1&cs-lang=vb#code-snippet-1
 
Write-Host "Your choice is $Result"

$Result = [System.Windows.MessageBox]::Show() # https://msdn.microsoft.com/en-us/library/system.windows.messagebox(v=vs.110).aspx?cs-save-lang=1&cs-lang=vb#code-snippet-1 
