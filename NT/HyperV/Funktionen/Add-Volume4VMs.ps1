function Add-Volume4VMs 
{
    param 
    (
        # VMRoot
        [Parameter(Mandatory = $true)]
        [char]
        $VMRootLetter
    )

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
    $null = New-Volume -DiskNumber $VDiskNumber -FriendlyName $VMVolumeName -FileSystem ReFS -DriveLetter $VMRootLetter
}