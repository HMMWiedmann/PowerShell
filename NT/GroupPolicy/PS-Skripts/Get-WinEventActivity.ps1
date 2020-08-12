function Get-WinEventActivity 
{
    [CmdletBinding()]
    param 
    (
        # Computername
        [Parameter(Mandatory = $true)]
        [string]$ComputerName,

        # GUID of Activity
        [Parameter(Mandatory = $true)]
        [string]$ActivityID,

        # Detailed?
        [Parameter(Mandatory = $false)]
        [switch]$Detailed
    )
    
    $ActivityID = $ActivityID -replace "{", ""
    $ActivityID = $ActivityID -replace "}", ""

    switch($Detailed)
    {
        'True'{
            $Events = Get-WinEvent -ComputerName $Computername `
                      -FilterXPath "*[System/Correlation/@ActivityID='{$ActivityID}']" `
                      -LogName 'Microsoft-Windows-GroupPolicy/Operational'

            foreach($Event in $Events)
            {
                Write-Host $Event.ID -ForegroundColor Green -NoNewline
                Write-Host "" $Event.TimeCreated
                Write-Host "-----------------------------------------------"
                $Event.Message | Format-List -Property Message           
                Write-Host "-----------------------------------------------"
                Write-Host ""
            }
        }

        Default {
                    Get-WinEvent -ComputerName $Computername `
                    -FilterXPath "*[System/Correlation/@ActivityID='{$ActivityID}']" `
                    -LogName 'Microsoft-Windows-GroupPolicy/Operational'
        }    
    }
}