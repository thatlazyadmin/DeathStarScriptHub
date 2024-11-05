# Load necessary assemblies for WPF
Add-Type -AssemblyName PresentationFramework

# Define reusable error handling function
function Show-Message {
    param (
        [string]$Message,
        [string]$Title = "Information",
        [System.Windows.MessageBoxImage]$Icon = [System.Windows.MessageBoxImage]::Information
    )
    [System.Windows.MessageBox]::Show($Message, $Title, [System.Windows.MessageBoxButton]::OK, $Icon)
}

# Define the XAML for the GUI
[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        Title="Conditional Access Policy Auditor (CAPA)" Height="450" Width="600">
    <Grid>
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>
        <StackPanel Orientation="Vertical" HorizontalAlignment="Center" Margin="10">
            <Image Name="LogoImage" Height="100" Width="100" Margin="0,10,0,10"/>
            <TextBlock Text="Conditional Access Policy Auditor" FontSize="20" FontWeight="Bold" HorizontalAlignment="Center"/>
        </StackPanel>
        <StackPanel Orientation="Horizontal" HorizontalAlignment="Center" Grid.Row="1" Margin="10">
            <Button Name="ConnectButton" Content="Connect to Entra ID" Width="150" Margin="5"/>
            <Button Name="ExportButton" Content="Export to Excel" Width="150" Margin="5" IsEnabled="False"/>
        </StackPanel>
        <DataGrid Name="PolicyDataGrid" Grid.Row="2" AutoGenerateColumns="True" Margin="10" IsReadOnly="True"/>
        <TextBlock Text="Created by Shaun Hardneck" Grid.Row="3" HorizontalAlignment="Right" Margin="10"/>
    </Grid>
</Window>
"@

# Parse the XAML
$reader = (New-Object System.Xml.XmlNodeReader $xaml)
$window = [Windows.Markup.XamlReader]::Load($reader)

# Define controls
$LogoImage = $window.FindName("LogoImage")
$ConnectButton = $window.FindName("ConnectButton")
$ExportButton = $window.FindName("ExportButton")
$PolicyDataGrid = $window.FindName("PolicyDataGrid")

# Function to Connect to Entra ID
function Connect-ToEntraID {
    $maxRetries = 3
    for ($i = 1; $i -le $maxRetries; $i++) {
        try {
            Import-Module Microsoft.Graph -ErrorAction Stop
            Connect-MgGraph -Scopes "Policy.Read.All" -ErrorAction Stop
            Show-Message -Message "Successfully connected to Entra ID." -Title "Connection Status"
            return $true
        }
        catch {
            if ($_ -match "function capacity 4096 has been exceeded") {
                if ($i -eq $maxRetries) {
                    Show-Message -Message "Connection failed due to capacity limitations. Please try again later." -Title "Connection Error" -Icon [System.Windows.MessageBoxImage]::Error
                } else {
                    Show-Message -Message "Retrying connection attempt $i of $maxRetries due to capacity limitation." -Title "Retrying"
                    Start-Sleep -Seconds 5
                }
            } else {
                Show-Message -Message "Failed to connect to Entra ID: $_" -Title "Connection Error" -Icon [System.Windows.MessageBoxImage]::Error
                return $false
            }
        }
    }
}

# Retrieve Conditional Access Policies
function Get-CAPolicies {
    try {
        $CAPolicies = Get-MgConditionalAccessPolicy -All
        $PolicyData = $CAPolicies | Select-Object @{
            Name="PolicyName"; Expression={$_.DisplayName}
        }, @{
            Name="State"; Expression={$_.State}
        }, @{
            Name="IncludeUsers"; Expression={$_.Conditions.Users.IncludeUsers -join ", "}
        }, @{
            Name="ExcludeUsers"; Expression={$_.Conditions.Users.ExcludeUsers -join ", "}
        }, @{
            Name="IncludeGroups"; Expression={$_.Conditions.Users.IncludeGroups -join ", "}
        }, @{
            Name="ExcludeGroups"; Expression={$_.Conditions.Users.ExcludeGroups -join ", "}
        }, @{
            Name="IncludeRoles"; Expression={$_.Conditions.Users.IncludeRoles -join ", "}
        }, @{
            Name="ExcludeRoles"; Expression={$_.Conditions.Users.ExcludeRoles -join ", "}
        }, @{
            Name="IncludeApplications"; Expression={$_.Conditions.Applications.IncludeApplications -join ", "}
        }, @{
            Name="ExcludeApplications"; Expression={$_.Conditions.Applications.ExcludeApplications -join ", "}
        }, @{
            Name="GrantControls"; Expression={$_.GrantControls.BuiltInControls -join ", "}
        }, @{
            Name="SessionControls"; Expression={$_.SessionControls -join ", "}
        }
        return $PolicyData
    }
    catch {
        Show-Message -Message "An error occurred while retrieving policies: $_" -Title "Error" -Icon [System.Windows.MessageBoxImage]::Error
        return $null
    }
}

# Export to Excel
function Export-CAPoliciesToExcel {
    try {
        $PolicyData = $PolicyDataGrid.ItemsSource
        if ($PolicyData -eq $null) {
            Show-Message -Message "No data available to export." -Title "Warning" -Icon [System.Windows.MessageBoxImage]::Warning
            return
        }
        $ExportPath = [System.IO.Path]::Combine([System.Environment]::GetFolderPath('Desktop'), "CAPolicies.xlsx")
        $PolicyData | Export-Excel -Path $ExportPath -AutoSize -Title "Conditional Access Policies"
        Show-Message -Message "Export completed successfully. File saved to: $ExportPath" -Title "Success"
    }
    catch {
        Show-Message -Message "An error occurred during export: $_" -Title "Export Error" -Icon [System.Windows.MessageBoxImage]::Error
    }
}

# Button actions
$ConnectButton.Add_Click({
    if (Connect-ToEntraID) {
        $PolicyData = Get-CAPolicies
        if ($PolicyData -ne $null) {
            $PolicyDataGrid.ItemsSource = $PolicyData
            $ExportButton.IsEnabled = $true
        }
    }
})
$ExportButton.Add_Click({ Export-CAPoliciesToExcel })

# Show window
$window.ShowDialog()
