# Disable-WDigestAuth.ps1

## Overview
**Disable-WDigestAuth.ps1** is a PowerShell script designed to ensure that 'WDigest Authentication' is set to 'Disabled' as per CIS Control 18.4.8 (L1). This control helps protect against the risk of plaintext password theft from memory by disabling WDigest authentication, which retains a copy of the user's plaintext password in the Lsass.exe process.

## Purpose
When WDigest authentication is enabled, Lsass.exe retains a copy of the user's plaintext password in memory, making it susceptible to theft. Disabling WDigest authentication enhances security by preventing this behavior. This script specifically targets Windows 7, Windows Server 2008, and older hosts where WDigest is enabled by default.

## Script Details
- **Registry Path**: `HKLM:\System\CurrentControlSet\Control\SecurityProviders\WDigest`
- **Registry Property**: `UseLogonCredential`
- **Desired Value**: `0` (Disabled)

The script performs the following actions:
1. Checks if the registry path exists. If not, it creates the path.
2. Retrieves the current value of `UseLogonCredential`.
3. Sets the `UseLogonCredential` property to `0` to disable WDigest authentication if it is not already set.

## Usage Instructions

### Upload the Script to Intune
1. Open the Microsoft Endpoint Manager admin center.
2. Navigate to `Devices > Scripts`.
3. Click `Add` and follow the prompts to upload the PowerShell script.

### Assign the Script
1. Assign the script to the appropriate group of devices (e.g., those running Windows 7, Windows Server 2008, or older versions).

## Author
Created by: Shaun Hardneck  
Blog: [That Lazy Admin](https://www.thatlazyadmin.com)

## License
This script is provided as-is without any warranty or support. Use it at your own risk.
