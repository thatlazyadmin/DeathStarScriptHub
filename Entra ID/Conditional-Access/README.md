# Export Conditional Access Policies to Excel

## Description

This PowerShell script exports all available Conditional Access policies in Microsoft Entra ID (formerly Azure AD) to an Excel file. The exported data includes detailed information on each policy's conditions, grant controls, and session controls, formatted for readability and user-friendliness.

## Features

- **Fetch Conditional Access Policies**: Connects to Microsoft Graph API to retrieve all Conditional Access policies.
- **Formatted Data Export**: Converts conditions, grant controls, and session controls into readable formats.
- **Excel Export**: Saves the formatted data into an Excel file.
- **Color Formatting**: Applies color formatting to the Excel file to enhance readability.

## Prerequisites

1. **Install Required Modules**:
   - Microsoft Graph PowerShell Module:
     ```powershell
     Install-Module Microsoft.Graph -Scope CurrentUser
     ```
   - ImportExcel Module:
     ```powershell
     Install-Module ImportExcel -Scope CurrentUser
     ```

2. **Permissions**:
   - Ensure you have the necessary permissions to read Conditional Access policies (e.g., `Policy.Read.All`).

## Usage

1. **Download the Script**:
   - Save the script file `Export-ConditionalAccessPoliciesToExcel.ps1` to your desired directory.

2. **Run the Script**:
   - Open PowerShell and navigate to the directory where the script is saved.
   - Run the script:
     ```powershell
     .\Export-ConditionalAccessPoliciesToExcel.ps1
     ```

3. **Excel Output**:
   - The script will create an Excel file named `ConditionalAccessPolicies.xlsx` in the same directory.
   - The Excel file will have color-coded columns to enhance readability:
     - **ID**: Light Blue
     - **Display Name**: Light Yellow
     - **State**: Light Green
     - **Conditions**: Light Gray
     - **Grant Controls**: Light Coral
     - **Session Controls**: Light Cyan

## Functions

### Get-ConditionalAccessPolicies

Fetches all Conditional Access policies from Microsoft Graph API, handling pagination if necessary.

### Format-Conditions

Converts the conditions into a more readable string format.

### Format-GrantControls

Converts the grant controls into a more readable string format.

### Format-SessionControls

Converts the session controls into a more readable string format.

## Color Formatting

The script uses the `ImportExcel` module to apply color formatting to specific columns in the Excel file, making the data more user-friendly and easier to read.

## Output

The script generates an Excel file `ConditionalAccessPolicies.xlsx` with the following columns:

- **ID**: The unique identifier of the policy.
- **Display Name**: The display name of the policy.
- **State**: The state of the policy (enabled/disabled).
- **Conditions**: The conditions under which the policy is applied.
- **Grant Controls**: The grant controls specified in the policy.
- **Session Controls**: The session controls specified in the policy.

## Conclusion

This script provides a comprehensive and user-friendly way to export Conditional Access policies from Microsoft Entra ID to an Excel file. The formatted and color-coded output makes it easier to review and analyze the policies.

---

For any issues or contributions, feel free to submit a pull request or open an issue on the repository.
