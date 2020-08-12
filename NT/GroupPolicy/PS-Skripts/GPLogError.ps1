﻿<#
.Synopsis
   Checks the Eventlog "Group Policy/Operational" for fatal errors.
.DESCRIPTION
   Checks the Eventlog "Group Policy/Operational" for fatal errors.
   Based on the activityID the whole process till the error will be
   displayed.
.EXAMPLE
   Get-GPFatalError -Computername Host4711
.EXAMPLE
   Another example of how to use this cmdlet
.NOTES
   Version 1.0.0 - 08/03/2017 Martin Handl - initial
#>
function Get-GPFatalError
{
    [CmdletBinding(SupportsShouldProcess=$true)]
    [Alias("Get-GPFE")]
    Param
    (
        # Param1 help description
        [Parameter(Mandatory=$true, 
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true, 
                   ValueFromRemainingArguments=$false, 
                   Position=0)]
        [Alias("Computer")] 
        $Computername
    )

    Begin
    {
        $PortOpen = Test-NetConnection -ComputerName $Computername -Port 135
        do
        {
            Write-Host -ForegroundColor Yellow -BackgroundColor Black "Probing RCP port - please wait."    
        }
        until (!($PortOpen -eq $null))

        if ($PortOpen.TcpTestSucceeded -eq $false)
        {
            Write-Host -ForegroundColor Yellow -BackgroundColor Black "Computer not found or RPC-Port is not accessible."
            Write-Host -ForegroundColor Yellow -BackgroundColor Black "Terminating script."
            Break
        } else {}
    }
    Process
    {
    $errorIDs = Get-WinEvent `
            } else {
                    Write-Host "Just one activityID has been found."
                    Write-Host "Created on $($errorIDs.TimeCreated) with the ActivityID: $($actIDs) "
                    $result = Get-WinEvent `
                    $result | Out-GridView
            }
        } else {

        Write-Host "`n`n+-------------------- Lucky you! --------------------+"
        Write-Host "`nNo fatal group policy event was detected on $Computername!"
        Write-Host "`nGroup policy does seem to work fine on $Computername!"
        Write-Host "+----------------- Enjoy your day. ------------------+"

        }
    }
    End
    {
    }
}