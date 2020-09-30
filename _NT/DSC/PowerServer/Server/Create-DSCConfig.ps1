function Create-DSCConfig
{
    [CmdletBinding()]
    param 
    (
        [Parameter(Mandatory = $true, Position = 1)]
        [string]$NodelistPath
    )

    $ConfigPath = "C:\DSC\MOF_Files\"

    $Nodelist = Import-Csv -Path $NodelistPath

    Import-Module xPSDesiredStateConfiguration

    foreach ($Node in $Nodelist) 
    {
        $NodeName = $Node.NodeName
        $WebServer = $Node.WebServer
        $FileServer = $Node.FileServer
        $RDP = $Node.RDP
        $Chrome = $Node.Chrome
        $ErrorActionPreference = "Stop" # Bei einem Fehler stoppt das Skript
        
        #region Werteüberprüfung
        if (!($FileServer -eq "Present" -or $FileServer -eq "Absent"))
        {
            Write-Error $NodeName" -- FileServer: Falscher Wert -- $FileServer"
            Write-Host ""
        }

        if (!($WebServer -eq "Present" -or $WebServer -eq "Absent"))
        {
            Write-Error $NodeName" -- WebServer: Falscher Wert -- $WebServer"
            Write-Host ""
        }

        if (!($RDP -eq "Present" -or $RDP -eq "Absent"))
        {
            Write-Error $NodeName" -- RDP: Falscher Wert -- $RDP"
            Write-Host ""
        }

        if (!($Chrome -eq "Present" -or $Chrome -eq "Absent"))
        {
            Write-Error $NodeName" -- Chrome: Falscher Wert -- $Chrome"
            Write-Host ""
        }
        #endregion

        #region DSC Konfiguration
        Configuration DSCConfig
        {
            Import-DscResource –ModuleName PSDesiredStateConfiguration
            Import-DscResource -ModuleName NetworkingDSC

            node $NodeName
            {
                # Web Server 
                WindowsFeature WebServer
                {
                    Ensure = $WebServer
                    Name = "Web-Server"
                }
            
                # File Server            
                WindowsFeature FileServer
                {
                    Ensure = $FileServer
                    Name = "FS-FileServer"
                }        

                # RDP
                if ($RDP -eq "Present") 
                {
                    $FirewallRule = "True"
                    $RegistryKey = "0"
                }
                elseif ($RDP -eq "Absent") 
                {
                    $FirewallRule = "False"
                    $RegistryKey = "1"   
                }

                Firewall RDP-User-TCP
                {
                    Name                  = "RemoteDesktop-UserMode-In-TCP"
                    Enabled               = $FirewallRule
                }

                Firewall RDP-User-UDP
                {
                    Name                  = "RemoteDesktop-UserMode-In-UDP"
                    Enabled               = $FirewallRule
                }

                Firewall RDP-Shadow
                {
                    Name                  = "RemoteDesktop-Shadow-In-TCP"
                    Enabled               = $FirewallRule
                }

                Registry RDP-RegistryKey
                {
                    Ensure      = "Present"
                    Key         = "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Terminal Server"
                    ValueName   = "fDenyTSConnections"
                    ValueData   = $RegistryKey
                    ValueType   = "Dword"
                }
        
                # Chrome Abfrage
                Package Chrome
                {
                    Ensure      = $Chrome 
                    Path        = "\\VXH2-DSC01.XCHANGE-HYBRID2.DE\tools\googlechromestandaloneenterprise64.msi"
                    Name        = "Google Chrome"
                    ProductId   = "B8B9997D-0338-3ECC-BEA2-EB79462E1D64"
                }
            }
        }
        #endregion
        
        DSCConfig -OutputPath $ConfigPath
    }

    Publish-DSCModuleAndMof -Source $ConfigPath -ModuleNameList NetworkingDSC -Force
}