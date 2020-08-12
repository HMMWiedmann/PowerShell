# https://docs.microsoft.com/de-de/powershell/dsc/partialconfigs

[DSCLocalConfigurationManager()]
configuration PartialConfigDemo
{
    Node localhost
    {
        PartialConfiguration ServiceAccountConfig
        {
            Description = 'Configuration to add the SharePoint service account to the Administrators group.'
            RefreshMode = 'Push'
        }
           PartialConfiguration SharePointConfig
        {
            Description = 'Configuration for the SharePoint server'
            RefreshMode = 'Push'
        }
    }
}

PartialConfigDemo