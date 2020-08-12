$DSCServerURL = 'https://VXH2-DSC01.XCHANGE-HYBRID2.DE:4711/PSDSCPullServer.svc'
$RegistrationKey = 'ea03b889-bb83-4cd7-ab49-8c53e9eac419'

[DSCLocalConfigurationManager()]
Configuration PullClientConfig
{
    Node $env:COMPUTERNAME
    {
        Settings
        {
            RefreshMode = 'Pull'
            RefreshFrequencyMins = 30
            RebootNodeIfNeeded = $true
            ConfigurationMode = 'ApplyAndAutoCorrect'
        }

        ConfigurationRepositoryWeb SetPullClient
        {
            ServerURL = $DSCServerURL
            RegistrationKey = $RegistrationKey
            ConfigurationNames = $env:COMPUTERNAME
        }
      
        ReportServerWeb SetReportServer
        {
            ServerURL = $DSCServerURL
        }
    }
}

PullClientConfig -OutputPath "C:\DSC\PullclientSetup"
Set-DscLocalConfigurationManager -ComputerName $env:COMPUTERNAME -Path "C:\DSC\PullclientSetup" -Verbose -Force