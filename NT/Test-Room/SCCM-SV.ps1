$Platznummer = $env:COMPUTERNAME.Substring($ENV:COMPUTERNAME.Length - 2)

$Win7PDPath = "C:\Temp\Parentdisks\Win7.vhdx"
$Win10PDPath = "C:\Temp\Parentdisks\Win10.vhdx"
$SwitchName = "EXTERNAL"

$Netadapter = (Get-NetAdapter -Physical | Select-Object -First 1).Name

$PoolFriendlyName = "Pool01"
$DiskFriendlyName = "VDisk01"

$VWIN7Name = "VWIN7-" + $Platznummer
$VWIN10Name = "VWIN10-" + $Platznummer

$RAMSize = 4GB
$CPU = 4

$DomainName = "mail.xchange-center.de"
$VWIN7IP = "192.168.160.3"
$VWIN10IP = "192.168.160.4"

$DNS1 = "192.168.160.203"
$DNS2 = "192.168.160.204"
$GW = "192.168.160.254"

# Virtual Switch erstellen
New-VMSwitch -Name $SwitchName -NetAdapterName $NetAdapter -AllowManagementOS $true

# Volumen V erstellen 
$PhysicalDisks = Get-PhysicalDisk -CanPool $true -PhysicallyConnected -StorageNode (Get-StorageNode -Name $env:COMPUTERNAME)
$StorageSubSystem = (Get-StorageSubSystem -FriendlyName "*Windows*").FriendlyName
New-StoragePool -FriendlyName $PoolFriendlyName -ProvisioningTypeDefault Fixed -StorageSubSystemFriendlyName $StorageSubSystem -PhysicalDisks $PhysicalDisks
New-VirtualDisk -StoragePoolFriendlyName $PoolFriendlyName -FriendlyName $DiskFriendlyName -UseMaximumSize -ProvisioningType Fixed -ResiliencySettingName Simple
$DiskNumber = (Get-VirtualDisk -FriendlyName $DiskFriendlyName | Get-Disk).Number
Initialize-Disk -Number $DiskNumber -PartitionStyle GPT 
New-Volume -DiskNumber $DiskNumber -FileSystem ReFS -DriveLetter "V" -FriendlyName "VMs"

# PDs kopieren
$Win7PD = Get-Item -Path $Win7PDPath 
$Win10PD = Get-Item -Path $Win10PDPath
$Win7PDDest = "V:\$VWIN7Name\$VWIN7Name.vhdx"
$Win10PDDest = "V:\$VWIN10Name\$VWIN10Name.vhdx"

New-Item -Path "V:\$VWIN7Name" -ItemType Directory
New-Item -Path "V:\$VWIN10Name" -ItemType Directory
Copy-Item $Win7PD -Destination $Win7PDDest
Copy-Item $Win10PD -Destination $Win10PDDest

# VWin7 erstellen
New-VM -VMName $VWIN7Name -Path V:\ -MemoryStartupBytes $RAMSize -SwitchName $SwitchName -VHDPath $Win7PDDest -Generation 1 
Set-VM -VMName $VWIN7Name -StaticMemory -ProcessorCount $CPU

# Vwin10 erstellen
New-VM -VMName $VWIN10Name -Path V:\ -MemoryStartupBytes $RAMSize -SwitchName $SwitchName -VHDPath $Win10PDDest -Generation 2
Set-VM -VMName $VWIN10Name -StaticMemory -ProcessorCount $CPU

# VM Konfig Win7
New-Item -Name "$VWIN7Name.cmd" -ItemType file -Path "V:\$VWIN7Name\" | Out-Null
New-Item -Name "$VWIN7Name.ps1" -ItemType file -Path "V:\$VWIN7Name\" | Out-Null
Add-Content -Path "V:\$VWIN7Name\$VWIN7Name.cmd" -value "powershell.exe Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Force"
Add-Content -Path "V:\$VWIN7Name\$VWIN7Name.cmd" -value "powershell.exe -noexit C:\SetupTemp\$VWIN7Name.ps1"
Add-Content -Path "V:\$VWIN7Name\$VWIN7Name.ps1" -value "Set-NetFirewallProfile -All -Enabled false"
Add-Content -Path "V:\$VWIN7Name\$VWIN7Name.ps1" -value "Set-ItemProperty -Path `'HKLM:\System\CurrentControlSet\Control\Terminal Server`'-name `"fDenyTSConnections`" -Value 0"
Add-Content -Path "V:\$VWIN7Name\$VWIN7Name.ps1" -value "Enable-NetFirewallRule -DisplayGroup `"Remote Desktop`""
Add-Content -Path "V:\$VWIN7Name\$VWIN7Name.ps1" -value "New-NetIPAddress -InterfaceAlias ethernet -IPAddress $VWIN7IP -PrefixLength 24 -DefaultGateway $GW"
Add-Content -Path "V:\$VWIN7Name\$VWIN7Name.ps1" -value "Set-DnsClientServerAddress -InterfaceAlias ethernet -ResetServerAddresses"
Add-Content -Path "V:\$VWIN7Name\$VWIN7Name.ps1" -value "Set-DnsClientServerAddress -InterfaceAlias ethernet -ServerAddresses $DNS1,$DNS2"
Add-Content -Path "V:\$VWIN7Name\$VWIN7Name.ps1" -value "`$Cred = New-object System.Management.Automation.PSCredential `"administrator@$DomainName`", (ConvertTo-SecureString -String `"C0mplex`" -AsPlainText -Force)"
Add-Content -Path "V:\$VWIN7Name\$VWIN7Name.ps1" -value "Add-Computer -DomainCredential `$cred -DomainName $DomainName -NewName $VWIN7Name -Restart"

Write-Verbose "Mounting $VWIN7Name.vhdx and copying the automated setup files."
$driveb4 = (Get-PSDrive).Name
Mount-VHD -Path "V:\$VWIN7Name\$VWIN7Name.vhdx"
$driveat = (Get-PSDrive).name
$drive = (Compare-Object -ReferenceObject $driveb4 -DifferenceObject $driveat).inputobject[-1] + ':'
New-Item -Path $drive\SetupTemp -ItemType Directory | Out-Null
Set-Location -Path $drive\SetupTemp | Out-Null
Copy-Item -Path "V:\$VWIN7Name\$VWIN7Name.cmd" -Destination . | Out-Null
Copy-Item -Path "V:\$VWIN7Name\$VWIN7Name.ps1" -Destination . | Out-Null
Set-Location -Path c: | Out-Null
Dismount-VHD -Path "V:\$VWIN7Name\$VWIN7Name.vhdx"
Write-Verbose "Dismounted $VWIN7Name.vhdx successfully."

# VM Konfig Win10
New-Item -Name "$VWIN10Name.cmd" -ItemType file -Path "V:\$VWIN10Name\" | Out-Null
New-Item -Name "$VWIN10Name.ps1" -ItemType file -Path "V:\$VWIN10Name\" | Out-Null
Add-Content -Path "V:\$VWIN10Name\$VWIN10Name.cmd" -value "powershell.exe Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Force"
Add-Content -Path "V:\$VWIN10Name\$VWIN10Name.cmd" -value "powershell.exe -noexit C:\SetupTemp\$VWIN10Name.ps1"
Add-Content -Path "V:\$VWIN10Name\$VWIN10Name.ps1" -value "Set-NetFirewallProfile -All -Enabled false"
Add-Content -Path "V:\$VWIN10Name\$VWIN10Name.ps1" -value "Set-ItemProperty -Path `'HKLM:\System\CurrentControlSet\Control\Terminal Server`'-name `"fDenyTSConnections`" -Value 0"
Add-Content -Path "V:\$VWIN10Name\$VWIN10Name.ps1" -value "Enable-NetFirewallRule -DisplayGroup `"Remote Desktop`""
Add-Content -Path "V:\$VWIN10Name\$VWIN10Name.ps1" -value "New-NetIPAddress -InterfaceAlias ethernet -IPAddress $VWIN10IP -PrefixLength 24 -DefaultGateway $GW"
Add-Content -Path "V:\$VWIN10Name\$VWIN10Name.ps1" -value "Set-DnsClientServerAddress -InterfaceAlias ethernet -ResetServerAddresses"
Add-Content -Path "V:\$VWIN10Name\$VWIN10Name.ps1" -value "Set-DnsClientServerAddress -InterfaceAlias ethernet -ServerAddresses $DNS1,$DNS2"
Add-Content -Path "V:\$VWIN10Name\$VWIN10Name.ps1" -value "`$Cred = New-object System.Management.Automation.PSCredential `"administrator@$DomainName`", (ConvertTo-SecureString -String `"C0mplex`" -AsPlainText -Force)"
Add-Content -Path "V:\$VWIN10Name\$VWIN10Name.ps1" -value "Add-Computer -DomainCredential `$cred -DomainName $DomainName -NewName $VWIN10Name -Restart"

Write-Verbose "Mounting $VWIN10Name.vhdx and copying the automated setup files."
$driveb4 = (Get-PSDrive).Name
Mount-VHD -Path "V:\$VWIN10Name\$VWIN10Name.vhdx"
$driveat = (Get-PSDrive).name
$drive = (Compare-Object -ReferenceObject $driveb4 -DifferenceObject $driveat).inputobject[-1] + ':'
New-Item -Path $drive\SetupTemp -ItemType Directory | Out-Null
Set-Location -Path $drive\SetupTemp | Out-Null
Copy-Item -Path "V:\$VWIN10Name\$VWIN10Name.cmd" -Destination . | Out-Null
Copy-Item -Path "V:\$VWIN10Name\$VWIN10Name.ps1" -Destination . | Out-Null
Set-Location -Path c: | Out-Null
Dismount-VHD -Path "V:\$VWIN10Name\$VWIN10Name.vhdx"
Write-Verbose "Dismounted $VWIN10Name.vhdx successfully."

# Start VMs
Start-VM -VM (Get-VM)