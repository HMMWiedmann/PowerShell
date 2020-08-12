<#
    .SYNOPSIS
    Creates Virtual Machines based on a CSV file.

    .DESCRIPTION
    Uses VMName, CPU, RAM of the CSV file to create the virtual Machines.
    Using the function Configure-VirtualMachine to set the VM at the right Configuration.

    .PARAMETER CSVListPath
    Path to CSV-List

    .PARAMETER ParentdiskPath
    Path to the Parentdisk you want to use for the Virtual Machines

    .PARAMETER SwitchName
    Name of the Virtual Switch that will be used to connect the VMs

    .PARAMETER InstallationPath
    Location of the Virtual Machine Files. Default is the Volume V:\.

    .PARAMETER Differencing
    You can use differencing to save Diskspace. Default is False, no differencing will be used.

    .EXAMPLE
    Add-VMs -CSVListPath "C:\Temp\CSVList.csv" -ParentdiskPath "V:\Parentdisks\Win10-1803-March.vhdx" -SwitchName EXTERNAL

    .EXAMPLE
    Add-VMs -CSVListPath "C:\Temp\CSVList.csv" -ParentdiskPath "V:\Parentdisks\Win10-1803-March.vhdx" -SwitchName EXTERNAL -InstallationPath V:\ -Differencing True

    .NOTES
    Inspired by Wiesners!.
#>
workflow Add-VMs
{
    param 
    (
        # required Parameters
        [Parameter(Mandatory = $true, Position = 1)]
        [string]$CSVListPath,

        [Parameter(Mandatory = $true, Position = 2)]
        [string]$ParentdiskPath,

        [Parameter(Mandatory = $true, Position = 3)]
        [string]$SwitchName,

        # not required Parameters
        [Parameter(Mandatory = $false, Position = 4)]
        [string]$InstallationPath,

        [Parameter(Mandatory = $false, Position = 5)]
        [ValidateSet("True","False")]
        [string]$Differencing,

        [Parameter(Mandatory = $false, Position = 6)]
        [switch]$WIN7VM
    )

    if ($InstallationPath -eq $null) 
    {
        $InstallationPath = 'V:\'
    }

    if ($Differencing -eq $null) 
    {
        $Differencing = "False"
    }

    $StartTime = Get-Date
    $Start = "$($StartTime.Hour):$($StartTime.Minute):$($StartTime.Second)"

    # Check Virtual Switch for the Virtual Machines
    try
    {
        if(!(Get-VMSwitch -Name $SwitchName -ErrorAction Ignore)) 
        {
            $NetAdapter = (Get-NetAdapter) | Where-Object { $PSItem.Status -eq "Up" } | Select-Object -First 1
            Rename-NetAdapter -NewName Datacenter -InputObject $NetAdapter
            New-VMSwitch -Name $SwitchName -NetAdapterName "Datacenter"
        }

        if(!(Get-VMSwitch -Name $SwitchName)) 
        {
            "No Virtual Switch and no NIC found"
            "stopping Workflow"
            Start-Sleep -Seconds 5
            Exit 1
        }        
    }
    catch { }

    # Client or Server
    $OSImage = Get-WindowsImage -ImagePath $ParentdiskPath -Index 1
    $OSType = $OSImage.InstallationType

    "Workflow started at $Start"
    "Using $CSVListPath as CSV-List"
    "VMs will be connected to VM-Switch: $SwitchName"

    $CSV = Import-csv -Path $CSVListPath

    foreach -Parallel  ($CSVLine in $CSV )
    {   
        if ($WIN7VM -eq $true) 
        {
    	    InlineScript
            {
                [string]$VMName = $using:CSVLine.VMName
                [int64]$RAM = $using:CSVLine.Memory
                [int64]$CPU = $using:CSVLine.CPU
                [string]$OSType = $using:OSType
                [int64]$RAMSize = $RAM * 1073741824
                [string]$VMRoot = $using:InstallationPath
                [string]$Differencing = $using:Differencing
                
                if(Get-VM -Name $VMName -ErrorAction Ignore)
                {
                    Write-Host "VM $VMName already exists!"
                    Write-Host ""
                    Exit 1
                }
                elseif ($Differencing -eq "True")
                {
                    if(($VMRoot.Substring($VMRoot.Length - 2)) -notlike "*\")
                    {
                        $VMRoot = $VMRoot + "\"
                    }

                    $DestinationFolder = "$($VMRoot)$($VMName)"

                    $null = New-VHD -Differencing -Path $DestinationFolder"\$VMName.vhdx" -ParentPath $using:ParentdiskPath
                    
                    $null = New-VM -VMName $VMName -Path $DestinationFolder -MemoryStartupBytes $RAMSize -SwitchName $using:Switchname -VHDPath "$DestinationFolder\$VMName.vhdx" -Generation 2 
                    $null = Set-VMProcessor -VMName $VMName -Count $CPU
                    $null = Set-VM -VMName $VMName -StaticMemory
                }
                elseif($Differencing -eq "False")
                {      

                    if(($VMRoot.Substring($VMRoot.Length - 2)) -notlike "*\")
                    {
                        $VMRoot = $VMRoot + "\"
                    }

                    $DestinationFolder = "$($VMRoot)$($VMName)"

                    if(!(Test-Path -Path $DestinationFolder)) 
                    {
                        New-Item $DestinationFolder -Type Directory | Out-Null
                    }

                    if(!(Test-Path -Path $DestinationFolder"\$VMName\$VMName.vhdx")) 
                    {
                        Write-Host "Copying VHDX of $VMName"
                        Copy-Item -Path $using:ParentdiskPath -Destination $DestinationFolder"\$VMName.vhdx" -Recurse -Force | Out-Null 
                        Write-Host "Done copying VHDX of $VMName"
                    } 
                    else
                    {
                        Write-Host ("VHDX of $VMName already at $DestinationFolder")
                    }

                    $null = New-VM -VMName $VMName -Path $DestinationFolder -MemoryStartupBytes $RAMSize -SwitchName $using:Switchname -VHDPath "$DestinationFolder\$VMName.vhdx" -Generation 1 
                    $null = Set-VMProcessor -VMName $VMName -Count $CPU
                    $null = Set-VM -VMName $VMName -StaticMemory
                }

                Write-Host ""
                Write-Host "Creation of $VMName is done"
                Write-Host "Check if $VMName is ready to configure!"
            }
        }
        else
        {
            InlineScript
            {
                [string]$VMName         = $using:CSVLine.VMName
                [int64]$RAM             = $using:CSVLine.Memory
                [int64]$CPU             = $using:CSVLine.CPU
                [int64]$AddVHDX_Size    = $using:CSVLine.AddVHDX_Size * 1073741824
                [string]$AddVHDX_Type   = $using:CSVLine.AddVHDX_Type
                [string]$OSType         = $using:OSType
                [int64]$RAMSize         = $RAM * 1073741824
                [string]$VMRoot         = $using:InstallationPath
                [string]$Differencing   = $using:Differencing
                
                if(Get-VM -Name $VMName -ErrorAction Ignore)
                {
                    Write-Host "VM $VMName already exists!"
                    Write-Host ""
                    Exit 1
                }
                elseif ($Differencing -eq "True") 
                {
                    if(($VMRoot.Substring($VMRoot.Length - 2)) -notlike "*\")
                    {
                        $VMRoot = $VMRoot + "\"
                    }

                    $DestinationFolder = "$($VMRoot)$($VMName)"

                    $null = New-VHD -Differencing -Path $DestinationFolder"\$VMName.vhdx" -ParentPath $using:ParentdiskPath
                    
                    $null = New-VM -VMName $VMName -Path $DestinationFolder -MemoryStartupBytes $RAMSize -SwitchName $using:Switchname -VHDPath "$DestinationFolder\$VMName.vhdx" -Generation 2 
                    $null = Set-VMProcessor -VMName $VMName -Count $CPU
                    $null = Set-VM -VMName $VMName -StaticMemory
                }
                elseif($Differencing -eq "False")
                {      

                    if(($VMRoot.Substring($VMRoot.Length - 2)) -notlike "*\")
                    {
                        $VMRoot = $VMRoot + "\"
                    }

                    $DestinationFolder = "$($VMRoot)$($VMName)"

                    if(!(Test-Path -Path $DestinationFolder)) 
                    {
                        New-Item $DestinationFolder -Type Directory | Out-Null
                    }

                    if(!(Test-Path -Path $DestinationFolder"\$VMName\$VMName.vhdx")) 
                    {
                        Write-Host "Copying VHDX of $VMName"
                        Copy-Item -Path $using:ParentdiskPath -Destination $DestinationFolder"\$VMName.vhdx" -Recurse -Force | Out-Null 
                        Write-Host "Done copying VHDX of $VMName"
                    } 
                    else
                    {
                        Write-Host ("VHDX of $VMName already at $DestinationFolder")
                    }

                    $null = New-VM -VMName $VMName -Path $DestinationFolder -MemoryStartupBytes $RAMSize -SwitchName $using:Switchname -VHDPath "$DestinationFolder\$VMName.vhdx" -Generation 2 
                    $null = Set-VMProcessor -VMName $VMName -Count $CPU
                    $null = Set-VM -VMName $VMName -StaticMemory
                }

                if ($null -ne $AddVHDX_Size)
                {
                    $VHDXPath = "V:\$($VMName)\$($VMName)-$($AddVHDX_Size).vhdx"

                    New-VHD -Path $VHDXPath -SizeBytes $AddVHDX_Size -ArgumentList $AddVHDX_Type
                    Add-VMHardDiskDrive -VMName $VM.Name -Path $VHDXPath -ControllerType SCSI -ControllerNumber 0 -ControllerLocation 2
                }
                
                Write-Host ""
                Write-Host "Creation of $VMName is done!"
            }
        
            "Starting configuration of VM: $($CSVLine.VMName)."

            Set-VirtualMachineConfiguration -VMName $CSVLine.VMName `
                -DoDomainJoin $CSVLine.DoDomainJoin `
                -DoIPConfig $CSVLine.DoIPConfig `
                -DomainName $CSVLine.DomainName `
                -IPv4 $CSVLine.IPv4 `
                -Subnet $CSVLine.SubnetPrefix `
                -DNS1 $CSVLine.DNS1 `
                -DNS2 $CSVLine.DNS2 `
                -OSType $using:OSType `
                -EnabledFirewall $CSVLine.EnabledFirewall

            "Done with configuration of VM: $($CSVLine.VMName)"
        }
    }

    ""
    "All VMs are done and ready!"
    $FinishTime = Get-Date
    $Finish =  $FinishTime - $StartTime
    $Finish = "$($Finish.Hours) Hours $($Finish.Minutes) Minutes $($Finish.Seconds) Seconds"
    "Workflow duration: $Finish"
}

<#
    .SYNOPSIS
    Configures Virtal Machines based on a CSV List.

    .DESCRIPTION
    Uses VMName, DoIPConfig, DoDomainJoin, IPv4, SubnetPrefix, DNS1, DNS2, DomainName, EnabledFirewall 
    to configure the Virtual Machine. VMName is required.

    .PARAMETER CSVListPath
    Path to the CSV list

    .PARAMETER VMName
    Name of the Virtual Machine

    .PARAMETER DoDomainJoin
    Set "DoDomainJoin" to True will join the VM into the "DomainName" Domain.

    .PARAMETER DoIPConfig
    Set "DoIPConfig" to True will configure the VMs Networkadapter with the values in "IPV4", "SubnetPrefix",
    "DNS1", "DNS2". Based on the IPv4 Value, the Gateway will be at xxx.xxx.xxx.254.

    .PARAMETER DomainName
    Set the Domain.

    .PARAMETER IPv4
    The IPv4 for the Networkadapter of the VM

    .PARAMETER Subnet
    Set the Subnetmask.

    .PARAMETER DNS1
    Set DNS Nr. 1 

    .PARAMETER DNS2
    Set DNS Nr. 2

    .PARAMETER OSType
    Client or Server

    .PARAMETER EnabledFirewall
    Windows Firewall on or off

    .EXAMPLE
    Configure-VirtualMachine -VMName $CSVLine.VMName -DoDomainJoin $CSVLine.DoDomainJoin -DoIPConfig $CSVLine.DoIPConfig `
    -DomainName $CSVLine.DomainName -IPv4 $CSVLine.IPv4 -Subnet $CSVLine.SubnetPrefix -DNS1 $CSVLine.DNS1 -DNS2 $CSVLine.DNS2 `
    -OSType $using:OSType -EnabledFirewall $CSVLine.EnabledFirewall
    
    .NOTES

#>
function Set-VirtualMachineConfiguration
{
    param 
    (
        # required Parameters
        [Parameter(Mandatory=$true, Position = 0)]
        [string]$VMName,

        [Parameter(Mandatory=$false, Position = 1)]
        [string]$DomainName,

        [Parameter(Mandatory=$false, Position = 2)]
        [string]$IPv4,

        [Parameter(Mandatory=$false, Position = 3)]
        [string]$Subnet,

        [Parameter(Mandatory=$false, Position = 4)]
        [string]$DNS1,

        [Parameter(Mandatory=$false, Position = 5)]
        [string]$DNS2,

        [Parameter(Mandatory=$false, Position = 6)]
        [ValidateSet("Server","Client")]
        [string]$OSType,

        [Parameter(Mandatory=$false, Position = 7)]
        [ValidateSet("True","False")]
        [string]$EnabledFirewall,

        [Parameter(Mandatory = $false, Position = 8)]
        [switch]$WIN7VM
    )

    if ($WIN7VM -eq $true) 
    {
        New-Item -Name "$VMName.cmd" -ItemType file -Path "V:\$VMName\" | Out-Null
        New-Item -Name "$VMName.ps1" -ItemType file -Path "V:\$VMName\" | Out-Null
        Add-Content -Path "V:\$VMName\$VMName.cmd" -value "powershell.exe Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Force"
        Add-Content -Path "V:\$VMName\$VMName.cmd" -value "powershell.exe -noexit C:\SetupTemp\$VMName.ps1"
        Add-Content -Path "V:\$VMName\$VMName.ps1" -value "Set-NetFirewallProfile -All -Enabled $EnabledFirewall"
        Add-Content -Path "V:\$VMName\$VMName.ps1" -value "Set-ItemProperty -Path `'HKLM:\System\CurrentControlSet\Control\Terminal Server`'-name `"fDenyTSConnections`" -Value 0"
        Add-Content -Path "V:\$VMName\$VMName.ps1" -value "Enable-NetFirewallRule -DisplayGroup `"Remote Desktop`""
        Add-Content -Path "V:\$VMName\$VMName.ps1" -value "`$Cred = New-object System.Management.Automation.PSCredential `"administrator@$DomainName`", (ConvertTo-SecureString -String `"C0mplex`" -AsPlainText -Force)"
        
        if ($null -ne $IPv4)
        {
            $DefaultGW = $IPv4 | Select-Object -First 1
            $DefaultGW2 = $DefaultGW.Split(".")[-1]
            $rem = $DefaultGW.Length - $DefaultGW2.Length
            $DefaultGW = $DefaultGW.Remove($rem)
            $DefaultGW = $DefaultGW + "254"

            Add-Content -Path "V:\$VMName\$VMName.ps1" -value "New-NetIPAddress -InterfaceAlias ethernet -IPAddress $IPv4 -PrefixLength $Subnet -DefaultGateway $GW"
            Add-Content -Path "V:\$VMName\$VMName.ps1" -value "Set-DnsClientServerAddress -InterfaceAlias ethernet -ResetServerAddresses"
            Add-Content -Path "V:\$VMName\$VMName.ps1" -value "Set-DnsClientServerAddress -InterfaceAlias ethernet -ServerAddresses $DNS1,$DNS2"
        }
        else 
        {
            "$($VMName): no IP Configuration"
        }

        if ($DoDomainJoin -eq "True") 
        {
            "$($VMName): You have to do the Domain Join manually!"
        }
        else 
        {
            "$($VMName): no Domain Join"     
        }

        Add-Content -Path "V:\$VMName\$VMName.ps1" -value "Rename-Computer -NewName $VMName -Restart"
        
        Write-Verbose "Mounting $VMName.vhdx and copying the automated setup files."
        $driveb4 = (Get-PSDrive).Name
        Mount-VHD -Path "V:\$VMName\$VMName.vhdx"
        $driveat = (Get-PSDrive).name
        $drive = (Compare-Object -ReferenceObject $driveb4 -DifferenceObject $driveat).inputobject[-1] + ':'
        New-Item -Path $drive\SetupTemp -ItemType Directory | Out-Null
        Set-Location -Path $drive\SetupTemp | Out-Null
        Copy-Item -Path "V:\$VMName\$VMName.cmd" -Destination . | Out-Null
        Copy-Item -Path "V:\$VMName\$VMName.ps1" -Destination . | Out-Null
        Set-Location -Path c: | Out-Null
        Dismount-VHD -Path "V:\$VMName\$VMName.vhdx"
        Write-Verbose "Dismounted $VMName.vhdx successfully."

        "Starting $VMName"
        Start-VM -VMName $VMName
    }
    else 
    {
        
        "Starting $VMName"
        Start-VM -VMName $VMName
        
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
        
        write-host "Waiting for Powershell Direct to start on VM: $($VMName)"

        while( (Invoke-Command -VMName $VMName -Credential $LocalCredential { "Test" } -ea SilentlyContinue) -ne "Test" )
        {
            Start-Sleep -Seconds 3
        }

        Write-Host "Powershell Direct responding on VM: $($VMName)"
            
        Invoke-Command -VMName $VMName  -Credential $LocalCredential `
            -ArgumentList $VMName, $DomainName, $IPv4, $Subnet, $DNS1, $DNS2, $EnabledFirewall `
            -ScriptBlock{

            [string]$VMName = $args[0]

            if ($DomainName -ne ""){ [string]$DomainName = $args[1] }
            if ($IPv4 -ne "") { [string]$IPv4 = $args[2] }
            if ($Subnet -ne "") { [string]$Subnet = $args[3] }
            if ($DNS1 -ne "") { [string]$DNS1 = $args[4] }
            if ($DNS2 -ne "") { [string]$DNS2 = $args[5] }
            if ($EnabledFirewall -ne "") { [string]$EnabledFirewall = $args[6] }

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

            # Enable/Disable Firewall
            Set-NetFirewallProfile -All -Enabled $EnabledFirewall 
                    
            # IP Configuration
            if ($null -ne $IPv4)
            {
                $DefaultGW = $IPv4 | Select-Object -First 1
                $DefaultGW2 = $DefaultGW.Split(".")[-1]
                $rem = $DefaultGW.Length - $DefaultGW2.Length
                $DefaultGW = $DefaultGW.Remove($rem)
                $DefaultGW = $DefaultGW + "254"

                $Netadapter = Get-NetAdapter | Select-Object -First 1 
                $Netadapter | Set-NetIPInterface -Dhcp Disabled | Out-Null
                $Netadapter | New-NetIPAddress -IPAddress $IPv4 -DefaultGateway $DefaultGW -PrefixLength $Subnet | Out-Null
                $Netadapter | Set-DnsClientServerAddress -ServerAddresses $DNS1,$DNS2 -ErrorAction Ignore -WarningAction Ignore -InformationAction Ignore | Out-Null
            }
            else 
            {
                "$($VMName): no IP Configuration"
            }
                    
            # DomainJoin   
            if ($null -ne $DomainName)
            {
                # Domain Credentials
                [string]$DomainAdmin = "Administrator@$DomainName"
                $DomainPWD = ConvertTo-SecureString "C0mplex" -AsPlainText -Force

                $DomainCredential = New-Object -TypeName System.Management.Automation.PSCredential ($DomainAdmin, $DomainPWD)
                Add-Computer -ComputerName $VMName -Credential $DomainCredential -DomainName $DomainName 

                Write-Host("$VMName joined the Domain $DomainName") -ForegroundColor Green
            }
            else 
            {
                "$($VMName): No Domainjoin"
            }

            Rename-Computer -NewName $VMName -ErrorAction SilentlyContinue
            Restart-Computer -Force
            Write-Host "$($VMName): Name was set"
        }

        while( (Invoke-Command -VMName $VMName -Credential $LocalCredential { "Test" } -ea SilentlyContinue) -ne "Test" )
        {
            Start-Sleep -Seconds 3
        }
        Write-Host "$($VMName): The virtual machine is ready for use!"
    }
}