# EntraSecurityGroupCreator.ps1

## Overview

The `EntraSecurityGroupCreator.ps1` script is designed to create Entra security groups based on the information provided in a CSV file. This script ensures that all necessary modules are installed and imported before executing the group creation process.

## Features

- Checks and installs necessary PowerShell modules.
- Connects to Microsoft Graph.
- Creates Entra security groups based on CSV input.
- Provides a fun and engaging banner to enhance the script's visual appeal.

## Prerequisites

Before running the script, ensure you have the following modules installed:
- `Microsoft.Graph.Identity.Governance`
- `Microsoft.Graph.Groups`

The script will prompt you to install these modules if they are not already installed.

## CSV Input Format

- **GroupName**: The name of the group to be created.
- **Description**: A brief description of the group.
- **RoleMember**: (Currently not used, but included for future enhancements).
- **IsMember**: (Currently not used, but included for future enhancements).

## Example CSV File

The CSV file should have the following structure and be named `EntraSecurityGroupsPIMSettings.csv`:

```csv
GroupName,Description,RoleMember,IsMember
"Finance Team","Group for Finance Department","ROLE_FINANCE;ROLE_ACCOUNTING","MEMBER_FINANCE"
"HR Team","Group for Human Resources","ROLE_HR;ROLE_RECRUITMENT","MEMBER_HR"
"IT Support","Group for IT Support Staff","ROLE_IT_SUPPORT;ROLE_NETWORK","MEMBER_IT"
"Marketing Team","Group for Marketing Department","ROLE_MARKETING;ROLE_SALES","MEMBER_MARKETING"
```
- **GroupName**: The name of the group to be created.
- **Description**: A brief description of the group.
- **RoleMember**: (Currently not used, but included for future enhancements).
- **IsMember**: (Currently not used, but included for future enhancements).

**Ensure this CSV file is placed in the same directory as the EntraSecurityGroupCreator.ps1 script.**


## How to Use

1. Clone the repository or download the `EntraSecurityGroupCreator.ps1` script.
2. Ensure your CSV file is named `EntraSecurityGroupsPIMSettings.csv` and is located in the same directory as the script.
3. Open a PowerShell window and navigate to the directory containing the script.
4. Run the script:
   ```powershell
   .\EntraSecurityGroupCreator.ps1
   ```

## Contributing
If you would like to contribute to this project, please fork the repository and submit a pull request with your changes.

## License
This project is licensed under the MIT License. See the LICENSE file for details.