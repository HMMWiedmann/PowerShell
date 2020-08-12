New-Volume -FriendlyName D-DiskR -StoragePoolFriendlyName S2DPool -FileSystem CSVFS_ReFS -StorageTierFriendlyNames Performance,Capacity -StorageTierSizes 50gb,100gb -DriveLetter R
New-Volume -FriendlyName D-DiskL -StoragePoolFriendlyName S2DPool -FileSystem ReFS -StorageTierFriendlyNames Performance,Capacity -StorageTierSizes 50gb,100gb -DriveLetter L

New-Volume -FriendlyName S-DiskR -StoragePoolFriendlyName S2DPool -FileSystem CSVFS_ReFS -StorageTierFriendlyNames Performance,Capacity -StorageTierSizes 50gb,100gb -DriveLetter R
New-Volume -FriendlyName S-DiskL -StoragePoolFriendlyName S2DPool -FileSystem ReFS -StorageTierFriendlyNames Performance,Capacity -StorageTierSizes 50gb,100gb -DriveLetter L

Grant-SRAccess -ComputerName Node-Y -Cluster CLU-GHIJ

New-SRPartnership -SourceComputerName CLU-ABYZ -SourceRGName RG01 -SourceVolumeName "C:\ClusterStorage\Volume1" -SourceLogVolumeName "L:" -DestinationComputerName CLU-GHIJ -DestinationRGName RG01 -DestinationVolumeName "C:\ClusterStorage\Volume3" -DestinationLogVolumeName "L:"

Get-SRGroup