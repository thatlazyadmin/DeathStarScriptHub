<#
.SYNOPSIS
    This script audits mailboxes to identify those that have calendar sharing enabled prior to disabling the feature globally.

    Created by: Shaun Hardneck
    Contact: hello@unerd.co.za
    Blog: www.thatlazyadmin.com

.DESCRIPTION
    This script performs the following actions:
    1. Retrieves all mailboxes in the organization.
    2. For each mailbox, identifies the default calendar folder based on the mailbox's language settings.
    3. Checks if calendar publishing is enabled for the default calendar folder.
    4. Displays the mailboxes with calendar publishing enabled along with the URL of the published calendar.
    5. Exports the results to a CSV file with the current date stamp.

    This script is crucial for administrators to audit calendar sharing settings before globally disabling the feature, ensuring no critical shared calendars are inadvertently affected.

.PARAMETER None

.EXAMPLE
    .\Audit-CalendarSharing.ps1
    This example runs the script to audit calendar sharing settings and export the results to a CSV file.

.NOTES
    This script is necessary to ensure that all shared calendars are identified before disabling calendar sharing globally. It helps administrators take necessary actions to inform users or preserve important shared calendars.
#>

# Import required modules
# Import-Module ExchangeOnlineManagement -ErrorAction SilentlyContinue

# Connect to Exchange Online
try {
    Connect-ExchangeOnline -ShowProgress $true
    Write-Host "Successfully connected to Exchange Online." -ForegroundColor Green
} catch {
    Write-Host "Failed to connect to Exchange Online. Please check your credentials and network connection." -ForegroundColor Red
    exit
}

# Function to audit calendar sharing
function Audit-CalendarSharing {
    try {
        $mailboxes = Get-Mailbox -ResultSize Unlimited
        $auditResults = @()

        foreach ($mailbox in $mailboxes) {
            # Get the name of the default calendar folder
            $calendarFolder = [string](Get-ExoMailboxFolderStatistics $mailbox.PrimarySmtpAddress -FolderScope Calendar | Where-Object { $_.FolderType -eq 'Calendar' }).Name

            if ($calendarFolder) {
                # Get users calendar folder settings for their default Calendar folder
                $calendar = Get-MailboxCalendarFolder -Identity "$($mailbox.PrimarySmtpAddress):\$calendarFolder"

                if ($calendar.PublishEnabled) {
                    $auditResults += [PSCustomObject]@{
                        PrimarySmtpAddress = $mailbox.PrimarySmtpAddress
                        PublishedCalendarUrl = $calendar.PublishedCalendarUrl
                    }
                    Write-Host -ForegroundColor Yellow "Calendar publishing is enabled for $($mailbox.PrimarySmtpAddress) on $($calendar.PublishedCalendarUrl)"
                }
            }
        }

        $totalCount = $auditResults.Count

        if ($totalCount -gt 0) {
            Write-Host "Audit completed. Total mailboxes with calendar publishing enabled: $totalCount" -ForegroundColor Green
            $auditResults | Format-Table PrimarySmtpAddress, PublishedCalendarUrl

            # Export to CSV
            $currentDate = Get-Date -Format "yyyyMMdd"
            $fileName = "CalendarSharingAudit_$currentDate.csv"
            $auditResults | Export-Csv -Path $fileName -NoTypeInformation
            Write-Host "Exported audit results to $fileName" -ForegroundColor Green
        } else {
            Write-Host "No mailboxes with calendar publishing enabled found." -ForegroundColor Yellow
        }
    } catch {
        Write-Host "Failed to retrieve mailbox calendar sharing information. Please ensure you have the necessary permissions." -ForegroundColor Red
    }
}

# Execute the function
Audit-CalendarSharing