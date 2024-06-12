# Microsoft Teams Channel Privacy Update Script

This PowerShell script allows administrators to update the privacy settings of Microsoft Teams channels, setting them to private. It provides a user-friendly interface to list all Teams, select a specific Team, list its channels, and modify the privacy setting of a chosen channel.

## Prerequisites
- PowerShell 5.1 or higher
- Microsoft Graph PowerShell SDK: Install via `Install-Module Microsoft.Graph -Scope CurrentUser`
- Permissions: `Group.ReadWrite.All`, `ChannelMember.ReadWrite.All`

## Setup
Ensure you have administrative rights to manage Teams and channels. The script will prompt you to sign in to Microsoft Graph and consent to the necessary permissions.

## Usage
Execute the script from your PowerShell terminal:

```powershell
./TeamsChannelPrivacyUpdate.ps1
```
Follow the on-screen prompts to select a Team and a channel to set its privacy to private.

## Features
 - Lists all available Microsoft Teams
 - Displays all channels within a selected Team
 - Sets the selected channel's privacy to private

## Error Handling
The script handles errors such as failed retrievals, invalid user selections, and update failures, ensuring robust operation.

## Author
Created by: Shaun Hardneck
Website: (ThatLazyAdmin)[www.thatlazyadmin.com]

