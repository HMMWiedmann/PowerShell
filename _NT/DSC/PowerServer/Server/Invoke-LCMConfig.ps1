function Invoke-LCMConfig
{
    param 
    (
        [Parameter(Mandatory = $true, Position = 2)]
        [ValidateSet("Push","Pull","Disabled")]
        [string]$RefreshMode,

        [Parameter(Mandatory = $true, Position = 1)]
        [string]$ClientListPath,

        [Parameter(Mandatory = $true, Position = 3)]
        [string]$RegistrationKey,

        [Parameter(Mandatory = $true, Position = 4)]
        [string]$DSCServerURL,

        [Parameter(Mandatory = $false, Position = 5)]
        [string]$DatabasePath
    )

    if($DatabasePath = $null)
    {
        $DatabasePath = "C:"
    }

    $ClientList = Import-Csv -Path $ClientListPath

    foreach ($ClientList in $ClientList)
    {
        $ClientName = $ClientList.NodeName

        [DSCLocalConfigurationManager()]
        Configuration PullClientConfig
        {
            Node $ClientName
            {
                Settings
                {
                    RefreshMode = $RefreshMode
                    RefreshFrequencyMins = 30
                    RebootNodeIfNeeded = $true
                    ConfigurationMode = 'ApplyAndAutoCorrect'
                    ActionAfterReboot = 'ContinueConfiguration'
                }

                ConfigurationRepositoryWeb SetPullClient
                {
                    ServerURL          = $DSCServerURL
                    RegistrationKey    = $RegistrationKey
                    ConfigurationNames = $ClientName
                }

                ReportServerWeb SetDSCReportClient
                {
                    ServerURL = $DSCServerURL
                    RegistrationKey = $RegistrationKey
                }
            }
        }
        PullClientConfig -OutputPath "$DatabasePath\DSCDatabase\LCMConfigs"
        Set-DscLocalConfigurationManager -ComputerName $ClientName -Path "$DatabasePath\DSCDatabase\LCMConfigs" -Verbose -Force
    }
}