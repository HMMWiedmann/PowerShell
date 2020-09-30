# funktioniert nur mit Windows 10 oder Server VMs
# nicht Windows 7


$HyperV_Hosts = (Get-ADComputer -Filter { dnshostname -like "*hyperv*" }).DNSHostName 

$ParentdiskPath = "V:\Parentdisks\WindowsServer2019.vhdx"

$VMConfig = @{

    VMNamePre = "VWIN10-"
    CPU = 4
    RAM = 8
    SwitchName = "SET"
    DoIPConfig = "True"
    DoDomainJoin = "True"  
    IPv4Pre = "192.168.1." # $IPv4Address = $VMConfig.IPv4Pre + $Platznummer + $VMConfig.IPv4Suf
    IPv4Suf = "1"
    SubnetMask = "24"
    DNS1 = "192.168.1.201"
    DNS2 = "192.168.2.202"
    DomainName = "ADS-CENTER.DE"
    EnabledFirewall = "False"
    Differencing = "False"
    OSType = "Server" # oder "Client"
}

# Copy Parentdisk
foreach($HV in $HyperV_Hosts)
{
    Copy-Item -Path $ParentdiskPath -Recurse -Destination "\\$HV\V$\Parentdisks\Parentdisk.vhdx"
}

# VM erstellen
Invoke-Command -ComputerName $HyperV_Hosts -ArgumentList $VMConfig -ScriptBlock{

    $VMConfig = $args[0]
    $Platznummer = $env:COMPUTERNAME.Substring($ENV:COMPUTERNAME.Length - 2)
    $ParentdiskPath = "V:\Parentdisks\Parentdisk.vhdx"

    $CPU = $VMConfig.CPU
    $RAMSize = $VMConfig.RAM
    $Switchname = $VMConfig.SwitchName
    $VMName = $VMConfig.VMNamePre + $Platznummer

    if(Get-VM -Name $VMName -ErrorAction Ignore)
    {
        Write-Host "VM $VMName already exists!"
        Write-Host ""
        Exit 1
    }
    elseif ($Differencing -eq "True") 
    {
        $DestinationFolder = "V:\$VMName"

        $null = New-VHD -Differencing -Path "$DestinationFolder\$VMName.vhdx" -ParentPath $ParentdiskPath
        
        $null = New-VM -VMName $VMName -Path $DestinationFolder -MemoryStartupBytes $RAMSize -SwitchName $Switchname -VHDPath "$DestinationFolder\$VMName.vhdx" -Generation 2 
        $null = Set-VMProcessor -VMName $VMName -Count $CPU
        $null = Set-VM -VMName $VMName -StaticMemory
    }
    elseif($Differencing -eq "False")
    {      
        $DestinationFolder = "V:\$VMName"

        if(!(Test-Path -Path $DestinationFolder)) 
        {
            $Null = DestinationFolder -Type Directory
        }

        if(!(Test-Path -Path "$DestinationFolder\$VMName.vhdx")) 
        {
            Write-Host "Copying VHDX of $VMName"
            Copy-Item -Path $ParentdiskPath -Destination $DestinationFolder"\$VMName.vhdx" -Recurse -Force | Out-Null 
            Write-Host "Done copying VHDX of $VMName"
        } 
        else
        {
            Write-Host ("VHDX of $VMName already at $DestinationFolder")
        }

        $null = New-VM -VMName $VMName -Path $DestinationFolder -MemoryStartupBytes $RAMSize -SwitchName $Switchname -VHDPath "$DestinationFolder\$VMName.vhdx" -Generation 2 
        $null = Set-VMProcessor -VMName $VMName -Count $CPU
        $null = Set-VM -VMName $VMName -StaticMemory
    }

    "Starting $VMName"
    Start-VM -VMName $VMName

    Write-Host ""
    Write-Host "Creation of $VMName is done!"
}

# VM konfigurieren
Invoke-Command -ComputerName $HyperV_Hosts -ArgumentList $VMConfig -ScriptBlock{

    $VMConfig = $args[0]
    $Platznummer = $env:COMPUTERNAME.Substring($ENV:COMPUTERNAME.Length - 2)

    $DoDomainJoin = $VMConfig.DoDomainJoin
    $DoIPConfig = $VMConfig.DoIPConfig
    $Subnet = $VMConfig.SubnetMask
    $DNS1 = $VMConfig.DNS1
    $DNS2 = $VMConfig.DNS2
    $DomainName = $VMConfig.DomainName
    $EnabledFirewall = $VMConfig.EnabledFirewall
    $VMName = $VMConfig.VMNamePre + $Platznummer
    $IPv4Address = $VMConfig.IPv4Pre + $Platznummer + $VMConfig.IPv4Suf
    $OSType = $VMConfig.OSType

    if ($OSType -eq "Server") 
    {
        # Local Server Credentials
        [string]$LocalAdmin = "Administrator"
        $LocalPWD = ConvertTo-SecureString "C0mplex" -AsPlainText -Force
                        
        $LocalCredential = New-Object -TypeName System.Management.Automation.PSCredential ($LocalAdmin, $LocalPWD)  
    }
    elseif ($OSType -eq "Client")     
    {
        # Local Client Credentials
        [string]$LocalAdmin = "Admin"
        $LocalPWD = ConvertTo-SecureString "C0mplex" -AsPlainText -Force
                        
        $LocalCredential = New-Object -TypeName System.Management.Automation.PSCredential ($LocalAdmin, $LocalPWD)     
    }
    
    Write-Host "Waiting for Powershell Direct to start on VM: $($VMName)"

    while( (Invoke-Command -VMName $VMName -Credential $LocalCredential { "Test" } -ea SilentlyContinue) -ne "Test" )
    {
        Start-Sleep -Seconds 3
    }

    Write-Host "Powershell Direct responding on VM: $($VMName)"
          
    Invoke-Command -VMName $VMName  -Credential $LocalCredential `
        -ArgumentList $VMName, $DoDomainJoin, $DoIPConfig, $DomainName, $IPv4, $Subnet, $DNS1, $DNS2, $EnabledFirewall `
        -ScriptBlock{

        [string]$VMName = $args[0]
        [string]$DoDomainJoin = $args[1]
        [string]$DoIPConfig = $args[2]

        if ($DomainName -ne ""){ [string]$DomainName = $args[3] }
        if ($IPv4 -ne "") { [string]$IPv4 = $args[4] }
        if ($Subnet -ne "") { [string]$Subnet = $args[5] }
        if ($DNS1 -ne "") { [string]$DNS1 = $args[6] }
        if ($DNS2 -ne "") { [string]$DNS2 = $args[7] }
        if ($EnabledFirewall -ne "") { [string]$EnabledFirewall = $args[8] }

        # Delete local Users exept Administrator and Admin
        try 
        {
            $User = (Get-LocalUser).Where{ !(($PSItem.Name -eq "Admin") -or ($PSItem.Name -eq "Administrator"))}
            $User.foreach{ Remove-LocalUser -Name $PSItem -ErrorAction SilentlyContinue -ErrorVariable $Usererror }    
        }
        catch{}

        # Modify Poweroptions
        powercfg.exe /change monitor-timeout-ac 0 | Out-Null
        powercfg.exe /change monitor-timeout-dc 0 | Out-Null
        powercfg.exe /change standby-timeout-dc 0 | Out-Null
        powercfg.exe /change standby-timeout-ac 0 | Out-Null
        powercfg.exe /change hibernate-timeout-ac 0 | Out-Null
        powercfg.exe /change hibernate-timeout-dc 0 | Out-Null                
                      
        # Enable RDP
        Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Terminal Server" -Name "fDenyTSConnections" -Value 0 -Force
        Enable-NetFirewallRule -DisplayGroup "Remote Desktop"

        if ($EnabledFirewall -eq "False") 
        {
            # Disable Firewall
            Set-NetFirewallProfile -All -Enabled False 
        }
        elseif($EnabledFirewall -eq "True")
        {
            # Enable Firewall
            Set-NetFirewallProfile -All -Enabled True
        }

        # IP Configuration
        if ($DoIPConfig -eq "True")
        {
            $DefaultGW = $IPv4Address | Select-Object -First 1
            $DefaultGW2 = $DefaultGW.Split(".")[-1]
            $rem = $DefaultGW.Length - $DefaultGW2.Length
            $DefaultGW = $DefaultGW.Remove($rem)
            $DefaultGW = $DefaultGW + "254"

            $Netadapter = Get-NetAdapter | Select-Object -First 1 
            $Netadapter | Set-NetIPInterface -Dhcp Disabled | Out-Null
            $Netadapter | New-NetIPAddress -IPAddress $IPv4Address -DefaultGateway $DefaultGW -PrefixLength $Subnet | Out-Null
            $Netadapter | Set-DnsClientServerAddress -ServerAddresses $DNS1,$DNS2 -ErrorAction Ignore -WarningAction Ignore -InformationAction Ignore | Out-Null
        }
        else 
        {
            "$VMName -- no IP Configuration"
        }
                
        # DomainJoin   
        if ($DoDomainJoin -eq "True")
        {
            # Domain Credentials
            [string]$DomainAdmin = "Administrator@$DomainName"
            $DomainPWD = ConvertTo-SecureString "C0mplex" -AsPlainText -Force

            $DomainCredential = New-Object -TypeName System.Management.Automation.PSCredential ($DomainAdmin, $DomainPWD)
            Add-Computer -ComputerName $VMName -Credential $DomainCredential -DomainName $DomainName 

            Write-Host ("$VMName joined the Domain $DomainName") -ForegroundColor Green
        }
        else 
        {
            "$VMName -- No Domainjoin"
        }

        Rename-Computer -NewName $VMName -ErrorAction SilentlyContinue

        Restart-Computer -Force

        Write-Host $VMname": Name was set"
     }

     while( (Invoke-Command -VMName $VMName -Credential $LocalCredential { "Test" } -ea SilentlyContinue) -ne "Test" )
     {
        Start-Sleep -Seconds 3
     }
     Write-Host "VM: $VMName is ready for use!"
}