# Log Analytics Tables Retention Export Script

![Azure](https://img.shields.io/badge/Azure-PowerShell-blue.svg)

## Overview

This PowerShell script connects to Microsoft Azure, allows the user to select a subscription and a Log Analytics workspace, and then provides the option to list tables based on either the Basic Table Plan or Analytics Table Plan. It retrieves and exports detailed information about each table's retention settings, including the table name, plan, default workspace retention period, total retention period, and calculated archive retention period.

## Features

- Connects to Microsoft Azure using `Connect-AzAccount`.
- Lists all available Azure subscriptions and allows the user to select one.
- Lists all Log Analytics workspaces within the selected subscription.
- Provides a menu to choose between Basic Table Plan and Analytics Table Plan.
- Retrieves detailed information about the tables' retention settings.
- Calculates the archive retention period.
- Exports the results to a CSV file named `LogAnalyticsTables.csv`.

## Usage

### Prerequisites

- Azure PowerShell module installed
- Appropriate permissions to access the Azure resources

### Steps

1. Clone the repository and navigate to the folder `LogAnalyticsTableRetentionExport`:
    ```bash
    git clone https://github.com/yourusername/LogAnalyticsTableRetentionExport.git
    cd LogAnalyticsTableRetentionExport
    ```

2. Run the script in PowerShell:
    ```powershell
    .\LogAnalyticsTablesRetentionExport.ps1
    ```

3. Follow the prompts:
    - Log in to your Azure account.
    - Select the desired subscription by entering the corresponding number.
    - Select the desired Log Analytics workspace by entering the corresponding number.
    - Choose the log type by entering `1` for Basic Table Plan or `2` for Analytics Table Plan.

4. The script will retrieve the relevant table information and export it to `LogAnalyticsTables.csv`.

### Example Output

The exported CSV file will contain the following columns:
- **TableName**: The name of the Log Analytics table.
- **Plan**: The plan type (Basic or Analytics).
- **RetentionInDays**: The default retention period for the workspace.
- **TotalRetentionInDays**: The total retention period for the table.
- **ArchiveRetentionInDays**: The calculated archive retention period.

## Created By

- **Shaun Hardneck (ThatLazyAdmin)**
- **Blog**: [ThatLazyAdmin](http://www.thatlazyadmin.com)

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Special thanks to the Azure community for their invaluable support and resources.

---

Feel free to customize the sections to better fit your specific needs and preferences. Happy scripting!