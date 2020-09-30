# $VMNames = "VFILE02-02","VFILE03-02","VFILE04-02","VFILE05-02","VFILE06-02","VFILE07-02","VFILE08-02","VFILE09-02","VFILE15-02"
$VMNames = "VWIN10-02","VWIN10-03", "VWIN10-04", "VWIN10-05", "VWIN10-06", "VWIN10-07", "VWIN10-08", "VWIN10-09", "VWIN10-15"

$ParentdiskPath = "V:\Parentdisks\WIN10-1809-x64-EE-Gen2.316.vhdx"
$CPUCount = 4
$Ram = 8GB
$VMSwitchName = "EXTERNAL"

$DomainName = "ADS-CENTER.DE"
$DNSServers = @("192.168.1.201","192.168.2.202")
$Gateway = "192.168.1.254"
$IPStart = "192.168.1."
$IPEnd = "5"

# VM Credentials
$OSType = (Get-WindowsImage -ImagePath $ParentdiskPath -Index 1).InstallationType
if ($OSType -eq "Server") 
{
    # Local Server Credentials
    [string]$LocalAdmin = "Administrator"
    $LocalPWD = ConvertTo-SecureString "C0mplex" -AsPlainText -Force
                    
    $VMCred = New-Object -TypeName System.Management.Automation.PSCredential ($LocalAdmin, $LocalPWD)  
}
elseif ($OSType -eq "Client")     
{
    # Local Client Credentials
    [string]$LocalAdmin = "Admin"
    $LocalPWD = ConvertTo-SecureString "C0mplex" -AsPlainText -Force
                    
    $VMCred = New-Object -TypeName System.Management.Automation.PSCredential ($LocalAdmin, $LocalPWD)     
}

# Domain Credentials
[string]$DomainAdmin = "Administrator@$DomainName"
$DomainPWD = ConvertTo-SecureString "C0mplex" -AsPlainText -Force
$DomainCredential = New-Object -TypeName System.Management.Automation.PSCredential ($DomainAdmin, $DomainPWD)

foreach ($Name in $VMNames)
{ 
    $null = New-Item -Path "V:\$($Name)\" -ItemType Directory 
    Copy-Item -Path $ParentdiskPath -Destination "V:\$($Name)\$($Name).vhdx" -Force
}

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

    $Platznummer = $Name.Substring($Name.Length -2)
    if($Platznummer[0] -eq "0")
    {
        $Platznummer = $Platznummer.Substring($Platznummer.Length - 1)
    }
    $IPAddress = $IPStart + $Platznummer + $IPEnd
    Invoke-Command -VMName $Name -Credential $VMCred -ScriptBlock `
    {
        Remove-NetIPAddress -InterfaceIndex (Get-NetAdapter).InterfaceIndex -Confirm:$false
        Set-DnsClientServerAddress -ResetServerAddresses -InterfaceIndex (Get-NetAdapter).InterfaceIndex
        Set-NetIPInterface -InterfaceIndex (Get-NetAdapter).InterfaceIndex -Dhcp Disabled
        $null = New-NetIPAddress -IPAddress $using:IPAddress -InterfaceIndex (Get-NetAdapter).InterfaceIndex -DefaultGateway $using:Gateway -AddressFamily IPv4 -PrefixLength 24
        Set-DnsClientServerAddress -InterfaceIndex (Get-NetAdapter).InterfaceIndex -ServerAddresses $using:DNSServers

        Set-NetFirewallProfile -All -Enabled False
        $null = Disable-ScheduledTask -TaskName Installation -TaskPath \Microsoft\Windows\LanguageComponentsInstaller

        Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Terminal Server" -Name "fDenyTSConnections" -Value 0 -Force
        Enable-NetFirewallRule -DisplayGroup "Remote Desktop"

        #Add-Computer -Credential $using:DomainCredential -DomainName $using:DomainName -Restart
    }
}

<#region zusätzliche Platte

foreach ($Name in $VMNames)
{   
    New-VHD -Path V:\$($Name)\$($Name)-20GB.vhdx -SizeBytes 20GB -Fixed
    Add-VMHardDiskDrive -VMName $Name -Path V:\$($Name)\$($Name)-20GB.vhdx -ControllerType SCSI -ControllerNumber 0 -ControllerLocation 2
}

Invoke-Command -VMName $VMNames -Credential $VMCred -ScriptBlock `
{ 
    $Disk = Get-Disk | Where-Object -Property Size -eq 20GB
    Set-Disk -Number $Disk.Number -IsOffline $false
    New-Volume -DiskNumber $Disk.Number -FriendlyName Share -FileSystem NTFS -DriveLetter S
}
endregion#>