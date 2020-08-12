[DSCLocalConfigurationManager()]
Configuration PullClientConfig
{
    Node $env:COMPUTERNAME
    {
        Settings
        {
            RefreshMode = 'Push'
        }
    }
}

PullClientConfig -OutputPath "C:\DSC\PullclientSetup"
Set-DscLocalConfigurationManager -ComputerName $env:COMPUTERNAME -Path "C:\DSC\PullclientSetup" -Verbose -Force