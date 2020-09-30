Import-Module xPSDesiredStateConfiguration

configuration FileServer
{    
    Import-DscResource –ModuleName PSDesiredStateConfiguration
    
    node VDSCCLIENT-22
    {
        
        WindowsFeature FileServer
        {
           Ensure = "Present"
           Name = "FS-FileServer"
        }
    }
}

FileServer -OutputPath C:\DSC\ConfigurationsPublish-DSCModuleAndMof -Source C:\DSC\Configurations 