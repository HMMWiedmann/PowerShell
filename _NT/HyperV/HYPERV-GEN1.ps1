$VMNames = "VFILE02-01", "VFILE03-01", "VFILE04-01", "VFILE05-01", "VFILE06-01", "VFILE07-01", "VFILE08-01", "VFILE15-01"
$ParentdiskPath = "V:\Parentdisks\W2K08R2SP1-60GB-Dyn-Gen1(190219).vhdx"
$SwitchName = "EXTERNAL"

foreach($Name in $VMNames)
{
    New-VHD -Path V:\$($Name)\$($Name).vhdx -Differencing -ParentPath $ParentdiskPath
    New-VM -Path V:\ -Name $Name -MemoryStartupBytes 2GB -SwitchName $SwitchName -VHDPath V:\$($Name)\$($Name).vhdx -BootDevice VHD -Generation 1
}

foreach($Name in $VMNames)
{
    New-VHD -Path V:\$($Name)\$($Name)-20GB.vhdx -SizeBytes 20GB -Fixed
    Add-VMHardDiskDrive -VMName $Name -Path V:\$($Name)\$($Name)-20GB.vhdx -ControllerType SCSI -ControllerNumber 0 -ControllerLocation 2
}

Start-VM -VM (Get-VM)