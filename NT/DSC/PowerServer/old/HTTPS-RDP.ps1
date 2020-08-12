Import-Module xPSDesiredStateConfiguration

configuration WinRM_HTTPS-RDP
{
    Import-DscResource –ModuleName PSDesiredStateConfiguration 
    Import-DscResource -ModuleName xNetworking

    node VDSCCLIENT-22
    {
       xFirewall WinRM_HTTPS
       {
            Name                  = "WinRM_HTTPS"
            DisplayName           = "WinRM_HTTPS"
            Ensure                = "Present"
            Profile               = ("Domain, Private, Public")
            Direction             = "Inbound"
            RemotePort            = "5986"
            LocalPort             = "Any"        
            Protocol              = "TCP"
            Enabled               = "True"
            Action                = "Allow"
        }
   
        xFirewall RDP-User-TCP
        {
            Name                  = "RemoteDesktop-UserMode-In-TCP"
            Enabled               = "True"
        }

        xFirewall RDP-User-UDP
        {
            Name                  = "RemoteDesktop-UserMode-In-UDP"
            Enabled               = "True"
        }

        xFirewall RDP-Shadow
        {
            Name                  = "RemoteDesktop-Shadow-In-TCP"
            Enabled               = "True"
        }

        Registry RDP-RegistryKey
        {
            Ensure      = "Present"
            Key         = "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Terminal Server"
            ValueName   = "fDenyTSConnections"
            ValueData   = "0"
            ValueType   = "Dword"
        }        
    }
}

WinRM_HTTPS-RDP -OutputPath C:\DSC\Configurations\
Publish-DSCModuleAndMof -Source C:\DSC\Configurations\ -ModuleNameList xNetworking