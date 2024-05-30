# Permanent Banner
Write-Host "================================================================" -ForegroundColor Green
Write-Host " THATLAZYADMIN - Export Sent Email Addresses Script"              -ForegroundColor Green
Write-Host "================================================================" -ForegroundColor Green

# Function to export sent email addresses
Function Export-SentEmailAddresses {
    param (
        [string]$UserEmailAddress,
        [datetime]$StartDate,
        [datetime]$EndDate
    )

    # Check if StartDate is within the allowed range (not older than 10 days)
    if (($StartDate -lt (Get-Date).AddDays(-10))) {
        Write-Host "Invalid StartDate value. The StartDate can't be older than 10 days from today." -ForegroundColor Red
        return
    }

    # Connect to Exchange Online
    Write-Host "Connecting to Exchange Online..." -ForegroundColor Cyan
    
    Try {
        Import-Module ExchangeOnlineManagement -ErrorAction SilentlyContinue
        Connect-ExchangeOnline -ShowProgress $false -ErrorAction SilentlyContinue
    }
    Catch {
        Write-Host "Error connecting to Exchange Online: $_" -ForegroundColor Red
        Return
    }

    # Collect recipient email addresses and display names
    $Recipients = @()

    Try {
        Write-Host "Searching sent items..." -ForegroundColor Cyan
        $Messages = Get-MessageTrace -SenderAddress $UserEmailAddress -StartDate $StartDate -EndDate $EndDate
        foreach ($Message in $Messages) {
            $RecipientAddresses = $Message.Recipients
            foreach ($Recipient in $RecipientAddresses) {
                $Recipients += [PSCustomObject]@{
                    EmailAddress = $Recipient.Address
                    DisplayName  = $Recipient.DisplayName
                }
            }
        }
    }
    Catch {
        Write-Host "Error retrieving message trace: $_" -ForegroundColor Red
        Disconnect-ExchangeOnline -Confirm:$false
        Return
    }

    # Check if any recipients were found
    if ($Recipients.Count -eq 0) {
        Write-Host "No sent emails found in the specified date range." -ForegroundColor Yellow
    } else {
        Write-Host "Number of emails found: $($Recipients.Count)" -ForegroundColor Green

        # Export to CSV
        Write-Host "Exporting results to CSV..." -ForegroundColor Cyan
        Try {
            $ExportFilePath = "$PSScriptRoot\SentEmailAddresses_$($UserEmailAddress.Replace('@','_'))_$($StartDate.ToString('yyyyMMdd'))_$($EndDate.ToString('yyyyMMdd')).csv"
            $Recipients | Export-Csv -Path $ExportFilePath -NoTypeInformation
            Write-Host "Export completed: $ExportFilePath" -ForegroundColor Green
        }
        Catch {
            Write-Host "An error occurred: $_" -ForegroundColor Red
            Disconnect-ExchangeOnline -Confirm:$false
            Return
        }
    }

    # Disconnect from Exchange Online
    Disconnect-ExchangeOnline -Confirm:$false
}

# Main script logic
Try {
    $StartDate = Read-Host "Enter start date (yyyy-MM-dd)"
    $EndDate = Read-Host "Enter end date (yyyy-MM-dd)"
    $UserEmailAddress = Read-Host "Enter user email address"

    # Convert string dates to DateTime
    $StartDateTime = [datetime]::ParseExact($StartDate, "yyyy-MM-dd", $null)
    $EndDateTime = [datetime]::ParseExact($EndDate, "yyyy-MM-dd", $null)

    # Call the function to export sent email addresses
    Export-SentEmailAddresses -UserEmailAddress $UserEmailAddress -StartDate $StartDateTime -EndDate $EndDateTime
}
Catch {
    Write-Host "An error occurred: $_" -ForegroundColor Red
}
