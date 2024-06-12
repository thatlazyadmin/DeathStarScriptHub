# Microsoft Teams Channel Privacy Update Script

This PowerShell script allows administrators to update the privacy settings of Microsoft Teams channels, setting them to private. It provides a user-friendly interface to list all Teams, select a specific Team, list its channels, and modify the privacy setting of a chosen channel.

## Prerequisites
- PowerShell 5.1 or later.
- Microsoft Teams PowerShell module. Install it using the following command:
  ```powershell
  Install-Module -Name PowerShellGet -Force -AllowClobber
  Install-Module -Name MicrosoftTeams -Force -AllowClobber
  ```

## Usage
1. Connect to the Desired Environment
When you run the script, you will be prompted to select the environment you want to connect to:
•	Commercial: The standard Microsoft Teams environment.
•	GCC: Government Community Cloud.
•	GCCH: GCC High.

2. Main Menu
After selecting the environment, you will see the main menu with the following options:
•	1. List all Public Teams: This option lists all Teams in the selected environment that are currently set to public visibility.
•	2. Change Team to Private: This option allows you to select a Team and change its visibility from public to private.
•	0. Exit: Exit the script.

3. List Public Teams
This option retrieves and displays all Teams that are currently set to public visibility.

4. Change Team Visibility
This option lists all Teams, allowing you to select a Team by its number. If the selected Team is public, you can confirm to change its visibility to private. If the Team is already private, no changes will be made.

## Running the Script
1.	Open PowerShell.
2.	Run the script.
3.	Follow the on-screen prompts to select the environment and desired actions.

## Script Insights
•	Environment Selection: The script supports connecting to different Microsoft Teams environments by using the -TeamsEnvironmentName parameter.
•	Interactive Menu: Users are guided through a series of options to manage Team visibility interactively.
•	Visibility Management: The script focuses on changing the visibility of Teams, which in turn affects the visibility of all channels within those Teams.

### Example Usage
1.	Select Environment:

Select the environment to connect to:
1. Commercial
2. GCC
3. GCCH

Enter your choice:
2.	Main Menu:

Main Menu:
1. List all Public Teams
2. Change Team to Private
0. Exit

Enter your choice:
3.	List Public Teams:

Listing all public teams:
Team1 - Visibility: Public
Team2 - Visibility: Public

4.	Change Team Visibility:

Listing all Teams:
1. Team1 - Visibility: Public
2. Team2 - Visibility: Private

Select a Team to change visibility by number (Enter '0' to skip):
You selected Team: Team1 with current visibility: Public
This Team is Public. Do you want to change it to Private? (Y/N):
Setting Team 'Team1' to Private... Done!








## Author
Created by: Shaun Hardneck
Website: (ThatLazyAdmin)[www.thatlazyadmin.com]

