$RegistrationUrl    = 'https://we-agentservice-prod-1.azure-automation.net/accounts/e2c241ef-27be-43f8-97ff-626024e17b6d'
$RegistrationKey    = '9vxmIJ737V2E9pl1SPwjNDUDf7qTWXlrOEBzQEzDd+383i55CkGN7hFRyqQhbYocrIhyizQEOFM5pxsQqVBY6g=='
$ConfigurationNames = 'WebServer.IsWebServer'

$RegistrationUrl2   = 'https://we-agentservice-prod-1.azure-automation.net/accounts/750a302b-aefb-462b-9d53-8c6c7e94c8c8'
$RegistrationKey2   = 'WK9f5iVtmJ8ai9fXkZ0tPoOH92C3F5nXnQe7Qu1gzMAUibrVqnlcu/EiGFsIX/bamxDL1/X+Thzw2mzm23p3+w=='
$ConfigurationNames2 = 'FileServer.IsFileServer'

$LCMConfigPath = 'C:\DSC\LCMConfig'

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
            AllowModuleOverwrite           = $true 
        }

        # Pull Server 1
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

        PartialConfiguration 'WebServer'
        {
            ConfigurationSource = '[ConfigurationRepositoryWeb]AZ-MF-AutomationAccount'
            RefreshMode         = 'Pull'
        }

        # Pull Server 2
        ConfigurationRepositoryWeb 'AZ-MF-AutomationAccount2'
        {
            ServerUrl          = $RegistrationUrl2
            RegistrationKey    = $RegistrationKey2
            ConfigurationNames = $ConfigurationNames2
        }

        ResourceRepositoryWeb 'AZ-MF-AutomationAccount2'
        {
            ServerUrl       = $RegistrationUrl2
            RegistrationKey = $RegistrationKey2
        }

        PartialConfiguration 'FileServer'
        {
            ConfigurationSource = '[ConfigurationRepositoryWeb]AZ-MF-AutomationAccount2'
            RefreshMode         = 'Pull'
        }
    }
}

Azure-LCMConfig -OutputPath $LCMConfigPath
Set-DscLocalConfigurationManager -ComputerName $env:COMPUTERNAME -Path $LCMConfigPath -Verbose -Force