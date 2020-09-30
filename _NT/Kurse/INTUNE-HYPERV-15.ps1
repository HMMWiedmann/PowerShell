<# 
    HYPERV-XX
    XX-VWIN10-01 --> Azure AD Registered
    XX-VWIN10-02 --> Azure AD Joined
    XX-VWIN10-03 --> Hybrid Azure AD Joined
    XX-VWIN10-04 --> 1803, Azure AD Joined
    XX-VWIN10-05 --> Autopilot User-Driven
    XX-VWIN10-06 --> Autopilot Hybrid Join
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

function Check-VMState 
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
$pNICs = Get-NetAdapter -Physical | Where-Object -Property InterfaceDescription -eq "Broadcom*" 
New-VMSwitch -Name $VMSwitchName -NetAdapterName $pNICs.Name
#endregion

#region Settings der VMs
$Platznummer = $env:COMPUTERNAME.Substring($ENV:COMPUTERNAME.Length - 2)
$VMNames = "$($Platznummer)-VWIN10-01", "$($Platznummer)-VWIN10-02","$($Platznummer)-VWIN10-03", "$($Platznummer)-VWIN10-05", "$($Platznummer)-VWIN10-06"
$ParentdiskPath = "C:\Parentdisks\WIN10-1809-x64-EE-Gen2.437.vhdx"
$CPUCount = 4
$Ram = 8GB
$VMSwitchName = "SET"
$DomainName = "Intune-Center.de"
$OUPath
#endregion

#region Credentials
# Local Client Credentials
[string]$LocalAdmin = "Admin"
$LocalPWD = ConvertTo-SecureString "C0mplex" -AsPlainText -Force
$VMCred = New-Object -TypeName System.Management.Automation.PSCredential ($LocalAdmin, $LocalPWD)

# Domain Credentials
[string]$DomainAdmin = "Administrator@$DomainName"
$DomainPWD = ConvertTo-SecureString "C0mplex" -AsPlainText -Force
$DomainCredential = New-Object -TypeName System.Management.Automation.PSCredential ($DomainAdmin, $DomainPWD)
#endregion

Copy-parallel -ParentdiskPath $ParentdiskPath -VMDriveLetter $VMDriveLetter -VMNames $VMNames

#region Kreation und Konfuration
foreach ($Name in $VMNames)
{
    $null = New-VM -Name $Name -MemoryStartupBytes $Ram -Path V:\ -Generation 2 -VHDPath "V:\$($Name)\$($Name).vhdx" -BootDevice VHD
    Set-VMProcessor -VMName $Name -Count $CPUCount
    Connect-VMNetworkAdapter -VMNetworkAdapter (Get-VMNetworkAdapter -VMName $Name) -SwitchName $VMSwitchName
    Start-VM -VMName $Name

    Check-VMState -VMName $Name -VMCredential $VMCred
    Invoke-Command -VMName $Name -Credential $VMCred -ScriptBlock{ Rename-Computer -NewName $using:Name -Restart -Force }
    Check-VMState -VMName $Name -VMCredential $VMCred

    Invoke-Command -VMName $Name -Credential $VMCred -ScriptBlock `
    {
        Set-NetFirewallProfile -All -Enabled False
        Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Terminal Server" -Name "fDenyTSConnections" -Value 0 -Force
        Enable-NetFirewallRule -DisplayGroup "Remote Desktop"
    }
}

################################################################################
# Windows 10 Hybrid Azure AD Joined Device
Invoke-Command -VMName "$($Platznummer)-VWIN10-03" -Credential $VMCred -ScriptBlock `
{
    Add-Computer -DomainName $DomainName -DomainCredential $DomainCredential -OUPath $OUPath -Restart
}

################################################################################
# Alte Windows Version VM
$OldVMName = "$($Platznummer)-VWIN10-04"
$OldParentdiskPath = ""

$null = New-Item -Type Directory -Path "$($VMDriveLetter):\$($OldVMName)" -Force
Copy-Item -Path $OldParentdiskPath -Destination "$($VMDriveLetter):\$($OldVMName)\$($OldVMName).vhdx" -Force

$null = New-VM -Name $OldVMName -MemoryStartupBytes $Ram -Path V:\ -Generation 2 -VHDPath "$($VMDriveLetter):\$($OldVMName)\$($OldVMName).vhdx" -BootDevice VHD
Set-VMProcessor -VMName $OldVMName -Count $CPUCount
Connect-VMNetworkAdapter -VMNetworkAdapter (Get-VMNetworkAdapter -VMName $OldVMName) -SwitchName $VMSwitchName
Start-VM -VMName $OldVMName

Check-VMState -VMName $OldVMName -VMCredential $VMCred
Invoke-Command -VMName $OldVMName -Credential $VMCred -ScriptBlock{ Rename-Computer -NewName $using:OldVMName -Restart -Force }
Check-VMState -VMName $OldVMName -VMCredential $VMCred

Invoke-Command -VMName $OldVMName -Credential $VMCred -ScriptBlock `
{
    Set-NetFirewallProfile -All -Enabled False
    Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Terminal Server" -Name "fDenyTSConnections" -Value 0 -Force
    Enable-NetFirewallRule -DisplayGroup "Remote Desktop"
    Set-Service -Name wuauserv -StartupType Disabled
}
Check-VMState -VMName $OldVMName -VMCredential $VMCred
#endregion

Checkpoint-VM -VM (Get-VM) -SnapshotName "CleanInstall"