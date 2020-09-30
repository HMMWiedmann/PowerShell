Import-Module xPSDesiredStateConfiguration

configuration WebServer
{    
    Import-DscResource –ModuleName PSDesiredStateConfiguration
    
    node VDSCCLIENT-22
    {
        
        WindowsFeature FileServer
        {
           Ensure = "Absent"
           Name = "FS-FileServer"
        }

        WindowsFeature WebServer
        {
            Ensure = "Present"
            Name = "Web-Server"
        }
    }
}

WebServer -OutputPath C:\DSC\ConfigurationsPublish-DSCModuleAndMof -Source C:\DSC\Configurations 