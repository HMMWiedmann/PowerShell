$AllPools = Get-StoragePool

if((($AllPools | Measure-Object).count) -gt "1")
{
    # Remove StoragePools
    $SPName = (Get-StoragePool -IsPrimordial $false).FriendlyName
    Set-StoragePool -FriendlyName $SPName -IsReadOnly $false
    Get-StoragePool -FriendlyName $SPName | Get-VirtualDisk | Remove-VirtualDisk -Confirm:$false
    Remove-StoragePool -FriendlyName $SPName -Confirm:$false
}

# Disks löschen
$Disks = Get-Disk | Where-Object { $PSitem.Number -ne "0" }
$SelectedDisks = $Disks | Where-Object { $PSItem.BusType -ne "USB" }
Clear-Disk -Number $SelectedDisks.Number -Confirm:$false -RemoveData -RemoveOEM

# Disks reset
$PhysicalDisks = Get-PhysicalDisk | Where-Object { $PSItem.DeviceId -ne "0" }
Reset-PhysicalDisk -InputObject $PhysicalDisks