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
            ServerURL = 'https://VCCDSC-01:4711/PSDSCPullServer.svc'
            RegistrationKey = 'e5aa82fd-bcc8-4407-8fb7-28ff48a8473b'
            ConfigurationNames = $env:COMPUTERNAME
        }
    }
}

PullClientConfig -OutputPath "C:\DSC\PullclientSetup"
Set-DscLocalConfigurationManager -ComputerName $env:COMPUTERNAME -Path "C:\DSC\PullclientSetup" -Verbose -Force