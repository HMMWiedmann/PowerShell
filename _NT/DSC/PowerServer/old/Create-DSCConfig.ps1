function Create-DSCConfig
{
    param 
    (
        [Parameter(Mandatory = $true)]
        [string]$ClientlistPath,

        [Parameter(Mandatory = $true)]
        [string]$DatabasePath
    )

    $Clientlist = Import-Csv -Path $ClientlistPath

    Import-Module xPSDesiredStateConfiguration

    foreach ($Clientlist in $Clientlist) 
    {
    $NodeName = $ClientList.NodeName
    $WebServer = $ClientList.WebServer
    $FileServer = $ClientList.FileServer
    $RDP = $ClientList.RDP
    $Chrome = $ClientList.Chrome
    
    # Abfragen nach dem Wert 
        if ($FileServer -eq "Present"){}
        elseif ($FileServer -eq "Absent"){}
        else
        {
            Write-Host $NodeName": Falscher Wert -- $FileServer"
            Write-Host ""
        }

        if ($WebServer -eq "Present"){}
        elseif ($WebServer -eq "Absent"){}
        else
        {
            Write-Host $NodeName": Falscher Wert -- $WebServer"
            Write-Host ""   
        }

        if ($RDP -eq "Present"){}
        elseif ($RDP -eq "Absent"){}
        else
        {
            Write-Host $NodeName": Falscher Wert -- $RDP"
            Write-Host ""   
        }

        if ($Chrome -eq "Present"){}
        elseif ($Chrome -eq "Absent"){}
        else
        {
            Write-Host $NodeName": Falscher Wert -- $Chrome"
            Write-Host ""   
        }

    
    Configuration DSCConfig-Automation
    {
        Import-DscResource –ModuleName PSDesiredStateConfiguration
        Import-DscResource -ModuleName xNetworking

        node $NodeName
        {
            # Web Server installieren
            WindowsFeature WebServer
            {
                Ensure = $WebServer
                Name = "Web-Server"
            }
        
            # File Server installieren                
            WindowsFeature FileServer
            {
                Ensure = $FileServer
                Name = "FS-FileServer"
            }        

            # RDP
            if ($RDP -eq "Present")
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
            elseif ($RDP -eq "Absent")
            {
                xFirewall RDP-User-TCP
                {
                    Name                  = "RemoteDesktop-UserMode-In-TCP"
                    Enabled               = "False"
                }

                xFirewall RDP-User-UDP
                {
                    Name                  = "RemoteDesktop-UserMode-In-UDP"
                    Enabled               = "False"
                }

                xFirewall RDP-Shadow
                {
                    Name                  = "RemoteDesktop-Shadow-In-TCP"
                    Enabled               = "False"
                }

                Registry RDP-RegistryKey
                {
                    Ensure      = "Present"
                    Key         = "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Terminal Server"
                    ValueName   = "fDenyTSConnections"
                    ValueData   = "1"
                    ValueType   = "Dword"
                }
            }
    
            # Chrome Abfrage
            Package Chrome
            {
                Ensure      = $Chrome 
                Path        = "\\VCCDSC-02.mail.cluster-center.de\tools\googlechromestandaloneenterprise64.msi"
                Name        = "Google Chrome"
                ProductId   = "E093BF8F-9D6D-342E-ADAC-7BD6F40C3BDE"
            }
        }
    }
    DSCConfig-Automation -OutputPath "$DatabasePath\DSCDatabase\Configurations"
    }
    Publish-DSCModuleAndMof -Source "$DatabasePath\DSCDatabase\Configurations" -ModuleNameList xNetworking 
}