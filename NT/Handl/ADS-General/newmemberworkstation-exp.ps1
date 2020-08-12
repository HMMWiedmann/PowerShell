<#
	.SYNOPSIS
		Creates a new member workstation for an existing domain.

	.DESCRIPTION
		Creates a new member workstation for an existing domain
		and joins the system to that domain.

	.PARAMETER  Computername
		Defines the VM Computer name.

	.PARAMETER  ParentDiskPath
		Defines the path to the parent disk.

	.PARAMETER  VMPath
		Defines the path for the VM files.

	.PARAMETER  IPv4Address
		Defines the IPv4 address used by this system.

	.PARAMETER  SubnetMask
		Defines the IPv4 address used by this system.
	
	.PARAMETER  DomainName
		Defines the name of the domain to join as a 
		workstation system.

	.PARAMETER  DNSServer
		Specifies the preferred DNS Server IPv4 address.

	.PARAMETER  LegacyWorkstation
		Specifies that the workstation system is Windows 7 or older.

	.EXAMPLE
		. .\newmemberworkstation.ps1
		New-ADMemberWorkstation -Computername TestWK -ParentDiskPath c:\PD\Win7\Win7.vhdx -VMPath v:\VMs -IPv4Address 192.168.1.1 -SubnetMask 255.255.255.0 -DNSServer 192.168.1.2 -DomainName Test.de -LegacyWorkstation

	.EXAMPLE
		. c:\temp\newmemberworkstation.ps1
		New-ADMemberWorkstation -Computername TestWK -ParentDiskPath c:\PD\Win7\Win7.vhdx -VMPath v:\VMs -IPv4Address 192.168.1.1 -SubnetMask 255.255.255.0 -DNSServer 192.168.1.2 -DomainName Test.de -LegacyWorkstation

	.INPUTS
		System.String

	.OUTPUTS
		System.String

	.NOTES
		Version 1.0.0 - 05/12/2017 - Martin Handl - Initial Version
		Version 1.0.1 - 05/29/2017 - Martin Handl - IE default URLs set to about:blank
		Version 1.0.1 - 01/16/2018 - Martin Handl - setup routine completely automated

	.LINK
		about_functions_advanced

	.LINK
		about_comment_based_help

	.LINK
		about_functions_advanced_parameters

	.LINK
		about_functions_advanced_methods
#>
function New-ADMemberWorkstation
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
		[ValidateSet("255.0.0.0", "255.255.0.0", "255.255.255.0")]
		[System.String]$SubnetMask,
		[Parameter(Position = 5,
				   Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
		[System.String]$DomainName,
		[Parameter(Position = 6,
				   Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
		[Switch]$LegacyWorkstation,
		[Parameter(Position = 7,
				   Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
		[System.String]$DNSServer
	)
	begin
	{
		#Writing Debug Infos
		Write-Verbose "Computername is $Computername"
		Write-Verbose "PartenDiskPath is $ParentDiskPath"
		Write-Verbose "VMPath is $VMPath"
		Write-Verbose "IPv4Address is $IPv4Address"
		Write-Verbose "Subnetmask is $SubnetMask"
		Write-Verbose "Domainname is $DomainName"
		
		$NetBIOSFR = $DomainName.Split(".")[0]
		$threeocts = $IPv4Address.Split(".")[0..2] -join "."
		$GW = $threeocts + ".254"
		$CPUCount = [math]::Floor(((Get-CimInstance -ClassName Win32_processor).numberoflogicalprocessors | Measure-Object -Sum).Sum / 3)
		
		#Creating answerfiles
		New-Item -ItemType directory -Path $VMPath -Name $Computername -Force
		New-Item -ItemType directory -Path $VMPath\$Computername -Name 'Virtual Hard Disks'
		switch ($LegacyWorkstation)
		{
			true {
				New-Item -Name "$Computername.cmd" -ItemType File -Path "$VMPath\$Computername\Virtual Hard Disks\"
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\$Computername.cmd" -Value "netsh interface ipv6 delete dnsserver `"Local Area Connection`" ::1"
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\$Computername.cmd" -Value "netsh interface ipv4 set address `"Local Area Connection`" static $IPv4Address 255.255.255.0 $GW 1"
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\$Computername.cmd" -Value "netsh interface ipv4 set dns `"Local Area Connection`" static $DNSServer"
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\$Computername.cmd" -Value "netdom renamecomputer localhost /newname:$Computername /Force /Reboot"
				
				New-Item -Name "$Computername.ps1" -ItemType File -Path "$VMPath\$Computername\Virtual Hard Disks\"
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\$Computername.ps1" -Value "Set-ItemProperty -Path 'HKLM:\Software\Microsoft\Windows\CurrentVersion\RunOnce' -Name `"DomJoin.ps1`" -Value `"C:\SetupTemp\DomJoin.ps1`""
				
				New-Item -Path "$VMPath\$Computername\Virtual Hard Disks\DomJoin.cmd"
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\DomJoin.cmd" -Value "powershell.exe -ExecutionPolicy bypass -file C:\SetupTemp\DomJoin.ps1"
				
				New-Item -Path "$VMPath\$Computername\Virtual Hard Disks\DomJoin.ps1"
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\DomJoin.ps1" -Value "Remove-ItemProperty -Path `'HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon`' -Name AutoAdminLogon"
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\DomJoin.ps1" -Value "Remove-ItemProperty -Path `'HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon`' -Name DefaultUserName"
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\DomJoin.ps1" -Value "Remove-ItemProperty -Path `'HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon`' -Name DefaultPassword"
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\DomJoin.ps1" -Value "Remove-ItemProperty -Path `'HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon`' -Name DefaultDomain"
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\DomJoin.ps1" -Value "`$Cred = New-object System.Management.Automation.PSCredential `"administrator@$DomainName`", (ConvertTo-SecureString -String `"C0mplex`" -AsPlainText -Force)"
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\DomJoin.ps1" -Value "Add-Computer -DomainCredential `$Cred -DomainName $DomainName -Restart"
			}
			default
			{
				New-Item -Name "$Computername.cmd" -ItemType File -Path "$VMPath\$Computername\Virtual Hard Disks\"
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\$Computername.cmd" -Value "powershell.exe -ExecutionPolicy bypass -file C:\SetupTemp\$Computername.ps1"
								
				New-Item -Name "$Computername.ps1" -ItemType File -Path "$VMPath\$Computername\Virtual Hard Disks\"
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\$Computername.ps1" -Value "Set-ItemProperty -Path 'HKLM:\Software\Microsoft\Windows\CurrentVersion\RunOnce' -Name `"DomJoin.ps1`" -Value `"C:\SetupTemp\DomJoin.ps1`""
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\$Computername.ps1" -Value "Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled false"
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\$Computername.ps1" -Value "Set-ItemProperty -Path `"HKLM:\System\CurrentControlSet\Control\Terminal Server`"-name `"fDenyTSConnections`" -Value 0"
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\$Computername.ps1" -Value "Enable-NetFirewallRule -DisplayGroup `"Remote Desktop`""
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\$Computername.ps1" -Value "Set-ItemProperty -Path `"HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp`" -name `"UserAuthentication`" -Value 1"
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\$Computername.ps1" -Value "Disable-NetAdapterBinding -InterfaceAlias ethernet -ComponentID ms_tcpip6"
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\$Computername.ps1" -Value "Set-ItemProperty -Path `"HKLM:\SOFTWARE\Microsoft\Internet Explorer\Main`" -Name `"Default_Page_URL`" -Value `"about:blank`""
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\$Computername.ps1" -Value "Set-ItemProperty -Path `"HKLM:\SOFTWARE\Microsoft\Internet Explorer\Main`" -Name `"Default_Search_URL`" -Value `"about:blank`""
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\$Computername.ps1" -Value "Set-ItemProperty -Path `"HKLM:\SOFTWARE\Microsoft\Internet Explorer\Main`" -Name `"Search Page`" -Value `"about:blank`""
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\$Computername.ps1" -Value "Set-ItemProperty -Path `"HKLM:\SOFTWARE\Microsoft\Internet Explorer\Main`" -Name `"Start Page`" -Value `"about:blank`""
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\$Computername.ps1" -Value "Set-ItemProperty -Path `"HKCU:\SOFTWARE\Microsoft\Internet Explorer\Main`" -Name `"Search Page`" -Value `"about:blank`""
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\$Computername.ps1" -Value "Set-ItemProperty -Path `"HKCU:\SOFTWARE\Microsoft\Internet Explorer\Main`" -Name `"Start Page`" -Value `"about:blank`""
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\$Computername.ps1" -Value "Set-ItemProperty -Path `"HKCU:\SOFTWARE\Microsoft\Internet Explorer\Main`" -Name `"Default_Page_URL`" -Value `"about:blank`""
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\$Computername.ps1" -Value "Set-ItemProperty -Path `"HKCU:\SOFTWARE\Microsoft\Internet Explorer\Main`" -Name `"First Home Page`" -Value `"about:blank`""
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\$Computername.ps1" -Value "New-NetIPAddress -InterfaceAlias ethernet -IPAddress $IPv4Address -PrefixLength 24 -DefaultGateway $GW"
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\$Computername.ps1" -Value "Set-DnsClientServerAddress -InterfaceAlias ethernet -ResetServerAddresses"
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\$Computername.ps1" -Value "Set-DnsClientServerAddress -InterfaceAlias ethernet -ServerAddresses `"$DNSServer`""
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\$Computername.ps1" -Value "Rename-Computer -NewName $Computername -Restart"
				
				New-Item -Path "$VMPath\$Computername\Virtual Hard Disks\DomJoin.cmd"
				Add-Content -PassThru "$VMPath\$Computername\Virtual Hard Disks\DomJoin.cmd" -Value "powershell.exe -ExecutionPolicy bypass -file C:\SetupTemp\DomJoin.ps1"
				
				New-Item -Path "$VMPath\$Computername\Virtual Hard Disks\DomJoin.ps1"
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\DomJoin.ps1" -Value "Remove-ItemProperty -Path `'HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon`' -Name AutoAdminLogon"
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\DomJoin.ps1" -Value "Remove-ItemProperty -Path `'HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon`' -Name DefaultUserName"
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\DomJoin.ps1" -Value "Remove-ItemProperty -Path `'HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon`' -Name DefaultPassword"
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\DomJoin.ps1" -Value "Remove-ItemProperty -Path `'HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon`' -Name DefaultDomain"
				Add-Content -PassThru "$VMPath\$Computername\Virtual Hard Disks\DomJoin.ps1" -Value "`$Cred = New-object System.Management.Automation.PSCredential `"administrator@$DomainName`", (ConvertTo-SecureString -String `"C0mplex`" -AsPlainText -Force)"
				Add-Content -PassThru "$VMPath\$Computername\Virtual Hard Disks\DomJoin.ps1" -Value "Add-Computer -DomainCredential `$Cred -DomainName $DomainName -Restart"
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
		switch ($LegacyWorkstation)
		{
			true {
				Copy-Item -Path "$VMPath\$Computername\Virtual Hard Disks\$Computername.cmd" -Destination . | Out-Null
				Copy-Item -Path "$VMPath\$Computername\Virtual Hard Disks\DomJoin.cmd" -Destination . | Out-Null
				Copy-Item -Path "$VMPath\$Computername\Virtual Hard Disks\DomJoin.ps1" -Destination . | Out-Null
				Set-Location -Path c: | Out-Null
				reg load HKLM\VM $drive\Windows\System32\config\SOFTWARE
				Set-ItemProperty -Path 'HKLM:\vm\Microsoft\Windows\CurrentVersion\RunOnce' -Name "$($Computername).cmd" -Value "C:\SetupTemp\$Computername.cmd"
				reg unload HKLM\VM
				Dismount-VHD -Path "$VMPath\$Computername\Virtual Hard Disks\$Computername.vhdx"
			}
			default
			{
				Copy-Item -Path "$VMPath\$Computername\Virtual Hard Disks\$Computername.cmd" -Destination . | Out-Null
				Copy-Item -Path "$VMPath\$Computername\Virtual Hard Disks\$Computername.ps1" -Destination . | Out-Null
				Copy-Item -Path "$VMPath\$Computername\Virtual Hard Disks\DomJoin.cmd" -Destination . | Out-Null
				Copy-Item -Path "$VMPath\$Computername\Virtual Hard Disks\DomJoin.ps1" -Destination . | Out-Null
				Set-Location -Path c: | Out-Null
				reg load HKLM\VM $drive\Windows\System32\config\SOFTWARE
				Set-ItemProperty -Path 'HKLM:\vm\Microsoft\Windows\CurrentVersion\RunOnce' -Name "$($Computername).cmd" -Value "C:\SetupTemp\$Computername.cmd"
				reg unload HKLM\VM
				Dismount-VHD -Path "$VMPath\$Computername\Virtual Hard Disks\$Computername.vhdx"
			}
		}
		
		#creating new VM
		switch ($LegacyWorkstation)
		{
			true {
				New-VM -Name $Computername -MemoryStartupBytes 1024MB -Path $VMPath -VHDPath "$VMPath\$Computername\Virtual Hard Disks\$Computername.vhdx"
				Set-VM -Name $Computername -DynamicMemory
				Set-VMProcessor -VMName $Computername -Count $CPUCount
				Connect-VMNetworkAdapter -VMName $Computername -SwitchName Private-1
			}
			default
			{
				New-VM -Name $Computername -MemoryStartupBytes 1024MB -Path $VMPath -VHDPath "$VMPath\$Computername\Virtual Hard Disks\$Computername.vhdx" -Generation 2
				Set-VM -Name $Computername -DynamicMemory
				Set-VMProcessor -VMName $Computername -Count $CPUCount
				Connect-VMNetworkAdapter -VMName $Computername -SwitchName Private-1
			}
		}
		
	}
	end
	{
	}
}