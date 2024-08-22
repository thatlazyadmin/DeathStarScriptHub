# DefenderConfigAssessment PowerShell Module

## Overview

The `DefenderConfigAssessment` PowerShell module helps IT administrators and security professionals evaluate Microsoft Defender for Endpoint configurations against Microsoft's best practices. Ensuring that security configurations are compliant with recommended settings is crucial for maintaining a robust security posture and protecting endpoints from various threats.

## Features

- **Automated Security Assessment**: Automatically retrieves and evaluates your Microsoft Defender for Endpoint configurations.
- **Comprehensive Reporting**: Exports detailed results to a CSV file for easy analysis.
- **Multi-Tenant Support**: Includes tenant-specific information, making it ideal for organizations managing multiple tenants.
- **Ease of Use**: Simple installation and usage, reducing the learning curve for administrators.

## Installation

You can install the `DefenderConfigAssessment` module from the PowerShell Gallery:

```powershell
Install-Module -Name DefenderConfigAssessment -Scope CurrentUser
```
## Usage

To run the Defender Configuration Assessment, use the Start-DefenderConfigAssessment function:

```powershell
Start-DefenderConfigAssessment
```

## Functions

- **Connect-Graph:** Connects to Microsoft Graph with the required scopes.
- **Get-DeviceConfigurationProfiles:** Retrieves device configuration profiles from Intune.
- **Get-DefenderConfiguration:** Retrieves Defender for Endpoint configuration.
- **Convert-ASRValue:** Maps ASR rule values to readable strings.
- **Convert-SettingValue:** Maps configuration setting values to readable strings.
- **Get-TenantInformation:** Retrieves tenant information.
- **Test-DefenderConfiguration:** Evaluates Defender for Endpoint configuration against best practices.
- **Export-Results:** Exports the assessment results to a CSV file.
- **Show-Banner:** Displays a banner with information about the assessment.
- **Start-DefenderConfigAssessment:** Runs the full assessment process.

## Examples

```powershell
# Import the module
Import-Module DefenderConfigAssessment

# Run the assessment
Start-DefenderConfigAssessment
```

## License

This project is licensed under the MIT License. See the LICENSE file for details.

## Contact

**Author:** Shaun Hardneck
**Email:** Shaun@thatlazyadmin.com
**Blog:** www.thatlazyadmin.com
**LinkedIn:** Shaun Hardneck



