function New-Volume4VMs
{
	param
	(
		[Parameter(Mandatory = $false, Position = 0)]
		[char]$VMDriveLetter
	)

	Begin 
	{
		if($VMDriveLetter -eq $null)
		{
			$VMDriveLetter = 'V'
		}

		$StoragePoolName        = "Pool01"
		$VirtualDiskName        = "VDisk01"
		$VMVolumeName           = "VMs"
		$PhysicalDisks = (Get-PhysicalDisk -CanPool $true)		
		$SelectedDisks = ($PhysicalDisks.where{ $PSitem.Bustype -ne "USB" }).where{ $PSitem.Bustype -ne "NVMe" }
		$StorageSubSystemFriendlyName = (Get-StorageSubSystem -FriendlyName "*Windows*").FriendlyName
	}

	Process
	{		
		# Create Storage Pool
		$null = New-StoragePool -StorageSubSystemFriendlyName $StorageSubSystemFriendlyName -FriendlyName $StoragePoolName -PhysicalDisks $SelectedDisks
		
		#Create Virtual Disk
		$null = New-VirtualDisk -StoragePoolFriendlyName $StoragePoolName -FriendlyName $VirtualDiskName -UseMaximumSize -ProvisioningType Fixed -ResiliencySettingName Simple

		# Initialize VDisk
		$null = Initialize-Disk -FriendlyName $VirtualDiskName -PartitionStyle GPT

		# Create Volume
		$VDiskNumber = (Get-Disk -FriendlyName $VirtualDiskName).Number        
		$null = New-Volume -DiskNumber $VDiskNumber -FriendlyName $VMVolumeName -FileSystem ReFS -DriveLetter $VMDriveLetter	
	}

    End
    {
		Get-Volume -DriveLetter $VMDriveLetter
	}
} 