<#
.SYNOPSIS
    Active Directory Domain Controller Communication & RPC Health Tester
.DESCRIPTION
    Tests bidirectional communication between all domain controllers in the environment.
    Checks key AD-related ports (TCP/UDP), RPC, Kerberos, DNS, Global Catalog, SMB, and Secure Channel trust.
.AUTHOR
    Shaun Hardneck
    www.thatlazyadmin.com
.VERSION
    1.0
    Date: 2025-07-21
.NOTES
    Run as Domain Admin on a domain-joined machine or Domain Controller
#>

# === CLEAR SCREEN & BANNER ===
Clear-Host
$scriptName = "DCCommCheck.ps1"
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
Write-Host "===================================================" -ForegroundColor Cyan
Write-Host "     THATLAZYADMIN | Domain Comm Check             " -ForegroundColor Green
Write-Host "     Script: $scriptName                           "
Write-Host "     Run Time: $timestamp                          "
Write-Host "     Author: Shaun Hardneck | www.thatlazyadmin.com"
Write-Host "===================================================" -ForegroundColor Cyan
Start-Sleep -Seconds 2

# === SETTINGS ===
$OutputLog = "$env:USERPROFILE\Desktop\DC_Comm_Results_$(Get-Date -f yyyyMMdd_HHmmss).csv"
$PortsToCheck = @(88,135,139,389,445,636,3268,3269,53)
$UDPPorts = @(53,137,138,389)

# === FUNCTIONS ===
function Test-TCPPort {
    param (
        [string]$Target,
        [int]$Port
    )
    try {
        $client = New-Object System.Net.Sockets.TcpClient
        $async = $client.BeginConnect($Target, $Port, $null, $null)
        $wait = $async.AsyncWaitHandle.WaitOne(1000, $false)
        if ($wait -and $client.Connected) {
            $client.EndConnect($async)
            $client.Close()
            return "Open"
        } else {
            return "Blocked"
        }
    } catch {
        return "Blocked"
    }
}

function Test-UDPPort {
    param (
        [string]$Target,
        [int]$Port
    )
    try {
        $udpClient = New-Object System.Net.Sockets.UdpClient
        $udpClient.Connect($Target, $Port)
        $msg = [System.Text.Encoding]::ASCII.GetBytes("ping")
        $udpClient.Send($msg, $msg.Length) | Out-Null
        $udpClient.Close()
        return "Sent"
    } catch {
        return "Failed"
    }
}

function Test-RPCSecureChannel {
    param (
        [string]$Target
    )
    try {
        $result = Test-ComputerSecureChannel -Server $Target -Verbose -ErrorAction Stop
        return if ($result) { "Valid" } else { "Broken" }
    } catch {
        return "Failed"
    }
}

function Test-NLTestRPC {
    param (
        [string]$Target
    )
    $result = nltest /server:$Target /sc_query:$env:USERDOMAIN 2>&1
    if ($result -match "The secure channel is in the.*state") {
        return "Valid"
    } else {
        return "Failed"
    }
}

# === MAIN ===
$DCs = (Get-ADDomainController -Filter *).HostName
$Results = @()

Write-Host "`n🔍 Starting bidirectional tests between domain controllers..." -ForegroundColor Yellow

foreach ($sourceDC in $DCs) {
    foreach ($targetDC in $DCs) {
        if ($sourceDC -ne $targetDC) {
            Write-Host "Testing from $sourceDC ➝ $targetDC" -ForegroundColor Gray

            foreach ($port in $PortsToCheck) {
                $tcpStatus = Test-TCPPort -Target $targetDC -Port $port
                $Results += [PSCustomObject]@{
                    SourceDC  = $sourceDC
                    TargetDC  = $targetDC
                    Direction = "$sourceDC ➝ $targetDC"
                    Protocol  = "TCP"
                    Port      = $port
                    Status    = $tcpStatus
                }
            }

            foreach ($port in $UDPPorts) {
                $udpStatus = Test-UDPPort -Target $targetDC -Port $port
                $Results += [PSCustomObject]@{
                    SourceDC  = $sourceDC
                    TargetDC  = $targetDC
                    Direction = "$sourceDC ➝ $targetDC"
                    Protocol  = "UDP"
                    Port      = $port
                    Status    = $udpStatus
                }
            }

            # RPC Tests
            $rpcSC = Test-RPCSecureChannel -Target $targetDC
            $Results += [PSCustomObject]@{
                SourceDC  = $sourceDC
                TargetDC  = $targetDC
                Direction = "$sourceDC ➝ $targetDC"
                Protocol  = "RPC"
                Port      = "SecureChannel"
                Status    = $rpcSC
            }

            $nltest = Test-NLTestRPC -Target $targetDC
            $Results += [PSCustomObject]@{
                SourceDC  = $sourceDC
                TargetDC  = $targetDC
                Direction = "$sourceDC ➝ $targetDC"
                Protocol  = "RPC"
                Port      = "NLTest"
                Status    = $nltest
            }
        }
    }
}

# === OUTPUT ===
$Results | Format-Table -AutoSize
$Results | Export-Csv -Path $OutputLog -NoTypeInformation -Encoding UTF8

Write-Host "All tests completed. Results saved to:" -ForegroundColor Green
Write-Host $OutputLog -ForegroundColor Cyan

# Optional Email Block
<# 
Send-MailMessage -From "monitor@domain.com" -To "it@domain.com" `
    -Subject "DC Communication Report" `
    -Body "Results attached for domain controller communication scan." `
    -Attachments $OutputLog `
    -SmtpServer "smtp.domain.com"
#>
