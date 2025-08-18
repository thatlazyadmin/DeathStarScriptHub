# EntraGroupAudit-Export

## 🔍 Overview

`Export-EntraGroupMembers.ps1` is a PowerShell script built using Microsoft Graph that allows you to:

- Prompt for an **Entra ID (Azure AD)** security group name
- Retrieve all members of that group
- Collect only user attributes that have values
- Export those user details to a clean, professional `.csv` file

Developed by **THATLAZYADMIN**  
📧 shaun@thatlazyadmin.com | 🌐 www.thatlazyadmin.com

---

## 🚀 Features

- Prompts for group name interactively
- Retrieves all user attributes using Microsoft Graph
- Filters out empty/null attributes to keep the CSV clean
- Exports to a timestamped CSV file
- Clears the PowerShell screen and displays a clean UI banner

---

## 🧰 Requirements

- PowerShell 7.x or Windows PowerShell 5.1+
- Microsoft Graph PowerShell SDK

Install the Microsoft Graph module (if not already installed):

```powershell
Install-Module Microsoft.Graph -Scope CurrentUser -Force

### Required Graph permissions:
 - Group.Read.All
 - User.Read.All
 - Directory.Read.All

#### Ensure you're logged in with sufficient rights to read group and user information in Entra ID.