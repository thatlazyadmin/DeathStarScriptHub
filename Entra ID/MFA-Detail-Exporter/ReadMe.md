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
Install-Module -Name Microsoft.Graph -Scope CurrentUser
```

## Usage:

1. Open the script in your preferred PowerShell editor.

2. Run the script:

```sh
.\MFADetailExporter.ps1
```
3. Follow the on-screen instructions to authenticate with Microsoft Graph.

4. The script will export the MFA phone methods to a CSV file named UserMfaPhoneNumbers_<date>.csv.

### Script Details
## Banner

The script features a permanent banner with a custom message:

```sh
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@##++............++++##@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@##++....    ....++####@@@@@@@@@@@@
@@@@##++..              ..........      ..++##@@@@@@@@@@@@@@####....    ..........              ..++##@@@@
@@..          ++##@@@@@@@@@@@@@@@@@@@@##..                        ++##@@@@@@@@@@@@@@@@@@##++..        ..@@
@@..        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@..                ##@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@++      ..@@
@@++      ##@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@              ##@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@      ..@@
@@@@..    ##@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@++            @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@..    @@@@
@@@@@@    ##@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@++  ++####    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@..  ##@@@@
@@@@@@..  ##@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@..  @@@@@@##  ##@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    @@@@@@
@@@@@@##  ++@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@  ++@@@@@@@@  ++@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@  ..@@@@@@
@@@@@@@@  ..@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@++  ##@@@@@@@@..  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@##  ##@@@@@@
@@@@@@@@..  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    @@@@@@@@@@##  ##@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@++  @@@@@@@@
@@@@@@@@##  ##@@@@@@@@@@@@@@@@@@@@@@@@@@@@++  ##@@@@@@@@@@@@    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@  ..@@@@@@@@
@@@@@@@@@@  ..@@@@@@@@@@@@@@@@@@@@@@@@@@##  ..@@@@@@@@@@@@@@##  ..@@@@@@@@@@@@@@@@@@@@@@@@@@##  ##@@@@@@@@
@@@@@@@@@@++  ++@@@@@@@@@@@@@@@@@@@@@@##    @@@@@@@@@@@@@@@@@@++  ++@@@@@@@@@@@@@@@@@@@@@@@@  ..@@@@@@@@@@
@@@@@@@@@@@@..  ++@@@@@@@@@@@@@@@@@@++    @@@@@@@@@@@@@@@@@@@@@@++  ..##@@@@@@@@@@@@@@@@##  ..@@@@@@@@@@@@
@@@@@@@@@@@@@@++    ..++++####++..    ..@@@@@@@@@@@@@@@@@@@@@@@@@@##      ++++####++..    ++@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@++..            ..##@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@##..          ..++@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
```
## Suppressing Errors
The script suppresses error messages to ensure a smooth operation:

```powershell

catch {
    # Suppress error messages by continuing silently
    continue
}
```
## Exporting Data
The data is exported to a CSV file with a date stamp for easy record-keeping:

```powershell

$currentDate = Get-Date -Format "yyyy-MM-dd"
$outputFile = "UserMfaPhoneNumbers_$currentDate.csv"
```

## License
This project is licensed under the MIT License - see the LICENSE file for details.

## Contact
For further inquiries, visit the [ThatLazyAdmin](http://www.thatlazyadmin.com) Blog