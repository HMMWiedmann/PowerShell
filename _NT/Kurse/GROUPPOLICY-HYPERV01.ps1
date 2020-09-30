# Hilfsfunktionen
workflow Copy-parallel
{
    param 
    (
        [Parameter(Mandatory = $true)]
        [string]$ParentdiskPath,

        [Parameter(Mandatory = $true)]
        [string]$VMDriveLetter,
    
        [Parameter(Mandatory = $true)]
        [System.Collections.ArrayList]$VMNames
    )

    foreach -parallel ($Name in $VMNames) 
    {
        "Copying VM: $Name"
        $null = New-Item -Type Directory -Path "$($VMDriveLetter):\$($Name)" -Force
        Copy-Item -Path $ParentdiskPath -Destination "$($VMDriveLetter):\$($Name)\$($Name).vhdx" -Force    }
}

#region Storage Pool + Volumen
$VMDriveLetter = 'V'
$StoragePoolName        = "Pool01"
$VirtualDiskName        = "VDisk01"
$VMVolumeName           = "VMs"
$PhysicalDisks = (Get-PhysicalDisk -CanPool $true)		
$SelectedDisks = ($PhysicalDisks.where{ $PSitem.Bustype -ne "USB" }).where{ $PSitem.Bustype -ne "NVMe" }
$StorageSubSystemFriendlyName = (Get-StorageSubSystem -FriendlyName "*Windows*").FriendlyName

$null = New-StoragePool -StorageSubSystemFriendlyName $StorageSubSystemFriendlyName -FriendlyName $StoragePoolName -PhysicalDisks $SelectedDisks
$null = New-VirtualDisk -StoragePoolFriendlyName $StoragePoolName -FriendlyName $VirtualDiskName -UseMaximumSize -ProvisioningType Fixed -ResiliencySettingName Simple
$null = Initialize-Disk -FriendlyName $VirtualDiskName -PartitionStyle GPT
$VDiskNumber = (Get-Disk -FriendlyName $VirtualDiskName).Number        
$null = New-Volume -DiskNumber $VDiskNumber -FriendlyName $VMVolumeName -FileSystem ReFS -DriveLetter $VMDriveLetter	
#endregion

#region Settings der VMs 
$VMNames = "VWIN10-01", "VWIN10-02","VWIN10-03", "VWIN10-04", "VWIN10-05", "VWIN10-06", "VWIN10-07", "VWIN10-08", "VWIN10-09", "VWIN10-10",  "VWIN10-15", "VWIN10-13", "VWIN10-14"

$ParentdiskPath = "C:\Parentdisks\WIN10-1809-x64-EE-Gen2.437.vhdx"
$CPUCount = 4
$Ram = 4GB
$VMSwitchName = "EXTERNAL"

$DoDomainJoin = $True

$DomainName = "ADS-CENTER.DE"
$DNSServers = @("192.168.1.201","192.168.2.202")
$Gateway = "192.168.1.254"
$IPStart = "192.168.1."
$IPEnd = "3"
#endregion

#region Credentials
# Local Client Credentials
[string]$LocalAdmin = "Admin"
$LocalPWD = ConvertTo-SecureString "C0mplex" -AsPlainText -Force
$VMCred = New-Object -TypeName System.Management.Automation.PSCredential ($LocalAdmin, $LocalPWD)     

if($DoDomainJoin -eq $True)
{
    # Domain Credentials
    [string]$DomainAdmin = "Administrator@$DomainName"
    $DomainPWD = ConvertTo-SecureString "C0mplex" -AsPlainText -Force
    $DomainCredential = New-Object -TypeName System.Management.Automation.PSCredential ($DomainAdmin, $DomainPWD)
}
#endregion

#region VMSwitch 
$pNICs = Get-NetAdapter -Physical | Where-Object -Property Status -eq "UP"
New-VMSwitch -Name $VMSwitchName -NetAdapterName $pNICs.Name
#endregion 

Copy-parallel -ParentdiskPath $ParentdiskPath -VMDriveLetter $VMDriveLetter -VMNames $VMNames

#region Kreation und Konfuration
foreach ($Name in $VMNames)
{
    $null = New-VM -Name $Name -MemoryStartupBytes $Ram -Path V:\ -Generation 2 -VHDPath "V:\$($Name)\$($Name).vhdx" -BootDevice VHD
    Set-VMProcessor -VMName $Name -Count $CPUCount
    Connect-VMNetworkAdapter -VMNetworkAdapter (Get-VMNetworkAdapter -VMName $Name) -SwitchName $VMSwitchName
    Add-VMDvdDrive -VMName $Name 
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

    $Platznummer = $Name.Substring($Name.Length -2)
    if($Platznummer[0] -eq "0")
    {
        $Platznummer = $Platznummer.Substring($Platznummer.Length - 1)
    }
    $IPAddress = $IPStart + $Platznummer + $IPEnd
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

        if($using:DoDomainJoin -eq $true)
        {
            Add-Computer -Credential $using:DomainCredential -DomainName $using:DomainName -Restart
        }        
    }
}
#endregion