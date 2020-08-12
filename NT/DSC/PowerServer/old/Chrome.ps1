Import-Module xPSDesiredStateConfiguration

configuration Chrome
{    
    Import-DscResource –ModuleName PSDesiredStateConfiguration
    
    node VDSCCLIENT-22
    {
        Package Chrome
        {
            Ensure      = "Present"  
            Path        = "\\VCCDSC-02.mail.cluster-center.de\tools\googlechromestandaloneenterprise64.msi"
            Name        = "Google Chrome"
            ProductId   = "E093BF8F-9D6D-342E-ADAC-7BD6F40C3BDE"
        }
    }
}

Chrome -OutputPath C:\DSC\ConfigurationsPublish-DSCModuleAndMof -Source C:\DSC\Configurations