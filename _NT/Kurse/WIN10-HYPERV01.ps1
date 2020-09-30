#$VMNames10 = "VWIN10-01", "VWIN10-02","VWIN10-03", "VWIN10-04", "VWIN10-05", "VWIN10-06", "VWIN10-07", "VWIN10-08", "VWIN10-09", "VWIN10-10", "VWIN10-15"
#$VMNames7  = "VWIN7-01",  "VWIN7-02", "VWIN7-03",  "VWIN7-04",  "VWIN7-05",  "VWIN7-06",  "VWIN7-07",  "VWIN7-08",  "VWIN7-09",  "VWIN7-10",  "VWIN7-15"

$VMNames10 = "VWIN10-04", "VWIN10-05", "VWIN10-06", "VWIN10-15"
$VMNames7 = "VWIN7-04", "VWIN7-05", "VWIN7-06", "VWIN7-15"
$ParentdiskPath10 = "C:\Parentdisks\WIN10-1803-ENT-x64-GEN2-AW-MAI.vhdx"
$ParentdiskPath7 = "C:\Parentdisks\WIN7SP1-ENTERPRISE-EN-x64-60Dyn-AW.vhdx"
$VMSwitchName = "SET"
$VMRootLetter = 'V'

Set-VMHost -VirtualMachinePath ($VMRootLetter + ":\") -VirtualHardDiskPath ($VMRootLetter + ":\")
Set-VMHost -EnableEnhancedSessionMode $true

function Enable-WIN10HYPERV01 
{
    [CmdletBinding()]
    param 
    (
        # VMNames Windows 10 
        [Parameter(Mandatory = $true)]
        [System.Collections.ArrayList]
        $VMNames10,

        # VMNames Windows 7
        [Parameter(Mandatory = $true)]
        [System.Collections.ArrayList]
        $VMNames7,

        # Parentdiskpath of Windows 10 VHDX
        [Parameter(Mandatory = $true)]
        [string]
        $Parentdiskpath10,

        # Parentdiskpath of Windows 7 VHDX
        [Parameter(Mandatory = $true)]
        [string]
        $ParentdiskPath7,

        # VMSwitchName for the VMs
        [Parameter(Mandatory = $true)]
        [string]
        $VMSwitchName,

        # Letter of VM Volume
        [Parameter(Mandatory = $true)]
        [char]
        $VMRootLetter
    )
    
    begin 
    {
        $DomainName = "ADS-CENTER.DE"
        $DNSServers = @("192.168.1.201","192.168.2.202")
        $Gateway = "192.168.1.254"
        $IPStart = "192.168.1."
        $IPEnd7 = "3"
        $IPEnd10 = "4"

        $CPUCount = 4
        $Ram = 4GB

        Write-Host "Creating Volume for VMs, using all available Disks."
        Add-Volume4VMs -VMRootLetter $VMRootLetter

        Write-Host "Creating VM Switch, using all physical and available NICs"
        Add-VMSwitch4VMs -VMSwitchName $VMSwitchName

        # Local Client Credentials
        [string]$LocalAdmin = "Admin"
        $LocalPWD = ConvertTo-SecureString "C0mplex" -AsPlainText -Force                
        $VMCred = New-Object -TypeName System.Management.Automation.PSCredential ($LocalAdmin, $LocalPWD) 
    }
    
    process 
    {
        Write-Host "Copying the Parentdisks to " + ($VMRootLetter + ":\")
        Copy-VHDXParallel -ParentdiskPath $ParentdiskPath7 -VMDriveLetter V -VMNames $VMNames7
        Copy-VHDXParallel -ParentdiskPath $ParentdiskPath10 -VMDriveLetter V -VMNames $VMNames10
        
        Write-Host "Creating Windows 10 VMs."
        foreach ($Name in $VMNames10)
        {
            $null = New-VM -Name $Name -MemoryStartupBytes $Ram -Path ($VMRootLetter + ":\") -Generation 2 -VHDPath ($VMRootLetter + ":\") + "$($Name)\$($Name).vhdx" -BootDevice VHD
            Set-VMProcessor -VMName $Name -Count $CPUCount
            Connect-VMNetworkAdapter -VMNetworkAdapter (Get-VMNetworkAdapter -VMName $Name) -SwitchName $VMSwitchName
            "Starting VM: $Name"
            Start-VM -VMName $Name
        }
        
        Write-Host "Configuring Windows 10 VMs."
        foreach ($Name in $VMNames10)
        {
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
        
            $Platznummer = $Name.Substring($Name.Length -2)
            if($Platznummer[0] -eq "0")
            {
                $Platznummer = $Platznummer.Substring($Platznummer.Length - 1)
            }
            $IPAddress = $IPStart + $Platznummer + $IPEnd10
        
            While((Invoke-Command -VMName $Name -Credential $VMCred { "Test" } -ErrorAction SilentlyContinue) -ne "Test")
            {
                 Start-Sleep -Seconds 3
            }
            Start-Sleep -Seconds 10
            
            Invoke-Command -VMName $Name -Credential $VMCred -ScriptBlock `
            {
                Remove-NetIPAddress -InterfaceIndex (Get-NetAdapter).InterfaceIndex -Confirm:$false
                Set-DnsClientServerAddress -ResetServerAddresses -InterfaceIndex (Get-NetAdapter).InterfaceIndex
                Set-NetIPInterface -InterfaceIndex (Get-NetAdapter).InterfaceIndex -Dhcp Disabled
                $null = New-NetIPAddress -IPAddress $using:IPAddress -InterfaceIndex (Get-NetAdapter).InterfaceIndex -DefaultGateway $using:Gateway -AddressFamily IPv4 -PrefixLength 24
                Set-DnsClientServerAddress -InterfaceIndex (Get-NetAdapter).InterfaceIndex -ServerAddresses $using:DNSServers
        
                Set-NetFirewallProfile -All -Enabled False
                $null = Disable-ScheduledTask -TaskName Installation -TaskPath \Microsoft\Windows\LanguageComponentsInstaller
        
                Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Terminal Server" -Name "fDenyTSConnections" -Value 0 -Force
                Enable-NetFirewallRule -DisplayGroup "Remote Desktop"
            }
        }

        Write-Host "Creating Windows 7 VMs."
        foreach ($Name in $VMNames7)
        {
            $null = New-VM -Name $Name -MemoryStartupBytes $Ram -Path ($VMRootLetter + ":\") -Generation 1 -VHDPath ($VMRootLetter + ":\") + "$($Name)\$($Name).vhdx" -BootDevice VHD
            Set-VMProcessor -VMName $Name -Count $CPUCount
            Connect-VMNetworkAdapter -VMNetworkAdapter (Get-VMNetworkAdapter -VMName $Name) -SwitchName $VMSwitchName
        }
        
        Write-Host "Configuring Windows 7 VMs."
        foreach ($VMName in $VMNames7)
        {
            New-Item -Name "$($VMName).cmd" -ItemType file -Path ($VMRootLetter + ":\") + "$VMName\" | Out-Null
            New-Item -Name "$($VMName).ps1" -ItemType file -Path ($VMRootLetter + ":\") + "$VMName\" | Out-Null
            Add-Content -Path ($VMRootLetter + ":\") + "$VMName\$($VMName).cmd" -value "powershell.exe Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Force"
            Add-Content -Path ($VMRootLetter + ":\") + "$VMName\$($VMName).cmd" -value "powershell.exe -noexit C:\SetupTemp\$($VMName).ps1"
            Add-Content -Path ($VMRootLetter + ":\") + "$VMName\$($VMName).ps1" -value "Set-NetFirewallProfile -All -Enabled '$''false'"
            Add-Content -Path ($VMRootLetter + ":\") + "$VMName\$($VMName).ps1" -value "Set-ItemProperty -Path `'HKLM:\System\CurrentControlSet\Control\Terminal Server`'-name `"fDenyTSConnections`" -Value 0"
            Add-Content -Path ($VMRootLetter + ":\") + "$VMName\$($VMName).ps1" -value "Enable-NetFirewallRule -DisplayGroup `"Remote Desktop`""
            Add-Content -Path ($VMRootLetter + ":\") + "$VMName\$($VMName).ps1" -value "`$Cred = New-object System.Management.Automation.PSCredential `"administrator@$DomainName`", (ConvertTo-SecureString -String `"C0mplex`" -AsPlainText -Force)"
        
            $Platznummer = $Name.Substring($Name.Length -2)
            if($Platznummer[0] -eq "0")
            {
                $Platznummer = $Platznummer.Substring($Platznummer.Length - 1)
            }
            $IPAddress = $IPStart + $Platznummer + $IPEnd7
        
            Add-Content -Path ($VMRootLetter + ":\") + "$VMName\$($VMName).ps1" -value "New-NetIPAddress -InterfaceAlias ethernet -IPAddress $IPAddress -PrefixLength 24 -DefaultGateway $Gateway"
            Add-Content -Path ($VMRootLetter + ":\") + "$VMName\$($VMName).ps1" -value "Set-DnsClientServerAddress -InterfaceAlias ethernet -ResetServerAddresses"
            Add-Content -Path ($VMRootLetter + ":\") + "$VMName\$($VMName).ps1" -value "Set-DnsClientServerAddress -InterfaceAlias ethernet -ServerAddresses $DNSServers"
        
            Add-Content -Path ($VMRootLetter + ":\") + "$VMName\$VMName.ps1" -value "Rename-Computer -NewName $VMName -Restart"
            
            Write-Verbose "Mounting $VMName.vhdx and copying the automated setup files."
            $driveb4 = (Get-PSDrive).Name
            Mount-VHD -Path ($VMRootLetter + ":\") + "$VMName\$VMName.vhdx"
            $driveat = (Get-PSDrive).name
            $drive = (Compare-Object -ReferenceObject $driveb4 -DifferenceObject $driveat).inputobject[-1] + ':'
            New-Item -Path $drive\SetupTemp -ItemType Directory | Out-Null
            Set-Location -Path $drive\SetupTemp | Out-Null
            Copy-Item -Path ($VMRootLetter + ":\") + "$VMName\$VMName.cmd" -Destination . | Out-Null
            Copy-Item -Path ($VMRootLetter + ":\") + "$VMName\$VMName.ps1" -Destination . | Out-Null
            Set-Location -Path c: | Out-Null
            Dismount-VHD -Path ($VMRootLetter + ":\") + "$VMName\$VMName.vhdx"
            Write-Verbose "Dismounted $VMName.vhdx successfully."
        
            "Starting VM: $VMName"
            Start-VM -VMName $VMName
            "Please use the Config-Skript at C:\SetupTemp for additional configuration!"
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


Enable-WIN10HYPERV01  -VMNames10 $VMNames10 `
                       -VMNames7 $VMNames7 `
                       -Parentdiskpath10 $ParentdiskPath10 `
                       -ParentdiskPath7 $ParentdiskPath7 `
                       -VMSwitchName $VMSwitchName `
                       -VMRootLetter $VMRootLetter