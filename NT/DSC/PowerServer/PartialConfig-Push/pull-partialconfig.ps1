$RegistrationKey = '5b41f4e6-5e6d-45f5-8102-f2227468ef38'
$ServerURL = 'https://CONTOSO-PullSrv:8080/PSDSCPullServer.svc'

[DscLocalConfigurationManager()]
Configuration PartialConfigDemoConfigNames
{
        Settings
        {
            RefreshFrequencyMins            = 30;
            RefreshMode                     = "PULL";
            ConfigurationMode               ="ApplyAndAutocorrect";
            AllowModuleOverwrite            = $true;
            RebootNodeIfNeeded              = $true;
        }
        ConfigurationRepositoryWeb CONTOSO-PullSrv
        {
            ServerURL                       = $ServerURL
            RegistrationKey                 = $RegistrationKey
            ConfigurationNames              = @("File1", "File2")
        }

        PartialConfiguration File1
        {
            Description                     = "ServiceAccountConfig"
            ConfigurationSource             = @("[ConfigurationRepositoryWeb]CONTOSO-PullSrv")
        }

        PartialConfiguration File2
        {
            Description                     = "SharePointConfig"
            ConfigurationSource             = @("[ConfigurationRepositoryWeb]CONTOSO-PullSrv")
        }
}