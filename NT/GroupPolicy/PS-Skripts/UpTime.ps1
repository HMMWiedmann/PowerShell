<#
.Synopsis
   Retrieves uptime of a windows computer
.DESCRIPTION
   Retrieves uptime of a windows computer by using Windows Remoting via
   TCP Port 5958. The computer must be up and running, Windows Remoting 
   must be enabled.
.EXAMPLE
   Get-ComputerUpTime
.EXAMPLE
   Get-ComputerUpTime -Computername Computer1
.INPUTS
   Pipeline input accepted,
.OUTPUTS
   Output is [string].
.NOTES
   Version 1.0.0
.COMPONENT
   Systems administration
.ROLE
   Administration, helpdesk
.FUNCTIONALITY
   Uptime values can be used to identify the usage of the computer.
#>
function Get-ComputerUpTime
{
    [CmdletBinding(SupportsShouldProcess=$true)]
    [OutputType([String])]
    Param
    (
        # Param1 help description
        [Parameter(Mandatory=$true, 
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true, 
                   Position=0)]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [Alias("Server","CN","Identity")] 
        $Computername
    )

    Begin
    {
    $ErrorActionPreference = "SilentlyContinue"
    $Port = (New-Object net.sockets.tcpclient $Computername, 5985).connected
    if ($Port -eq $null) { Write-Host -ForegroundColor Red "Computer is not running or Windows Remoting not enabled."; Break }
    else { }
    }
    Process
    {
    $TimeSpan = New-TimeSpan `
                -Start `
                        $((Get-CimInstance -ComputerName $Computername -ClassName Win32_OperatingSystem).LastBootUpTime) `
                -End (Get-Date) | Select-Object -Property Hours,Minutes
    }
    End
    {
    if ($TimeSpan.hours -lt 1 -and $TimeSpan.minutes -lt 10) { Write-Host "Freshly rebooted" }
    elseif ($TimeSpan.hours -lt 1 -and $TimeSpan.minutes -ge 10 -and $TimeSpan.hours -lt 8) { Write-Host "Usual computer usage" }
    else { Write-Host "Work horse" }
    }
}
