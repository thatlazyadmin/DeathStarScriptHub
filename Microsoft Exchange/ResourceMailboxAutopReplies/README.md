# Get-EXOResourceMailboxAutoReplies.ps1

## Overview
`Get-EXOResourceMailboxAutoReplies.ps1` is a PowerShell script designed to retrieve the automatic reply settings for all resource mailboxes (room and equipment mailboxes) in an Exchange Online environment. The script exports the results to a CSV file for easy review and analysis.

## Features
- Connects to Exchange Online using user-provided credentials.
- Retrieves automatic reply settings for all resource mailboxes.
- Outputs mailbox display name, auto-reply state, internal message, and external message.
- Exports the retrieved information to a CSV file named `ResourceMailboxAutoReplies.csv`.
- Provides colored output for better readability during execution.
- Disconnects from Exchange Online after completing the task.

## Prerequisites
- Exchange Online PowerShell module (`ExchangeOnlineManagement`) must be installed.
- Appropriate permissions to access Exchange Online mailboxes.

## Usage
1. Open PowerShell.
2. Ensure the Exchange Online Management module is installed. If not, install it using:
    ```powershell
    Install-Module ExchangeOnlineManagement
    ```
3. Run the script:
    ```powershell
    .\Get-EXOResourceMailboxAutoReplies.ps1
    ```
4. When prompted, enter your Exchange Online credentials.

## Output
The script outputs the following information for each resource mailbox:
- Display Name
- Auto Reply State
- Internal Message
- External Message

The output is saved in a CSV file named `ResourceMailboxAutoReplies.csv` in the directory where the script is executed.

## Notes
- Script created by: Shaun Hardneck
- Blog: [www.thatlazyadmin.com](https://www.thatlazyadmin.com)

## License
This script is provided as-is without warranty of any kind. Use at your own risk.
