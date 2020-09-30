function Prestage-DSCClients
{
    param
    (
        [Parameter(Mandatory = $true)]
        [string]$OUPath,

        [Parameter(Mandatory = $true)]
        [string]$ClientListPath
    )

    $ClientList = Import-Csv -Path $ClientListPath

    foreach ($ClientList in $ClientList)
    {
        $MACAdress = $ClientList.MACAdresse
        $ClientName = $ClientList.NodeName
        [guid]$Guid = "00000000-0000-0000-0000-$MACAdress"

        # Hinzufügen
        New-ADComputer -Name $ClientName -OtherAttributes @{'NetBootGuid' = $Guid } -Path $OUPath 

        # Gruppe und ComputerObject festlegen
        $ComputerObject = Get-ADComputer -Identity $ClientName
        $Group = (Get-ADGroup -Identity "UG-WDS-DSC").ObjectGuid 

        # Object zur Gruppe hinzufügen
        Add-ADGroupMember -Identity $Group -Members $ComputerObject    
    }
}