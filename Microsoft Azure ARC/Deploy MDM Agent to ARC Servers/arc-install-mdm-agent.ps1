# Example PowerShell script to install the Intune MDM Agent
$mdmEnrollmentUrl = "https://enrollment.manage.microsoft.com/enrollmentserver/discovery.svc"
$mdmAgentDownloadUrl = "https://go.microsoft.com/fwlink/?linkid=2153551" # Replace with actual download URL

# Download and install the Intune MDM agent
Invoke-WebRequest -Uri $mdmAgentDownloadUrl -OutFile "C:\mdm-agent-setup.exe"
Start-Process -FilePath "C:\mdm-agent-setup.exe" -ArgumentList "/quiet /url $mdmEnrollmentUrl" -Wait

# Optional: Add the device to the specific Intune Device Group using Intune Graph API
$deviceId = (Get-WmiObject -Class Win32_ComputerSystem).Name
$intuneDeviceGroupId = "your-intune-device-group-id" # Replace with your Intune device group ID

# Add the device to the Intune Device Group
# Authentication and API call to Microsoft Graph to add the device to the group
