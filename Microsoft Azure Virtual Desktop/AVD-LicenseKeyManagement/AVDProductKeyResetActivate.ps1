# Synopsis:
# This script performs a series of operations to troubleshoot and reset the Windows product key. 
# It includes checking DNS resolution for the KMS service, uninstalling the existing key, installing a new key, 
# and activating it. Each step logs the result to the console and a log file for tracking. This script is designed 
# to run in an Azure environment using the Azure Run Command feature.
#
# Author: Shaun Hardneck
# Email: shaun@thatlazyadmin.com
# Blog: www.thatlazyadmin.com
# Date: October 2024

# Function to log and display messages
function Log-Output {
    param (
        [string]$message
    )
    Write-Host $message -ForegroundColor Green
    Add-Content -Path "process_log.txt" -Value $message
}

# Step 1: Perform nslookup
Log-Output "Step 1: Performing nslookup for azkms.core.windows.net..."
$nslookupResult = nslookup azkms.core.windows.net
if ($?) {
    Log-Output "Step 1: nslookup successful."
} else {
    Log-Output "Step 1: nslookup failed."
}

# Step 2: Run slmgr /dlv
Log-Output "Step 2: Running slmgr /dlv..."
Start-Process -FilePath "slmgr.vbs" -ArgumentList "/dlv" -Wait
if ($?) {
    Log-Output "Step 2: slmgr /dlv successful."
} else {
    Log-Output "Step 2: slmgr /dlv failed."
}

# Step 3: Run slmgr /upk
Log-Output "Step 3: Running slmgr /upk..."
Start-Process -FilePath "slmgr.vbs" -ArgumentList "/upk" -Wait
if ($?) {
    Log-Output "Step 3: slmgr /upk successful."
} else {
    Log-Output "Step 3: slmgr /upk failed."
}

# Step 4: Run slmgr /ipk with new key
Log-Output "Step 4: Installing product key with slmgr /ipk..."
Start-Process -FilePath "slmgr.vbs" -ArgumentList "/ipk NPPR9-FWDCX-D2C8J-H872K-2YT43" -Wait
if ($?) {
    Log-Output "Step 4: slmgr /ipk successful."
} else {
    Log-Output "Step 4: slmgr /ipk failed."
}

# Step 5: Run slmgr /ato to activate the product
Log-Output "Step 5: Activating the product with slmgr /ato..."
Start-Process -FilePath "slmgr.vbs" -ArgumentList "/ato" -Wait
if ($?) {
    Log-Output "Step 5: slmgr /ato successful."
} else {
    Log-Output "Step 5: slmgr /ato failed."
}

# Step 6: Run slmgr /dlv again
Log-Output "Step 6: Running slmgr /dlv again..."
Start-Process -FilePath "slmgr.vbs" -ArgumentList "/dlv" -Wait
if ($?) {
    Log-Output "Step 6: slmgr /dlv successful."
} else {
    Log-Output "Step 6: slmgr /dlv failed."
}

# Step 7: Open the registry editor (regedit)
Log-Output "Step 7: Opening Registry Editor..."
Start-Process -FilePath "regedit.exe" -Wait
if ($?) {
    Log-Output "Step 7: regedit opened successfully."
} else {
    Log-Output "Step 7: regedit failed to open."
}

# Final output message
Log-Output "All steps completed. Process log saved to process_log.txt."

# Ensure Azure Run Command completes successfully
exit 0
