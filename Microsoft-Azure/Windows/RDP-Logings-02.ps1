<#
.SYNOPSIS
  Get remote desktop sessions for a specified computer or computers, from the Terminal
  Services event log. Adapted from https://serverfault.com/a/687079/78216, https://ss64.com/ps/get-winevent.html
  Requires appropriate permission on computers to call Get-WinEvent remotely, PowerShell Active Directory module.
  By Thomas Williams <https://github.com/thomasswilliams>
.DESCRIPTION
  Pass one or more computer names, or run without parameters to be prompted for computer name(s).
.PARAMETER computers
  Computer or computers to get Remote Desktop history for.
.EXAMPLE
  $DebugPreference = "Continue"; & '.\remote-desktop-history.ps1'; $DebugPreference = "SilentlyContinue"
  Runs with debug statements, prompts for a computer, and turns debug statements off at the end.
.EXAMPLE
  .\remote-desktop-history.ps1 "PC1"
  Gets Remote Desktop history for computer "PC1".
.EXAMPLE
  .\remote-desktop-history.ps1 "PC1", "PC2", "SERVER1"
  Gets Remote Desktop history for computers "PC1", "PC2", "SERVER1".
#>
[CmdletBinding()]
Param(
  [Parameter(Mandatory = $false,
             Position = 0,
             ValueFromPipeline = $true,
             ValueFromPipelineByPropertyName = $true,
             HelpMessage = "Computer or computers to get Remote Desktop history for.")]
  [String[]]$computers
)
Begin {
  # Active Directory module needed for Get-ADUser
  Import-Module ActiveDirectory -Verbose:$false
}
Process {
  # error on coding violations
  Set-StrictMode -Version Latest

  Function getDisplayNameFromUser($userName) {
    <#
      .SYNOPSIS
        Get the user object from AD using default settings, and return the display name.
        Expects Windows login without domain.
    #>
    Try {
      # note getting user object may error, if so return empty string
      # expand the name property otherwise will get object e.g. "@{ name=xxx }"
      Return Get-ADUser $userName -ErrorAction SilentlyContinue | Select-Object -ExpandProperty name
    } Catch {
      Return [string]::Empty
    }
  }

  # if passed computer name is empty, prompt user
  If ([string]::IsNullOrEmpty($computers)) {
    # get user input (string)
    [string]$input_from_user = Read-Host "Remote Desktop history
Enter computer name (blank to quit)"
    # if user input contains comma or space characters, split into computer collection
    If ($input_from_user.indexOf(",") -gt -1) {
      $computers = $input_from_user -Split ","
    } ElseIf ($input_from_user.indexOf(" ") -gt -1) {
      $computers = $input_from_user -Split " "
    } Else {
      # set computers collection to user input
      $computers = $input_from_user
    }
  }
  # check for cancel here
  If ([string]::IsNullOrEmpty($computers)) {
    Write-Output "No computer entered, quitting..."
    Exit
  }
  # set up filter for Get-WinEvent
  $filter = @{
    # specified event log:
    #  "The following is a list of Remote Desktop Services events that can appear in the event log
    #   of a computer that is running a Remote Desktop Services role service, such as Remote Desktop
    #   Session Host or Remote Desktop Gateway. The events can be viewed by using Event Viewer."
    # see docs at https://technet.microsoft.com/en-au/library/ff404144%28v=ws.10%29.aspx?f=255&MSPPError=-2147217396
    # "...includes both RDP logins as well as regular console logins too" as per https://gallery.technet.microsoft.com/scriptcenter/Remote-Desktop-Connection-3fe225cd
    LogName = "Microsoft-Windows-TerminalServices-LocalSessionManager/Operational"
    # last 180 days only
    # note event log may not retain events back this far, depending on max size and overwrite settings
    StartTime = (Get-Date).AddDays(-180)
    # limit to events:
    #  21 = logon
    #  23 = logoff
    #  24 = disconnected
    #  25 = reconnection
    ID = 21, 23, 24, 25
  }

  # loop through computers collection
  ForEach ($computer in $computers) {
    # reset timer
    $TimerStart = Get-Date

    # if the computer is online
    If (Test-Connection $computer -Count 1 -Quiet -ErrorAction SilentlyContinue) {
      Write-Debug "$computer is online, about to get events from event log..."

      Try {
        # empty results collection for starters
        $Results = @()
        # get events collection from log for computer, for specified filter
        # this may fail if the user running this script does not have permissions e.g. is a non-admin user
        # see https://social.technet.microsoft.com/Forums/lync/en-US/b72162d1-2c86-4d1a-9727-ec7269814cc4/getwinevent-with-nonadministrative-user?forum=winserverpowershell for potential workaround (not tested)
        $Events = Get-WinEvent -ComputerName $computer -FilterHashtable $filter

        "Got $($Events.Count ?? 0) events from $computer in " + [math]::Round((New-Timespan -Start $TimerStart -End $(Get-Date)).TotalSeconds, 2) + " seconds" | ForEach-Object { Write-Debug $_ }

        # reset progress counter
        $progress_counter = 0
        # pre-calculate event count variable to avoid recalculating in loop
        $Events_count = $Events.Count

        # loop through each event in returned events
        ForEach ($Event in $Events) {
          # increment progress counter
          $progress_counter++
          # output progress
          Write-Progress -Activity "Processing $($Events_count) events from $($computer)..." -Status " " -PercentComplete ($progress_counter/$Events_count * 100)

          # convert to XML to better access some nested properties
          $EventXml = [xml]$Event.ToXML()
          # if the XML has nested property for source IP address, get that, else empty string
          # some events do not have a source IP address e.g. logoff
          $source_ip = [string]::Empty
          If (Get-Member -InputObject $EventXml.Event.UserData.EventXML -Name Address -MemberType Properties) {
            $source_ip = $EventXml.Event.UserData.EventXML.Address
          }

          # put together array of properties from event log, and extract nested
          # properties like user and IP
          $Result = @{
            Computer = $computer
            # remove seconds & format event time to unambiguous month format d/MMM/YYYY (because, Aussie here)
            # can change date & time format - set to "G" for instance for general date long time using local regional settings
            Time = $Event.TimeCreated.toString("d/MMM/yyyy h:mmtt")
            "Event ID" = $Event.Id
            # get just the first line of the event message
            "Desc" = ($Event.Message -split [environment]::NewLine)[0]
            # (optional) remove leading domain from username
            Username = [string]$EventXml.Event.UserData.EventXML.User.Replace("DOMAIN\", [string]::Empty)
            # get display name from AD for the user, pass to "getDisplayNameFromUser" function, remove leading domain
            DisplayName = getDisplayNameFromUser([string]$EventXml.Event.UserData.EventXML.User.Replace("DOMAIN\", [string]::Empty))
            "Source IP" = $source_ip
          }

          # include this event in the results collection
          # add "event description" property determined by event ID
          $Results += (New-Object PSObject -Property $Result) |
          Select-Object Computer, Time, Username, DisplayName, "Source IP",
            @{ Name = "Event description"; Expression = {
                If ($Event.Id -eq "21") { "Logon" }
                If ($Event.Id -eq "23") { "Logoff" }
                If ($Event.Id -eq "24") { "Disconnected" }
                If ($Event.Id -eq "25") { "Reconnection" }
              }
            }
        }

        # output subset of results to console, formatted as a table with width adjusted
        $Results | Select-Object -First 40 | Format-Table -Property * -AutoSize
      } Catch {
        $msg = "Error getting events on $computer" + ": " + $error[0].ToString()
        Write-Error $msg
      }
    } Else {
      Write-Warning "The computer $computer is not contactable, skipping..."
    }
  }
  # return successfully
  # environment error code will equal zero by default
  Write-Debug "Done!"
  Exit
}