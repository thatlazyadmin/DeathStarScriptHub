<#
.SYNOPSIS
    This script exports all Intune Device Configuration policies and displays them on the screen.
.DESCRIPTION
    The script connects to Microsoft Graph, retrieves all Intune Device Configuration policies, 
    displays their details on the screen, and exports them to a CSV file named 'IntuneDeviceConfigPolicies.csv'.
.NOTES
    Author: Shaun Hardneck
    Blog: www.thatlazyadmin.com
    Company: URBANNERD CONSULTING
    Email: Shaun@thatlazyadmin.com
    Created: July 2024
#>

# Import necessary modules
# Import-Module Microsoft.Graph

# Function to export and display Intune Device Configuration Policies
function Export-IntuneDeviceConfigPolicies {
    try {
        # Authenticate to Microsoft Graph
        Connect-MgGraph -Scopes "DeviceManagementConfiguration.Read.All" -NoWelcome

        # Get all device configuration policies
        $deviceConfigPolicies = Get-MgDeviceManagement_DeviceConfiguration

        # Check if any policies were found
        if ($deviceConfigPolicies.Count -eq 0) {
            Write-Host "No device configuration policies found."
            return
        }

        # Display the policies on screen
        $deviceConfigPolicies | ForEach-Object {
            Write-Host "Policy ID: $($_.Id)"
            Write-Host "Policy Name: $($_.DisplayName)"
            Write-Host "Description: $($_.Description)"
            Write-Host "Platform: $($_.PlatformType)"
            Write-Host "Last Modified: $($_.LastModifiedDateTime)"
            Write-Host "Created Date: $($_.CreatedDateTime)"
            Write-Host "------------------------------------"
        }

        # Export policies to a CSV file
        $outputFilePath = "IntuneDeviceConfigPolicies.csv"
        $deviceConfigPolicies | Select-Object Id, DisplayName, Description, PlatformType, LastModifiedDateTime, CreatedDateTime | Export-Csv -Path $outputFilePath -NoTypeInformation

        Write-Host "Device configuration policies have been exported to $outputFilePath"
    }
    catch {
        Write-Host "An error occurred: $_"
    }
    finally {
        # Disconnect from Microsoft Graph
        Disconnect-MgGraph
    }
}

# Call the function
Export-IntuneDeviceConfigPolicies
