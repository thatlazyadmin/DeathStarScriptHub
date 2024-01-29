# Variables
$prefix = "thelazyadmin"
$dateStamp = Get-Date -Format "yyyyMMdd"
$storageAccountName = $prefix + $dateStamp
$resourceGroupName = "lab-rsg104" # Specify your resource group name
$location = "southafricanorth" # Specify the location e.g. "South African North"
$skuName = "Standard_LRS" # Choose the SKU name for the storage account
$fileShareName = $dateStamp
$fileShareQuota = 50 # Quota in GB

# Function to ensure storage account name is within Azure constraints and unique
Function Get-ValidStorageAccountName {
    param([string]$name)

    # Storage account name must be between 3 and 24 characters in length and use numbers and lower-case letters only
    $validName = $name.ToLower() -replace '[^a-z0-9]', ''

    # Truncate to 24 characters if longer
    if ($validName.Length -gt 24) {
        $validName = $validName.Substring(0, 24)
    }

    return $validName
}

# Ensure the storage account name is valid and unique
$storageAccountName = Get-ValidStorageAccountName -name $storageAccountName

# Create a new Azure Storage Account
New-AzStorageAccount -ResourceGroupName $resourceGroupName -Name $storageAccountName -Location $location -SkuName $skuName

# Retrieve storage account key
$storageAccountKey = (Get-AzStorageAccountKey -ResourceGroupName $resourceGroupName -Name $storageAccountName)[0].Value

# Create context for the new storage account
$context = New-AzStorageContext -StorageAccountName $storageAccountName -StorageAccountKey $storageAccountKey

# Create Azure File Share (without specifying quota here)
New-AzStorageShare -Name $fileShareName -Context $context

# Set the quota for the file share
Set-AzStorageShareQuota -Name $fileShareName -Context $context -Quota $fileShareQuota

# Output success message in green
Write-Host "Storage account '$storageAccountName' and file share '$fileShareName' with a quota of $fileShareQuota GB created successfully." -ForegroundColor Green