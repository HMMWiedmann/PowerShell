$VMNames = "MP01", "MP02", "DP01", "DP02"

$ParentdiskPath = "V:\Parentdisks\W2K19-Net.35-Gen2-80GB-AW.404.vhdx"
$CPUCount = 8
$Ram = 20GB
$VMSwitchName = "SET"

$DomainName = "MAIL.XCHANGE-CENTER.DE"
$DNSServers = @("192.168.160.203","192.168.160.204")
$Gateway = "192.168.160.254"

$DoDomainJoin = $true

# Local Server Credentials
[string]$LocalAdmin = "Administrator"
$LocalPWD = ConvertTo-SecureString "C0mplex" -AsPlainText -Force
                
$VMCred = New-Object -TypeName System.Management.Automation.PSCredential ($LocalAdmin, $LocalPWD)  

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
    Copy-Item -Path $ParentdiskPath -Destination "V:\$($Name)\$($Name).vhdx" -Force
}

Write-Host "Die VMs werden erstellt."

foreach ($Name in $VMNames)
{
    $null = New-VM -Name $Name -MemoryStartupBytes $Ram -Path V:\ -Generation 2 -VHDPath "V:\$($Name)\$($Name).vhdx" -BootDevice VHD
    Set-VMProcessor -VMName $Name -Count $CPUCount
    Connect-VMNetworkAdapter -VMNetworkAdapter (Get-VMNetworkAdapter -VMName $Name) -SwitchName $VMSwitchName
    Start-VM -VMName $Name

    While((Invoke-Command -VMName $Name -Credential $VMCred { "Test" } -ErrorAction SilentlyContinue) -ne "Test")
    {
         Start-Sleep -Seconds 3
    }
    Start-Sleep -Seconds 10

    Invoke-Command -VMName $Name -Credential $VMCred -ScriptBlock{ Rename-Computer -NewName $using:Name -Restart -Force }

    While((Invoke-Command -VMName $Name -Credential $VMCred { "Test" } -ErrorAction SilentlyContinue) -ne "Test")
    {
         Start-Sleep -Seconds 3
    }
    Start-Sleep -Seconds 10
}

Write-Host "Die VMs werden konfguriert."

# MP01
Invoke-Command -VMName MP01 -Credential $VMCred -ScriptBlock `
{
    $NetAdapter = (Get-NetAdapter).InterfaceIndex

    Remove-NetIPAddress -InterfaceIndex $NetAdapter -Confirm:$false
    Set-DnsClientServerAddress -ResetServerAddresses -InterfaceIndex $NetAdapter
    Set-NetIPInterface -InterfaceIndex (Get-NetAdapter).InterfaceIndex -Dhcp Disabled
    $null = New-NetIPAddress -IPAddress "192.168.160.212" -InterfaceIndex $NetAdapter -DefaultGateway $using:Gateway -AddressFamily IPv4 -PrefixLength 24
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

# MP02
Invoke-Command -VMName MP02 -Credential $VMCred -ScriptBlock `
{
    $NetAdapter = (Get-NetAdapter).InterfaceIndex

    Remove-NetIPAddress -InterfaceIndex $NetAdapter -Confirm:$false
    Set-DnsClientServerAddress -ResetServerAddresses -InterfaceIndex $NetAdapter
    Set-NetIPInterface -InterfaceIndex (Get-NetAdapter).InterfaceIndex -Dhcp Disabled
    $null = New-NetIPAddress -IPAddress "192.168.160.213" -InterfaceIndex $NetAdapter -DefaultGateway $using:Gateway -AddressFamily IPv4 -PrefixLength 24
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

# DP01
New-VHD -Path V:\DP01\DP01-200GB.vhdx -SizeBytes 200GB -Fixed
$null = Add-VMHardDiskDrive -VMName DP01 -Path V:\DP01\DP01-200GB.vhdx -ControllerType SCSI -ControllerNumber 0 -ControllerLocation 2
Invoke-Command -VMName DP01 -Credential $VMCred -ScriptBlock `
{
    $NetAdapter = (Get-NetAdapter).InterfaceIndex

    Remove-NetIPAddress -InterfaceIndex $NetAdapter -Confirm:$false
    Set-DnsClientServerAddress -ResetServerAddresses -InterfaceIndex $NetAdapter
    Set-NetIPInterface -InterfaceIndex (Get-NetAdapter).InterfaceIndex -Dhcp Disabled
    $null = New-NetIPAddress -IPAddress "192.168.160.214" -InterfaceIndex $NetAdapter -DefaultGateway $using:Gateway -AddressFamily IPv4 -PrefixLength 24
    Set-DnsClientServerAddress -InterfaceIndex $NetAdapter -ServerAddresses $using:DNSServers

    Set-NetFirewallProfile -All -Enabled False
    $null = Disable-ScheduledTask -TaskName Installation -TaskPath \Microsoft\Windows\LanguageComponentsInstaller

    Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Terminal Server" -Name "fDenyTSConnections" -Value 0 -Force
    Enable-NetFirewallRule -DisplayGroup "Remote Desktop"

    $Disk = Get-Disk | Where-Object -Property Size -eq 200GB
    Set-Disk -Number $Disk.Number -IsOffline $false
    New-Volume -DiskNumber $Disk.Number -FriendlyName ContentLib -FileSystem NTFS -DriveLetter L

    if ($using:DoDomainJoin -eq $true) 
    {
        Add-Computer -Credential $using:DomainCredential -DomainName $using:DomainName -Restart
    }
}

# DP02
New-VHD -Path V:\DP02\DP02-200GB.vhdx -SizeBytes 200GB -Fixed
$null = Add-VMHardDiskDrive -VMName DP02 -Path V:\DP02\DP02-200GB.vhdx -ControllerType SCSI -ControllerNumber 0 -ControllerLocation 2
Invoke-Command -VMName DP02 -Credential $VMCred -ScriptBlock `
{
    $NetAdapter = (Get-NetAdapter).InterfaceIndex

    Remove-NetIPAddress -InterfaceIndex $NetAdapter -Confirm:$false
    Set-DnsClientServerAddress -ResetServerAddresses -InterfaceIndex $NetAdapter
    Set-NetIPInterface -InterfaceIndex $NetAdapter -Dhcp Disabled
    $null = New-NetIPAddress -IPAddress "192.168.160.215" -InterfaceIndex $NetAdapter -DefaultGateway $using:Gateway -AddressFamily IPv4 -PrefixLength 24
    Set-DnsClientServerAddress -InterfaceIndex $NetAdapter -ServerAddresses $using:DNSServers

    Set-NetFirewallProfile -All -Enabled False
    $null = Disable-ScheduledTask -TaskName Installation -TaskPath \Microsoft\Windows\LanguageComponentsInstaller

    Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Terminal Server" -Name "fDenyTSConnections" -Value 0 -Force
    Enable-NetFirewallRule -DisplayGroup "Remote Desktop"

    $Disk = Get-Disk | Where-Object -Property Size -eq 200GB
    Set-Disk -Number $Disk.Number -IsOffline $false
    New-Volume -DiskNumber $Disk.Number -FriendlyName ContentLib -FileSystem NTFS -DriveLetter L

    if ($using:DoDomainJoin -eq $true) 
    {
        Add-Computer -Credential $using:DomainCredential -DomainName $using:DomainName -Restart
    }
}