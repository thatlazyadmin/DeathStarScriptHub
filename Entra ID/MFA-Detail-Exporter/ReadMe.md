# MFA Phone Method Exporter

## Overview

The **MFA Phone Method Exporter** script is designed to help administrators export a list of all the contact numbers users have used for Multi-Factor Authentication (MFA). This script connects to Microsoft Graph, retrieves user MFA phone methods, and exports the details to a CSV file.

### Features

- Connects seamlessly to Microsoft Graph with the required permissions.
- Retrieves and exports user MFA phone methods.
- Suppresses error messages related to access issues for a smooth operation.
- Provides a success message upon completion.
- Generates a date-stamped CSV file for easy record-keeping.
- Includes a permanent banner with a custom message.

### Author

Created by **Shaun Hardneck**  
Blog: [ThatLazyAdmin](http://www.thatlazyadmin.com)

---

## Table of Contents

- [Getting Started](#getting-started)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Usage](#usage)
- [License](#license)

---

## Getting Started

Follow these instructions to get a copy of the script up and running on your local machine.

### Prerequisites

Ensure you have the following installed:

- PowerShell 5.1 or higher
- Microsoft Graph PowerShell SDK

### Installation

1. **Clone the repository:**

   ```sh
   git clone https://github.com/your-username/mfa-phone-method-exporter.git
   cd mfa-phone-method-exporter

2. **Install the Microsoft Graph PowerShell SDK:**

```sh
Copy code
Install-Module -Name Microsoft.Graph -Scope CurrentUser

## Usage:
Open the script in your preferred PowerShell editor.

Run the script:

sh
Copy code
.\MFADetailExporter.ps1

Follow the on-screen instructions to authenticate with Microsoft Graph.

The script will export the MFA phone methods to a CSV file named UserMfaPhoneNumbers_<date>.csv.

