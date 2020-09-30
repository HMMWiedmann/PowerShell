$CSV = Import-Csv -Path "C:\DSC\CSV\serverlist.csv"

Import-Module xPSDesiredStateConfiguration

foreach($CSV in $CSV)
{

$Server = $CSV.Name
$Role = $CSV.Role
$RDP = $CSV.RDP
$Chrome = $CSV.Chrome

Configuration DSCComplete
{
    Import-DscResource –ModuleName PSDesiredStateConfiguration
    Import-DscResource -ModuleName xNetworking

    node $Server
    {
        # Web Server installieren
        if ($Role -eq "WebServer")
        {
            WindowsFeature WebServer
            {
                Ensure = "Present"
                Name = "Web-Server"
            }
        }

        # File Server installieren
        if ($Role -eq "FileServer")
        {
            WindowsFeature WebServer
            {
                Ensure = "Present"
                Name = "FS-FileServer"
            }
        }

        # RDP Abfrage
        if ($RDP -eq "true")
        {
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

        # Chrome Abfrage
        if ($Chrome -eq "true")
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
}
DSCComplete -OutputPath C:\DSC\Configurations
}
# Publish-DSCModuleAndMof -Source C:\DSC\Configurations