# Install-Module -Name WindowsImageTools -Force -Scope CurrentUser

$OutputPath = "C:\Temp"

$ISOPath = "C:\Temp2\en_windows_10_business_editions_version_1909_x64_dvd_ada535d0.iso"
$ISOMount = Mount-DiskImage -StorageType ISO -ImagePath $ISOPath -PassThru
$ISODriveLetter = ((Get-Volume).where{$PSItem.Size -eq $ISOMount.Size}).Driveletter

$InstallWIMPath = "$($ISODriveLetter):\sources\install.wim"
$EntImageIndex = (Get-WindowsImage -ImagePath $InstallWIMPath).Where{$PSItem.ImageName -eq "Windows 10 Enterprise"}.ImageIndex



$MounPath = "$env:TEMP\Mount-$(New-Guid)"
$MountFolder = New-Item -Path $MounPath -ItemType Directory -Force


Convert-WIM2VHD -Path "$OutputPath\"









Remove-Item -Path $MountFolder -Recurse -Force