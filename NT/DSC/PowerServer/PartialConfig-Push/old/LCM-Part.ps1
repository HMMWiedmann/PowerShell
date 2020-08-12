$LCMConfigPath = 'C:\DSC\LCMConfig' 

[DscLocalConfigurationManager()]
Configuration PartialTest
{
    Node $env:COMPUTERNAME
    {
        Settings
        {
            ConfigurationMode = 'ApplyAndAutoCorrect'
            RebootNodeIfNeeded = $true
        }

        PartialConfiguration Text1
        {
            RefreshMode = 'Push'
        }

        PartialConfiguration Text2
        {
            RefreshMode = 'Push'
        }

        PartialConfiguration Text3
        {
            RefreshMode = 'Push'
        }
    }
}

PartialTest -OutputPath $LCMConfigPath