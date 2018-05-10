# https://social.technet.microsoft.com/Forums/office/en-US/97017441-6a0a-46be-8986-192eadf1f130/running-progressbar-on-powershellgui-systemwindowsforms-when-form-loaded?forum=winserverpowershell

Function StartProgressBar
{
	if($i -le 5){
	    $pbrTest.Value = $i
	    $script:i += 1
	}
	else {
		$timer.enabled = $false
	}
	
}

$Form = New-Object System.Windows.Forms.Form
$Form.width = 400
$Form.height = 600
$Form.Text = "Add Resource"

# Init ProgressBar
$pbrTest = New-Object System.Windows.Forms.ProgressBar
$pbrTest.Maximum = 100
$pbrTest.Minimum = 0
$pbrTest.Location = new-object System.Drawing.Size(10,10)
$pbrTest.size = new-object System.Drawing.Size(100,50)
$i = 0
$Form.Controls.Add($pbrTest)

# Button
$btnConfirm = new-object System.Windows.Forms.Button
$btnConfirm.Location = new-object System.Drawing.Size(120,10)
$btnConfirm.Size = new-object System.Drawing.Size(100,30)
$btnConfirm.Text = "Start Progress"
$Form.Controls.Add($btnConfirm)

$timer = New-Object System.Windows.Forms.Timer 
$timer.Interval = 1000

$timer.add_Tick({
StartProgressBar
})

$timer.Enabled = $true
$timer.Start()

# Button Click Event to Run ProgressBar
$btnConfirm.Add_Click({
    
    While ($i -le 100) {
        $pbrTest.Value = $i
        Start-Sleep -m 1
        "VALLUE EQ"
        $i
        $i += 1
    }
})

# Show Form
$Form.Add_Shown({$Form.Activate()})
$Form.ShowDialog() 

