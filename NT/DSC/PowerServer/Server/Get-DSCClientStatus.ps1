function Get-DSCClientStatus
{
    # $Credentials steht für die Anmeldedaten am Client
    # $NumOfLastStatuses steht für die Anzahl der anzuzeigenden Jobs pro Client
    # $ClientListPath gibt den Pfad zu CSV-Datei an
    
    Param
    (
        [Parameter(Mandatory = $true)]
        [pscredential]$Credentials,

        [Parameter(Mandatory = $true)]
        [ValidateRange(1,50)]
        [Int32]$NumOfLastStatuses,
        
        [Parameter(Mandatory = $true)]
        [string]$ClientListPath
    )
    
    $ClientList = Import-Csv -Path $ClientListPath

    foreach ($ClientList in $ClientList)
    {
        $ClientName = $ClientList.NodeName
        $CimSession = New-CimSession -ComputerName $ClientName -Credential $Credentials
        $Status = Get-DscConfigurationStatus -CimSession $CimSession -All | Select-Object -First $NumOfLastStatuses
        $Status | Select-Object PSComputerName,Status,Type,StartDate
        $CiminstanceID = ($CimSession).InstanceId
        Remove-CimSession -InstanceId $CiminstanceID
    } 
}   