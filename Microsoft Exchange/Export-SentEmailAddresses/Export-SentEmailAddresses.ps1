# Permanent Banner
Write-Host "================================================================" -ForegroundColor Green
Write-Host " THATLAZYADMIN - Export Sent Email Addresses Script" -ForegroundColor Green
Write-Host "================================================================" -ForegroundColor Green

# Function to export sent email addresses
Function Export-SentEmailAddresses {
    param (
        [string]$UserEmailAddress,
        [string]$StartDate,
        [string]$EndDate
    )

    # Connect to Exchange Online
    Write-Host "Connecting to Exchange Online..." -ForegroundColor Cyan

    Try {
        Import-Module ExchangeOnlineManagement -ErrorAction SilentlyContinue
        Connect-ExchangeOnline -ShowProgress $false -WarningAction SilentlyContinue
    }
    Catch {
        Write-Host "Error connecting to Exchange Online: $_" -ForegroundColor Red
        Return
    }

    # Collect recipient email addresses and display names
    $Recipients = @()

    Try {
        Write-Host "Searching sent items..." -ForegroundColor Cyan

        # Use Get-MessageTrace to search for sent items
        $Messages = Get-MessageTrace -SenderAddress $UserEmailAddress -StartDate $StartDate -EndDate $EndDate
        foreach ($Message in $Messages) {
            foreach ($Recipient in $Message.Recipients) {
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
        Write-Host "Number of emails found: $($Messages.Count)" -ForegroundColor Green

        # Export to CSV
        Write-Host "Exporting results to CSV..." -ForegroundColor Cyan
        Try {
            $ExportFilePath = "$PSScriptRoot\SentEmailAddresses_$($UserEmailAddress.Replace('@','_'))_$($StartDate.Replace('/',''))_$($EndDate.Replace('/','')).csv"
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
    $StartDate = Read-Host "Enter start date (MM/dd/yyyy)"
    $EndDate = Read-Host "Enter end date (MM/dd/yyyy)"
    $UserEmailAddress = Read-Host "Enter user email address"

    # Call the function to export sent email addresses
    Export-SentEmailAddresses -UserEmailAddress $UserEmailAddress -StartDate $StartDate -EndDate $EndDate
}
Catch {
    Write-Host "An error occurred: $_" -ForegroundColor Red
}
