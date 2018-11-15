####################################################



"Generating Report..."

$support_org = @("Brazil-Curitiba", "Brazil-Rio de Janeiro", "Brazil-Asset Management", "Brazil-Curitiba Corporate Evolution Solution Center", "Argentina-Asset Management","Argentina-End User Services","Argentina-Infrastructure","Argentina-Torre Boston IT Solution Center", "Argentina-Docklands IT Solution Center", "Mexico", "Guyana", "Andean North-End User Services", "Northern Node-Asset Management")
$WorkOrderAPI = "http://ticket/api/workorder/group"
$IncidentAPI = "http://ticket/api/incident/group"
$ResponseType = "application/json"
$Incidents = @()
$WorkOrders = @()

ForEach ($SupportGroup in $support_org)
{
$Incidents += Invoke-RestMethod -Method Get -Uri "$IncidentAPI/$SupportGroup" -ContentType $ResponseType -UseDefaultCredentials
$WorkOrders += Invoke-RestMethod -Method Get -Uri "$WorkOrderAPI/$SupportGroup" -ContentType $ResponseType -UseDefaultCredentials
}

"Ticket information retrieved."

$Incidents2 = $Incidents | select @{Name="Age";Expression={"{0:N2}" -f (New-Timespan -start ([datetime]$_.Submit_date) -end (get-date) ).TotalDays}} ,@{Name="Incident Number"; Expression={$_.incident_number}}, @{Name="Submit Date"; Expression={([datetime]$_.Submit_date) -f "G"}}, Priority, Status, Summary, @{Name="Assigned Group";Expression={$_.Assignee.Group}}, @{Name="Assignee";Expression={$_.Assignee.Name}}#  | Export-Csv -Path C:\xom\SPTTemp\Incidents.csv -NoTypeInformation
$WorkOrders2 = $WorkOrders | select @{Name="Age";Expression={if ([string]::IsNullOrEmpty($_.Needed_By_date)) {"{0:N2}" -f (New-Timespan -start ([datetime]$_.Submit_date) -end (get-date) ).TotalDays} elseif ( (get-date).ToShortDateString() -eq  ([datetime]$_.Needed_By_Date).ToShortDateString() ) {"Due Date Today"} elseif ( ( [datetime]$_.Needed_By_Date ).ToShortDateString() -eq ((get-date).AddHours(29).ToShortDateString() ) ) {"Due Date Tomorrow"} elseif ( ( [datetime]$_.Needed_By_Date ).ToShortDateString() -lt (get-date).ToShortDateString() ) {"Past Due Date"} else {"On Time"} } }, @{Name="Need By Date";Expression={if ([string]::IsNullOrEmpty($_.Needed_By_date) ) {"NULL"} else {([datetime]$_.Needed_By_date).AddHours(5).ToShortDateString()}}}, @{Name="Work Order ID";Expression={$_.work_order_id}}, @{Name="Submit Date";Expression={([datetime]$_.Submit_Date) -f "G"}}, Priority, Status, Summary, @{Name="Assignee Support Group";expression={$_.assignee.group}}, @{Name="Assignee";Expression={$_.Assignee.Name}} # | Export-Csv -Path C:\xom\SPTTemp\WO.csv -NoTypeInformation

#Create excel COM object
$excel = New-Object -ComObject excel.application


#Add workbook

$workbook = $excel.Workbooks.Add()
$workbook.worksheets.add() | out-null

"Excel Workbook created."
"Generating Incident table"

#Set up Incidents Worksheet
$IncidentsInfoSheet = $workbook.Worksheets.Item(1)
$IncidentsInfoSheet.Name = 'Incidents'
$IncidentsInfoSheet.Activate() | Out-Null

$row = 1
$column = 1
$IncidentsInfoSheet.Cells.Item($row, $column) = "Age"

$column++
$IncidentsInfoSheet.Cells.Item($row, $column) = "Incident Number"

$column++
$IncidentsInfoSheet.Cells.Item($row, $column) = "Submit Date"

$column++
$IncidentsInfoSheet.Cells.Item($row, $column) = "Priority"

$column++
$IncidentsInfoSheet.Cells.Item($row, $column) = "Status"

$column++
$IncidentsInfoSheet.Cells.Item($row, $column) = "Summary"

$column++
$IncidentsInfoSheet.Cells.Item($row, $column) = "Assigned Group"

$column++
$IncidentsInfoSheet.Cells.Item($row, $column) = "Assignee"

#Copy Report to Excel
foreach ($INC in $Incidents2)
{
    $column = 1
    $row++
    $IncidentsInfoSheet.Cells.Item($row, $column) = $INC.Age
    
    $column++
    $IncidentsInfoSheet.Cells.Item($row, $column) = $INC.'Incident Number'
    
    $column++
    $IncidentsInfoSheet.Cells.Item($row, $column) = $INC.'Submit Date'
    
    $column++
    $IncidentsInfoSheet.Cells.Item($row, $column) = $inc.Priority

    $column++
    $IncidentsInfoSheet.Cells.Item($row, $column) = $inc.Status

    $column++
    $IncidentsInfoSheet.Cells.Item($row, $column) = $inc.Summary

    $column++
    $IncidentsInfoSheet.Cells.Item($row, $column) = $inc.'Assigned Group'

    $column++
    $IncidentsInfoSheet.Cells.Item($row, $column) = $inc.Assignee

}

"Incidents table created"

#Format INC table
$tableINC = $IncidentsInfoSheet.ListObjects.Add([Microsoft.Office.Interop.Excel.XlListObjectSourceType]::xlSrcRange, $IncidentsInfoSheet.UsedRange, $null,[Microsoft.Office.Interop.Excel.XlYesNoGuess]::xlYes)
$tableINC.name = "INC Table"
$tableINC.TableStyle = "TableStyleMedium6"

#Sort INC Table by Age (descending)
$tableINC.Sort.SortFields.Clear()
$tableINC.Sort.SortFields.Add($tableINC.Range.Columns.Item(2)) |  out-null
$tableINC.Sort.Apply()
$tableINC.Range.Columns.AutoFit() | out-null
$tableINC.Range.Rows.AutoFit() | out-null

"Incident Table formatted"

#Condition Format on INC Age
$selection = $tableINC.Range.Columns.Item(1)
$selection.FormatConditions.AddColorScale(3) | out-null
$selection.FormatConditions.item(1).colorscalecriteria.item(1).type = 0
$selection.FormatConditions.item(1).colorscalecriteria.item(2).type = 0
$selection.FormatConditions.item(1).colorscalecriteria.item(3).type = 0

$selection.FormatConditions.item(1).colorscalecriteria.item(1).value = 0
$selection.FormatConditions.item(1).colorscalecriteria.item(2).value = 0.75
$selection.FormatConditions.item(1).colorscalecriteria.item(3).value = 1

$selection.FormatConditions.item(1).colorscalecriteria.item(1).formatcolor.color = [System.Drawing.Color]::FromArgb(69,252,83)
$selection.FormatConditions.item(1).colorscalecriteria.item(3).formatcolor.color = [System.Drawing.Color]::FromArgb(223,47,47)

"Incident Color Scale created"
"Incident table creation completed."
"Generating WO Table"

#Set up WO Worksheet

$WOInfoSheet = $workbook.Worksheets.Item(2)
$WOInfoSheet.Name = 'Work Orders'
$WOInfoSheet.Activate() | Out-Null

$column = 1
$row = 1

$WOInfoSheet.Cells.Item($row, $column) = "Age"

$column++
$WOInfoSheet.Cells.Item($row, $column) = "Need By Date"

$column++
$WOInfoSheet.Cells.Item($row, $column) = "Work Order ID"

$column++
$WOInfoSheet.Cells.Item($row, $column) = "Submit Date"

$column++
$WOInfoSheet.Cells.Item($row, $column) = "Priority"

$column++
$WOInfoSheet.Cells.Item($row, $column) = "Status"

$column++
$WOInfoSheet.Cells.Item($row, $column) = "Summary"

$column++
$WOInfoSheet.Cells.Item($row, $column) = "Assignee Support Group"

$column++
$WOInfoSheet.Cells.Item($row, $column) = "Assignee"


#Copy WO Data to Excel



foreach ($WO in $WorkOrders2)
{
    $column = 1
    $row++
    $WOInfoSheet.Cells.Item($row, $column) = $WO.Age

    $column++
    $WOInfoSheet.Cells.Item($row, $column) = $WO.'Need By Date'

    $column++
    $WOInfoSheet.Cells.Item($row, $column) = $WO.'Work Order ID'

    $column++
    $WOInfoSheet.Cells.Item($row, $column) = $WO.'Submit Date'

    $column++
    $WOInfoSheet.Cells.Item($row, $column) = $WO.Priority

    $column++
    $WOInfoSheet.Cells.Item($row, $column) = $WO.Status

    $column++
    $WOInfoSheet.Cells.Item($row, $column) = $WO.Summary

    $column++
    $WOInfoSheet.Cells.Item($row, $column) = $WO.'Assignee Support Group'

    $column++
    $WOInfoSheet.Cells.Item($row, $column) = $WO.Assignee

}

"WO table created"

#Format WO table
$tableWO = $WOInfoSheet.ListObjects.Add([Microsoft.Office.Interop.Excel.XlListObjectSourceType]::xlSrcRange, $WOInfoSheet.UsedRange, $null,[Microsoft.Office.Interop.Excel.XlYesNoGuess]::xlYes)
$tableWO.name = "WO Table"
$tableWO.TableStyle = "TableStyleMedium6"

#Sort WO Table by Work Order ID
$tableWO.Sort.SortFields.Clear()
$tableWO.Sort.SortFields.Add($tableWO.Range.Columns.Item(3)) | out-null
$tableWO.Sort.Apply()
$tableWO.Range.Columns.AutoFit() | out-null
$tableWO.Range.Rows.AutoFit() | out-null

"WO table formatted"

#Condition Format the WO by Age

$selection = $TableWO.range.columns.item(1)

$selection.FormatConditions.Add(1,3,"On Time") | out-null
$selection.FormatConditions.item(1).interior.color = [System.Drawing.Color]::FromArgb(146, 208, 80)

$selection.FormatConditions.Add(1,3,"Due Date Tomorrow") | Out-Null
$selection.FormatConditions.item(2).interior.color = [System.Drawing.Color]::FromArgb(255, 192, 0)

$selection.FormatConditions.Add(1,3,"Due Date Today") | out-null
$selection.FormatConditions.item(3).interior.color = [System.Drawing.Color]::FromArgb(255, 192, 0)

$selection.FormatConditions.Add(1,3,"Past Due Date") | out-null
$selection.FormatConditions.item(4).interior.color = [System.Drawing.Color]::FromArgb(255, 0, 0)

"WO Conditional Format Completed"
"WO table creation completed."


"Report created"
"Showing Excel"

#Make Visible
$excel.Visible = $True

$file = "C:\Temp\Aging_Report.xlsx"
if (Test-Path $file) {Remove-Item $file}
$workbook.saveas($file)
