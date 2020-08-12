<#
	.SYNOPSIS
		Creates a new VM to be a DC.

	.DESCRIPTION
		Creates a new VM to be a DC for a new Forest.

	.PARAMETER  Computername
		Defines the VM Computer name.

	.PARAMETER  ParentDiskPath
		Defines the path to the parent disk.

	.PARAMETER  VMPath
		Defines the path for the VM files.

	.PARAMETER  IPv4Address
		Defines the IPv4 address used by this DC.

	.PARAMETER  SubnetMask
		Defines the IPv4 address used by this DC.
	
	.PARAMETER  ForestName
		Defines the name of the new forest.

	.PARAMETER  ForestMode
		Defines the forest functional level of the new forest.

	.PARAMETER  LegacyDC
		This switch parameter defines wether a legacy (aka 2008 R2) DC
		will be used.

	.EXAMPLE
		. .\newrwdc.ps1
		New-ADForest -Computername TestDC -ParentDiskPath c:\PD\2008R2\2008R2.vhdx -VMPath v:\VMs -IPv4Address 192.168.1.1 -SubnetMask 255.255.255.0 -ForestName TestForest -ForestMode Win2008R2

	.EXAMPLE
		. c:\temp\newrwdc.ps1
		New-ADForest -Computername TestDC -ParentDiskPath c:\PD\2008R2\2008R2.vhdx -VMPath v:\VMs -IPv4Address 192.168.1.1 -SubnetMask 255.255.255.0 -ForestName TestForest -ForestMode Win2008R2

	.INPUTS
		System.String

	.OUTPUTS
		System.String

	.NOTES
		Version 1.0.0 - 05/08/2017 - Martin Handl - Initial Version
		Version 1.0.1 - 05/12/2017 - Martin Handl - deleted ValidateSet VMPath
		Version 1.0.2 - 05/18/2017 - Martin Handl - Disabled Server Manager + ADCare
		Version 1.0.3 - 05/23/2017 - Martin Handl - NetBIOS Name added
		Version 1.0.4 - 05/29/2017 - Martin Handl - IE Enhanced security disabled
		Version 1.0.5 - 01/15/2018 - Martin Handl - Installation sequence completely automated

	.LINK
		about_functions_advanced

	.LINK
		about_comment_based_help

	.LINK
		about_functions_advanced_parameters

	.LINK
		about_functions_advanced_methods
#>
function New-ADForest
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
		[System.String]$ForestName,
		[Parameter(Position = 6,
				   Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
		[System.String]$NetBIOSName,
		[Parameter(Position = 7,
				   Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
		[ValidateSet("Win2000", "Win2003", "Win2008", "Win2008R2", "Win2012", "Win2012R2", "WinThreshold")]
		[System.String]$ForestMode,
		[Parameter(Position = 8,
				   Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
		[Switch]$LegacyDC
	)
	begin
	{
		#Writing Debug Infos
		Write-Verbose "Computername is $Computername"
		Write-Verbose "PartenDiskPath is $ParentDiskPath"
		Write-Verbose "VMPath is $VMPath"
		Write-Verbose "IPv4Address is $IPv4Address"
		Write-Verbose "Subnetmask is $SubnetMask"
		Write-Verbose "Forestname is $ForestName"
		Write-Verbose "Forestname is $NetBIOSName"
		Write-Verbose "ForestMode is $ForestMode"
		
		$DnsServer = $IPv4Address
		$threeocts = $IPv4Address.Split(".")[0 .. 2] -join "."
		$GW = $threeocts + ".254"
		$CPUCount = [math]::Floor(((Get-CimInstance -ClassName Win32_processor).numberoflogicalprocessors | Measure-Object -Sum).Sum / 3)
		switch ($SubnetMask)
		{
			255.0.0.0 { $SNM = "8" }
			255.255.0.0 { $SNM = "16" }
			Default { $SNM = "24" }
		}
		
		#Creating answerfiles
		New-Item -ItemType directory -Path $VMPath -Name $Computername -Force
		New-Item -ItemType directory -Path $VMPath\$Computername -Name 'Virtual Hard Disks'
		switch ($LegacyDC)
		{
			true {
				switch ($ForestMode)
				{
					Win2000 {
						$ForestModeL = 0
					}
					Win2003 {
						$ForestModeL = 2
					}
					Win2008 {
						$ForestModeL = 3
					}
					Win2008R2 {
						$ForestModeL = 4
					}
					Win2012 {
						$ForestModeL = 5
					}
					Win2012R2 {
						$ForestModeL = 6
					}
					WinThreshold {
						$ForestModeL = 7
					}
					default
					{
						$ForestModeL = 4
					}
				}
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\$Computername.cmd" -value "powershell.exe -executionpolicy bypass c:\SetupTemp\$Computername.ps1"
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\$Computername.cmd" -Value "netsh interface ipv6 delete dnsserver `"Local Area Connection`" ::1"
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\$Computername.cmd" -Value "netsh interface ipv4 set address `"Local Area Connection`" static $IPv4Address 255.255.255.0 $GW 1"
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\$Computername.cmd" -Value "netsh interface ipv4 set dns `"Local Area Connection`" static $DnsServer"
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\$Computername.cmd" -value "dism.exe /online /enable-feature /featurename:DNS-Server-Full-Role"
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\$Computername.cmd" -value "dism.exe /online /enable-feature /featurename:NetFx3"
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\$Computername.cmd" -value "dism.exe /online /enable-feature /featurename:DirectoryServices-DomainController"
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\$Computername.cmd" -Value "netdom renamecomputer localhost /newname:$Computername /Force /Reboot"
				
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
				
				New-Item -Name "DCPromo.cmd" -ItemType File -Path "$VMPath\$Computername\Virtual Hard Disks\"
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\DCPromo.cmd" -Value "powershell.exe -ExecutionPolicy bypass -file C:\SetupTemp\dcpromo.ps1"
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\DCPromo.cmd" -Value "dcpromo.exe /answer:C:\SetupTemp\DCPromo-$NetBIOSName.txt"
				
				New-Item -Name "DCPromo.ps1" -ItemType File -Path "$VMPath\$Computername\Virtual Hard Disks\"
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\DCPromo.ps1" -Value "Set-ItemProperty -Path 'HKLM:\Software\Microsoft\Windows\CurrentVersion\RunOnce' -Name `"ADCare.cmd`" -Value `"C:\SetupTemp\ADCare.cmd`""
				
				New-Item -Name "DCPromo-$NetBIOSName.txt" -ItemType File -Path "$VMPath\$Computername\Virtual Hard Disks\"
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\DCPromo-$NetBIOSName.txt" -Value "; DCPROMO unattend file (automatically generated by dcpromo)"
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\DCPromo-$NetBIOSName.txt" -Value "; Usage:"
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\DCPromo-$NetBIOSName.txt" -Value "; dcpromo.exe /unattend:C:\dcpromo.txt"
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\DCPromo-$NetBIOSName.txt" -Value ";"
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\DCPromo-$NetBIOSName.txt" -Value "`[DCInstall`]"
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\DCPromo-$NetBIOSName.txt" -Value "; New forest promotion"
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\DCPromo-$NetBIOSName.txt" -Value "ReplicaOrNewDomain`=Domain"
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\DCPromo-$NetBIOSName.txt" -Value "NewDomain`=Forest"
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\DCPromo-$NetBIOSName.txt" -Value "NewDomainDNSName`=$ForestName"
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\DCPromo-$NetBIOSName.txt" -Value "ForestLevel`=$ForestModeL"
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\DCPromo-$NetBIOSName.txt" -Value "DomainNetbiosName`=$NetBIOSName"
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\DCPromo-$NetBIOSName.txt" -Value "DomainLevel`=$ForestModeL"
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\DCPromo-$NetBIOSName.txt" -Value "InstallDNS`=Yes"
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\DCPromo-$NetBIOSName.txt" -Value "ConfirmGc`=Yes"
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\DCPromo-$NetBIOSName.txt" -Value "CreateDNSDelegation`=No"
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\DCPromo-$NetBIOSName.txt" -Value "DatabasePath`=`"C:\Windows\NTDS`""
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\DCPromo-$NetBIOSName.txt" -Value "LogPath`=`"C:\Windows\NTDS`""
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\DCPromo-$NetBIOSName.txt" -Value "SYSVOLPath`=`"C:\Windows\SYSVOL`""
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\DCPromo-$NetBIOSName.txt" -Value "; Set SafeModeAdminPassword to the correct value prior to using the unattend file"
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\DCPromo-$NetBIOSName.txt" -Value "SafeModeAdminPassword`=C0mplex"
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\DCPromo-$NetBIOSName.txt" -Value "; Run-time flags (optional)"
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\DCPromo-$NetBIOSName.txt" -Value "RebootOnCompletion`=Yes"
				
				New-Item -Name "ADCare.cmd" -ItemType File -Path "$VMPath\$Computername\Virtual Hard Disks\"
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\$Computername.cmd" -Value "netsh interface ipv4 set dns `"Local Area Connection`" static $DnsServer"
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\ADCare.cmd" -Value "dnscmd.exe /ZoneAdd $($IPv4Address.Split(".")[2]).$($IPv4Address.Split(".")[1]).$($IPv4Address.Split(".")[0]).in-addr.arpa /dsPrimary"
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\ADCare.cmd" -Value "dnscmd.exe /Config $($IPv4Address.Split(".")[2]).$($IPv4Address.Split(".")[1]).$($IPv4Address.Split(".")[0]).in-addr.arpa /AllowUpdate 2"
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\ADCare.cmd" -Value "net start dnscache `&`& net stop dnscache"
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\ADCare.cmd" -Value "powershell.exe -ExecutionPolicy bypass -file C:\SetupTemp\ADCare.ps1"
				
				New-Item -Name "ADCare.ps1" -ItemType File -Path "$VMPath\$Computername\Virtual Hard Disks\"
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\ADCare.ps1" -Value "Rename-ADObject -NewName `"HQ`" -Identity `"CN=Default-First-Site-Name,CN=Sites,CN=Configuration,`$((Get-ADDomain).DistinguishedName)`""
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\ADCare.ps1" -Value "New-ADObject -Path `"CN=Subnets,CN=Sites,CN=Configuration,`$((Get-ADDomain).DistinguishedName)`" -Name `"$threeocts.0/24`" -Type subnet -OtherAttributes @{ siteObject = `"CN=HQ,CN=Sites,CN=Configuration,`$((Get-ADDomain).DistinguishedName)`"  }"
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\ADCare.ps1" -Value "Remove-ItemProperty -Path `'HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon`' -Name AutoAdminLogon"
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\ADCare.ps1" -Value "Remove-ItemProperty -Path `'HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon`' -Name DefaultUserName"
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\ADCare.ps1" -Value "Remove-ItemProperty -Path `'HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon`' -Name DefaultPassword"
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\ADCare.ps1" -Value "Remove-ItemProperty -Path `'HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon`' -Name DefaultDomain"
				
			}
			default
			{
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\$Computername.cmd" -Value "powershell.exe -file C:\SetupTemp\$Computername.ps1"
				
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\$Computername.ps1" -Value "Get-ScheduledTask -TaskName ServerManager | Disable-ScheduledTask"
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\$Computername.ps1" -Value "Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled false"
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\$Computername.ps1" -Value "Set-ItemProperty -Path `"HKLM:\System\CurrentControlSet\Control\Terminal Server`"-name `"fDenyTSConnections`" -Value 0"
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\$Computername.ps1" -Value "Enable-NetFirewallRule -DisplayGroup `"Remote Desktop`""
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\$Computername.ps1" -Value "Set-ItemProperty -Path `"HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp`" -name `"UserAuthentication`" -Value 1"
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\$Computername.ps1" -Value "Disable-NetAdapterBinding -InterfaceAlias ethernet -ComponentID ms_tcpip6"
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\$Computername.ps1" -Value "New-NetIPAddress -InterfaceAlias ethernet -IPAddress $IPv4Address -PrefixLength 24 -DefaultGateway $GW"
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\$Computername.ps1" -Value "Set-DnsClientServerAddress -InterfaceAlias ethernet -ResetServerAddresses"
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\$Computername.ps1" -Value "Set-DnsClientServerAddress -InterfaceAlias ethernet -ServerAddresses `"$IPv4Address`""
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
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\$Computername.ps1" -Value "Install-WindowsFeature -Name DNS, AD-Domain-Services -IncludeManagementTools"
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\$Computername.ps1" -Value "Set-ItemProperty -Path 'HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name AutoAdminLogon -Value 1"
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\$Computername.ps1" -Value "Set-ItemProperty -Path 'HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name DefaultUserName -Value `"Administrator`""
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\$Computername.ps1" -Value "Set-ItemProperty -Path 'HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name DefaultPassword -Value `"C0mplex`""
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\$Computername.ps1" -Value "Set-ItemProperty -Path 'HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name DefaultDomain -Value `".`""
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\$Computername.ps1" -Value "Set-ItemProperty -Path 'HKLM:\Software\Microsoft\Windows\CurrentVersion\RunOnce' -Name `"dcpromo.cmd`" -Value `"C:\SetupTemp\dcpromo.cmd`""
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\$Computername.ps1" -Value "Rename-Computer -NewName $Computername -Restart"
				
				New-Item -Name "DCPromo.cmd" -ItemType File -Path "$VMPath\$Computername\Virtual Hard Disks\"
				Add-Content -PassThru "$VMPath\$Computername\Virtual Hard Disks\DCPromo.cmd" -Value "powershell.exe -ExecutionPolicy bypass -file C:\SetupTemp\DCPromo.ps1"
				
				New-Item -Name "DCPromo.ps1" -ItemType File -Path "$VMPath\$Computername\Virtual Hard Disks\"
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\DCPromo.ps1" -Value "Set-ItemProperty -Path 'HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name AutoAdminLogon -Value 1"
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\DCPromo.ps1" -Value "Set-ItemProperty -Path 'HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name DefaultUserName -Value `"Administrator`""
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\DCPromo.ps1" -Value "Set-ItemProperty -Path 'HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name DefaultPassword -Value `"C0mplex`""
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\DCPromo.ps1" -Value "Set-ItemProperty -Path 'HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name DefaultDomain -Value `"$ForestName`""
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\DCPromo.ps1" -Value "Set-ItemProperty -Path 'HKLM:\Software\Microsoft\Windows\CurrentVersion\RunOnce' -Name `"ADCare.cmd`" -Value `"C:\SetupTemp\ADCare.cmd`""
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\DCPromo.ps1" -Value "Import-Module ADDSDeployment"
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\DCPromo.ps1" -Value "Install-ADDSForest -CreateDnsDelegation:`$false -DatabasePath `"C:\Windows\NTDS`" -DomainMode `"$ForestMode`" -DomainName `"$ForestName`" -DomainNetbiosName `"$NetBIOSName`" -ForestMode `"$ForestMode`" -InstallDns:`$true -LogPath `"C:\Windows\NTDS`" -NoRebootOnCompletion:`$false -SysvolPath `"C:\Windows\SYSVOL`" -Force:`$true -SafeModeAdministratorPassword (ConvertTo-SecureString -AsPlainText -Force -String `"C0mplex`")"
				
				New-Item -Name "ADCare.cmd" -ItemType File -Path "$VMPath\$Computername\Virtual Hard Disks\"
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\ADCare.cmd" -Value "powershell.exe -ExecutionPolicy bypass -file c:\SetupTemp\ADCare.ps1"
				
				New-Item -Name "ADCare.ps1" -ItemType File -Path "$VMPath\$Computername\Virtual Hard Disks\"
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\ADCare.ps1" -Value "Add-DnsServerPrimaryZone -Name `"$($IPv4Address.Split(".")[2]).$($IPv4Address.Split(".")[1]).$($IPv4Address.Split(".")[0]).in-addr.arpa`" -DynamicUpdate Secure -ReplicationScope Domain"
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\ADCare.ps1" -Value "Set-DnsClientServerAddress -InterfaceAlias ethernet -ServerAddresses $DnsServer"
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\ADCare.ps1" -Value "Restart-Service -Name dnscache -Force"
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\ADCare.ps1" -Value "Rename-ADObject -NewName `"HQ`" -Identity `"CN=Default-First-Site-Name,CN=Sites,CN=Configuration,`$((Get-ADDomain).DistinguishedName)`""
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\ADCare.ps1" -Value "New-ADReplicationSubnet -Name `"$threeocts`.0/24`" -Site `"HQ`""
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\ADCare.ps1" -Value "Remove-ItemProperty -Path `'HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon`' -Name AutoAdminLogon"
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\ADCare.ps1" -Value "Remove-ItemProperty -Path `'HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon`' -Name DefaultUserName"
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\ADCare.ps1" -Value "Remove-ItemProperty -Path `'HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon`' -Name DefaultPassword"
				Add-Content -Path "$VMPath\$Computername\Virtual Hard Disks\ADCare.ps1" -Value "Remove-ItemProperty -Path `'HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon`' -Name DefaultDomain"
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
				Copy-Item -Path "$VMPath\$Computername\Virtual Hard Disks\DCPromo-$NetBIOSName.txt" -Destination . | Out-Null
				Copy-Item -Path "$VMPath\$Computername\Virtual Hard Disks\ADCare.cmd" -Destination . | Out-Null
				Copy-Item -Path "$VMPath\$Computername\Virtual Hard Disks\ADCare.ps1" -Destination . | Out-Null
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
				Copy-Item -Path "$VMPath\$Computername\Virtual Hard Disks\ADCare.cmd" -Destination . | Out-Null
				Copy-Item -Path "$VMPath\$Computername\Virtual Hard Disks\ADCare.ps1" -Destination . | Out-Null
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