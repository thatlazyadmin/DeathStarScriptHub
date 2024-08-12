# DefenderConfigAssessment PowerShell Script

## Overview

The `DefenderConfigAssessment` PowerShell script is designed to connect to Microsoft Graph and retrieve the configuration settings for Microsoft Defender for Endpoint. This includes antivirus settings and Attack Surface Reduction (ASR) rules. The script evaluates these settings against Microsoft's best practices and exports the results to a CSV file for analysis. The purpose of this script is to help administrators ensure that their Defender for Endpoint configurations are aligned with recommended security practices.

## Author

- **Created by:** Shaun Hardneck
- **Contact:** [Shaun@thatlazyadmin.com](mailto:Shaun@thatlazyadmin.com)
- **Blog:** [www.thatlazyadmin.com](https://www.thatlazyadmin.com)

## Synopsis

This script connects to Microsoft Graph and retrieves the configuration settings for Microsoft Defender for Endpoint, including antivirus settings and Attack Surface Reduction (ASR) rules. It evaluates these settings against Microsoft's best practices and exports the results to a CSV file for analysis.

## Prerequisites

- PowerShell 7 or later
- Microsoft Graph PowerShell SDK
- Required permissions: `DeviceManagementConfiguration.Read.All`

## Usage

1. **Clone the repository:**

    ```sh
    git clone https://github.com/YourUsername/DefenderConfigAssessment.git
    cd DefenderConfigAssessment
    ```

2. **Install the Microsoft Graph PowerShell SDK if not already installed:**

    ```powershell
    Install-Module Microsoft.Graph -Scope CurrentUser
    ```

3. **Run the script:**

    Open a PowerShell terminal and execute the script:

    ```powershell
    .\DefenderConfigAssessment.ps1
    ```

## Script Details

### Functions

- **Connect-Graph**: Connects to Microsoft Graph with the necessary scopes.
- **Get-DeviceConfigurationProfiles**: Retrieves all device configuration profiles from Intune.
- **Get-DefenderConfiguration**: Retrieves Microsoft Defender for Endpoint configuration settings.
- **Map-ASRValue**: Maps ASR rule values to their descriptions.
- **Map-SettingValue**: Maps general settings values to their descriptions.
- **Evaluate-DefenderConfiguration**: Evaluates the configuration against best practices.
- **Export-Results**: Exports the evaluation results to a CSV file.

### Parameters

- `None`

### Example Output

The script generates a CSV file named `DefenderConfigurationAssessmentResults.csv` containing the evaluation results of your Microsoft Defender for Endpoint configurations.

### Output Columns

- **Setting**: The configuration setting or ASR rule.
- **ExpectedValue**: The recommended value for the setting.
- **ActualValue**: The current value of the setting.
- **Compliant**: Indicates whether the current value is compliant with the recommended value.

### Value Explanations

- **MAPSReporting**:
  - `0`: Disabled
  - `1`: Basic
  - `2`: Advanced
- **SubmitSamplesConsent**:
  - `0`: Never
  - `1`: Always Prompt
  - `2`: Send Safe Samples Automatically
  - `3`: Send All Samples Automatically
- **DisableBlockAtFirstSeen**:
  - `0`: Enabled
  - `1`: Disabled
- **DisableIOAVProtection**:
  - `0`: Enabled
  - `1`: Disabled
- **CloudBlockLevel**:
  - `0`: Not Set
  - `1`: High
  - `2`: High + (Extended)
- **DisableRealtimeMonitoring**:
  - `0`: Enabled
  - `1`: Disabled
- **DisableBehaviorMonitoring**:
  - `0`: Enabled
  - `1`: Disabled
- **DisableScriptScanning**:
  - `0`: Enabled
  - `1`: Disabled
- **DisableRemovableDriveScanning**:
  - `0`: Enabled
  - `1`: Disabled
- **PUAProtection**:
  - `0`: Disabled
  - `1`: Enabled
- **DisableArchiveScanning**:
  - `0`: Enabled
  - `1`: Disabled
- **DisableEmailScanning**:
  - `0`: Enabled
  - `1`: Disabled
- **EnableControlledFolderAccess**:
  - `0`: Disabled
  - `1`: Enabled
- **EnableNetworkProtection**:
  - `0`: Disabled
  - `1`: Enabled
- **ProcessMitigation**:
  - `0`: Not Configured
  - `1`: Configured

### ASR Rule Values

- **Not Configured or Disabled**: `0`
- **Block**: `1`
- **Audit**: `2`
- **Warn**: `6`

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature-branch`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin feature-branch`)
5. Create a new Pull Request

## Contact

If you have any questions or suggestions, feel free to contact me at [Shaun@thatlazyadmin.com](mailto:Shaun@thatlazyadmin.com).

---

**Disclaimer**: This script is provided as-is without any warranties. Use at your own risk.