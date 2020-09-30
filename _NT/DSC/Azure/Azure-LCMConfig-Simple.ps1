$RegistrationUrl    = 'https://we-agentservice-prod-1.azure-automation.net/accounts/a5a168e1-a39a-4bcb-bfd6-937ca435aa71'
$RegistrationKey    = 'yOnimIUqWuNv2T2gHiQCrpqDNEgxh6IMO8m2ODKSEPISeri3mye8jahGoAnlBIWv6aQv+TJyxnPMwLhdOZbgHg=='
$ConfigurationNames = 'WebServer.IsWebServer'
$LCMConfigPath      = 'C:\DSC\LCMConfig'

[DscLocalConfigurationManager()]
Configuration Azure-LCMConfig
{
    Node $env:COMPUTERNAME
    {
        Settings
        {
            RefreshFrequencyMins           = 30
            RefreshMode                    = 'Pull'
            ConfigurationMode              = 'ApplyAndAutoCorrect'
            RebootNodeIfNeeded             = $true
            ActionAfterReboot              = 'ContinueConfiguration'
            ConfigurationModeFrequencyMins = 15
        }

        ConfigurationRepositoryWeb 'AZ-MF-AutomationAccount'
        {
            ServerUrl          = $RegistrationUrl
            RegistrationKey    = $RegistrationKey
            ConfigurationNames = $ConfigurationNames
        }

        ResourceRepositoryWeb 'AZ-MF-AutomationAccount'
        {
            ServerUrl       = $RegistrationUrl
            RegistrationKey = $RegistrationKey
        }

        ReportServerWeb 'AZ-MF-AutomationAccount'
        {
            ServerUrl       = $RegistrationUrl
            RegistrationKey = $RegistrationKey
        }
    }
}

Azure-LCMConfig -OutputPath $LCMConfigPath
Set-DscLocalConfigurationManager -ComputerName $env:COMPUTERNAME -Path $LCMConfigPath -Verbose -Force
Update-DscConfiguration -Wait -Verbose -ComputerName $env:COMPUTERNAME