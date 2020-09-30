# HYPERVV01
$VMNames = "FSP", "VDHCP-01", "RP01", "SUP", "VSSG", "RDP01", "VFILE-01"

$ServerPD = "V:\Parentdisks\W2K19-Net.35-Gen2-80GB-AW.404.vhdx"
$ClientPD = "V:\Parentdisks\WIN10-1809-x64-EE-Gen2.404.vhdx"
$VMSwitchName = "SET"

$DomainName = "MAIL.XCHANGE-CENTER.DE"
$DNSServers = @("192.168.160.203","192.168.160.204")
$Gateway = "192.168.160.254"

$DoDomainJoin = $true

$LocalPWD = ConvertTo-SecureString "C0mplex" -AsPlainText -Force

# Local Server Credentials
[string]$ServerLocalAdmin = "Administrator"                    
$ServerVMCred = New-Object -TypeName System.Management.Automation.PSCredential ($ServerLocalAdmin, $LocalPWD)

# Local Client Credentials
[string]$ClientLocalAdmin = "Admin"                   
$ClientVMCred = New-Object -TypeName System.Management.Automation.PSCredential ($ClientLocalAdmin, $LocalPWD)     

if ($DoDomainJoin -eq $true) 
{
    # Domain Credentials
    [string]$DomainAdmin = "Administrator@$DomainName"
    $DomainPWD = ConvertTo-SecureString "C0mplex" -AsPlainText -Force
    $DomainCredential = New-Object -TypeName System.Management.Automation.PSCredential ($DomainAdmin, $DomainPWD)
}

Write-Host "Die Parentdisks werden kopiert."

foreach ($Name in $VMNames)
{ 
    $null = New-Item -Path "V:\$($Name)\" -ItemType Directory 
    Copy-Item -Path $ServerPD -Destination "V:\$($Name)\$($Name).vhdx" -Force
}

Write-Host "Die VMs wird erstellt."

foreach ($Name in $VMNames)
{
    $null = New-VM -Name $Name -MemoryStartupBytes 2GB -Path V:\ -Generation 2 -VHDPath "V:\$($Name)\$($Name).vhdx" -BootDevice VHD
    Connect-VMNetworkAdapter -VMNetworkAdapter (Get-VMNetworkAdapter -VMName $Name) -SwitchName $VMSwitchName 
}

Write-Host "VMConfigs wird angepasst."

#region Base Config

# FSP
Set-VM -Name FSP -MemoryStartupBytes 4GB -StaticMemory 
Set-VMProcessor -VMName FSP -Count 4

# VDHCP-01
Set-VM -Name VDHCP-01 -MemoryStartupBytes 4GB -StaticMemory 
Set-VMProcessor -VMName VDHCP-01 -Count 4

# RP01
Set-VM -Name RP01 -MemoryStartupBytes 10GB -StaticMemory 
Set-VMProcessor -VMName RP01 -Count 4
$null = New-VHD -Path V:\RP01\RP01-40GB.vhdx -SizeBytes 40GB -Fixed
Add-VMHardDiskDrive -VMName RP01 -Path V:\RP01\RP01-40GB.vhdx -ControllerType SCSI -ControllerNumber 0 -ControllerLocation 2

# SUP
Set-VM -Name SUP -MemoryStartupBytes 10GB -StaticMemory 
Set-VMProcessor -VMName SUP -Count 4
$null = New-VHD -Path V:\SUP\SUP-200GB.vhdx -SizeBytes 200GB -Dynamic
Add-VMHardDiskDrive -VMName SUP -Path V:\SUP\SUP-200GB.vhdx -ControllerType SCSI -ControllerNumber 0 -ControllerLocation 2

# VSSG
Set-VM -Name VSSG -MemoryStartupBytes 8GB -StaticMemory 
Set-VMProcessor -VMName VSSG -Count 4

# RDP01
Set-VM -Name RDP01 -MemoryStartupBytes 12GB -StaticMemory 
Set-VMProcessor -VMName RDP01 -Count 6
$null = New-VHD -Path V:\RDP01\RDP01-200GB.vhdx -SizeBytes 200GB -Dynamic
Add-VMHardDiskDrive -VMName RDP01 -Path V:\RDP01\RDP01-200GB.vhdx -ControllerType SCSI -ControllerNumber 0 -ControllerLocation 2

# VFILE-01
Set-VM -Name VFILE-01 -MemoryStartupBytes 12GB -StaticMemory 
Set-VMProcessor -VMName VFILE-01 -Count 6
$null = New-VHD -Path V:\VFILE-01V\FILE-01-200GB.vhdx -SizeBytes 200GB -Dynamic
Add-VMHardDiskDrive -VMName VFILE-01 -Path V:\VFILE-01V\FILE-01-200GB.vhdx -ControllerType SCSI -ControllerNumber 0 -ControllerLocation 2


#endregion 

Write-Host "Die VMs wird konfiguriert."

# Start VMs
Start-VM -VM (Get-VM)

# Umbenennen
foreach ($Name in $VMNames)
{
    While((Invoke-Command -VMName $Name -Credential $ServerVMCred { "Test" } -ErrorAction SilentlyContinue) -ne "Test")
    {
            Start-Sleep -Seconds 3
    }
    Start-Sleep -Seconds 10

    Invoke-Command -VMName $Name -Credential $ServerVMCred -ScriptBlock{ Rename-Computer -NewName $using:Name -Restart -Force }

    While((Invoke-Command -VMName $Name -Credential $ServerVMCred { "Test" } -ErrorAction SilentlyContinue) -ne "Test")
    {
            Start-Sleep -Seconds 3
    }
    Start-Sleep -Seconds 10
}

#region In VM Config

# FSP
Invoke-Command -VMName FSP -Credential $ServerVMCred -ScriptBlock `
{
    $NetAdapter = (Get-NetAdapter).InterfaceIndex

    Remove-NetIPAddress -InterfaceIndex $NetAdapter -Confirm:$false
    Set-DnsClientServerAddress -ResetServerAddresses -InterfaceIndex $NetAdapter
    Set-NetIPInterface -InterfaceIndex (Get-NetAdapter).InterfaceIndex -Dhcp Disabled
    $null = New-NetIPAddress -IPAddress "192.168.160.216" -InterfaceIndex $NetAdapter -DefaultGateway $using:Gateway -AddressFamily IPv4 -PrefixLength 24
    Set-DnsClientServerAddress -InterfaceIndex $NetAdapter -ServerAddresses $using:DNSServers

    Set-NetFirewallProfile -All -Enabled False
    $null = Disable-ScheduledTask -TaskName Installation -TaskPath \Microsoft\Windows\LanguageComponentsInstaller

    Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Terminal Server" -Name "fDenyTSConnections" -Value 0 -Force
    Enable-NetFirewallRule -DisplayGroup "Remote Desktop"

    if ($using:DoDomainJoin -eq $true) 
    {
        Add-Computer -Credential $using:DomainCredential -DomainName $using:DomainName -Restart
    }
}

# VDHCP-01
Invoke-Command -VMName VDHCP-01 -Credential $ServerVMCred -ScriptBlock `
{
    $NetAdapter = (Get-NetAdapter).InterfaceIndex

    Remove-NetIPAddress -InterfaceIndex $NetAdapter -Confirm:$false
    Set-DnsClientServerAddress -ResetServerAddresses -InterfaceIndex $NetAdapter
    Set-NetIPInterface -InterfaceIndex (Get-NetAdapter).InterfaceIndex -Dhcp Disabled
    $null = New-NetIPAddress -IPAddress "192.168.160.217" -InterfaceIndex $NetAdapter -DefaultGateway $using:Gateway -AddressFamily IPv4 -PrefixLength 24
    Set-DnsClientServerAddress -InterfaceIndex $NetAdapter -ServerAddresses $using:DNSServers

    Set-NetFirewallProfile -All -Enabled False
    $null = Disable-ScheduledTask -TaskName Installation -TaskPath \Microsoft\Windows\LanguageComponentsInstaller

    Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Terminal Server" -Name "fDenyTSConnections" -Value 0 -Force
    Enable-NetFirewallRule -DisplayGroup "Remote Desktop"

    if ($using:DoDomainJoin -eq $true) 
    {
        Add-Computer -Credential $using:DomainCredential -DomainName $using:DomainName -Restart
    }
}

# RP01
Invoke-Command -VMName RP01 -Credential $ServerVMCred -ScriptBlock `
{
    $NetAdapter = (Get-NetAdapter).InterfaceIndex

    Remove-NetIPAddress -InterfaceIndex $NetAdapter -Confirm:$false
    Set-DnsClientServerAddress -ResetServerAddresses -InterfaceIndex $NetAdapter
    Set-NetIPInterface -InterfaceIndex (Get-NetAdapter).InterfaceIndex -Dhcp Disabled
    $null = New-NetIPAddress -IPAddress "192.168.160.218" -InterfaceIndex $NetAdapter -DefaultGateway $using:Gateway -AddressFamily IPv4 -PrefixLength 24
    Set-DnsClientServerAddress -InterfaceIndex $NetAdapter -ServerAddresses $using:DNSServers

    Set-NetFirewallProfile -All -Enabled False
    $null = Disable-ScheduledTask -TaskName Installation -TaskPath \Microsoft\Windows\LanguageComponentsInstaller

    Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Terminal Server" -Name "fDenyTSConnections" -Value 0 -Force
    Enable-NetFirewallRule -DisplayGroup "Remote Desktop"

    if ($using:DoDomainJoin -eq $true) 
    {
        Add-Computer -Credential $using:DomainCredential -DomainName $using:DomainName -Restart
    }
}

# SUP
Invoke-Command -VMName SUP -Credential $ServerVMCred -ScriptBlock `
{
    $NetAdapter = (Get-NetAdapter).InterfaceIndex

    Remove-NetIPAddress -InterfaceIndex $NetAdapter -Confirm:$false
    Set-DnsClientServerAddress -ResetServerAddresses -InterfaceIndex $NetAdapter
    Set-NetIPInterface -InterfaceIndex (Get-NetAdapter).InterfaceIndex -Dhcp Disabled
    $null = New-NetIPAddress -IPAddress "192.168.160.219" -InterfaceIndex $NetAdapter -DefaultGateway $using:Gateway -AddressFamily IPv4 -PrefixLength 24
    Set-DnsClientServerAddress -InterfaceIndex $NetAdapter -ServerAddresses $using:DNSServers

    Set-NetFirewallProfile -All -Enabled False
    $null = Disable-ScheduledTask -TaskName Installation -TaskPath \Microsoft\Windows\LanguageComponentsInstaller

    Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Terminal Server" -Name "fDenyTSConnections" -Value 0 -Force
    Enable-NetFirewallRule -DisplayGroup "Remote Desktop"

    if ($using:DoDomainJoin -eq $true) 
    {
        Add-Computer -Credential $using:DomainCredential -DomainName $using:DomainName -Restart
    }
}

# VSSG
Invoke-Command -VMName VSSG -Credential $ServerVMCred -ScriptBlock `
{
    $NetAdapter = (Get-NetAdapter).InterfaceIndex

    Remove-NetIPAddress -InterfaceIndex $NetAdapter -Confirm:$false
    Set-DnsClientServerAddress -ResetServerAddresses -InterfaceIndex $NetAdapter
    Set-NetIPInterface -InterfaceIndex (Get-NetAdapter).InterfaceIndex -Dhcp Disabled
    $null = New-NetIPAddress -IPAddress "192.168.180.111" -InterfaceIndex $NetAdapter -DefaultGateway "192.168.180.254" -AddressFamily IPv4 -PrefixLength 24
    Set-DnsClientServerAddress -InterfaceIndex $NetAdapter -ServerAddresses $using:DNSServers

    Set-NetFirewallProfile -All -Enabled False
    $null = Disable-ScheduledTask -TaskName Installation -TaskPath \Microsoft\Windows\LanguageComponentsInstaller

    Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Terminal Server" -Name "fDenyTSConnections" -Value 0 -Force
    Enable-NetFirewallRule -DisplayGroup "Remote Desktop"

    if ($using:DoDomainJoin -eq $true) 
    {
        Add-Computer -Credential $using:DomainCredential -DomainName $using:DomainName -Restart
    }
}

# RDP01
Invoke-Command -VMName RDP01 -Credential $ServerVMCred -ScriptBlock `
{
    $NetAdapter = (Get-NetAdapter).InterfaceIndex

    Remove-NetIPAddress -InterfaceIndex $NetAdapter -Confirm:$false
    Set-DnsClientServerAddress -ResetServerAddresses -InterfaceIndex $NetAdapter
    Set-NetIPInterface -InterfaceIndex (Get-NetAdapter).InterfaceIndex -Dhcp Disabled
    $null = New-NetIPAddress -IPAddress "192.168.180.1" -InterfaceIndex $NetAdapter -DefaultGateway "192.168.180.254" -AddressFamily IPv4 -PrefixLength 24
    Set-DnsClientServerAddress -InterfaceIndex $NetAdapter -ServerAddresses $using:DNSServers

    Set-NetFirewallProfile -All -Enabled False
    $null = Disable-ScheduledTask -TaskName Installation -TaskPath \Microsoft\Windows\LanguageComponentsInstaller

    Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Terminal Server" -Name "fDenyTSConnections" -Value 0 -Force
    Enable-NetFirewallRule -DisplayGroup "Remote Desktop"

    if ($using:DoDomainJoin -eq $true) 
    {
        Add-Computer -Credential $using:DomainCredential -DomainName $using:DomainName -Restart
    }
}

# VFILE-01
Invoke-Command -VMName VFILE-01 -Credential $ServerVMCred -ScriptBlock `
{
    $NetAdapter = (Get-NetAdapter).InterfaceIndex

    Remove-NetIPAddress -InterfaceIndex $NetAdapter -Confirm:$false
    Set-DnsClientServerAddress -ResetServerAddresses -InterfaceIndex $NetAdapter
    Set-NetIPInterface -InterfaceIndex (Get-NetAdapter).InterfaceIndex -Dhcp Disabled
    $null = New-NetIPAddress -IPAddress "192.168.160.222" -InterfaceIndex $NetAdapter -DefaultGateway $using:Gateway -AddressFamily IPv4 -PrefixLength 24
    Set-DnsClientServerAddress -InterfaceIndex $NetAdapter -ServerAddresses $using:DNSServers

    Set-NetFirewallProfile -All -Enabled False
    $null = Disable-ScheduledTask -TaskName Installation -TaskPath \Microsoft\Windows\LanguageComponentsInstaller

    Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Terminal Server" -Name "fDenyTSConnections" -Value 0 -Force
    Enable-NetFirewallRule -DisplayGroup "Remote Desktop"

    if ($using:DoDomainJoin -eq $true) 
    {
        Add-Computer -Credential $using:DomainCredential -DomainName $using:DomainName -Restart
    }
}

#endregion 

Write-Host "Die zusätzlichen Platten werden formartiert."

#region format Volume

# RP01
Invoke-Command -VMName RP01 -Credential $ServerVMCred -ScriptBlock `
{ 
    $Disk = Get-Disk | Where-Object -Property Size -eq 40GB
    Set-Disk -Number $Disk.Number -IsOffline $false
    $null = New-Volume -DiskNumber $Disk.Number -FriendlyName SQL -FileSystem NTFS -DriveLetter S
}

# SUP
Invoke-Command -VMName SUP -Credential $ServerVMCred -ScriptBlock `
{ 
    $Disk = Get-Disk | Where-Object -Property Size -eq 200GB
    Set-Disk -Number $Disk.Number -IsOffline $false
    $null = New-Volume -DiskNumber $Disk.Number -FriendlyName SQL -FileSystem NTFS -DriveLetter S
}

# RDP01
Invoke-Command -VMName RDP01 -Credential $ServerVMCred -ScriptBlock `
{ 
    $Disk = Get-Disk | Where-Object -Property Size -eq 200GB
    Set-Disk -Number $Disk.Number -IsOffline $false
    $null = New-Volume -DiskNumber $Disk.Number -FriendlyName ContentLib -FileSystem NTFS -DriveLetter L
}

# VFILE-01
Invoke-Command -VMName VFILE-01 -Credential $ServerVMCred -ScriptBlock `
{ 
    $Disk = Get-Disk | Where-Object -Property Size -eq 200GB
    Set-Disk -Number $Disk.Number -IsOffline $false
    $null = New-Volume -DiskNumber $Disk.Number -FriendlyName Share -FileSystem NTFS -DriveLetter S
}

#endregion

Write-Host "Die Windows 10 VM wird erstellt."

#region VWIN10-SSG

$null = New-Item -Path "V:\VWIN10-SSG\" -ItemType Directory 
Copy-Item -Path $ClientPD -Destination "V:\VWIN10-SSG\VWIN10-SSG.vhdx" -Force
$null = New-VM -Name VWIN10-SSG -MemoryStartupBytes 4GB -Path V:\ -Generation 2 -VHDPath "V:\VWIN10-SSG\VWIN10-SSG.vhdx" -BootDevice VHD
Connect-VMNetworkAdapter -VMNetworkAdapter (Get-VMNetworkAdapter -VMName VWIN10-SSG) -SwitchName $VMSwitchName 
Set-VMProcessor -VMName VWIN10-SSG -Count 4
Start-VM -Name VWIN10-SSG

While((Invoke-Command -VMName VWIN10-SSG -Credential $ClientVMCred { "Test" } -ErrorAction SilentlyContinue) -ne "Test")
{
        Start-Sleep -Seconds 3
}
Start-Sleep -Seconds 10

Invoke-Command -VMName VWIN10-SSG -Credential $ClientVMCred -ScriptBlock{ Rename-Computer -NewName VWIN10-SSG -Restart -Force }

While((Invoke-Command -VMName VWIN10-SSG -Credential $ClientVMCred { "Test" } -ErrorAction SilentlyContinue) -ne "Test")
{
        Start-Sleep -Seconds 3
}
Start-Sleep -Seconds 10

Invoke-Command -VMName VWIN10-SSG -Credential $ClientVMCred -ScriptBlock `
{
    $NetAdapter = (Get-NetAdapter).InterfaceIndex

    Remove-NetIPAddress -InterfaceIndex $NetAdapter -Confirm:$false
    Set-DnsClientServerAddress -ResetServerAddresses -InterfaceIndex $NetAdapter
    Set-NetIPInterface -InterfaceIndex (Get-NetAdapter).InterfaceIndex -Dhcp Disabled
    $null = New-NetIPAddress -IPAddress "192.168.180.2" -InterfaceIndex $NetAdapter -DefaultGateway "192.168.180.254" -AddressFamily IPv4 -PrefixLength 24
    Set-DnsClientServerAddress -InterfaceIndex $NetAdapter -ServerAddresses $using:DNSServers

    Set-NetFirewallProfile -All -Enabled False
    $null = Disable-ScheduledTask -TaskName Installation -TaskPath \Microsoft\Windows\LanguageComponentsInstaller

    Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Terminal Server" -Name "fDenyTSConnections" -Value 0 -Force
    Enable-NetFirewallRule -DisplayGroup "Remote Desktop"

    #Add-Computer -Credential $using:DomainCredential -DomainName $using:DomainName -Restart
}

#endregion