# SecureMailBannerInjector

## Overview
The `SecureMailBannerInjector.ps1` script is designed to enhance security awareness within Microsoft Exchange Online environments by appending a customizable security warning banner to emails received from outside the organization. This automation ensures consistent application across all received external emails, alerting users to exercise caution.

## Why This Script Was Created
In today’s digital age, email communications are a common vector for phishing attacks and other security threats. Increasing user awareness about the origin of emails—specifically identifying external emails—is crucial for preventing security breaches. This script was created to automate the process of adding a prominent warning banner to such emails, thereby helping users to instantly recognize external communications and encouraging them to verify the sender's identity before interacting with the content. The goal is to foster a security-conscious culture within organizations.

## Features
- **Customizable Banner:** The script allows customization of the banner text, colors, and fonts to align with organizational branding and security policies.
- **Automatic Deployment:** Once set up, the script automatically applies the banner to all incoming external emails without requiring manual intervention.
- **High Priority Rule:** The script sets the rule with a high priority, ensuring it precedes other mail flow rules.

## Prerequisites
- PowerShell 5.1 or higher
- Exchange Online Management Module for PowerShell
- Administrative credentials for Microsoft Exchange Online

## Installation and Setup
1. **Connect to Exchange Online PowerShell**:
   Open PowerShell and connect to Exchange Online using the following command:
   ```powershell
   Connect-ExchangeOnline
`
2. **Run the Script**
    Download and execute the SecureMailBannerInjector.ps1 script in PowerShell:
    ```powershell
    .\SecureMailBannerInjector.ps1
    ```

## Usage
After running the script, it will automatically create a new mail flow rule in your Exchange Online environment. This rule appends a security warning banner to all emails received from external sources, highlighting their origin and reminding users to be cautious.

## Screenshots

**Email with Banner**

![alt text](SecureBanner-01-2.png)

**Executing the Script**

![alt text](SecureBanner-02-1.png)

## Contributing
Contributions to the SecureMailBannerInjector script are welcome. Please feel free to fork the repository, make changes, and submit pull requests. You can also open issues if you find bugs or have feature suggestions

## License
This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments
- **Created by**: Shaun Hardneck
- **Blog**: [ThatLazyAdmin](http://www.thatlazyadmin.com)
