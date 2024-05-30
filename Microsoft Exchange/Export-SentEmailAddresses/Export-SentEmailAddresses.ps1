# Permanent Banner
Write-Host "================================================================"
Write-Host " URBANNERD CONSULTING - Export Sent Email Addresses Script"
Write-Host "================================================================"

# Function to select subscription
Function Select-Subscription {
    Write-Host "Returning to subscription selection..."
    # Your subscription selection logic here
}

# Function to export sent email addresses
Function Export-SentEmailAddresses {
    param (
        [string]$UserEmailAddress,
        [datetime]$StartDate,
        [datetime]$EndDate
    )

    # Connect to Exchange Online
    Write-Host "Connecting to Exchange Online..."
    $UserCredential = Get-Credential

    Try {
        Connect-ExchangeOnline -ShowBanner
    }
    Catch {
        Write-Host "Error connecting to Exchange Online: $_"
        Return
    }

    # Collect recipient email addresses and display names
    $Recipients = @()

    Try {
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
        Write-Host "Error retrieving message trace: $_"
        Disconnect-ExchangeOnline -Confirm:$false
        Return
    }

    # Export to CSV
    Write-Host "Exporting results to CSV..."
    $ExportFilePath = "$env:USERPROFILE\Desktop\SentEmailAddresses_$($UserEmailAddress.Replace('@','_'))_$($StartDate.ToString('yyyyMMdd'))_$($EndDate.ToString('yyyyMMdd')).csv"
    $Recipients | Export-Csv -Path $ExportFilePath -NoTypeInformation

    Write-Host "Export completed: $ExportFilePath"

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
    Write-Host "An error occurred: $_"
    Select-Subscription
}
