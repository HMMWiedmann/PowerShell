<#
    HYPERV-XX
    XX-VWIN10-01 --> Hybrid Azure AD Joined
    XX-VWIN10-02 --> Azure AD Joined
    XX-VWIN10-03 --> 1803, Azure AD Joined
    XX-VWIN10-04 --> Autopilot Hybrid User-Driven
    XX-VWIN10-05 --> Azure AD Registered, Backup
#>

#Region Hilfsfunktionen
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
        Copy-Item -Path $ParentdiskPath -Destination "$($VMDriveLetter):\$($Name)\$($Name).vhdx" -Force
    }
}
function Test-VMState
{
    param 
    (
        # Parameter help description
        [Parameter(Mandatory=$true)]
        [string]
        $VMName,
        # Parameter help description
        [Parameter(Mandatory=$true)]
        [pscredential]
        $VMCredential
    )
    
    While((Invoke-Command -VMName $VMName -Credential $VMCredential { "Test" } -ErrorAction SilentlyContinue) -ne "Test")
    {
         Start-Sleep -Seconds 3
    }
    Start-Sleep -Seconds 10
}
#endregion

#region HyperV Server Einstellungen
Set-VMHost -EnableEnhancedSessionMode $True
Set-NetFirewallProfile -All -Enabled False
Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Terminal Server" -Name "fDenyTSConnections" -Value 0 -Force
Enable-NetFirewallRule -DisplayGroup "Remote Desktop"
Install-WindowsFeature -Name RSAT-AD-Tools,GPMC -IncludeAllSubFeature
powercfg.exe /change monitor-timeout-ac 0
powercfg.exe /change monitor-timeout-dc 0
powercfg.exe /change standby-timeout-dc 0
powercfg.exe /change standby-timeout-ac 0
powercfg.exe /change hibernate-timeout-ac 0
powercfg.exe /change hibernate-timeout-dc 0
Get-ScheduledTask -TaskName ServerManager | Disable-ScheduledTask | Out-Null
Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Force
#endregion

#region Storage Pool + Volumen
$VMDriveLetter                = 'V'
$StoragePoolName              = "Pool01"
$VirtualDiskName              = "VDisk01"
$VMVolumeName                 = "VMs"
$PhysicalDisks                = (Get-PhysicalDisk -CanPool $true)		
$SelectedDisks                = ($PhysicalDisks.where{ $PSitem.Bustype -ne "USB" }).where{ $PSitem.Bustype -ne "NVMe" }
$StorageSubSystemFriendlyName = (Get-StorageSubSystem -FriendlyName "*Windows*").FriendlyName

$null = New-StoragePool -StorageSubSystemFriendlyName $StorageSubSystemFriendlyName -FriendlyName $StoragePoolName -PhysicalDisks $SelectedDisks
$null = New-VirtualDisk -StoragePoolFriendlyName $StoragePoolName -FriendlyName $VirtualDiskName -UseMaximumSize -ProvisioningType Fixed -ResiliencySettingName Simple
$null = Initialize-Disk -FriendlyName $VirtualDiskName -PartitionStyle GPT
$VDiskNumber = (Get-Disk -FriendlyName $VirtualDiskName).Number        
$null = New-Volume -DiskNumber $VDiskNumber -FriendlyName $VMVolumeName -FileSystem ReFS -DriveLetter $VMDriveLetter
#endregion

#region VMSwitch SET
$DeviceType = (Get-CimInstance -ClassName Win32_Computersystem).Model
if ($DeviceType -like "*PowerEdge T430*") 
{
    $pNICs = Get-NetAdapter | Where-Object -Property InterfaceDescription -like "*Broadcom NetXtreme Gigabit Ethernet*" | Where-Object -Property Status -EQ "UP"
}
elseif ($DeviceType -like "*Precision Tower 7910*" -or $DeviceType -like "*Precision Tower 7810*") 
{
    $pNICs = Get-NetAdapter | Where-Object -Property InterfaceDescription -like "*Intel(R) Ethernet Connection I217-LM*" | Where-Object -Property Status -EQ "UP"
}

$VMSwitchName = "SET"
New-VMSwitch -Name $VMSwitchName -NetAdapterName $pNICs.Name | Out-Null
#endregion

#region Settings der VMs
$Platznummer = $env:COMPUTERNAME.Substring($ENV:COMPUTERNAME.Length - 2)

$VMNames = "$($Platznummer)-VWIN10-01", "$($Platznummer)-VWIN10-02","$($Platznummer)-VWIN10-04", "$($Platznummer)-VWIN10-05"
$ParentdiskPath = "C:\Parentdisks\INTUNE-XX-VWIN10-YY(1903).vhdx"

$OldVMName = "$($Platznummer)-VWIN10-03"
$OldParentdiskPath = "C:\Parentdisks\WIN10-1809-x64-EE-GEN2-AW.557.vhdx"

if ($DeviceType -like "*PowerEdge T430*") 
{
    $CPUCount = 8
    $Ram = 8GB
}
elseif ($DeviceType -like "*Precision Tower 7910*" -or "*Precision Tower 7810*") 
{
    $CPUCount = 4
    $Ram = 4GB
}
#endregion

#region Credentials
# Local Client Credentials
[string]$LocalAdmin = "Admin"
$LocalPWD = ConvertTo-SecureString "C0mplex" -AsPlainText -Force
$VMCred = New-Object -TypeName System.Management.Automation.PSCredential ($LocalAdmin, $LocalPWD)
#endregion

#region VM Parentdisk kopieren
Copy-parallel -ParentdiskPath $ParentdiskPath -VMDriveLetter $VMDriveLetter -VMNames $VMNames
Write-Host "Copying VM: $OldVMName"
$null = New-Item -Type Directory -Path "$($VMDriveLetter):\$($OldVMName)" -Force
Copy-Item -Path $OldParentdiskPath -Destination "$($VMDriveLetter):\$($OldVMName)\$($OldVMName).vhdx" -Force
#endregion

#region VM Erstellung
foreach ($Name in $VMNames)
{
    Write-Host "Creating VM: $Name"
    $null = New-VM -Name $Name -MemoryStartupBytes $Ram -Path "$($VMDriveLetter):\" -Generation 2 -VHDPath "$($VMDriveLetter):\$($Name)\$($Name).vhdx" -BootDevice VHD
    Set-VMProcessor -VMName $Name -Count $CPUCount
    Connect-VMNetworkAdapter -VMNetworkAdapter (Get-VMNetworkAdapter -VMName $Name) -SwitchName $VMSwitchName
    Start-VM -VMName $Name
}


################################################################################
# Alte Windows Version VM

Write-Host "Creating VM: $OldVMName"
$null = New-VM -Name $OldVMName -MemoryStartupBytes $Ram -Path "$($VMDriveLetter):\" -Generation 2 -VHDPath "$($VMDriveLetter):\$($OldVMName)\$($OldVMName).vhdx" -BootDevice VHD
Set-VMProcessor -VMName $OldVMName -Count $CPUCount
Connect-VMNetworkAdapter -VMNetworkAdapter (Get-VMNetworkAdapter -VMName $OldVMName) -SwitchName $VMSwitchName
Start-VM -VMName $OldVMName
#endregion

#region VM Konfiguration
foreach ($Name in $VMNames)
{
    Write-Host "Configuring VM: $Name"
    Test-VMState -VMName $Name -VMCredential $VMCred
    Invoke-Command -VMName $Name -Credential $VMCred -ScriptBlock `
    {
        Set-NetFirewallProfile -All -Enabled False
        Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Terminal Server" -Name "fDenyTSConnections" -Value 0 -Force
        Enable-NetFirewallRule -DisplayGroup "Remote Desktop"
        Set-Service -Name wuauserv -StartupType Disabled
        powercfg.exe /change monitor-timeout-ac 0
        powercfg.exe /change monitor-timeout-dc 0
        powercfg.exe /change standby-timeout-dc 0
        powercfg.exe /change standby-timeout-ac 0
        powercfg.exe /change hibernate-timeout-ac 0
        powercfg.exe /change hibernate-timeout-dc 0
        Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Force
        Rename-Computer -NewName $using:Name -Restart -Force
    }
}


################################################################################
# Alte Windows Version VM

Write-Host "Configuring VM: $OldVMName"
Test-VMState -VMName $OldVMName -VMCredential $VMCred
Invoke-Command -VMName $OldVMName -Credential $VMCred -ScriptBlock `
{
    Set-NetFirewallProfile -All -Enabled False
    Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Terminal Server" -Name "fDenyTSConnections" -Value 0 -Force
    Enable-NetFirewallRule -DisplayGroup "Remote Desktop"
    Set-Service -Name wuauserv -StartupType Disabled    
    powercfg.exe /change monitor-timeout-ac 0
    powercfg.exe /change monitor-timeout-dc 0
    powercfg.exe /change standby-timeout-dc 0
    powercfg.exe /change standby-timeout-ac 0
    powercfg.exe /change hibernate-timeout-ac 0
    powercfg.exe /change hibernate-timeout-dc 0
    Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Force
    Rename-Computer -NewName $using:OldVMName -Restart -Force
}
Test-VMState -VMName $OldVMName -VMCredential $VMCred


################################################################################
# TPM Chips
$TPMVMNames = "$($Platznummer)-VWIN10-02"

foreach ($TPMVMName in $TPMVMNames)
{
    Write-Host "Enable TPM Chip on VM: $TPMVMName"
    Test-VMState -VMName $TPMVMName -VMCredential $VMCred
    Stop-VM -Force -VMName $TPMVMName
    Set-VMKeyProtector -VMName $TPMVMName -NewLocalKeyProtector
    Enable-VMTPM -VMName $TPMVMName
    Start-VM -VMName $TPMVMName
}
#endregion