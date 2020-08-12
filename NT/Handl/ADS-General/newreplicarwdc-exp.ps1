<#
	.SYNOPSIS
		Creates a new VM to be a replica DC.

	.DESCRIPTION
		Creates a new VM to be a replica DC for a new Forest.

	.PARAMETER  Computername
		Defines the VM Computer name.

	.PARAMETER  ParentDiskPath
		Defines the path to the parent disk.

	.PARAMETER  VMPath
		Defines the path for the VM files.

	.PARAMETER  IPv4Address
		Defines the IPv4 address used by this replica DC.

	.PARAMETER  SubnetMask
		Defines the IPv4 address used by this replica DC.
	
	.PARAMETER  DomainName
		Defines the name of the domain to join as a 
		replica DC.

	.PARAMETER  LegacyDC
		This switch parameter defines wether a legacy (aka 2008 R2) DC
		will be used.

	.PARAMETER  DNSServer
		Specifies the preferred DNS Server IPv4 address.

	.EXAMPLE
		. .\newreplicarwdc.ps1
		New-ADReplicaDC -Computername vdc02 -ParentDiskPath D:\pd\2008R2\2008R2.vhdx -VMPath V:\VMs\Test -IPv4Address 192.168.0.2 -SubnetMask '255.255.255.0' -DomainName test.de -LegacyDC -DNSServer 192.168.0.1

	.EXAMPLE
		. C:\temp\newreplicarwdc.ps1
		New-ADReplicaDC -Computername vdc02 -ParentDiskPath D:\pd\2008R2\2008R2.vhdx -VMPath V:\VMs\Test -IPv4Address 192.168.0.2 -SubnetMask '255.255.255.0' -DomainName test.de -LegacyDC -DNSServer 192.168.0.1

	.INPUTS
		System.String

	.OUTPUTS
		System.String

	.NOTES
		Version 1.0.0 - 05/09/2017 - Martin Handl - Initial Version
		Version 1.0.1 - 05/12/2017 - Martin Handl - help information extended
												  - deleted ValidateSet VMPath
		Version 1.0.2 - 05/18/2017 - Martin Handl - Disabled Server Manager
		Version 1.0.3 - 05/28/2017 - Martin Handl - IE enhanced security disabled
		Version 1.0.4 - 06/10/2017 - Martin Handl - Site name set to HQ
		Version 1.0.5 - 09/18/2017 - Martin Handl - Updates help with correct examples
		Version 1.0.6 - 01/14/2018 - Martin Handl - Fully automated setup routine
		Version 1.0.6 - 01/16/2018 - Martin Handl - sitename added
		Version 1.0.7 - 01/22/2018 - Martin Handl - Bugfix with dcpromo.ps1

	.LINK
		about_functions_advanced

	.LINK
		about_comment_based_help

	.LINK
		about_functions_advanced_parameters

	.LINK
		about_functions_advanced_methods
#>
function New-ADReplicaDC
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
		[System.String]$NetBIOSName,
		[Parameter(Position = 7,
				   Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
		[Switch]$LegacyDC,
		[Parameter(Position = 8,
				   Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
		[System.String]$DNSServer,
		[Parameter(Position = 9,
				   Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
		[System.String]$SiteName
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
		if ($SiteName.Length -eq 0) { $SiteName = "HQ" }
		
		#Creating answerfiles
		New-Item -ItemType directory -Path $VMPath -Name $Computername -Force
		New-Item -ItemType directory -Path $VMPath\$Computername -Name 'Virtual Hard Disks'
		switch ($LegacyDC)
		{
			true {
				New-Item -Name "$Computername.cmd" -ItemType File -Path "$VMPath\$Computername\Virtual Hard Disks\"
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\$Computername.cmd" -value "powershell.exe -executionpolicy bypass c:\SetupTemp\$Computername.ps1"
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\$Computername.cmd" -Value "netsh interface ipv6 delete dnsserver `"Local Area Connection`" ::1"
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\$Computername.cmd" -Value "netsh interface ipv4 set address `"Local Area Connection`" static $IPv4Address 255.255.255.0 $GW 1"
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\$Computername.cmd" -Value "netsh interface ipv4 set dns `"Local Area Connection`" static $DNSServer"
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\$Computername.cmd" -value "dism.exe /online /enable-feature /featurename:DNS-Server-Full-Role"
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\$Computername.cmd" -value "dism.exe /online /enable-feature /featurename:NetFx3"
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\$Computername.cmd" -value "dism.exe /online /enable-feature /featurename:DirectoryServices-DomainController"
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\$Computername.cmd" -Value "netdom renamecomputer localhost /newname:$Computername /Force /Reboot"
				
				New-Item -Name "$Computername.ps1" -ItemType File -Path "$VMPath\$Computername\Virtual Hard Disks\"
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\$Computername.ps1" -Value "Set-ItemProperty -Path 'HKLM:\Software\Microsoft\Windows\CurrentVersion\RunOnce' -Name `"dcpromo.cmd`" -Value `"C:\SetupTemp\dcpromo.cmd`""
				
				New-Item -Name "DCPromo.cmd" -ItemType File -Path "$VMPath\$Computername\Virtual Hard Disks\"
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\DCPromo.cmd" -Value "powershell.exe -executionpolicy bypass c:\SetupTemp\DCPromo.ps1"
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\DCPromo.cmd" -Value "dcpromo.exe /answer:c:\SetupTemp\DCPromo-Replica-$NetBIOSFR.txt"
				
				New-Item -Name "DCPromo.ps1" -ItemType File -Path "$VMPath\$Computername\Virtual Hard Disks\"
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\DCPromo.ps1" -Value "Remove-ItemProperty -Path 'HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name AutoAdminLogon"
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\DCPromo.ps1" -Value "Remove-ItemProperty -Path 'HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name DefaultUserName"
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\DCPromo.ps1" -Value "Remove-ItemProperty -Path 'HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name DefaultPassword"
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\DCPromo.ps1" -Value "Remove-ItemProperty -Path 'HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name DefaultDomain"
				
				New-Item -Name "DCPromo-Replica-$NetBIOSFR.txt" -ItemType File -Path "$VMPath\$Computername\Virtual Hard Disks\"
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\DCPromo-Replica-$NetBIOSFR.txt" -Value "; DCPROMO unattend file (automatically generated by dcpromo)"
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\DCPromo-Replica-$NetBIOSFR.txt" -Value "; Usage:"
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\DCPromo-Replica-$NetBIOSFR.txt" -Value ";   dcpromo.exe /unattend:C:\dcpromo-replica.txt"
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\DCPromo-Replica-$NetBIOSFR.txt" -Value ";"
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\DCPromo-Replica-$NetBIOSFR.txt" -Value "; You may need to fill in password fields prior to using the unattend file."
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\DCPromo-Replica-$NetBIOSFR.txt" -Value "; If you leave the values for `"Password`" and/or `"DNSDelegationPassword`""
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\DCPromo-Replica-$NetBIOSFR.txt" -Value "; as `"*`", then you will be asked for credentials at runtime."
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\DCPromo-Replica-$NetBIOSFR.txt" -Value ";"
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\DCPromo-Replica-$NetBIOSFR.txt" -Value "[DCInstall]"
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\DCPromo-Replica-$NetBIOSFR.txt" -Value "; Replica DC promotion"
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\DCPromo-Replica-$NetBIOSFR.txt" -Value "ReplicaOrNewDomain`=Replica"
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\DCPromo-Replica-$NetBIOSFR.txt" -Value "ReplicaDomainDNSName`=$DomainName"
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\DCPromo-Replica-$NetBIOSFR.txt" -Value "SiteName`=$SiteName"
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\DCPromo-Replica-$NetBIOSFR.txt" -Value "InstallDNS`=Yes"
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\DCPromo-Replica-$NetBIOSFR.txt" -Value "ConfirmGc`=Yes"
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\DCPromo-Replica-$NetBIOSFR.txt" -Value "CreateDNSDelegation`=No"
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\DCPromo-Replica-$NetBIOSFR.txt" -Value "UserDomain`=$DomainName"
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\DCPromo-Replica-$NetBIOSFR.txt" -Value "UserName`=$NetBIOSName\administrator"
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\DCPromo-Replica-$NetBIOSFR.txt" -Value "Password`=C0mplex"
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\DCPromo-Replica-$NetBIOSFR.txt" -Value "DatabasePath`=`"C:\Windows\NTDS`""
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\DCPromo-Replica-$NetBIOSFR.txt" -Value "LogPath`=`"C:\Windows\NTDS`""
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\DCPromo-Replica-$NetBIOSFR.txt" -Value "SYSVOLPath`=`"C:\Windows\SYSVOL`""
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\DCPromo-Replica-$NetBIOSFR.txt" -Value "; Set SafeModeAdminPassword to the correct value prior to using the unattend file"
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\DCPromo-Replica-$NetBIOSFR.txt" -Value "SafeModeAdminPassword`=C0mplex"
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\DCPromo-Replica-$NetBIOSFR.txt" -Value "; Run-time flags (optional)"
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\DCPromo-Replica-$NetBIOSFR.txt" -Value "; CriticalReplicationOnly`=Yes"
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\DCPromo-Replica-$NetBIOSFR.txt" -Value "RebootOnCompletion`=Yes"
			}
			default
			{
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\$Computername.cmd" -Value "powershell.exe -ExecutionPolicy bypass -file C:\SetupTemp\$Computername.ps1"
				
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\$Computername.ps1" -Value "Get-ScheduledTask -TaskName ServerManager | Disable-ScheduledTask"
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\$Computername.ps1" -Value "Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled false"
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\$Computername.ps1" -Value "Set-ItemProperty -Path `"HKLM:\System\CurrentControlSet\Control\Terminal Server`"-name `"fDenyTSConnections`" -Value 0"
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\$Computername.ps1" -Value "Enable-NetFirewallRule -DisplayGroup `"Remote Desktop`""
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\$Computername.ps1" -Value "Set-ItemProperty -Path `"HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp`" -name `"UserAuthentication`" -Value 1"
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\$Computername.ps1" -Value "Disable-NetAdapterBinding -InterfaceAlias ethernet -ComponentID ms_tcpip6"
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\$Computername.ps1" -Value "New-NetIPAddress -InterfaceAlias ethernet -IPAddress $IPv4Address -PrefixLength 24 -DefaultGateway $GW"
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\$Computername.ps1" -Value "Set-ItemProperty -Path `"HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}`" -Name IsInstalled -Type DWord -Value 0"
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\$Computername.ps1" -Value "Set-ItemProperty -Path `"HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}`" -Name IsInstalled -Type DWord -Value 0"
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\$Computername.ps1" -Value "Set-ItemProperty -Path `"HKLM:\SOFTWARE\Microsoft\Internet Explorer\Main`" -Name `"Default_Page_URL`" -Value `"about:blank`""
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\$Computername.ps1" -Value "Set-ItemProperty -Path `"HKLM:\SOFTWARE\Microsoft\Internet Explorer\Main`" -Name `"Default_Search_URL`" -Value `"about:blank`""
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\$Computername.ps1" -Value "Set-ItemProperty -Path `"HKLM:\SOFTWARE\Microsoft\Internet Explorer\Main`" -Name `"Search Page`" -Value `"about:blank`""
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\$Computername.ps1" -Value "Set-ItemProperty -Path `"HKLM:\SOFTWARE\Microsoft\Internet Explorer\Main`" -Name `"Start Page`" -Value `"about:blank`""
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\$Computername.ps1" -Value "Set-ItemProperty -Path `"HKCU:\SOFTWARE\Microsoft\Internet Explorer\Main`" -Name `"Search Page`" -Value `"about:blank`""
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\$Computername.ps1" -Value "Set-ItemProperty -Path `"HKCU:\SOFTWARE\Microsoft\Internet Explorer\Main`" -Name `"Start Page`" -Value `"about:blank`""
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\$Computername.ps1" -Value "Set-ItemProperty -Path `"HKCU:\SOFTWARE\Microsoft\Internet Explorer\Main`" -Name `"Default_Page_URL`" -Value `"about:blank`""
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\$Computername.ps1" -Value "Set-ItemProperty -Path `"HKCU:\SOFTWARE\Microsoft\Internet Explorer\Main`" -Name `"First Home Page`" -Value `"about:blank`""
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\$Computername.ps1" -Value "Set-ItemProperty -Path 'HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name AutoAdminLogon -Value 1"
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\$Computername.ps1" -Value "Set-ItemProperty -Path 'HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name DefaultUserName -Value `"Administrator`""
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\$Computername.ps1" -Value "Set-ItemProperty -Path 'HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name DefaultPassword -Value `"C0mplex`""
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\$Computername.ps1" -Value "Set-ItemProperty -Path 'HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name DefaultDomain -Value `".`""
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\$Computername.ps1" -Value "Set-ItemProperty -Path 'HKLM:\Software\Microsoft\Windows\CurrentVersion\RunOnce' -Name `"dcpromo.cmd`" -Value `"C:\SetupTemp\dcpromo.cmd`""
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\$Computername.ps1" -Value "Set-DnsClientServerAddress -InterfaceAlias ethernet -ResetServerAddresses"
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\$Computername.ps1" -Value "Set-DnsClientServerAddress -InterfaceAlias ethernet -ServerAddresses `"$DNSServer`""
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\$Computername.ps1" -Value "Install-WindowsFeature -Name DNS, AD-Domain-Services -IncludeManagementTools"
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\$Computername.ps1" -Value "Rename-Computer -NewName $Computername -Restart"
				
				Add-Content -PassThru "$VMPath\$Computername\Virtual Hard Disks\DCPromo.cmd" -Value "powershell.exe -ExecutionPolicy bypass -file C:\SetupTemp\DCPromo.ps1"
				
				Add-Content -PassThru "$VMPath\$Computername\Virtual Hard Disks\DCPromo.ps1" -Value "Remove-ItemProperty -Path `'HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon`' -Name AutoAdminLogon"
				Add-Content -PassThru "$VMPath\$Computername\Virtual Hard Disks\DCPromo.ps1" -Value "Remove-ItemProperty -Path `'HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon`' -Name DefaultUserName"
				Add-Content -PassThru "$VMPath\$Computername\Virtual Hard Disks\DCPromo.ps1" -Value "Remove-ItemProperty -Path `'HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon`' -Name DefaultPassword"
				Add-Content -PassThru "$VMPath\$Computername\Virtual Hard Disks\DCPromo.ps1" -Value "Remove-ItemProperty -Path `'HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon`' -Name DefaultDomain"
				Add-Content -PassThru "$VMPath\$Computername\Virtual Hard Disks\DCPromo.ps1" -Value "Import-Module ADDSDeployment"
				Add-Content -PassThru "$VMPath\$Computername\Virtual Hard Disks\DCPromo.ps1" -Value "Install-ADDSDomainController -Credential (New-Object System.Management.Automation.PSCredential $NetBIOSName\Administrator,(ConvertTo-SecureString -AsPlainText -Force -String `"C0mplex`")) -NoGlobalCatalog:`$false -CreateDnsDelegation:`$false -CriticalReplicationOnly:`$false -DatabasePath `"C:\Windows\NTDS`" -DomainName `"$DomainName`" -InstallDns:`$true -LogPath `"C:\Windows\NTDS`" -NoRebootOnCompletion:`$false -SiteName `"$SiteName`" -SysvolPath `"C:\Windows\SYSVOL`" -SafeModeAdministratorPassword (ConvertTo-SecureString -AsPlainText -Force -String `"C0mplex`") -Force:`$true"
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
		switch ($LegacyDC)
		{
			true {
				Copy-Item -Path "$VMPath\$Computername\Virtual Hard Disks\$Computername.cmd" -Destination . | Out-Null
				Copy-Item -Path "$VMPath\$Computername\Virtual Hard Disks\$Computername.ps1" -Destination . | Out-Null
				Copy-Item -Path "$VMPath\$Computername\Virtual Hard Disks\DCPromo.cmd" -Destination . | Out-Null
				Copy-Item -Path "$VMPath\$Computername\Virtual Hard Disks\DCPromo.ps1" -Destination . | Out-Null
				Copy-Item -Path "$VMPath\$Computername\Virtual Hard Disks\DCPromo-Replica-$NetBIOSFR.txt" -Destination . | Out-Null
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
				Copy-Item -Path "$VMPath\$Computername\Virtual Hard Disks\DCPromo.cmd" -Destination . | Out-Null
				Copy-Item -Path "$VMPath\$Computername\Virtual Hard Disks\DCPromo.ps1" -Destination . | Out-Null
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
		switch ($LegacyDC)
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