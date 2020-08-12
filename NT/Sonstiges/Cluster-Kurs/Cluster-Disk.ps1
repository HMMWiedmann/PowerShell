New-Volume -FriendlyName Disk-S -StoragePoolFriendlyName S2DPool -FileSystem ReFS -StorageTierFriendlyNames Performance,Capacity -StorageTierSizes 50gb,100gb -DriveLetter S
Get-VirtualDisk