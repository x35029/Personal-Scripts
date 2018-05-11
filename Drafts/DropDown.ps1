# http://stackoverflow.com/questions/25508087/powershell-default-dropdown-value

[array]$DropDownArrayItems = "","Group1","Group2","Group3"
[array]$DropDownArray = $DropDownArrayItems | sort

# This Function Returns the Selected Value and Closes the Form

function Return-DropDown {
    if ($DropDown.SelectedItem -eq $null){
        $DropDown.SelectedItem = $DropDown.Items[0]
        $script:Choice = $DropDown.SelectedItem.ToString()
        $Form.Close()
    }
    else{
        $script:Choice = $DropDown.SelectedItem.ToString()
        $Form.Close()
    }
}

function SelectGroup{
    [void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
    [void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing")


    $Form = New-Object System.Windows.Forms.Form

    $Form.width = 300
    $Form.height = 150
    $Form.Text = ”DropDown”

    $DropDown = new-object System.Windows.Forms.ComboBox
    $DropDown.Location = new-object System.Drawing.Size(100,10)
    $DropDown.Size = new-object System.Drawing.Size(130,30)

    ForEach ($Item in $DropDownArray) {
     [void] $DropDown.Items.Add($Item)
    }

    $Form.Controls.Add($DropDown)

    $DropDownLabel = new-object System.Windows.Forms.Label
    $DropDownLabel.Location = new-object System.Drawing.Size(10,10) 
    $DropDownLabel.size = new-object System.Drawing.Size(100,40) 
    $DropDownLabel.Text = "Select Group:"
    $Form.Controls.Add($DropDownLabel)

    $Button = new-object System.Windows.Forms.Button
    $Button.Location = new-object System.Drawing.Size(100,50)
    $Button.Size = new-object System.Drawing.Size(100,20)
    $Button.Text = "Select an Item"
    $Button.Add_Click({Return-DropDown})
    $form.Controls.Add($Button)
    $form.ControlBox = $false

    $Form.Add_Shown({$Form.Activate()})
    [void] $Form.ShowDialog()


    return $script:choice
}

$Group = $null
$Group = SelectGroup
while ($Group -like ""){
    $Group = SelectGroup
} 

