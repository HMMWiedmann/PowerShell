<#
	.SYNOPSIS
		Creates a new virtual router.

	.DESCRIPTION
		Creates a new virtual router.

	.PARAMETER  Computername
		Defines the VM Computer name.

	.PARAMETER  ParentDiskPath
		Defines the path to the parent disk.

	.PARAMETER  VMPath
		Defines the path for the VM files.

	.PARAMETER  IPv4Address
		Defines the IPv4 address used by this system.

	.PARAMETER  SubnetMaskLength
		Defines the subnet mask bit length.

	.PARAMETER  LegacyServer
		Specifies that the server system is 2008 R2 or older.

	.PARAMETER  NICCount
		Specifies the ammount of additional network interface cards (max. 7).

	.EXAMPLE
		. .\newvirtualrouter.ps1
		New-VirtualRouter -Computername TestSV -ParentDiskPath c:\PD\2008R2\2008R2.vhdx -VMPath v:\VMs -IPv4Address 192.168.1.1 -SubnetMaskLength 24 -LegacyServer -NICCount 4

	.EXAMPLE
		. c:\temp\newvirtualrouter.ps1
		New-VirtualRouter -Computername TestSV -ParentDiskPath c:\PD\2008R2\2008R2.vhdx -VMPath v:\VMs -IPv4Address 192.168.1.1 -SubnetMaskLength 24 -LegacyServer -NICCount 4

	.INPUTS
		System.String

	.OUTPUTS
		System.String

	.NOTES
		Version 1.0.0 - 05/18/2017 - Martin Handl - Initial Version
		Version 1.0.1 - 01/19/2018 - Martin Handl - Disableing all protocol bindings execpt IPv4
		Version 1.0.1 - 01/29/2018 - Martin Handl - Subnet mask bits implemented

	.LINK
		about_functions_advanced

	.LINK
		about_comment_based_help

	.LINK
		about_functions_advanced_parameters

	.LINK
		about_functions_advanced_methods
#>
function New-VirtualRouter
{
	[CmdletBinding()]
	param (
		[Parameter(Position = 0,
				   Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
		[System.String]$Computername,
		[Parameter(Position = 1,
				   Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
		[System.String]$ParentDiskPath,
		[Parameter(Position = 2,
				   Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
		[System.String]$VMPath,
		[Parameter(Position = 3,
				   Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
		[System.String]$IPv4Address,
		[Parameter(Position = 4,
				   Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
		[ValidateRange(0,32)]
		[System.String]$SubnetMaskLength,
		[Parameter(Position = 5,
				   Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
		[Switch]$LegacyServer,
		[Parameter(Position = 6,
			 Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
		[ValidateRange(1, 7)]
		[System.int32]$NICCount
	)
	begin
	{
		#Writing Debug Infos
		Write-Verbose "Computername is $Computername"
		Write-Verbose "PartenDiskPath is $ParentDiskPath"
		Write-Verbose "VMPath is $VMPath"
		Write-Verbose "IPv4Address is $IPv4Address"
		Write-Verbose "Subnetmask is $SubnetMask"
		
		$threeocts = $IPv4Address.Split(".")[0..2] -join "."
		$GW = $threeocts + ".254"
		$CPUCount = [math]::Floor(((Get-CimInstance -ClassName Win32_processor).numberoflogicalprocessors | Measure-Object -Sum).Sum / 3)
		
		function ConvertTo-Mask
		{
			[CmdLetBinding()]
			param (
				[Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
				[Alias("Length")]
				[ValidateRange(0, 32)]
				$Mask
			)
			
			$IP = ([Convert]::ToUInt32($(("1" * $Mask).PadRight(32, "0")), 2))
			Switch -RegEx ($IP)
			{
				"([01]{8}.){3}[01]{8}" {
					return [String]::Join('.', $($IP.Split('.') | ForEach-Object { [Convert]::ToUInt32($_, 2) }))
				}
				"\d" {
					$IP = [UInt32]$IP
					$DottedIP = $(For ($i = 3; $i -gt -1; $i--)
						{
							$Remainder = $IP % [Math]::Pow(256, $i)
							($IP - $Remainder) / [Math]::Pow(256, $i)
							$IP = $Remainder
						})
					
					$result = [String]::Join('.', $DottedIP)
					Write-Output $result
				}
				default
				{
					Write-Error "Cannot convert this format"
				}
			}
		}
		
		$decimalSubnetMask = ConvertTo-Mask -Mask $SubnetMaskLength
		
		#Creating answerfiles
		New-Item -ItemType directory -Path $VMPath -Name $Computername -Force
		New-Item -ItemType directory -Path $VMPath\$Computername -Name 'Virtual Hard Disks'
		switch ($LegacyServer)
		{
			true {
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\$Computername.cmd" -Value "netsh interface ipv6 delete dnsserver `"Local Area Connection`" ::1"
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\$Computername.cmd" -Value "netsh interface ipv4 set address `"Local Area Connection`" static $IPv4Address $decimalSubnetMask 1"
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\$Computername.cmd" -Value "netdom renamecomputer localhost /newname:$Computername /Force /Reboot"
				
			}
			default
			{
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\$Computername.cmd" -Value "powershell.exe -ExecutionPolicy bypass -file $Computername.ps1"
				
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\$Computername.ps1" -Value "Get-ScheduledTask -TaskName ServerManager | Disable-ScheduledTask"
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\$Computername.ps1" -Value "Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled false"
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\$Computername.ps1" -Value "Set-ItemProperty -Path `"HKLM:\System\CurrentControlSet\Control\Terminal Server`"-name `"fDenyTSConnections`" -Value 0"
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\$Computername.ps1" -Value "Enable-NetFirewallRule -DisplayGroup `"Remote Desktop`""
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\$Computername.ps1" -Value "Set-ItemProperty -Path `"HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp`" -name `"UserAuthentication`" -Value 1"
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\$Computername.ps1" -Value "Disable-NetAdapterBinding -InterfaceAlias ethernet -ComponentID ms_tcpip6"
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\$Computername.ps1" -Value "New-NetIPAddress -InterfaceAlias ethernet -IPAddress $IPv4Address -PrefixLength $SubnetMaskLength -DefaultGateway $GW"
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\$Computername.ps1" -Value "Disable-NetAdapterBinding -InterfaceAlias * -ComponentID ms_tcpip6, ms_rspndr, ms_lltdio, ms_lldp, ms_implat, ms_msclient, ms_pacer, ms_server"
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\$Computername.ps1" -Value "Install-WindowsFeature -Name Routing"
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\$Computername.ps1" -Value "Rename-Computer -NewName $Computername -Restart"
				
			}
		}
	}
	process
	{
		#Creating Virtual Hard Disks
		New-VHD -ParentPath $ParentDiskPath -Path "$VMPath\$Computername\Virtual Hard Disks\$Computername.vhdx" -Differencing | Out-Null
		
		#mounting and copying answer files
		$driveb4 = (Get-PSDrive).Name
		Mount-VHD -Path "$VMPath\$Computername\Virtual Hard Disks\$Computername.vhdx"
		$driveat = (Get-PSDrive).name
		$drive = (Compare-Object -ReferenceObject $driveb4 -DifferenceObject $driveat).inputobject[-1] + ':'
		New-Item -Path $drive\SetupTemp -ItemType Directory | Out-Null
		Set-Location -Path $drive\SetupTemp | Out-Null
		switch ($LegacyServer)
		{
			true {
				Copy-Item -Path "$VMPath\$Computername\Virtual Hard Disks\$Computername.cmd" -Destination . | Out-Null
				Set-Location -Path c: | Out-Null
				reg load HKLM\VM $drive\Windows\System32\config\SOFTWARE
				Set-ItemProperty -Path 'HKLM:\vm\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name AutoAdminLogon -Value 1
				Set-ItemProperty -Path 'HKLM:\vm\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name DefaultUserName -Value "Administrator"
				Set-ItemProperty -Path 'HKLM:\vm\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name DefaultPassword -Value "C0mplex"
				Set-ItemProperty -Path 'HKLM:\vm\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name DefaultDomain -Value "."
				Set-ItemProperty -Path 'HKLM:\vm\Microsoft\Windows\CurrentVersion\RunOnce' -Name "$($Computername).cmd" -Value "C:\SetupTemp\$Computername.cmd"
				reg unload HKLM\VM
				Dismount-VHD -Path "$VMPath\$Computername\Virtual Hard Disks\$Computername.vhdx"
			}
			default
			{
				Copy-Item -Path "$VMPath\$Computername\Virtual Hard Disks\$Computername.cmd" -Destination . | Out-Null
				Copy-Item -Path "$VMPath\$Computername\Virtual Hard Disks\$Computername.ps1" -Destination . | Out-Null
				Set-Location -Path c: | Out-Null
				reg load HKLM\VM $drive\Windows\System32\config\SOFTWARE
				Set-ItemProperty -Path 'HKLM:\vm\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name AutoAdminLogon -Value 1
				Set-ItemProperty -Path 'HKLM:\vm\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name DefaultUserName -Value "Administrator"
				Set-ItemProperty -Path 'HKLM:\vm\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name DefaultPassword -Value "C0mplex"
				Set-ItemProperty -Path 'HKLM:\vm\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name DefaultDomain -Value "."
				Set-ItemProperty -Path 'HKLM:\vm\Microsoft\Windows\CurrentVersion\RunOnce' -Name "$($Computername).cmd" -Value "C:\SetupTemp\$Computername.cmd"
				reg unload HKLM\VM
				Dismount-VHD -Path "$VMPath\$Computername\Virtual Hard Disks\$Computername.vhdx"
			}
		}
		
		#creating new VM
		switch ($LegacyServer)
		{
			true {
				New-VM -Name $Computername -MemoryStartupBytes 1024MB -Path $VMPath -VHDPath "$VMPath\$Computername\Virtual Hard Disks\$Computername.vhdx"
				Set-VM -Name $Computername -DynamicMemory
				Set-VMProcessor -VMName $Computername -Count $CPUCount
				for ($NIC = 0; $NIC -lt $NICCount; $NIC++)
				{
					Add-VMNetworkAdapter -VMName $Computername -SwitchName Private-1
				}
				Connect-VMNetworkAdapter -VMName $Computername -SwitchName Private-1
			}
			default
			{
				New-VM -Name $Computername -MemoryStartupBytes 1024MB -Path $VMPath -VHDPath "$VMPath\$Computername\Virtual Hard Disks\$Computername.vhdx" -Generation 2
				Set-VM -Name $Computername -DynamicMemory
				for ($NIC = 0; $NIC -lt $NICCount; $NIC++)
				{
					Add-VMNetworkAdapter -VMName $Computername -SwitchName Private-1
				}
				Set-VMProcessor -VMName $Computername -Count $CPUCount
				Connect-VMNetworkAdapter -VMName $Computername -SwitchName Private-1
			}
		}
		
	}
	end
	{
	}
}