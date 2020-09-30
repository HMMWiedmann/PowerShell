$VMNames = "SCCM-01", "SCCM-02", "VFILE-01"
$ParentdiskPath = "C:\Parentdisks\W2K19-Net.35-Gen2-80GB-AW.437.vhdx"
$VMSwitchName = "SET"
$VMRootLetter = 'V'
$DoDomainJoin = $false

Set-VMHost -VirtualMachinePath ($VMRootLetter + ":\") -VirtualHardDiskPath ($VMRootLetter + ":\")
Set-VMHost -EnableEnhancedSessionMode $true

function Enable-WIN10HYPERV02
{
    [CmdletBinding()]
    param 
    (
        # VMNames Windows 10 
        [Parameter(Mandatory = $true)]
        [System.Collections.ArrayList]
        $VMNames, 

        # Parentdiskpath of Windows 10 VHDX
        [Parameter(Mandatory = $true)]
        [string]
        $ParentdiskPath,

        # VMSwitchName for the VMs
        [Parameter(Mandatory = $true)]
        [string]
        $VMSwitchName,

        # Letter of VM Volume
        [Parameter(Mandatory = $true)]
        [char]
        $VMRootLetter,

        # Do Domain Join
        [Parameter(Mandatory = $true)]
        [bool]
        $DoDomainJoin
    )
    
    begin 
    {
        $CPUCount = 8
        $Ram = 16GB
        $DomainName = "ADS-CENTER.DE"
        $DNSServers = @("192.168.1.201","192.168.2.202")
        $Gateway = "192.168.1.254"

        # Local Server Credentials
        [string]$LocalAdmin = "Administrator"
        $LocalPWD = ConvertTo-SecureString "C0mplex" -AsPlainText -Force                
        $VMCred = New-Object -TypeName System.Management.Automation.PSCredential ($LocalAdmin, $LocalPWD)  

        if ($DoDomainJoin -eq $true) 
        {
            # Domain Credentials
            [string]$DomainAdmin = "Administrator@$DomainName"
            $DomainPWD = ConvertTo-SecureString "C0mplex" -AsPlainText -Force
            $DomainCredential = New-Object -TypeName System.Management.Automation.PSCredential ($DomainAdmin, $DomainPWD)
        }

        Write-Host "Creating Volume for VMs, using all available Disks."
        Add-Volume4VMs -VMRootLetter $VMRootLetter

        Write-Host "Creating VM Switch, using all physical and available NICs"
        Add-VMSwitch4VMs -VMSwitchName $VMSwitchName
    }
    
    process 
    {
        Write-Host "Die Parentdisks werden kopiert."
        Copy-VHDXParallel -ParentdiskPath $ParentdiskPath -VMDriveLetter $VMRootLetter -VMNames $VMNames

        Write-Host "Die VMs werden erstellt und umbennant."
        foreach ($Name in $VMNames)
        {
            $null = New-VM -Name $Name -MemoryStartupBytes $Ram -Path V:\ -Generation 2 -VHDPath "V:\$($Name)\$($Name).vhdx" -BootDevice VHD
            Set-VMProcessor -VMName $Name -Count $CPUCount
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
        }

        Write-Host "Die VMs werden konfguriert."

        # SCCM-01
        $null = New-VHD -Path ($VMRootLetter + ":\") + "SCCM-01\SCCM-01-200GB.vhdx" -SizeBytes 200GB -Fixed
        $null = New-VHD -Path ($VMRootLetter + ":\") + "SCCM-01\SCCM-01-40GB.vhdx" -SizeBytes 40GB -Fixed
        $null = Add-VMHardDiskDrive -VMName "SCCM-01" -Path ($VMRootLetter + ":\") + "SCCM-01\SCCM-01-200GB.vhdx" -ControllerType SCSI -ControllerNumber 0 -ControllerLocation 2
        $null = Add-VMHardDiskDrive -VMName "SCCM-01" -Path ($VMRootLetter + ":\") + "SCCM-01\SCCM-01-40GB.vhdx" -ControllerType SCSI -ControllerNumber 0 -ControllerLocation 3
        Invoke-Command -VMName "SCCM-01" -Credential $VMCred -ScriptBlock `
        {
            $NetAdapter = (Get-NetAdapter).InterfaceIndex

            Remove-NetIPAddress -InterfaceIndex $NetAdapter -Confirm:$false
            Set-DnsClientServerAddress -ResetServerAddresses -InterfaceIndex $NetAdapter
            Set-NetIPInterface -InterfaceIndex (Get-NetAdapter).InterfaceIndex -Dhcp Disabled
            $null = New-NetIPAddress -IPAddress "192.168.1.7" -InterfaceIndex $NetAdapter -DefaultGateway $using:Gateway -AddressFamily IPv4 -PrefixLength 24
            Set-DnsClientServerAddress -InterfaceIndex $NetAdapter -ServerAddresses $using:DNSServers

            Set-NetFirewallProfile -All -Enabled False
            $null = Disable-ScheduledTask -TaskName Installation -TaskPath \Microsoft\Windows\LanguageComponentsInstaller

            Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Terminal Server" -Name "fDenyTSConnections" -Value 0 -Force
            Enable-NetFirewallRule -DisplayGroup "Remote Desktop"

            $Disk = Get-Disk | Where-Object -Property Size -eq 200GB
            Set-Disk -Number $Disk.Number -IsOffline $false
            New-Volume -DiskNumber $Disk.Number -FriendlyName ContentLib -FileSystem NTFS -DriveLetter L

            $Disk = Get-Disk | Where-Object -Property Size -eq 40GB
            Set-Disk -Number $Disk.Number -IsOffline $false
            $null = New-Volume -DiskNumber $Disk.Number -FriendlyName SQL -FileSystem NTFS -DriveLetter S

            New-Item -ItemType Directory -Force -Path S:\SQL\PBB\

            if ($using:DoDomainJoin -eq $true) 
            {
                Add-Computer -Credential $using:DomainCredential -DomainName $using:DomainName -Restart
            }
        }

        # SCCM-02
        $null = New-VHD -Path ($VMRootLetter + ":\") + "SCCM-02\SCCM-02-200GB.vhdx" -SizeBytes 200GB -Fixed
        $null = Add-VMHardDiskDrive -VMName "SCCM-02" -Path ($VMRootLetter + ":\") + "SCCM-02\SCCM-02-200GB.vhdx" -ControllerType SCSI -ControllerNumber 0 -ControllerLocation 2
        Invoke-Command -VMName "SCCM-02" -Credential $VMCred -ScriptBlock `
        {
            $NetAdapter = (Get-NetAdapter).InterfaceIndex

            Remove-NetIPAddress -InterfaceIndex $NetAdapter -Confirm:$false
            Set-DnsClientServerAddress -ResetServerAddresses -InterfaceIndex $NetAdapter
            Set-NetIPInterface -InterfaceIndex $NetAdapter -Dhcp Disabled
            $null = New-NetIPAddress -IPAddress "192.168.1.8" -InterfaceIndex $NetAdapter -DefaultGateway $using:Gateway -AddressFamily IPv4 -PrefixLength 24
            Set-DnsClientServerAddress -InterfaceIndex $NetAdapter -ServerAddresses $using:DNSServers

            Set-NetFirewallProfile -All -Enabled False
            $null = Disable-ScheduledTask -TaskName Installation -TaskPath \Microsoft\Windows\LanguageComponentsInstaller

            Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Terminal Server" -Name "fDenyTSConnections" -Value 0 -Force
            Enable-NetFirewallRule -DisplayGroup "Remote Desktop"

            $Disk = Get-Disk | Where-Object -Property Size -eq 200GB
            Set-Disk -Number $Disk.Number -IsOffline $false
            New-Volume -DiskNumber $Disk.Number -FriendlyName ContentLib -FileSystem NTFS -DriveLetter L

            if ($using:DoDomainJoin -eq $true) 
            {
                Add-Computer -Credential $using:DomainCredential -DomainName $using:DomainName -Restart
            }
        }

        # VFILE-01
        $null = New-VHD -Path ($VMRootLetter + ":\") + "VFILE-01\VFILE-01-200GB.vhdx" -SizeBytes 200GB -Fixed
        $null = Add-VMHardDiskDrive -VMName "VFILE-01" -Path ($VMRootLetter + ":\") + "VFILE-01\VFILE-01-200GB.vhdx" -ControllerType SCSI -ControllerNumber 0 -ControllerLocation 2
        Invoke-Command -VMName "VFILE-01" -Credential $VMCred -ScriptBlock `
        {
            $NetAdapter = (Get-NetAdapter).InterfaceIndex

            Remove-NetIPAddress -InterfaceIndex $NetAdapter -Confirm:$false
            Set-DnsClientServerAddress -ResetServerAddresses -InterfaceIndex $NetAdapter
            Set-NetIPInterface -InterfaceIndex $NetAdapter -Dhcp Disabled
            $null = New-NetIPAddress -IPAddress "192.168.1.3" -InterfaceIndex $NetAdapter -DefaultGateway $using:Gateway -AddressFamily IPv4 -PrefixLength 24
            Set-DnsClientServerAddress -InterfaceIndex $NetAdapter -ServerAddresses $using:DNSServers

            Set-NetFirewallProfile -All -Enabled False
            $null = Disable-ScheduledTask -TaskName Installation -TaskPath \Microsoft\Windows\LanguageComponentsInstaller

            Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Terminal Server" -Name "fDenyTSConnections" -Value 0 -Force
            Enable-NetFirewallRule -DisplayGroup "Remote Desktop"

            $Disk = Get-Disk | Where-Object -Property Size -eq 200GB
            Set-Disk -Number $Disk.Number -IsOffline $false
            $null = New-Volume -DiskNumber $Disk.Number -FriendlyName Shares -FileSystem NTFS -DriveLetter S

            $null = Install-WindowsFeature -Name FS-FileServer
            $null = Install-WindowsFeature -Name DHCP -IncludeManagementTools -Restart

            if ($using:DoDomainJoin -eq $true) 
            {
                Add-Computer -Credential $using:DomainCredential -DomainName $using:DomainName -Restart
            }
        }
    }
    
    end 
    {
        Write-Host "All VMs are ready!"
    }
}

#Hilfsfunktionen
$Scriptpath = Get-Item -Path (Get-Item -Path $PSScriptRoot).PSParentPath
$Functions = "$Scriptpath\Funktionen"
. "$Functions\Add-VMSwitch4VMs.ps1"
. "$Functions\Add-Volume4VMs.ps1"
. "$Functions\Copy-VHDXParallel.ps1"

Enable-WIN10HYPERV02 -VMNames $VMNames `
                     -Parentdiskpath $ParentdiskPath `
                     -VMSwitchName $VMSwitchName `
                     -VMRootLetter $VMRootLetter `
                     -DoDomainJoin $DoDomainJoin