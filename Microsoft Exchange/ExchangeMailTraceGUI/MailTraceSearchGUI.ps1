# Ensure the ExchangeOnlineManagement module is installed and imported
if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Install-Module -Name ExchangeOnlineManagement -Force -Scope CurrentUser
}
Import-Module -Name ExchangeOnlineManagement -Force

# Add required assemblies
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Function to connect to Exchange Online
function Connect-ExchangeOnlineFunction {
    try {
        Connect-ExchangeOnline -ShowProgress $false -ErrorAction Stop
        [System.Windows.Forms.MessageBox]::Show("Connected to Exchange Online successfully.", "Information", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
        return $true
    } catch {
        [System.Windows.Forms.MessageBox]::Show("Failed to connect to Exchange Online: $_", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        return $false
    }
}

# Function to convert PSObject to DataTable
function ConvertTo-DataTable {
    param (
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [PSObject[]]$InputObject
    )

    $dataTable = New-Object System.Data.DataTable

    $InputObject[0].PSObject.Properties.Name | ForEach-Object {
        $col = New-Object System.Data.DataColumn
        $col.ColumnName = $_
        $dataTable.Columns.Add($col)
    }

    $InputObject | ForEach-Object {
        $row = $dataTable.NewRow()
        $_.PSObject.Properties.Name | ForEach-Object {
            $row[$_] = $_.PSObject.Properties[$_].Value
        }
        $dataTable.Rows.Add($row)
    }

    return $dataTable
}

# Function to show mail trace results in a GUI
function Show-MailTraceResults {
    param (
        [Parameter(Mandatory=$true)]
        [string]$startDate,
        
        [Parameter(Mandatory=$true)]
        [string]$endDate,
        
        [Parameter(Mandatory=$true)]
        [string]$sender,
        
        [Parameter(Mandatory=$true)]
        [string]$recipient
    )

    if (-not (Get-Command -Name Get-MessageTrace -ErrorAction SilentlyContinue)) {
        [System.Windows.Forms.MessageBox]::Show("The Get-MessageTrace cmdlet is not available. Please ensure you are connected to Exchange Online.", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        return
    }

    # Get mail trace results
    try {
        $results = Get-MessageTrace -StartDate $startDate -EndDate $endDate -SenderAddress $sender -RecipientAddress $recipient -ErrorAction Stop
        Write-Output "Mail trace results: $results"
    } catch {
        [System.Windows.Forms.MessageBox]::Show("Failed to retrieve message trace: $_", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        return
    }

    if ($results.Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show("No emails found for the given criteria.", "Information", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
        return
    }

    # Convert results to a format suitable for data binding
    $formattedResults = $results | Select-Object @{Name='Received';Expression={($_.Received -as [datetime]).ToString("yyyy-MM-dd HH:mm:ss")}}, SenderAddress, Subject
    $dataTable = ConvertTo-DataTable -InputObject $formattedResults

    Write-Output "Formatted results: $($dataTable | Out-String)"

    # Create a new form to display the results
    $resultsForm = New-Object system.Windows.Forms.Form
    $resultsForm.Text = "Mail Trace Results"
    $resultsForm.Size = New-Object System.Drawing.Size(800, 600)
    $resultsForm.StartPosition = "CenterScreen"

    # Label to show the number of emails found
    $resultsCountLabel = New-Object System.Windows.Forms.Label
    $resultsCountLabel.Text = "Number of emails found: $($results.Count)"
    $resultsCountLabel.Location = New-Object System.Drawing.Point(20, 20)
    $resultsCountLabel.AutoSize = $true
    $resultsForm.Controls.Add($resultsCountLabel)

    # Create a data grid view to show the results
    $dataGridView = New-Object System.Windows.Forms.DataGridView
    $dataGridView.Size = New-Object System.Drawing.Size(760, 500)
    $dataGridView.Location = New-Object System.Drawing.Point(20, 60)
    $dataGridView.AutoGenerateColumns = $false

    # Define columns for the data grid view
    $dateColumn = New-Object System.Windows.Forms.DataGridViewTextBoxColumn
    $dateColumn.Name = "Date"
    $dateColumn.HeaderText = "Date"
    $dateColumn.DataPropertyName = "Received"

    $fromColumn = New-Object System.Windows.Forms.DataGridViewTextBoxColumn
    $fromColumn.Name = "From"
    $fromColumn.HeaderText = "From"
    $fromColumn.DataPropertyName = "SenderAddress"

    $subjectColumn = New-Object System.Windows.Forms.DataGridViewTextBoxColumn
    $subjectColumn.Name = "Subject"
    $subjectColumn.HeaderText = "Subject"
    $subjectColumn.DataPropertyName = "Subject"

    # Add columns to the data grid view
    [void]$dataGridView.Columns.AddRange(@($dateColumn, $fromColumn, $subjectColumn))

    # Bind the results to the data grid view
    $dataGridView.DataSource = $dataTable

    # Add the data grid view to the form
    $resultsForm.Controls.Add($dataGridView)

    # Show the form
    $resultsForm.ShowDialog()
}

# Connect to Exchange Online
$connected = Connect-ExchangeOnlineFunction

if ($connected) {
    # Create the main form for input
    $form = New-Object system.Windows.Forms.Form
    $form.Text = "Exchange Mail Trace"
    $form.Size = New-Object System.Drawing.Size(400, 350)
    $form.StartPosition = "CenterScreen"

    # Create and add controls to the form
    $startDateLabel = New-Object System.Windows.Forms.Label
    $startDateLabel.Text = "Start Date (yyyy-MM-dd):"
    $startDateLabel.Location = New-Object System.Drawing.Point(10, 20)
    $form.Controls.Add($startDateLabel)

    $startDateTextBox = New-Object System.Windows.Forms.TextBox
    $startDateTextBox.Location = New-Object System.Drawing.Point(150, 20)
    $startDateTextBox.Width = 200
    $form.Controls.Add($startDateTextBox)

    $startDateExampleLabel = New-Object System.Windows.Forms.Label
    $startDateExampleLabel.Text = "(e.g., 2024-01-01)"
    $startDateExampleLabel.Location = New-Object System.Drawing.Point(150, 45)
    $startDateExampleLabel.AutoSize = $true
    $form.Controls.Add($startDateExampleLabel)

    $endDateLabel = New-Object System.Windows.Forms.Label
    $endDateLabel.Text = "End Date (yyyy-MM-dd):"
    $endDateLabel.Location = New-Object System.Drawing.Point(10, 80)
    $form.Controls.Add($endDateLabel)

    $endDateTextBox = New-Object System.Windows.Forms.TextBox
    $endDateTextBox.Location = New-Object System.Drawing.Point(150, 80)
    $endDateTextBox.Width = 200
    $form.Controls.Add($endDateTextBox)

    $endDateExampleLabel = New-Object System.Windows.Forms.Label
    $endDateExampleLabel.Text = "(e.g., 2024-01-31)"
    $endDateExampleLabel.Location = New-Object System.Drawing.Point(150, 105)
    $endDateExampleLabel.AutoSize = $true
    $form.Controls.Add($endDateExampleLabel)

    $senderLabel = New-Object System.Windows.Forms.Label
    $senderLabel.Text = "Sender:"
    $senderLabel.Location = New-Object System.Drawing.Point(10, 140)
    $form.Controls.Add($senderLabel)

    $senderTextBox = New-Object System.Windows.Forms.TextBox
    $senderTextBox.Location = New-Object System.Drawing.Point(150, 140)
    $senderTextBox.Width = 200
    $form.Controls.Add($senderTextBox)

    $recipientLabel = New-Object System.Windows.Forms.Label
    $recipientLabel.Text = "Recipient:"
    $recipientLabel.Location = New-Object System.Drawing.Point(10, 180)
    $form.Controls.Add($recipientLabel)

    $recipientTextBox = New-Object System.Windows.Forms.TextBox
    $recipientTextBox.Location = New-Object System.Drawing.Point(150, 180)
    $recipientTextBox.Width = 200
    $form.Controls.Add($recipientTextBox)

    $searchButton = New-Object System.Windows.Forms.Button
    $searchButton.Text = "Search"
    $searchButton.Location = New-Object System.Drawing.Point(150, 220)
    $searchButton.Add_Click({
        $startDate = $startDateTextBox.Text
        $endDate = $endDateTextBox.Text
        $sender = $senderTextBox.Text
        $recipient = $recipientTextBox.Text

        Show-MailTraceResults -startDate $startDate -endDate $endDate -sender $sender -recipient $recipient
    })
    $form.Controls.Add($searchButton)

    # Show the main form
    $form.ShowDialog()
}
