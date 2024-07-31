# Server Defender Audit and Installation Script

## Overview

This PowerShell script audits the installation status of Microsoft Defender for Endpoint on Windows Server 2016 and 2012 R2 servers within an Active Directory environment. If Microsoft Defender for Endpoint is not installed on a server, the script installs the necessary features. The results are then exported to a CSV file.

## Features

- **Active Directory Query**: Identifies servers running Windows Server 2016 and 2012 R2.
- **Defender Status Check**: Verifies if Microsoft Defender for Endpoint is installed on each server.
- **Automated Installation**: Installs Microsoft Defender for Endpoint on servers where it is not present.
- **Verbose Installation Logs**: Provides detailed output during the installation process for tracking.
- **Status Reporting**: Indicates the status of each server, including connection issues and installation success or failure.
- **CSV Export**: Outputs the audit and installation results to a CSV file.

## Prerequisites

- PowerShell 5.1 or later.
- Active Directory module for PowerShell.
- Appropriate permissions to query Active Directory and perform installations on target servers.

## Usage

1. **Download the Script:**
    - Save the script file as `ServerDefender_AuditAndInstall.ps1`.

2. **Run the Script:**
    - Open PowerShell with administrative privileges.
    - Execute the script:
      ```powershell
      .\ServerDefender_AuditAndInstall.ps1
      ```

3. **Review the Results:**
    - The script will output the status of each server to the console.
    - A summary of installations will be displayed at the end.
    - The results will be exported to a CSV file named `DefenderForEndpointAudit.csv` in the same directory as the script.

## Output

- **Console Output**: Displays the status of each server as the script runs, indicating:
  - Connection success or failure.
  - Installation progress with verbose logging.
  - Final status (e.g., Installed, Installed (Reboot Required), Offline or Not Available).
- **CSV File**: `DefenderForEndpointAudit.csv` containing:
  - `ServerName`: The name of the server.
  - `OperatingSystem`: The operating system of the server.
  - `DefenderStatus`: The status of Microsoft Defender for Endpoint on the server.

## Screenshot Output
![Script Output Screenshot](Defender for Endpoint/Audit-DefenderforEndpoint_Deploy-To-(Win2016-2012R2)/DefenderEndpoint_Install_status.png)

## License

This script is provided as-is without any warranties. Use at your own risk.

## Contact

For any questions or further assistance, please contact Shaun Hardneck at [Shaun@thatlazyadmin.com](mailto:Shaun@thatlazyadmin.com) or visit [www.thatlazyadmin.com](https://www.thatlazyadmin.com).

---

This `README.md` provides an overview of the script, its features, prerequisites, usage instructions, and the expected output.