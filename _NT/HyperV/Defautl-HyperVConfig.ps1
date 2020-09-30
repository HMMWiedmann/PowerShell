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

Set-VMHost -EnableEnhancedSessionMode $True -VirtualHardDiskPath "$($VMDriveLetter):\" -VirtualMachinePath "$($VMDriveLetter):\"
Set-NetFirewallProfile -All -Enabled False
Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Terminal Server" -Name "fDenyTSConnections" -Value 0 -Force
Enable-NetFirewallRule -DisplayGroup "Remote Desktop"
powercfg.exe /change monitor-timeout-ac 0
powercfg.exe /change monitor-timeout-dc 0
powercfg.exe /change standby-timeout-dc 0
powercfg.exe /change standby-timeout-ac 0
powercfg.exe /change hibernate-timeout-ac 0
powercfg.exe /change hibernate-timeout-dc 0
Get-ScheduledTask -TaskName ServerManager | Disable-ScheduledTask | Out-Null