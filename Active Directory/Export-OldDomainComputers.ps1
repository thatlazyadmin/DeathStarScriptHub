# Import the Active Directory module
Import-Module ActiveDirectory

# Display a permanent banner
Write-Host "Created by THATLAZYADMIN" -ForegroundColor Yellow -BackgroundColor DarkCyan

# Define the threshold date 200 days ago
$thresholdDate = (Get-Date).AddDays(-200)

# Function to get all computers older than the threshold date
function Get-OldComputers {
    return Get-ADComputer -Filter {LastLogonDate -lt $thresholdDate} -Property Name, LastLogonDate
}

# Function to export computers to CSV
function Export-ComputersToCSV($computers) {
    $csvPath = Join-Path (Get-Location) "OldComputers.csv"
    $computers | Select-Object Name, LastLogonDate | Export-Csv -Path $csvPath -NoTypeInformation
    Write-Output "Results have been exported to '$csvPath'"
}

# Function to delete old computers
function Delete-OldComputers($computers) {
    foreach ($computer in $computers) {
        Remove-ADComputer -Identity $computer.DistinguishedName -Confirm:$false
        Write-Output "Deleted $($computer.Name)"
    }
}

# Main script logic
function Main {
    Write-Output "Select an option:"
    Write-Output "1. List all the old computer accounts and export to CSV file"
    Write-Output "2. Delete all computer accounts found that are older than 200 days"
    $option = Read-Host "Enter your choice (1 or 2)"

    $oldComputers = Get-OldComputers

    switch ($option) {
        '1' {
            if ($oldComputers) {
                Export-ComputersToCSV $oldComputers
            } else {
                Write-Output "No computers found that are older than 200 days."
            }
        }
        '2' {
            if ($oldComputers) {
                $confirm = Read-Host "Are you sure you want to delete all found computers? (Y/N)"
                if ($confirm -eq 'Y') {
                    Delete-OldComputers $oldComputers
                } else {
                    Write-Output "Operation canceled."
                }
            } else {
                Write-Output "No computers found to delete."
            }
        }
        default {
            Write-Output "Invalid option selected."
        }
    }
}

# Run the main function
Main
