# Import necessary modules
Import-Module ActiveDirectory
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

function Show-Message {
    param (
        [string]$message
    )
    [System.Windows.Forms.MessageBox]::Show($message)
}

function Search-Group {
    $searchForm = New-Object System.Windows.Forms.Form
    $searchForm.Text = "Group Search"
    $searchForm.Size = New-Object System.Drawing.Size(400, 300)

    $label = New-Object System.Windows.Forms.Label
    $label.Text = "Search for Group:"
    $label.Location = New-Object System.Drawing.Point(10, 20)
    $searchForm.Controls.Add($label)

    $txtSearch = New-Object System.Windows.Forms.TextBox
    $txtSearch.Location = New-Object System.Drawing.Point(120, 18)
    $txtSearch.Width = 200
    $searchForm.Controls.Add($txtSearch)

    $lstGroups = New-Object System.Windows.Forms.ListBox
    $lstGroups.Location = New-Object System.Drawing.Point(10, 60)
    $lstGroups.Size = New-Object System.Drawing.Size(350, 150)
    $searchForm.Controls.Add($lstGroups)

    $btnSearch = New-Object System.Windows.Forms.Button
    $btnSearch.Text = "Search"
    $btnSearch.Location = New-Object System.Drawing.Point(330, 18)
    $btnSearch.Add_Click({
        $lstGroups.Items.Clear()
        $groups = Get-ADGroup -Filter "Name -like '*$($txtSearch.Text)*'" -Properties Name | Select-Object -ExpandProperty Name
        foreach ($group in $groups) {
            $lstGroups.Items.Add($group)
        }
    })
    $searchForm.Controls.Add($btnSearch)

    $btnSelect = New-Object System.Windows.Forms.Button
    $btnSelect.Text = "Select"
    $btnSelect.Location = New-Object System.Drawing.Point(150, 220)
    $btnSelect.Add_Click({
        $selectedGroup = $lstGroups.SelectedItem
        $searchForm.Tag = $selectedGroup
        $searchForm.Close()
    })
    $searchForm.Controls.Add($btnSelect)

    $searchForm.ShowDialog()

    return $searchForm.Tag
}

function Generate-Password {
    $length = 12
    $chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#$%^&*()"
    $password = -join ((65..90) + (97..122) + (48..57) + (33..47) | Get-Random -Count $length | % {[char]$_})
    return $password
}

function Create-UserForm {
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "Create New User"
    $form.Size = New-Object System.Drawing.Size(400, 450)
    
    $labelFN = New-Object System.Windows.Forms.Label
    $labelFN.Text = "First Name:"
    $labelFN.Location = New-Object System.Drawing.Point(10, 20)
    $form.Controls.Add($labelFN)

    $txtFN = New-Object System.Windows.Forms.TextBox
    $txtFN.Location = New-Object System.Drawing.Point(120, 18)
    $txtFN.Width = 200
    $form.Controls.Add($txtFN)

    $labelLN = New-Object System.Windows.Forms.Label
    $labelLN.Text = "Last Name:"
    $labelLN.Location = New-Object System.Drawing.Point(10, 60)
    $form.Controls.Add($labelLN)

    $txtLN = New-Object System.Windows.Forms.TextBox
    $txtLN.Location = New-Object System.Drawing.Point(120, 58)
    $txtLN.Width = 200
    $form.Controls.Add($txtLN)

    $labelUPN = New-Object System.Windows.Forms.Label
    $labelUPN.Text = "User Principal Name:"
    $labelUPN.Location = New-Object System.Drawing.Point(10, 100)
    $form.Controls.Add($labelUPN)

    $txtUPN = New-Object System.Windows.Forms.TextBox
    $txtUPN.Location = New-Object System.Drawing.Point(120, 98)
    $txtUPN.Width = 200
    $form.Controls.Add($txtUPN)

    $labelOU = New-Object System.Windows.Forms.Label
    $labelOU.Text = "Organizational Unit:"
    $labelOU.Location = New-Object System.Drawing.Point(10, 140)
    $form.Controls.Add($labelOU)

    $txtOU = New-Object System.Windows.Forms.TextBox
    $txtOU.Location = New-Object System.Drawing.Point(120, 138)
    $txtOU.Width = 200
    $form.Controls.Add($txtOU)

    $labelGroup = New-Object System.Windows.Forms.Label
    $labelGroup.Text = "Add to Group:"
    $labelGroup.Location = New-Object System.Drawing.Point(10, 180)
    $form.Controls.Add($labelGroup)

    $txtGroup = New-Object System.Windows.Forms.TextBox
    $txtGroup.Location = New-Object System.Drawing.Point(120, 178)
    $txtGroup.Width = 200
    $txtGroup.ReadOnly = $true
    $form.Controls.Add($txtGroup)

    $btnGroup = New-Object System.Windows.Forms.Button
    $btnGroup.Text = "Search"
    $btnGroup.Location = New-Object System.Drawing.Point(330, 178)
    $btnGroup.Add_Click({
        $selectedGroup = Search-Group
        if ($selectedGroup) {
            $txtGroup.Text = $selectedGroup
        }
    })
    $form.Controls.Add($btnGroup)

    $btnCreate = New-Object System.Windows.Forms.Button
    $btnCreate.Text = "Create User"
    $btnCreate.Location = New-Object System.Drawing.Point(150, 350)
    $btnCreate.Add_Click({
        $firstName = $txtFN.Text
        $lastName = $txtLN.Text
        $upn = $txtUPN.Text
        $ou = $txtOU.Text
        $group = $txtGroup.Text
        $password = Generate-Password

        try {
            New-ADUser -GivenName $firstName -Surname $lastName -UserPrincipalName $upn -SamAccountName $upn.Split('@')[0] `
                -Path $ou -AccountPassword (ConvertTo-SecureString $password -AsPlainText -Force) -Enabled $true
            
            if ($group) {
                Add-ADGroupMember -Identity $group -Members $upn.Split('@')[0]
            }

            $body = @"
Hello,

The new user $firstName $lastName has been successfully created in Active Directory.
User Principal Name: $upn
Password: $password

Please ensure the user changes the password upon first login.

Best regards,
IT Team
"@

            Show-Message "User $firstName $lastName created successfully!"
            Send-MailMessage -From "no-reply@company.com" -To "admin@company.com" -Subject "New User Created: $firstName $lastName" -Body $body -SmtpServer "smtp.company.com"
        }
        catch {
            Show-Message "Error creating user: $_"
        }
    })
    $form.Controls.Add($btnCreate)

    $form.ShowDialog()
}

Create-UserForm
