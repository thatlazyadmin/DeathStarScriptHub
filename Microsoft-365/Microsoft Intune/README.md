# Intune License Retrieval Script

## Overview
This PowerShell script leverages the Microsoft Graph API to pull all available Microsoft Intune licenses in a tenant and details the users who have these licenses assigned.

## Prerequisites
- PowerShell 5.1 or higher.
- Microsoft.Graph PowerShell SDK. Installation instructions:
  ```powershell
  Install-Module Microsoft.Graph -Scope CurrentUser

#Usage
Run the script in a PowerShell window with administrator privileges. Make sure you are authenticated to access Microsoft Graph.

#Authentication
The script uses delegated permissions to access directory data:

Directory.Read.All
To run this script, you will need to authenticate using Connect-MgGraph command as shown in the script.

#Output
The script outputs each Intune license available in the tenant and lists the users assigned to each license.

#License
This script is released under the MIT license.

#Contributions
Contributions are welcome. Please fork this repository and submit a pull request for any enhancements.



This README template outlines the script's purpose, prerequisites, how to use it, and how to contribute to it, ensuring clarity for anyone who wishes to utilize or contribute to the script. Adjust the README as needed based on your specific GitHub repository guidelines and contribution standards.




