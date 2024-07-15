# Add necessary modules
Import-Module Az.Compute

# Define colors for the script
$colorInfo = "Cyan"
$colorSuccess = "Green"
$colorError = "Red"
$colorDefault = "White"

# Function to display messages with color
function Write-Message {
    param (
        [string]$message,
        [string]$color = $colorDefault
    )
    Write-Host $message -ForegroundColor $color
}

# Function to create a new snapshot
function Create-Snapshot {
    param (
        [string]$resourceGroupName,
        [string]$diskName,
        [string]$location
    )
    
    $snapshotName = "$diskName-snapshot-$(Get-Date -Format 'yyyyMMddHHmmss')"
    $snapshotConfig = New-AzSnapshotConfig -SourceUri (Get-AzDisk -ResourceGroupName $resourceGroupName -DiskName $diskName).Id -Location $location -CreateOption Copy
    New-AzSnapshot -Snapshot $snapshotConfig -ResourceGroupName $resourceGroupName -SnapshotName $snapshotName
}

# Connect to Azure
Write-Message "Connecting to Azure..." $colorInfo
try {
    Connect-AzAccount -Devicecode -ErrorAction Stop
    Write-Message "Successfully connected to Azure." $colorSuccess
} catch {
    Write-Message "Failed to connect to Azure. Error: $_" $colorError
    exit
}

# Prompt for the resource group name
$resourceGroupName = Read-Host -Prompt "Enter the Resource Group Name"

# Verify the resource group exists
try {
    $resourceGroup = Get-AzResourceGroup -Name $resourceGroupName -ErrorAction Stop
    Write-Message "Resource Group '$resourceGroupName' found." $colorInfo
} catch {
    Write-Message "Resource Group '$resourceGroupName' not found. Please check the name and try again." $colorError
    exit
}

# Get all VMs in the specified resource group
$vms = Get-AzVM -ResourceGroupName $resourceGroupName

if ($vms.Count -eq 0) {
    Write-Message "No virtual machines found in the resource group '$resourceGroupName'." $colorError
    exit
}

# Retake snapshot for each VM
foreach ($vm in $vms) {
    Write-Message "Processing VM: $($vm.Name)" $colorInfo
    foreach ($disk in $vm.StorageProfile.OsDisk, $vm.StorageProfile.DataDisks) {
        if ($disk) {
            Write-Message "Creating snapshot for disk: $($disk.Name)" $colorInfo
            try {
                Create-Snapshot -resourceGroupName $resourceGroupName -diskName $disk.Name -location $vm.Location
                Write-Message "Snapshot created for disk: $($disk.Name)" $colorInfo
            } catch {
                Write-Message "Failed to create snapshot for disk: $($disk.Name). Error: $_" $colorError
            }
        }
    }
}

Write-Message "Snapshot process completed." $colorInfo