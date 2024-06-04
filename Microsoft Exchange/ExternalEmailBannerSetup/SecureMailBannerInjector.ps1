<#
.SYNOPSIS
ExternalEmailBannerSetup - Automate Security Alerts for External Emails

.DESCRIPTION
This PowerShell script enhances security within Microsoft Exchange Online by automatically appending a customizable warning banner to emails received from outside the organization. It is designed to help users approach external communications with heightened caution and vigilance.

.KEY FEATURES
- Customizable Banner: Modify the text, colors, and font to align the banner with your organization’s identity and security messaging.
- Automatic Application: Sets up a mail flow rule that automatically applies the banner to all incoming external emails, ensuring consistent implementation.
- Priority Setting: Establishes the rule with high priority to ensure it takes precedence over other mail flow rules.

.USAGE
Ideal for organizations that handle frequent external communications, mitigating risks associated with phishing and other malicious attacks through increased user awareness.

.HOW IT WORKS
1. Connects to Exchange Online using PowerShell.
2. Creates a new mail flow rule that appends a customizable disclaimer or warning banner to emails from outside the organization.
3. Provides customization options for the disclaimer and includes instructions for ensuring functionality across different email clients.

.BENEFITS
- Enhances security posture by alerting users to the external origin of emails.
- Reduces administrative workload by automating external email marking.
- Improves compliance with security policies requiring clear labeling of external communications.

.CREATED BY
Shaun Hardneck - www.thatlazyadmin.com
#>

# Connect to Exchange Online PowerShell without warnings
Connect-ExchangeOnline -showb

try {
     # Define the disclaimer text with HTML styling for spacing
     $DisclaimerText = "<p style='font-size:14px; font-family:Calibri, sans-serif; color: #FF0000; margin-bottom:20px;'>"
     $DisclaimerText += "<strong>Caution:</strong> This email originated from outside of the organization. "
     $DisclaimerText += "Do not click links or open attachments unless you recognize the sender and know the content is safe.</p>"
 
     # Create the mail flow rule with the updated disclaimer
     New-TransportRule -Name "ExternalSenderAlert" `
                       -FromScope NotInOrganization `
                       -ApplyHtmlDisclaimerText $DisclaimerText `
                       -ApplyHtmlDisclaimerLocation Prepend `
                       -Priority 0

    # Check and confirm the rule is created and enabled
    $rule = Get-TransportRule -Identity "ExternalSenderAlert"
    if ($rule) {
        Write-Host "The mail flow rule 'ExternalSenderAlert' has been successfully created and is now active." -ForegroundColor Green
    } else {
        Write-Host "Failed to verify the rule. Please check the rule configuration." -ForegroundColor Red
    }
} catch {
    Write-Host "Failed to create the rule. Error: $($_.Exception.Message)" -ForegroundColor Red
}
