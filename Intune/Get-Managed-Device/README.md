# Intune Managed Devices Retrieval Script

This PowerShell script retrieves a list of all managed Intune devices using Microsoft Graph and exports the device ID, device name, and last signed-in user to a CSV file.

## Overview

This script connects to Microsoft Graph using interactive authentication, retrieves a list of managed Intune devices, and exports the details to a CSV file. The script also displays the retrieved information in a table format for easy viewing.

## Features

- Connects to Microsoft Graph using interactive authentication.
- Retrieves a list of managed Intune devices.
- Exports device details (Device ID, Device Name, and Last Signed-In User) to a CSV file.
- Displays the retrieved information in a table format.

## Prerequisites

- PowerShell 5.1 or later.
- Microsoft Graph PowerShell SDK. Install it using the following command:
  ```powershell
  Install-Module -Name Microsoft.Graph -Scope CurrentUser

## License
This project is licensed under the MIT License - see the LICENSE file for details.


### Explanation:
- **Overview**: Provides a brief overview of the script and its purpose.
- **Features**: Lists the main features of the script.
- **Prerequisites**: Specifies the prerequisites for running the script.
- **Usage**: Instructions on how to run the script.
- **Script Details**: Includes the full script with comments and explanations.
- **Author**: Credits the author and includes a link to their blog.
- **License**: Mentions the license under which the project is distributed.