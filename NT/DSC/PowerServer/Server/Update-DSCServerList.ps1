workflow Update-DSCServerList
{
    Param
    (
        [Parameter(Mandatory = $true)]
        [PSCredential]
        $Credentials,

        [Parameter(Mandatory = $true)]
        $ClientListPath
    )
    
    $ClientList = Import-Csv -Path $ClientListPath

    foreach -parallel ($ClientList in $ClientList)
    {
        $NodeName = $ServerList.NodeName
        $ServerName = "$NodeName.$env:USERDNSDOMAIN"

       InlineScript
       {
            Update-DscConfiguration -Verbose -Wait
       } -PSComputerName $ServerName -PSCredential $Credentials         
    } 
} 