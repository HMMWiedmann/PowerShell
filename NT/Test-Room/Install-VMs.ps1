function Install-VMs 
{
    [CmdletBinding()]
    param 
    (
        # Platznummmern in Form von "01","02","03", usw.
        [Parameter(Mandatory = $true)]
        $Platznummern,

        # Der Anfang des VM Namens, wie VWIN10-xx
        [Parameter(Mandatory = $true)]
        [string]$VMNameStart,

        # Pfad zur Parentdisk
        [Parameter(Mandatory = $true)]
        [string]$ParentdiskPath,

        # Root-Verzeichnis der VMs
        [Parameter(Mandatory = $false)]
        [string]$VMRootFolder,

        # Anzahl der Prozessorkerne
        [Parameter(Mandatory = $false)]
        [int]$CPUCoreCount,

        # RAM-Größe in GB
        [Parameter(Mandatory = $false)]
        [System.Int64]$RAMSizeIngGB,

        # Name des VM Switches
        [Parameter(Mandatory = $false)]
        [string]$VMSwitchName,

        # soll es eine differencing Disk werden?
        [Parameter(Mandatory = $false)]
        [bool]$Differencing,

        #################################################################

        # Domain Name, wenn ein Wert eingetragen wird, wird die VM eingeklingt
        [Parameter(Mandatory = $false)]
        [string]$DomainName,

        #################################################################

        # DoIPConfig ja oder nein
        [Parameter(Mandatory = $false, ParameterSetName = "DoIPConfig")]
        [bool]$DoIPConfig,

        # IP Prefix, Beispiel "192.168.1.". Die IPAdresse setzt sich wie folgt zusammen: ( $IPAddressStart + $Platznummer + $IPAddressEnd )
        [Parameter(Mandatory = $false, ParameterSetName = "DoIPConfig")]
        [string]$IPAddressStart,

        # IP Suffix, Beispiel "5"
        [Parameter(Mandatory = $false, ParameterSetName = "DoIPConfig")]
        [string]$IPAddressEnd,

        # DNS Adressen, beispiel @("192.168.1.201","192.168.2.202")
        [Parameter(Mandatory = $false, ParameterSetName = "DoIPConfig")]
        $DNSAddresses,

        # Gateway Adresse, Beispiel "192.168.1.254"
        [Parameter(Mandatory = $false, ParameterSetName = "DoIPConfig")]
        [string]$GatewayAddress

        #################################################################
    )
    
    begin 
    {
        $ErrorActionPreference = "Stop"

        [System.Collections.ArrayList]$VMNames = @()

        foreach($Platz in $Platznummern)
        { 
            $VMNames.add($VMNameStart + $Platz) 
        }

        if (!$CPUCoreCount){ $CPUCoreCount = 2 }
        if (!$RAMSizeIngGB){ $RAMSizeIngGB = 2GB }
        if (!$VMSwitchName){ $VMSwitchName = "EXTERNAL" }
        if (!$VMRootFolder){ $VMRootFolder = "V:\" }

        # VM Credentials
        $OSType = (Get-WindowsImage -ImagePath $ParentdiskPath -Index 1).InstallationType
        if ($OSType -eq "Server") 
        {
            # Local Server Credentials
            [string]$LocalAdmin = "Administrator"
            $LocalPWD = ConvertTo-SecureString "C0mplex" -AsPlainText -Force
                            
            $VMCred = New-Object -TypeName System.Management.Automation.PSCredential ($LocalAdmin, $LocalPWD)  
        }
        elseif ($OSType -eq "Client")     
        {
            # Local Client Credentials
            [string]$LocalAdmin = "Admin"
            $LocalPWD = ConvertTo-SecureString "C0mplex" -AsPlainText -Force
                            
            $VMCred = New-Object -TypeName System.Management.Automation.PSCredential ($LocalAdmin, $LocalPWD)     
        }

        if ($null -ne $DomainName) 
        {
            # Domain Credentials
            [string]$DomainAdmin = "Administrator@$DomainName"
            $DomainPWD = ConvertTo-SecureString "C0mplex" -AsPlainText -Force
            $DomainCredential = New-Object -TypeName System.Management.Automation.PSCredential ($DomainAdmin, $DomainPWD)
        }
    }
    
    process 
    {
        foreach ($Name in $VMNames)
        {
            if(($VMRootFolder.Substring($VMRootFolder.Length - 2)) -notlike "*\")
            {
                $VMRootFolder = $VMRootFolder + "\"
            }

            $null = New-Item -Path "$($VMRootFolder)$($Name)\" -ItemType Directory -Force
            if ($Differencing -eq $false) 
            {            
                Copy-Item -Path $ParentdiskPath -Destination "$($VMRootFolder)$($Name)\$($Name).vhdx" -Force
            }
            elseif ($Differencing -eq $true) 
            {
                $null = New-VHD -Path "$($VMRootFolder)$($Name)\$($Name).vhdx" -Differencing -ParentPath $ParentdiskPath
            }
            $null = New-VM -Name $Name -MemoryStartupBytes $RAMSizeIngGB -Path $VMRootFolder -Generation 2 -VHDPath "$($VMRootFolder)$($Name)\$($Name).vhdx" -BootDevice VHD
            Set-VMProcessor -VMName $Name -Count $CPUCoreCount
            Connect-VMNetworkAdapter -VMNetworkAdapter (Get-VMNetworkAdapter -VMName $Name) -SwitchName $VMSwitchName


            Start-VM -VMName $Name

            While((Invoke-Command -VMName $Name -Credential $VMCred { "Test" } -ErrorAction SilentlyContinue) -ne "Test")
            {
                Start-Sleep -Seconds 3
            }
            Start-Sleep -Seconds 10

            Invoke-Command -VMName $Name -Credential $VMCred -ScriptBlock{ Rename-Computer -NewName $using:Name -Restart -Force }

            While((Invoke-Command -VMName $Name -Credential $VMCred { "Test" } -ErrorAction SilentlyContinue) -ne "Test")
            {
                Start-Sleep -Seconds 3
            }
            Start-Sleep -Seconds 10
            

            # VM Konfiguration
            $Platznummer = $Name.Substring($Name.Length -2)

            if($Platznummer[0] -eq "0")
            {
                $Platznummer = $Platznummer.Substring($Platznummer.Length - 1)
            }

            $IPAddress = ($IPAddressStart + $Platznummer + $IPAddressEnd)

            Invoke-Command -VMName $Name -Credential $VMCred -ScriptBlock `
            {
                $NetAdapterIndex = (Get-NetAdapter).InterfaceIndex

                # alte config entfernen
                Remove-NetIPAddress -InterfaceIndex $NetAdapterIndex -Confirm:$false
                Set-DnsClientServerAddress -ResetServerAddresses -InterfaceIndex $NetAdapterIndex
                Remove-NetRoute -InterfaceIndex $NetAdapterIndex -Confirm:$false
                Set-NetIPInterface -InterfaceIndex $NetAdapterIndex -Dhcp Disabled

                # neue config setzen
                $null = New-NetIPAddress -IPAddress $using:IPAddress -InterfaceIndex $NetAdapterIndex -DefaultGateway $using:GatewayAddress -AddressFamily IPv4 -PrefixLength 24
                Set-DnsClientServerAddress -InterfaceIndex $NetAdapterIndex -ServerAddresses $using:DNSAddresses

                # firewall aus
                Set-NetFirewallProfile -All -Enabled False

                # Language Installer Task deaktivieren
                $null = Disable-ScheduledTask -TaskName Installation -TaskPath \Microsoft\Windows\LanguageComponentsInstaller

                # RDP aktivieren
                Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Terminal Server" -Name "fDenyTSConnections" -Value 0 -Force
                Enable-NetFirewallRule -DisplayGroup "Remote Desktop"
            }
        }

        <#region zusätzliche Platte

        foreach ($Name in $VMNames)
        {   
            New-VHD -Path V:\$($Name)\$($Name)-20GB.vhdx -SizeBytes 20GB -Fixed
            Add-VMHardDiskDrive -VMName $Name -Path V:\$($Name)\$($Name)-20GB.vhdx -ControllerType SCSI -ControllerNumber 0 -ControllerLocation 2
        }

        Invoke-Command -VMName $VMNames -Credential $VMCred -ScriptBlock `
        { 
            $Disk = Get-Disk | Where-Object -Property Size -eq 20GB
            Set-Disk -Number $Disk.Number -IsOffline $false
            New-Volume -DiskNumber $Disk.Number -FriendlyName Share -FileSystem NTFS -DriveLetter S
        }
        endregion#>
    }
    
    end 
    {

    }
}