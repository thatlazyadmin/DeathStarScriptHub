# Azure NSG Rules Backup Script

## Overview

This PowerShell script is designed to automate the backup of all Network Security Group (NSG) rules across multiple Azure subscriptions. The script retrieves NSG rules and exports them to both JSON and CSV formats, making it easy to restore or review these configurations at a later time.

## Features

- **Multi-Subscription Support:** Automatically loops through all Azure subscriptions and backs up NSG rules for each subscription.
- **Export Formats:** NSG rules are exported in both JSON and CSV formats for flexibility and ease of use.
- **Organized Output:** The exported files are organized into a folder structure that includes the date and timestamp, ensuring that each backup is unique and easy to manage.
- **Error Handling:** All errors encountered during the script execution are logged to a dedicated `.txt` file for easy troubleshooting.
- **Clean Output:** The script suppresses all unnecessary information in the terminal, only displaying key progress updates, such as when switching between subscriptions.
- **Color-Coded Messages:** Important script messages are color-coded for enhanced readability.

## Prerequisites

- **PowerShell:** Ensure that you have PowerShell installed on your machine.
- **Azure PowerShell Modules:** The script requires the `Az.Accounts` and `Az.Network` modules. These should be installed and available in your PowerShell environment.
  - To install the Azure PowerShell modules, run the following command:
    ```powershell
    Install-Module -Name Az -AllowClobber -Scope CurrentUser
    ```

## How to Use

1. **Download the Script:** Clone the repository or download the script file directly.
2. **Run the Script:** Execute the script in your PowerShell environment. You will be prompted to authenticate with Azure if you are not already authenticated.
3. **Review Backups:** The script will create a backup folder with the date and timestamp. Inside, you'll find separate folders for each subscription, each containing the NSG rules in both JSON and CSV formats.

## Error Logging

- Any errors that occur during the execution of the script will be logged to a `.txt` file in the same directory as the backups.
- The error log is named using the format `AzureNSG_Backup_Errors_YYYYMMDD_HHmmss.txt`.

## Example Folder Structure

# AzureNSG_Backup_20240815_123456/
# │
# ├── Subscription-1/
# │ ├── NSG-1/
# │ │ ├── NSG-1_NSGRules.json
# │ │ └── NSG-1_NSGRules.csv
# │ └── NSG-2/
# │ ├── NSG-2_NSGRules.json
# │ └── NSG-2_NSGRules.csv
# │
# └── Subscription-2/
# ├── NSG-1/
# │ ├── NSG-1_NSGRules.json
# │ └── NSG-1_NSGRules.csv
# └── NSG-3/
# ├── NSG-3_NSGRules.json
# └── NSG-3_NSGRules.csv

## Notes

- The script is designed to handle environments with multiple subscriptions seamlessly.
- Ensure you have the necessary permissions to access and export NSG rules across all your Azure subscriptions.

## Author

- **Shaun Hardneck**
- [That Lazy Admin Blog](https://www.thatlazyadmin.com)

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
