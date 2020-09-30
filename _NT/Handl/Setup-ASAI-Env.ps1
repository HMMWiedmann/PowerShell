<#
	.SYNOPSIS
		Setup for Bastion Forest - aka asai-center.de.

	.DESCRIPTION
		One DC, one SQL-Server, one MIM-Server and one PAW will be setup.
		All VMs will be generation 2.

	.PARAMETER  Destination
		Absolute path to the destination folder for the VMs.

	.PARAMETER  Server2016PD
		Absolute path to the parent disk of a Server 2016.

	.PARAMETER  Windows10PD
		Absolute path to the parent disk of a Windows 10.

	.PARAMETER  Switchname
		Defines the Hyper-V switch name.

	.PARAMETER  LegacyForest
		Defines the Forest Functional Level 2008 R2.

	.EXAMPLE
		Enable-BastionForest -Destination $Destination -Server2016PD C:\PD\2016.vhdx -Windows10PD C:\PD\Windows10.vhdx

	.EXAMPLE
		Enable-BastionForest $Destination C:\PD\2016.vhdx C:\PD\Windows10.vhdx

	.NOTES
		01/30/2017 Martin Handl - Version 1.0
		01/31/2017 Martin Handl - Version 1.0.1 - Subnet fixed for reverse lookup zone + fixed probing for hyper-v module
												- Minor bug fixes
												- Improvements and adding LegacyForest Switch
		02/01/2017 Martin Handl - Version 1.0.2 - added sequence for setup scripts
		02/02/2017 Martin Handl - Version 1.0.3 - added registry patch for DCs (TcpIpClientSupport DWORD 1)
												- added DNS name resolution between forests
												- added PAMFeature via setup script
		02/07/2017 Martin Handl - Version 1.0.4 - Prefix for VMs added
		02/08/2017 Martin Handl - Version 1.0.5 - new OU strucute (Tier0 ... Tier2)
		02/23/2017 Martin Handl - Version 1.0.6 - trust fix for PIM_TRUST applied
		02/27/2017 Martin Handl - Version 1.0.7 - added powershell line to disable IE security on mimserver
		03/03/2017 Martin Handl - Version 1.0.8 - renamed MIMAdmin to MIMMan
		03/20/2017 Martin Handl - Version 1.0.9 - BreakGlass- and RedCard-Users implemented
		05/30/2017 Martin Handl - Version 1.0.10 - CPU count corrected
		09/18/2017 Martin Handl - Version 1.0.11 - PWDs set to "C0mplex"

	.LINK
		about_functions_advanced

	.LINK
		about_comment_based_help

#>
function Enable-BastionForest
{
	[cmdletbinding()]
	param
	(
		[parameter(Mandatory = $true,
				   ValueFromPipelineByPropertyName = $true,
				   Position = 0)]
		$Destination,
		[parameter(Mandatory = $true,
				   ValueFromPipelineByPropertyName = $true,
				   Position = 1)]
		$Server2016PD,
		[parameter(Mandatory = $true,
				   ValueFromPipelineByPropertyName = $true,
				   Position = 2)]
		$Windows10PD,
		[parameter(Mandatory = $true,
				   ValueFromPipelineByPropertyName = $true,
				   Position = 3)]
		$switchname,
		[parameter(Position = 4)]
		[switch]$LegacyForest,
		[parameter(Position = 5)]
		$Prefix
	)
	
	begin
	{
		Write-Debug "`$Destination is $Destination"
		Write-Debug "`$Server2016PD is $Server2016PD"
		Write-Debug "`$Windows10PD is $Windows10PD"
		Write-Debug "`$switchname is $switchname"
		Write-Debug "`$Prefix is $Prefix"
		
		Write-Verbose "Evaluating the number of logical processors..."
		$CPUCount = ((Get-CimInstance -ClassName win32_processor).NumberOfLogicalProcessors | Measure-Object -Sum).sum
		
		Write-Verbose "Probing for Hyper-V Powershell Module..."
		$HVModuleExistes = Get-Module -Name Hyper-V
		switch ($HVModuleExistes)
		{
			$null { Write-Host "Hyper-V-Module for Windows Powershell not found on this host! Please install RSAT for Hyper-V on this host an retry again. `nTerminating Script"; Break }
			Default { }
		}
		
		Write-Verbose "Probing for Hyper-V switch..."
		$HVSwitchExists = (Get-VMSwitch -Name $switchname).name
		switch ($HVSwitchExists)
		{
			$null { Write-Host "Hyper-V switch not found. Create the Hyper-V switch $switchname and retry again. `nTerminanting Script"; Break }
			Default { }
		}
		
		Write-Verbose "Probing path $Destination..."
		$PathDestExist = Test-Path -Path $Destination
		switch ($PathDestExist)
		{
			$false { Write-Host -ForegroundColor Yellow -BackgroundColor Black "Path to the VM Destination `($Destination`) does not exist! Please check path and retry again. `nTerminating Script"; Break }
			Default { }
		}
		
		Write-Verbose "Probing underlying paths..."
		$PathASAIExist = Test-Path -Path $Destination"\ASAI"
		if ($PathASAIExist -eq $true)
		{
			Write-Host "Path $Destination\ASAI is present (and should not be present). Clear the path an retry the script! `nTerminating the Script"; Break
		}
		else
		{
			Write-Debug "Non of the required underlying pathes have been found - continuing the script!"
		}
		
		Write-Verbose "Probing path $Server2016PD..."
		$PathPDServer2016Exist = Test-Path -Path $Server2016PD
		switch ($PathPDServer2016Exist)
		{
			$false { Write-Host -ForegroundColor Yellow -BackgroundColor Black "Path to the parent disk for Server 2016 `($Server2016PD`) does not exist! Please check path and retry again. `nTerminating Script"; Break }
			Default { }
		}
		
		Write-Verbose "Probing path $Windows10PD..."
		$PathPDWin10Exist = Test-Path -Path $Windows10PD
		switch ($PathPDWin10Exist)
		{
			$false { Write-Host -ForegroundColor Yellow -BackgroundColor Black "Path to the parent disk for Windows 10 `($Windows10PD`) does not exist! Please check path and retry again. `nTerminating Script"; Break }
			Default { }
		}
		
		Write-Verbose "Evaluation switch parameter LegacyForest"
		switch ($LegacyForest)
		{
			$true { $ForestDomainMode = 4 }
			Default { $ForestDomainMode = 7 }
		}
	}
	
	process
	{
		### Virtual Disk creation ###
		#BF
		Write-Verbose "Creating ASAI-VDC01 hard disk."
		New-VHD -ParentPath $Server2016PD -Path "$Destination\$($Prefix)ASAI\ASAI-VDC01\Virtual Hard Disks\ASAI-VDC01.vhdx" -Differencing | Out-Null
		Write-Verbose "Created ASAI-VDC01.vhdx virtual hard disk."
		Write-Verbose "Creating ASAI-VSQL01 hard disk."
		New-VHD -ParentPath $Server2016PD -Path "$Destination\$($Prefix)ASAI\ASAI-VSQL01\Virtual Hard Disks\ASAI-VSQL01.vhdx" -Differencing | Out-Null
		Write-Verbose "Created ASAI-VSQL01.vhdx virtual hard disk."
		Write-Verbose "Creating ASAI-VMIM01 hard disk."
		New-VHD -ParentPath $Server2016PD -Path "$Destination\$($Prefix)ASAI\ASAI-VMIM01\Virtual Hard Disks\ASAI-VMIM01.vhdx" -Differencing | Out-Null
		Write-Verbose "Created ASAI-VMIM01.vhdx virtual hard disk."
		Write-Verbose "Creating ASAI-VR hard disk."
		New-VHD -ParentPath $Server2016PD -Path "$Destination\$($Prefix)ASAI\ASAI-VR\Virtual Hard Disks\ASAI-VR.vhdx" -Differencing | Out-Null
		Write-Verbose "Created ASAI-VR.vhdx virtual hard disk."
		Write-Verbose "Creating ASAI-VPAW01 hard disk."
		New-VHD -ParentPath $Windows10PD -Path "$Destination\$($Prefix)ASAI\ASAI-VPAW01\Virtual Hard Disks\ASAI-VPAW01.vhdx" -Differencing | Out-Null
		Write-Verbose "Created ASAI-VPAW01.vhdx virtual hard disk."
		
		###PS-Config-Script###
		#ASAI-VDC01
		Write-Verbose "Creating automated setup files for ASAI-VDC01."
		New-Item -Name 01-ASAI-VDC01.cmd -ItemType file -Path "$Destination\$($Prefix)ASAI\ASAI-VDC01\Virtual Hard Disks\" | Out-Null
		New-Item -Name 01-ASAI-VDC01.ps1 -ItemType file -Path "$Destination\$($Prefix)ASAI\ASAI-VDC01\Virtual Hard Disks\" | Out-Null
		New-Item -Name 02-ASAI-VDC01-ADDeploy.ps1 -ItemType file -Path "$Destination\$($Prefix)ASAI\ASAI-VDC01\Virtual Hard Disks\" | Out-Null
		New-Item -Name 02-ASAI-VDC01-ADDeploy.cmd -ItemType file -Path "$Destination\$($Prefix)ASAI\ASAI-VDC01\Virtual Hard Disks\" | Out-Null
		New-Item -Name 03-ASAI-VDC01-ADCare.ps1 -ItemType file -Path "$Destination\$($Prefix)ASAI\ASAI-VDC01\Virtual Hard Disks\" | Out-Null
		New-Item -Name 03-ASAI-VDC01-ADCare.cmd -ItemType file -Path "$Destination\$($Prefix)ASAI\ASAI-VDC01\Virtual Hard Disks\" | Out-Null
		New-Item -Name 04-ASAI-VDC01-MIMPrep.ps1 -ItemType file -Path "$Destination\$($Prefix)ASAI\ASAI-VDC01\Virtual Hard Disks\" | Out-Null
		New-Item -Name 04-ASAI-VDC01-MIMPrep.cmd -ItemType file -Path "$Destination\$($Prefix)ASAI\ASAI-VDC01\Virtual Hard Disks\" | Out-Null
		New-Item -Name 05-ASAI-VDC01-MIMSecurtiy.cmd -ItemType file -Path "$Destination\$($Prefix)ASAI\ASAI-VDC01\Virtual Hard Disks\" | Out-Null
		New-Item -Name 06-ASAI-VDC01-RegPatch.cmd -ItemType file -Path "$Destination\$($Prefix)ASAI\ASAI-VDC01\Virtual Hard Disks\" | Out-Null
		New-Item -Name 06-ASAI-VDC01-RegPatch.ps1 -ItemType file -Path "$Destination\$($Prefix)ASAI\ASAI-VDC01\Virtual Hard Disks\" | Out-Null
		New-Item -Name 07-ASAI-VDC01-NameResolution.cmd -ItemType file -Path "$Destination\$($Prefix)ASAI\ASAI-VDC01\Virtual Hard Disks\" | Out-Null
		New-Item -Name 07-ASAI-VDC01-NameResolution.ps1 -ItemType file -Path "$Destination\$($Prefix)ASAI\ASAI-VDC01\Virtual Hard Disks\" | Out-Null
		New-Item -Name 08-ASAI-VDC01-PAMFeature.cmd -ItemType file -Path "$Destination\$($Prefix)ASAI\ASAI-VDC01\Virtual Hard Disks\" | Out-Null
		New-Item -Name 08-ASAI-VDC01-PAMFeature.ps1 -ItemType file -Path "$Destination\$($Prefix)ASAI\ASAI-VDC01\Virtual Hard Disks\" | Out-Null
		
		Add-Content -Path "$Destination\$($Prefix)ASAI\ASAI-VDC01\Virtual Hard Disks\01-ASAI-VDC01.cmd" -value "powershell.exe Set-ExecutionPolicy -ExecutionPolicy Unrestricted"
		Add-Content -Path "$Destination\$($Prefix)ASAI\ASAI-VDC01\Virtual Hard Disks\01-ASAI-VDC01.cmd" -value "powershell.exe -noexit C:\SetupTemp\01-ASAI-VDC01.ps1"
		Add-Content -Path "$Destination\$($Prefix)ASAI\ASAI-VDC01\Virtual Hard Disks\01-ASAI-VDC01.ps1" -value "Get-ScheduledTask -TaskName servermanager | Disable-ScheduledTask"
		Add-Content -Path "$Destination\$($Prefix)ASAI\ASAI-VDC01\Virtual Hard Disks\01-ASAI-VDC01.ps1" -value "Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled false"
		Add-Content -Path "$Destination\$($Prefix)ASAI\ASAI-VDC01\Virtual Hard Disks\01-ASAI-VDC01.ps1" -value "Set-ItemProperty -Path `'HKLM:\System\CurrentControlSet\Control\Terminal Server`'-name `"fDenyTSConnections`" -Value 0"
		Add-Content -Path "$Destination\$($Prefix)ASAI\ASAI-VDC01\Virtual Hard Disks\01-ASAI-VDC01.ps1" -value "Enable-NetFirewallRule -DisplayGroup `"Remote Desktop`""
		Add-Content -Path "$Destination\$($Prefix)ASAI\ASAI-VDC01\Virtual Hard Disks\01-ASAI-VDC01.ps1" -value "Set-ItemProperty -Path `'HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp`' -name `"UserAuthentication`" -Value 1"
		Add-Content -Path "$Destination\$($Prefix)ASAI\ASAI-VDC01\Virtual Hard Disks\01-ASAI-VDC01.ps1" -value "Disable-NetAdapterBinding -InterfaceAlias ethernet -ComponentID ms_tcpip6"
		Add-Content -Path "$Destination\$($Prefix)ASAI\ASAI-VDC01\Virtual Hard Disks\01-ASAI-VDC01.ps1" -value "New-NetIPAddress -InterfaceAlias ethernet -IPAddress 192.168.50.1 -PrefixLength 24 -DefaultGateway 192.168.50.254"
		Add-Content -Path "$Destination\$($Prefix)ASAI\ASAI-VDC01\Virtual Hard Disks\01-ASAI-VDC01.ps1" -value "Set-DnsClientServerAddress -InterfaceAlias ethernet -ResetServerAddresses"
		Add-Content -Path "$Destination\$($Prefix)ASAI\ASAI-VDC01\Virtual Hard Disks\01-ASAI-VDC01.ps1" -value "Set-DnsClientServerAddress -InterfaceAlias ethernet -ServerAddresses `"192.168.50.1`""
		Add-Content -Path "$Destination\$($Prefix)ASAI\ASAI-VDC01\Virtual Hard Disks\01-ASAI-VDC01.ps1" -Value "(Get-WmiObject -Class Win32_NetworkAdapterConfiguration | Where-Object { `$PSItem.description -like `"*hyper*`" }).settcpipnetbios(2)"
		Add-Content -Path "$Destination\$($Prefix)ASAI\ASAI-VDC01\Virtual Hard Disks\01-ASAI-VDC01.ps1" -value "Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools"
		Add-Content -Path "$Destination\$($Prefix)ASAI\ASAI-VDC01\Virtual Hard Disks\01-ASAI-VDC01.ps1" -value "Rename-Computer -NewName ASAI-VDC01 -Restart"
		Add-Content -Path "$Destination\$($Prefix)ASAI\ASAI-VDC01\Virtual Hard Disks\02-ASAI-VDC01-ADDeploy.cmd" -value "powershell.exe Set-ExecutionPolicy -ExecutionPolicy Unrestricted"
		Add-Content -Path "$Destination\$($Prefix)ASAI\ASAI-VDC01\Virtual Hard Disks\02-ASAI-VDC01-ADDeploy.cmd" -value "powershell.exe -noexit C:\SetupTemp\02-ASAI-VDC01-ADDeploy.ps1"
		Add-Content -Path "$Destination\$($Prefix)ASAI\ASAI-VDC01\Virtual Hard Disks\02-ASAI-VDC01-ADDeploy.ps1" -value "Import-Module ADDSDeployment"
		Add-Content -Path "$Destination\$($Prefix)ASAI\ASAI-VDC01\Virtual Hard Disks\02-ASAI-VDC01-ADDeploy.ps1" -Value "Install-ADDSForest -CreateDnsDelegation:`$false -DatabasePath `"C:\Windows\NTDS`" -DomainMode $ForestDomainMode -DomainName `"asai-center.de`" -DomainNetbiosName `"ASAI`" -ForestMode $ForestDomainMode -InstallDns:`$true -LogPath `"C:\Windows\NTDS`" -NoRebootOnCompletion:`$false -SafeModeAdministratorPassword (ConvertTo-SecureString -String `"C0mplex`" -AsPlainText -Force) -SysvolPath `"C:\Windows\SYSVOL`" -Force:`$true"
		Add-Content -Path "$Destination\$($Prefix)ASAI\ASAI-VDC01\Virtual Hard Disks\03-ASAI-VDC01-ADCare.ps1" -value "Add-DnsServerPrimaryZone -Name 50.168.192.in-addr.arpa -DynamicUpdate Secure -ReplicationScope Forest"
		Add-Content -Path "$Destination\$($Prefix)ASAI\ASAI-VDC01\Virtual Hard Disks\03-ASAI-VDC01-ADCare.ps1" -value "Set-DnsClientServerAddress -InterfaceAlias ethernet -ServerAddresses `"192.168.50.1`""
		Add-Content -Path "$Destination\$($Prefix)ASAI\ASAI-VDC01\Virtual Hard Disks\03-ASAI-VDC01-ADCare.ps1" -value "Rename-ADObject -NewName `"BB`" -Identity `"CN=Default-First-Site-Name,CN=Sites,CN=Configuration,DC=asai-center,DC=de`""
		Add-Content -Path "$Destination\$($Prefix)ASAI\ASAI-VDC01\Virtual Hard Disks\03-ASAI-VDC01-ADCare.ps1" -value "New-ADReplicationSubnet -Name 192.168.50.0/24 -Location `"BB`" -Site `"BB`""
		Add-Content -Path "$Destination\$($Prefix)ASAI\ASAI-VDC01\Virtual Hard Disks\03-ASAI-VDC01-ADCare.cmd" -value "powershell.exe Set-ExecutionPolicy -ExecutionPolicy Unrestricted"
		Add-Content -Path "$Destination\$($Prefix)ASAI\ASAI-VDC01\Virtual Hard Disks\03-ASAI-VDC01-ADCare.cmd" -value "powershell.exe -noexit C:\SetupTemp\03-ASAI-VDC01-ADCare.ps1"
		Add-Content -Path "$Destination\$($Prefix)ASAI\ASAI-VDC01\Virtual Hard Disks\05-ASAI-VDC01-MIMSecurtiy.cmd" -value "dsacls `"cn=adminsdholder,cn=system,dc=asai-center,DC=de`" /G ASAI\mimservice:WP`;`"member`""
		Add-Content -Path "$Destination\$($Prefix)ASAI\ASAI-VDC01\Virtual Hard Disks\05-ASAI-VDC01-MIMSecurtiy.cmd" -value "dsacls `"cn=adminsdholder,cn=system,dc=asai-center,DC=de`" /G ASAI\mimcomponent:WP`;`"member`""
		Add-Content -Path "$Destination\$($Prefix)ASAI\ASAI-VDC01\Virtual Hard Disks\05-ASAI-VDC01-MIMSecurtiy.cmd" -value "dsacls `"CN=AuthN Policies,CN=AuthN Policy Configuration,CN=Services,CN=Configuration,DC=ASAI-CENTER,DC=DE`" /G ASAI\T0-MIMMan:RPWPRCWD`;`;msDS-AuthNPolicy /i:s"
		Add-Content -Path "$Destination\$($Prefix)ASAI\ASAI-VDC01\Virtual Hard Disks\05-ASAI-VDC01-MIMSecurtiy.cmd" -value "dsacls `"CN=AuthN Policies,CN=AuthN Policy Configuration,CN=Services,CN=Configuration,DC=ASAI-CENTER,DC=DE`" /G ASAI\T0-MIMMan:CCDC`;msDS-AuthNPolicy"
		Add-Content -Path "$Destination\$($Prefix)ASAI\ASAI-VDC01\Virtual Hard Disks\05-ASAI-VDC01-MIMSecurtiy.cmd" -value "dsacls `"CN=AuthN Silos,CN=AuthN Policy Configuration,CN=Services,CN=Configuration,DC=ASAI-CENTER,DC=DE`" /G ASAI\T0-MIMMan:RPWPRCWD`;`;msDS-AuthNPolicySilo /i:s"
		Add-Content -Path "$Destination\$($Prefix)ASAI\ASAI-VDC01\Virtual Hard Disks\05-ASAI-VDC01-MIMSecurtiy.cmd" -value "dsacls `"CN=AuthN Silos,CN=AuthN Policy Configuration,CN=Services,CN=Configuration,DC=ASAI-CENTER,DC=DE`" /G ASAI\T0-MIMMan:CCDC`;msDS-AuthNPolicySilo"
		Add-Content -Path "$Destination\$($Prefix)ASAI\ASAI-VDC01\Virtual Hard Disks\06-ASAI-VDC01-RegPatch.cmd" -value "powershell.exe -noexit C:\SetupTemp\06-ASAI-VDC01-RegPatch.ps1"
		Add-Content -Path "$Destination\$($Prefix)ASAI\ASAI-VDC01\Virtual Hard Disks\07-ASAI-VDC01-NameResolution.cmd" -value "powershell.exe -noexit C:\SetupTemp\07-ASAI-VDC01-NameResolution.ps1"
		Add-Content -Path "$Destination\$($Prefix)ASAI\ASAI-VDC01\Virtual Hard Disks\07-ASAI-VDC01-NameResolution.ps1" -value "Add-DnsServerConditionalForwarderZone -ZoneName ads-center.de -ReplicationScope Forest -MasterServers 192.168.1.1"
		Add-Content -Path "$Destination\$($Prefix)ASAI\ASAI-VDC01\Virtual Hard Disks\07-ASAI-VDC01-NameResolution.ps1" -value "Add-DnsServerConditionalForwarderZone -ZoneName 1.168.192.in-addr.arpa -ReplicationScope Forest -MasterServers 192.168.1.1"
		Add-Content -Path "$Destination\$($Prefix)ASAI\ASAI-VDC01\Virtual Hard Disks\07-ASAI-VDC01-NameResolution.ps1" -value "Add-DnsServerConditionalForwarderZone -ZoneName xchange-center.de -ReplicationScope Forest -MasterServers 192.168.160.1"
		Add-Content -Path "$Destination\$($Prefix)ASAI\ASAI-VDC01\Virtual Hard Disks\07-ASAI-VDC01-NameResolution.ps1" -value "Add-DnsServerConditionalForwarderZone -ZoneName 160.168.192.in-addr.arpa -ReplicationScope Forest -MasterServers 192.168.160.1"
		Add-Content -Path "$Destination\$($Prefix)ASAI\ASAI-VDC01\Virtual Hard Disks\08-ASAI-VDC01-PAMFeature.cmd" -value "powershell.exe -noexit C:\SetupTemp\08-ASAI-VDC01-PAMFeature.ps1"
		Add-Content -Path "$Destination\$($Prefix)ASAI\ASAI-VDC01\Virtual Hard Disks\08-ASAI-VDC01-PAMFeature.ps1" -value "Get-ADOptionalFeature -Filter * | Enable-ADOptionalFeature -Scope ForestOrConfigurationSet -Target asai-center.de -Confirm:`$false"
		Write-Verbose "Created automated setup files for ASAI-VDC01."
		
		#MIMSetup
		Write-Verbose "Creating automated setup files for MIM-Prep."
		Add-Content -Path "$Destination\$($Prefix)ASAI\ASAI-VDC01\Virtual Hard Disks\04-ASAI-VDC01-MIMPrep.cmd" -value "powershell.exe -noexit C:\SetupTemp\04-ASAI-VDC01-MIMPrep.ps1"
		Add-Content -Path "$Destination\$($Prefix)ASAI\ASAI-VDC01\Virtual Hard Disks\04-ASAI-VDC01-MIMPrep.ps1" -value "New-ADOrganizationalUnit -Name ESAE"
		Add-Content -Path "$Destination\$($Prefix)ASAI\ASAI-VDC01\Virtual Hard Disks\04-ASAI-VDC01-MIMPrep.ps1" -value "New-ADOrganizationalUnit -Name PAW -Path `"OU=ESAE,DC=ASAI-CENTER,DC=DE`""
		Add-Content -Path "$Destination\$($Prefix)ASAI\ASAI-VDC01\Virtual Hard Disks\04-ASAI-VDC01-MIMPrep.ps1" -value "New-ADOrganizationalUnit -Name Desktop -Path `"OU=PAW,OU=ESAE,DC=ASAI-CENTER,DC=DE`""
		Add-Content -Path "$Destination\$($Prefix)ASAI\ASAI-VDC01\Virtual Hard Disks\04-ASAI-VDC01-MIMPrep.ps1" -value "New-ADOrganizationalUnit -Name Mobile -Path `"OU=PAW,OU=ESAE,DC=ASAI-CENTER,DC=DE`""
		Add-Content -Path "$Destination\$($Prefix)ASAI\ASAI-VDC01\Virtual Hard Disks\04-ASAI-VDC01-MIMPrep.ps1" -value "New-ADOrganizationalUnit -Name Tier0 -Path `"OU=ESAE,DC=ASAI-CENTER,DC=DE`""
		Add-Content -Path "$Destination\$($Prefix)ASAI\ASAI-VDC01\Virtual Hard Disks\04-ASAI-VDC01-MIMPrep.ps1" -value "New-ADOrganizationalUnit -Name Accounts -Path `"OU=Tier0,OU=ESAE,DC=ASAI-CENTER,DC=DE`""
		Add-Content -Path "$Destination\$($Prefix)ASAI\ASAI-VDC01\Virtual Hard Disks\04-ASAI-VDC01-MIMPrep.ps1" -value "New-ADOrganizationalUnit -Name Groups -Path `"OU=Tier0,OU=ESAE,DC=ASAI-CENTER,DC=DE`""
		Add-Content -Path "$Destination\$($Prefix)ASAI\ASAI-VDC01\Virtual Hard Disks\04-ASAI-VDC01-MIMPrep.ps1" -value "New-ADOrganizationalUnit -Name Servers -Path `"OU=Tier0,OU=ESAE,DC=ASAI-CENTER,DC=DE`""
		Add-Content -Path "$Destination\$($Prefix)ASAI\ASAI-VDC01\Virtual Hard Disks\04-ASAI-VDC01-MIMPrep.ps1" -value "New-ADOrganizationalUnit -Name Tier1 -Path `"OU=ESAE,DC=ASAI-CENTER,DC=DE`""
		Add-Content -Path "$Destination\$($Prefix)ASAI\ASAI-VDC01\Virtual Hard Disks\04-ASAI-VDC01-MIMPrep.ps1" -value "New-ADOrganizationalUnit -Name Accounts -Path `"OU=Tier1,OU=ESAE,DC=ASAI-CENTER,DC=DE`""
		Add-Content -Path "$Destination\$($Prefix)ASAI\ASAI-VDC01\Virtual Hard Disks\04-ASAI-VDC01-MIMPrep.ps1" -value "New-ADOrganizationalUnit -Name Groups -Path `"OU=Tier1,OU=ESAE,DC=ASAI-CENTER,DC=DE`""
		Add-Content -Path "$Destination\$($Prefix)ASAI\ASAI-VDC01\Virtual Hard Disks\04-ASAI-VDC01-MIMPrep.ps1" -value "New-ADOrganizationalUnit -Name Servers -Path `"OU=Tier1,OU=ESAE,DC=ASAI-CENTER,DC=DE`""
		Add-Content -Path "$Destination\$($Prefix)ASAI\ASAI-VDC01\Virtual Hard Disks\04-ASAI-VDC01-MIMPrep.ps1" -value "New-ADOrganizationalUnit -Name Tier2 -Path `"OU=ESAE,DC=ASAI-CENTER,DC=DE`""
		Add-Content -Path "$Destination\$($Prefix)ASAI\ASAI-VDC01\Virtual Hard Disks\04-ASAI-VDC01-MIMPrep.ps1" -value "New-ADOrganizationalUnit -Name Accounts -Path `"OU=Tier2,OU=ESAE,DC=ASAI-CENTER,DC=DE`""
		Add-Content -Path "$Destination\$($Prefix)ASAI\ASAI-VDC01\Virtual Hard Disks\04-ASAI-VDC01-MIMPrep.ps1" -value "New-ADOrganizationalUnit -Name Groups -Path `"OU=Tier2,OU=ESAE,DC=ASAI-CENTER,DC=DE`""
		Add-Content -Path "$Destination\$($Prefix)ASAI\ASAI-VDC01\Virtual Hard Disks\04-ASAI-VDC01-MIMPrep.ps1" -value "New-ADOrganizationalUnit -Name Servers -Path `"OU=Tier2,OU=ESAE,DC=ASAI-CENTER,DC=DE`""
		Add-Content -Path "$Destination\$($Prefix)ASAI\ASAI-VDC01\Virtual Hard Disks\04-ASAI-VDC01-MIMPrep.ps1" -value "New-ADUser -Name MIMMA -UserPrincipalName MIMMA@asai-center.de -AccountPassword (ConvertTo-SecureString -String `"C0mplex`" -AsPlainText -Force) -Path `"OU=Accounts,OU=Tier0,OU=ESAE, DC=asai-center,DC=de`" -Enabled `$true -PasswordNeverExpires `$true"
		Add-Content -Path "$Destination\$($Prefix)ASAI\ASAI-VDC01\Virtual Hard Disks\04-ASAI-VDC01-MIMPrep.ps1" -value "New-ADUser -Name MIMMonitor -UserPrincipalName MIMMonitor@asai-center.de -AccountPassword (ConvertTo-SecureString -String `"C0mplex`" -AsPlainText -Force) -Path `"OU=Accounts,OU=Tier0,OU=ESAE, DC=asai-center,DC=de`" -Enabled `$true -PasswordNeverExpires `$true"
		Add-Content -Path "$Destination\$($Prefix)ASAI\ASAI-VDC01\Virtual Hard Disks\04-ASAI-VDC01-MIMPrep.ps1" -value "New-ADUser -Name MIMComponent -UserPrincipalName MIMComponent@asai-center.de -AccountPassword (ConvertTo-SecureString -String `"C0mplex`" -AsPlainText -Force) -Path `"OU=Accounts,OU=Tier0,OU=ESAE, DC=asai-center,DC=de`" -Enabled `$true -PasswordNeverExpires `$true"
		Add-Content -Path "$Destination\$($Prefix)ASAI\ASAI-VDC01\Virtual Hard Disks\04-ASAI-VDC01-MIMPrep.ps1" -value "New-ADUser -Name MIMSync -UserPrincipalName MIMSync@asai-center.de -AccountPassword (ConvertTo-SecureString -String `"C0mplex`" -AsPlainText -Force) -Path `"OU=Accounts,OU=Tier0,OU=ESAE, DC=asai-center,DC=de`" -Enabled `$true -PasswordNeverExpires `$true"
		Add-Content -Path "$Destination\$($Prefix)ASAI\ASAI-VDC01\Virtual Hard Disks\04-ASAI-VDC01-MIMPrep.ps1" -value "New-ADUser -Name MIMMan1 -UserPrincipalName MIMMan1@asai-center.de -AccountPassword (ConvertTo-SecureString -String `"C0mplex`" -AsPlainText -Force) -Path `"OU=Accounts,OU=Tier0,OU=ESAE, DC=asai-center,DC=de`" -Enabled `$true -PasswordNeverExpires `$true -Description `"MIM BreakGlass user 1`""
		Add-Content -Path "$Destination\$($Prefix)ASAI\ASAI-VDC01\Virtual Hard Disks\04-ASAI-VDC01-MIMPrep.ps1" -value "New-ADUser -Name MIMMan2 -UserPrincipalName MIMMan2@asai-center.de -AccountPassword (ConvertTo-SecureString -String `"C0mplex`" -AsPlainText -Force) -Path `"OU=Accounts,OU=Tier0,OU=ESAE, DC=asai-center,DC=de`" -Enabled `$true -PasswordNeverExpires `$true -Description `"MIM BreakGlass user 2`""
		Add-Content -Path "$Destination\$($Prefix)ASAI\ASAI-VDC01\Virtual Hard Disks\04-ASAI-VDC01-MIMPrep.ps1" -value "New-ADUser -Name MIMMhandl -UserPrincipalName MIMMhandl@asai-center.de -AccountPassword (ConvertTo-SecureString -String `"C0mplex`" -AsPlainText -Force) -Path `"OU=Accounts,OU=Tier0,OU=ESAE, DC=asai-center,DC=de`" -Enabled `$true -PasswordNeverExpires `$true -Description `"MIM SCAMA user`""
		Add-Content -Path "$Destination\$($Prefix)ASAI\ASAI-VDC01\Virtual Hard Disks\04-ASAI-VDC01-MIMPrep.ps1" -value "New-ADUser -Name MIMDturner -UserPrincipalName MIMDturner@asai-center.de -AccountPassword (ConvertTo-SecureString -String `"C0mplex`" -AsPlainText -Force) -Path `"OU=Accounts,OU=Tier0,OU=ESAE, DC=asai-center,DC=de`" -Enabled `$true -PasswordNeverExpires `$true -Description `"MIM SCAMA user`""
		Add-Content -Path "$Destination\$($Prefix)ASAI\ASAI-VDC01\Virtual Hard Disks\04-ASAI-VDC01-MIMPrep.ps1" -value "New-ADUser -Name MIMTpham -UserPrincipalName MIMTpham@asai-center.de -AccountPassword (ConvertTo-SecureString -String `"C0mplex`" -AsPlainText -Force) -Path `"OU=Accounts,OU=Tier0,OU=ESAE, DC=asai-center,DC=de`" -Enabled `$true -PasswordNeverExpires `$true -Description `"MIM SCAMA user`""
		Add-Content -Path "$Destination\$($Prefix)ASAI\ASAI-VDC01\Virtual Hard Disks\04-ASAI-VDC01-MIMPrep.ps1" -value "New-ADUser -Name MIMService -UserPrincipalName MIMService@asai-center.de -AccountPassword (ConvertTo-SecureString -String `"C0mplex`" -AsPlainText -Force) -Path `"OU=Accounts,OU=Tier0,OU=ESAE, DC=asai-center,DC=de`" -Enabled `$true -PasswordNeverExpires `$true"
		Add-Content -Path "$Destination\$($Prefix)ASAI\ASAI-VDC01\Virtual Hard Disks\04-ASAI-VDC01-MIMPrep.ps1" -value "New-ADUser -Name Sharepoint -UserPrincipalName Sharepoint@asai-center.de -AccountPassword (ConvertTo-SecureString -String `"C0mplex`" -AsPlainText -Force) -Path `"OU=Accounts,OU=Tier0,OU=ESAE, DC=asai-center,DC=de`" -Enabled `$true -PasswordNeverExpires `$true"
		Add-Content -Path "$Destination\$($Prefix)ASAI\ASAI-VDC01\Virtual Hard Disks\04-ASAI-VDC01-MIMPrep.ps1" -value "New-ADUser -Name SQLEngine -UserPrincipalName SQLEngine@asai-center.de -AccountPassword (ConvertTo-SecureString -String `"C0mplex`" -AsPlainText -Force) -Path `"OU=Accounts,OU=Tier0,OU=ESAE, DC=asai-center,DC=de`" -Enabled `$true -PasswordNeverExpires `$true"
		Add-Content -Path "$Destination\$($Prefix)ASAI\ASAI-VDC01\Virtual Hard Disks\04-ASAI-VDC01-MIMPrep.ps1" -value "New-ADUser -Name BackupAdmin -UserPrincipalName BackupAdmin@asai-center.de -AccountPassword (ConvertTo-SecureString -String `"C0mplex`" -AsPlainText -Force) -Path `"OU=Accounts,OU=Tier0,OU=ESAE, DC=asai-center,DC=de`" -Enabled `$true -PasswordNeverExpires `$true"
		Add-Content -Path "$Destination\$($Prefix)ASAI\ASAI-VDC01\Virtual Hard Disks\04-ASAI-VDC01-MIMPrep.ps1" -value "New-ADGroup -Name T0-MIMMan -GroupCategory Security -GroupScope Universal  -Path `"OU=Groups,OU=Tier0,OU=ESAE, DC=asai-center,DC=de`""
		Add-Content -Path "$Destination\$($Prefix)ASAI\ASAI-VDC01\Virtual Hard Disks\04-ASAI-VDC01-MIMPrep.ps1" -value "Add-ADGroupMember -Identity `"T0-MIMMan`" -Members `"MIMMan1`",`"MIMMan2`""
		Add-Content -Path "$Destination\$($Prefix)ASAI\ASAI-VDC01\Virtual Hard Disks\04-ASAI-VDC01-MIMPrep.ps1" -value "New-ADGroup -Name T0-MIMAd -GroupCategory Security -GroupScope Universal  -Path `"OU=Groups,OU=Tier0,OU=ESAE, DC=asai-center,DC=de`""
		Add-Content -Path "$Destination\$($Prefix)ASAI\ASAI-VDC01\Virtual Hard Disks\04-ASAI-VDC01-MIMPrep.ps1" -value "Add-ADGroupMember -Identity `"T0-MIMAd`" -Members `"MIMMhandl`",`"MIMDturner`",`"MIMTpham`""
		Add-Content -Path "$Destination\$($Prefix)ASAI\ASAI-VDC01\Virtual Hard Disks\04-ASAI-VDC01-MIMPrep.ps1" -value "Add-ADGroupMember -Identity `"Administrators`" -Members `"T0-MIMAd`",`"T0-MIMMan`""
		Add-Content -Path "$Destination\$($Prefix)ASAI\ASAI-VDC01\Virtual Hard Disks\04-ASAI-VDC01-MIMPrep.ps1" -value "New-ADGroup -Name MIMSvcAccounts -GroupCategory Security -GroupScope Universal -Path `"OU=Groups,OU=Tier0,OU=ESAE, DC=asai-center,DC=de`""
		Add-Content -Path "$Destination\$($Prefix)ASAI\ASAI-VDC01\Virtual Hard Disks\04-ASAI-VDC01-MIMPrep.ps1" -value "Add-ADGroupMember -Identity `"MIMSvcAccounts`" -Members `"MIMMonitor`",`"MIMComponent`",`"MIMService`""
		Add-Content -Path "$Destination\$($Prefix)ASAI\ASAI-VDC01\Virtual Hard Disks\04-ASAI-VDC01-MIMPrep.ps1" -value "setspn.exe -S http/ASAI-VMIM01 sharepoint"
		Add-Content -Path "$Destination\$($Prefix)ASAI\ASAI-VDC01\Virtual Hard Disks\04-ASAI-VDC01-MIMPrep.ps1" -value "setspn.exe -S http/ASAI-VMIM01.asai-center.de sharepoint"
		Add-Content -Path "$Destination\$($Prefix)ASAI\ASAI-VDC01\Virtual Hard Disks\04-ASAI-VDC01-MIMPrep.ps1" -value "setspn.exe -S FIMService/ASAI-VMIM01 MIMService"
		Add-Content -Path "$Destination\$($Prefix)ASAI\ASAI-VDC01\Virtual Hard Disks\04-ASAI-VDC01-MIMPrep.ps1" -value "setspn.exe -S FIMService/ASAI-VMIM01.asai-center.de MIMService"
		Write-Verbose "Created automated setup files for MIM-Prep."
		
		Write-Verbose "Mounting ASAI-VDC01.vhdx and copying automated setup files."
		$driveb4 = (Get-PSDrive).Name
		Mount-VHD -Path "$Destination\$($Prefix)ASAI\ASAI-VDC01\Virtual Hard Disks\ASAI-VDC01.vhdx"
		$driveat = (Get-PSDrive).name
		$drive = (Compare-Object -ReferenceObject $driveb4 -DifferenceObject $driveat).inputobject[-1] + ':'
		New-Item -Path $drive\SetupTemp -ItemType Directory | Out-Null
		Set-Location -Path $drive\SetupTemp | Out-Null
		Copy-Item -Path "$Destination\$($Prefix)ASAI\ASAI-VDC01\Virtual Hard Disks\01-ASAI-VDC01.cmd" -Destination . | Out-Null
		Copy-Item -Path "$Destination\$($Prefix)ASAI\ASAI-VDC01\Virtual Hard Disks\01-ASAI-VDC01.ps1" -Destination . | Out-Null
		Copy-Item -Path "$Destination\$($Prefix)ASAI\ASAI-VDC01\Virtual Hard Disks\02-ASAI-VDC01-ADDeploy.ps1" -Destination . | Out-Null
		Copy-Item -Path "$Destination\$($Prefix)ASAI\ASAI-VDC01\Virtual Hard Disks\02-ASAI-VDC01-ADDeploy.cmd" -Destination . | Out-Null
		Copy-Item -Path "$Destination\$($Prefix)ASAI\ASAI-VDC01\Virtual Hard Disks\03-ASAI-VDC01-ADCare.ps1" -Destination . | Out-Null
		Copy-Item -Path "$Destination\$($Prefix)ASAI\ASAI-VDC01\Virtual Hard Disks\03-ASAI-VDC01-ADCare.cmd" -Destination . | Out-Null
		Copy-Item -Path "$Destination\$($Prefix)ASAI\ASAI-VDC01\Virtual Hard Disks\04-ASAI-VDC01-MIMPrep.ps1" -Destination . | Out-Null
		Copy-Item -Path "$Destination\$($Prefix)ASAI\ASAI-VDC01\Virtual Hard Disks\04-ASAI-VDC01-MIMPrep.cmd" -Destination . | Out-Null
		Copy-Item -Path "$Destination\$($Prefix)ASAI\ASAI-VDC01\Virtual Hard Disks\05-ASAI-VDC01-MIMSecurtiy.cmd" -Destination . | Out-Null
		Copy-Item -Path "$Destination\$($Prefix)ASAI\ASAI-VDC01\Virtual Hard Disks\06-ASAI-VDC01-RegPatch.cmd" -Destination . | Out-Null
		Copy-Item -Path "$Destination\$($Prefix)ASAI\ASAI-VDC01\Virtual Hard Disks\06-ASAI-VDC01-RegPatch.ps1" -Destination . | Out-Null
		Copy-Item -Path "$Destination\$($Prefix)ASAI\ASAI-VDC01\Virtual Hard Disks\07-ASAI-VDC01-NameResolution.cmd" -Destination . | Out-Null
		Copy-Item -Path "$Destination\$($Prefix)ASAI\ASAI-VDC01\Virtual Hard Disks\07-ASAI-VDC01-NameResolution.ps1" -Destination . | Out-Null
		Copy-Item -Path "$Destination\$($Prefix)ASAI\ASAI-VDC01\Virtual Hard Disks\08-ASAI-VDC01-PAMFeature.cmd" -Destination . | Out-Null
		Copy-Item -Path "$Destination\$($Prefix)ASAI\ASAI-VDC01\Virtual Hard Disks\08-ASAI-VDC01-PAMFeature.ps1" -Destination . | Out-Null
		Set-Location -Path c: | Out-Null
		Dismount-VHD -Path "$Destination\$($Prefix)ASAI\ASAI-VDC01\Virtual Hard Disks\ASAI-VDC01.vhdx"
		Write-Verbose "Dismounted ASAI-VDC01.vhdx successfully."
		
		#ASAI-VSQL01
		Write-Verbose "Creating automated setup files for SQL server installation."
		New-Item -Name 01-ASAI-VSQL01.cmd -ItemType file -Path "$Destination\$($Prefix)ASAI\ASAI-VSQL01\Virtual Hard Disks\" | Out-Null
		New-Item -Name 01-ASAI-VSQL01.ps1 -ItemType file -Path "$Destination\$($Prefix)ASAI\ASAI-VSQL01\Virtual Hard Disks\" | Out-Null
		New-Item -Name 02-ASAI-VSQL01Prep.ps1 -ItemType file -Path "$Destination\$($Prefix)ASAI\ASAI-VSQL01\Virtual Hard Disks\" | Out-Null
		New-Item -Name 02-ASAI-VSQL01Prep.cmd -ItemType file -Path "$Destination\$($Prefix)ASAI\ASAI-VSQL01\Virtual Hard Disks\" | Out-Null
		New-Item -Name 03-ASAI-VSQL01Setup.cmd -ItemType file -Path "$Destination\$($Prefix)ASAI\ASAI-VSQL01\Virtual Hard Disks\" | Out-Null
		Add-Content -Path "$Destination\$($Prefix)ASAI\ASAI-VSQL01\Virtual Hard Disks\01-ASAI-VSQL01.ps1" -value "Get-ScheduledTask -TaskName servermanager | Disable-ScheduledTask"
		Add-Content -Path "$Destination\$($Prefix)ASAI\ASAI-VSQL01\Virtual Hard Disks\01-ASAI-VSQL01.ps1" -value "Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled false"
		Add-Content -Path "$Destination\$($Prefix)ASAI\ASAI-VSQL01\Virtual Hard Disks\01-ASAI-VSQL01.ps1" -value "Set-ItemProperty -Path `"HKLM:\System\CurrentControlSet\Control\Terminal Server`" -name `"fDenyTSConnections`" -Value 0"
		Add-Content -Path "$Destination\$($Prefix)ASAI\ASAI-VSQL01\Virtual Hard Disks\01-ASAI-VSQL01.ps1" -value "Enable-NetFirewallRule -DisplayGroup `"Remote Desktop`""
		Add-Content -Path "$Destination\$($Prefix)ASAI\ASAI-VSQL01\Virtual Hard Disks\01-ASAI-VSQL01.ps1" -value "Set-ItemProperty -Path `"HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp`" -name `"UserAuthentication`" -Value 1"
		Add-Content -Path "$Destination\$($Prefix)ASAI\ASAI-VSQL01\Virtual Hard Disks\01-ASAI-VSQL01.ps1" -value "Disable-NetAdapterBinding -InterfaceAlias ethernet -ComponentID ms_tcpip6"
		Add-Content -Path "$Destination\$($Prefix)ASAI\ASAI-VSQL01\Virtual Hard Disks\01-ASAI-VSQL01.ps1" -value "New-NetIPAddress -InterfaceAlias ethernet -IPAddress 192.168.50.2 -PrefixLength 24 -DefaultGateway 192.168.50.254"
		Add-Content -Path "$Destination\$($Prefix)ASAI\ASAI-VSQL01\Virtual Hard Disks\01-ASAI-VSQL01.ps1" -value "Set-DnsClientServerAddress -InterfaceAlias ethernet -ResetServerAddresses"
		Add-Content -Path "$Destination\$($Prefix)ASAI\ASAI-VSQL01\Virtual Hard Disks\01-ASAI-VSQL01.ps1" -value "Set-DnsClientServerAddress -InterfaceAlias ethernet -ServerAddresses `"192.168.50.1`""
		Add-Content -Path "$Destination\$($Prefix)ASAI\ASAI-VSQL01\Virtual Hard Disks\01-ASAI-VSQL01.ps1" -value "(Get-WmiObject -Class Win32_NetworkAdapterConfiguration | Where-Object { `$PSItem.description -like `"*hyper*`" }).settcpipnetbios(2)"
		Add-Content -Path "$Destination\$($Prefix)ASAI\ASAI-VSQL01\Virtual Hard Disks\01-ASAI-VSQL01.ps1" -value "`$Cred = New-object System.Management.Automation.PSCredential `"administrator@asai-center.de`", (ConvertTo-SecureString -String `"C0mplex`" -AsPlainText -Force)"
		Add-Content -Path "$Destination\$($Prefix)ASAI\ASAI-VSQL01\Virtual Hard Disks\01-ASAI-VSQL01.ps1" -value "Add-Computer -DomainCredential `$cred -DomainName asai-center.de -NewName ASAI-VSQL01 -OUPath `"OU=Servers,OU=Tier0,OU=ESAE,DC=ASAI-CENTER,DC=DE`" -Restart"
		Add-Content -Path "$Destination\$($Prefix)ASAI\ASAI-VSQL01\Virtual Hard Disks\01-ASAI-VSQL01.cmd" -value "powershell.exe Set-ExecutionPolicy -ExecutionPolicy Unrestricted"
		Add-Content -Path "$Destination\$($Prefix)ASAI\ASAI-VSQL01\Virtual Hard Disks\01-ASAI-VSQL01.cmd" -value "powershell.exe -noexit C:\SetupTemp\01-ASAI-VSQL01.ps1"
		Add-Content -Path "$Destination\$($Prefix)ASAI\ASAI-VSQL01\Virtual Hard Disks\02-ASAI-VSQL01Prep.ps1" -value "Install-WindowsFeature Net-Framework-Features,rsat-ad-powershell –includeallsubfeature -restart -source d:\sources\SxS"
		Add-Content -Path "$Destination\$($Prefix)ASAI\ASAI-VSQL01\Virtual Hard Disks\02-ASAI-VSQL01Prep.cmd" -value "powershell.exe -noexit C:\SetupTemp\02-ASAI-VSQL01Prep.ps1"
		Add-Content -Path "$Destination\$($Prefix)ASAI\ASAI-VSQL01\Virtual Hard Disks\03-ASAI-VSQL01Setup.cmd" -value "D:\setup.exe /Q /IACCEPTSQLSERVERLICENSETERMS /ACTION=install /FEATURES=SQL /INSTANCENAME=MSSQLSERVER /SQLSVCACCOUNT=`"ASAI\SqlEngine`" /SQLSVCPASSWORD=`"C0mplex`" /AGTSVCSTARTUPTYPE=Automatic /AGTSVCACCOUNT=`"NT AUTHORITY\Network Service`" /SQLSYSADMINACCOUNTS=`"ASAI\MIMMan1`""
		
		Write-Verbose "Mounting ASAI-VSQL01.vhdx and copying the automated setup files."
		$driveb4 = (Get-PSDrive).Name
		Mount-VHD -Path "$Destination\$($Prefix)ASAI\ASAI-VSQL01\Virtual Hard Disks\ASAI-VSQL01.vhdx"
		$driveat = (Get-PSDrive).name
		$drive = (Compare-Object -ReferenceObject $driveb4 -DifferenceObject $driveat).inputobject[-1] + ':'
		New-Item -Path $drive\SetupTemp -ItemType Directory | Out-Null
		Set-Location -Path $drive\SetupTemp | Out-Null
		Copy-Item -Path "$Destination\$($Prefix)ASAI\ASAI-VSQL01\Virtual Hard Disks\01-ASAI-VSQL01.cmd" -Destination . | Out-Null
		Copy-Item -Path "$Destination\$($Prefix)ASAI\ASAI-VSQL01\Virtual Hard Disks\01-ASAI-VSQL01.ps1" -Destination . | Out-Null
		Copy-Item -Path "$Destination\$($Prefix)ASAI\ASAI-VSQL01\Virtual Hard Disks\02-ASAI-VSQL01Prep.ps1" -Destination . | Out-Null
		Copy-Item -Path "$Destination\$($Prefix)ASAI\ASAI-VSQL01\Virtual Hard Disks\02-ASAI-VSQL01Prep.cmd" -Destination . | Out-Null
		Copy-Item -Path "$Destination\$($Prefix)ASAI\ASAI-VSQL01\Virtual Hard Disks\03-ASAI-VSQL01Setup.cmd" -Destination . | Out-Null
		Set-Location -Path c: | Out-Null
		Dismount-VHD -Path "$Destination\$($Prefix)ASAI\ASAI-VSQL01\Virtual Hard Disks\ASAI-VSQL01.vhdx"
		Write-Verbose "Dismounted ASAI-VSQL01.vhdx successfully."
		
		#ASAI-VMIM01
		Write-Verbose "Creating automated setup files for MIM server installation."
		New-Item -Name 01-ASAI-VMIM01.cmd -ItemType file -Path "$Destination\$($Prefix)ASAI\ASAI-VMIM01\Virtual Hard Disks\" | Out-Null
		New-Item -Name 01-ASAI-VMIM01.ps1 -ItemType file -Path "$Destination\$($Prefix)ASAI\ASAI-VMIM01\Virtual Hard Disks\" | Out-Null
		New-Item -Name 04-VMIMPortal.cmd -ItemType file -Path "$Destination\$($Prefix)ASAI\ASAI-VMIM01\Virtual Hard Disks\" | Out-Null
		New-Item -Name 04-VMIMPortal.ps1 -ItemType file -Path "$Destination\$($Prefix)ASAI\ASAI-VMIM01\Virtual Hard Disks\" | Out-Null
		New-Item -Name 02-VMIMSPSPrep.cmd -ItemType file -Path "$Destination\$($Prefix)ASAI\ASAI-VMIM01\Virtual Hard Disks\" | Out-Null
		New-Item -Name 02-VMIMSPSPrep.ps1 -ItemType file -Path "$Destination\$($Prefix)ASAI\ASAI-VMIM01\Virtual Hard Disks\" | Out-Null
		New-Item -Name 05-VMIMIISAuth.cmd -ItemType file -Path "$Destination\$($Prefix)ASAI\ASAI-VMIM01\Virtual Hard Disks\" | Out-Null
		New-Item -Name 03-ASAI-VMIM01-MIMApp.ps1 -ItemType file -Path "$Destination\$($Prefix)ASAI\ASAI-VMIM01\Virtual Hard Disks\" | Out-Null
		Add-Content -Path "$Destination\$($Prefix)ASAI\ASAI-VMIM01\Virtual Hard Disks\01-ASAI-VMIM01.ps1" -value "Get-ScheduledTask -TaskName servermanager | Disable-ScheduledTask"
		Add-Content -Path "$Destination\$($Prefix)ASAI\ASAI-VMIM01\Virtual Hard Disks\01-ASAI-VMIM01.ps1" -value "Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled false"
		Add-Content -Path "$Destination\$($Prefix)ASAI\ASAI-VMIM01\Virtual Hard Disks\01-ASAI-VMIM01.ps1" -value "Set-ItemProperty -Path `"HKLM:\System\CurrentControlSet\Control\Terminal Server`" -name `"fDenyTSConnections`" -Value 0"
		Add-Content -Path "$Destination\$($Prefix)ASAI\ASAI-VMIM01\Virtual Hard Disks\01-ASAI-VMIM01.ps1" -value "Enable-NetFirewallRule -DisplayGroup `"Remote Desktop`""
		Add-Content -Path "$Destination\$($Prefix)ASAI\ASAI-VMIM01\Virtual Hard Disks\01-ASAI-VMIM01.ps1" -value "Set-ItemProperty -Path `"HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp`" -name `"UserAuthentication`" -Value 1"
		Add-Content -Path "$Destination\$($Prefix)ASAI\ASAI-VMIM01\Virtual Hard Disks\01-ASAI-VMIM01.ps1" -value "Disable-NetAdapterBinding -InterfaceAlias ethernet -ComponentID ms_tcpip6"
		Add-Content -Path "$Destination\$($Prefix)ASAI\ASAI-VMIM01\Virtual Hard Disks\01-ASAI-VMIM01.ps1" -value "New-NetIPAddress -InterfaceAlias ethernet -IPAddress 192.168.50.3 -PrefixLength 24 -DefaultGateway 192.168.50.254"
		Add-Content -Path "$Destination\$($Prefix)ASAI\ASAI-VMIM01\Virtual Hard Disks\01-ASAI-VMIM01.ps1" -value "Set-DnsClientServerAddress -InterfaceAlias ethernet -ResetServerAddresses"
		Add-Content -Path "$Destination\$($Prefix)ASAI\ASAI-VMIM01\Virtual Hard Disks\01-ASAI-VMIM01.ps1" -value "Set-DnsClientServerAddress -InterfaceAlias ethernet -ServerAddresses `"192.168.50.1`""
		Add-Content -Path "$Destination\$($Prefix)ASAI\ASAI-VMIM01\Virtual Hard Disks\01-ASAI-VMIM01.ps1" -value "(Get-WmiObject -Class Win32_NetworkAdapterConfiguration | Where-Object { `$PSItem.description -like `"*hyper*`" }).settcpipnetbios(2)"
		Add-Content -Path "$Destination\$($Prefix)ASAI\ASAI-VMIM01\Virtual Hard Disks\01-ASAI-VMIM01.ps1" -value "`$Cred = New-object System.Management.Automation.PSCredential `"administrator@asai-center.de`", (ConvertTo-SecureString -String `"C0mplex`" -AsPlainText -Force)"
		Add-Content -Path "$Destination\$($Prefix)ASAI\ASAI-VMIM01\Virtual Hard Disks\01-ASAI-VMIM01.ps1" -value "Add-Computer -DomainCredential `$cred -DomainName asai-center.de -NewName ASAI-VMIM01 -OUPath `"OU=Servers,OU=Tier0,OU=ESAE,DC=ASAI-CENTER,DC=DE`" -Restart"
		Add-Content -Path "$Destination\$($Prefix)ASAI\ASAI-VMIM01\Virtual Hard Disks\01-ASAI-VMIM01.cmd" -value "powershell.exe Set-ExecutionPolicy -ExecutionPolicy Unrestricted"
		Add-Content -Path "$Destination\$($Prefix)ASAI\ASAI-VMIM01\Virtual Hard Disks\01-ASAI-VMIM01.cmd" -value "powershell.exe -noexit C:\SetupTemp\01-ASAI-VMIM01.ps1"
		
		#MIM SPSPrep
		Write-Verbose "Creating automated setup files for sharepoint server installation."
		Add-Content -Path "$Destination\$($Prefix)ASAI\ASAI-VMIM01\Virtual Hard Disks\02-VMIMSPSPrep.cmd" -value "powershell.exe -noexit C:\SetupTemp\02-VMIMSPSPrep.ps1"
		Add-Content -Path "$Destination\$($Prefix)ASAI\ASAI-VMIM01\Virtual Hard Disks\02-VMIMSPSPrep.ps1" -value "import-module ServerManager"
		Add-Content -Path "$Destination\$($Prefix)ASAI\ASAI-VMIM01\Virtual Hard Disks\02-VMIMSPSPrep.ps1" -value "Add-WindowsFeature NET-HTTP-Activation,NET-Non-HTTP-Activ,NET-WCF-Pipe-Activation45,NET-WCF-HTTP-Activation45,Web-Server,Web-WebServer,Web-Common-Http,Web-Static-Content,Web-Default-Doc,Web-Dir-Browsing,Web-Http-Errors,Web-App-Dev,Web-Asp-Net,Web-Asp-Net45,Web-Net-Ext,Web-Net-Ext45,Web-ISAPI-Ext,Web-ISAPI-Filter,Web-Health,Web-Http-Logging,Web-Log-Libraries,Web-Request-Monitor,Web-Http-Tracing,Web-Security,Web-Basic-Auth,Web-Windows-Auth,Web-Filtering,Web-Digest-Auth,Web-Performance,Web-Stat-Compression,Web-Dyn-Compression,Web-Mgmt-Tools,Web-Mgmt-Console,Web-Mgmt-Compat,Web-Metabase,WAS,WAS-Process-Model,WAS-NET-Environment,WAS-Config-APIs,Web-Lgcy-Scripting,Windows-Identity-Foundation,Xps-Viewer -source `"d:\sources\SxS`""
		Add-Content -Path "$Destination\$($Prefix)ASAI\ASAI-VMIM01\Virtual Hard Disks\02-VMIMSPSPrep.ps1" -value "Set-ItemProperty -Path `"HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}`" -Name IsInstalled -Type DWord -Value 0"
		Add-Content -Path "$Destination\$($Prefix)ASAI\ASAI-VMIM01\Virtual Hard Disks\02-VMIMSPSPrep.ps1" -value "Set-ItemProperty -Path `"HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}`" -Name IsInstalled -Type DWord -Value 0"
		Add-Content -Path "$Destination\$($Prefix)ASAI\ASAI-VMIM01\Virtual Hard Disks\04-VMIMIISAuth.cmd" -value "iisreset /STOP"
		Add-Content -Path "$Destination\$($Prefix)ASAI\ASAI-VMIM01\Virtual Hard Disks\04-VMIMIISAuth.cmd" -value "C:\Windows\System32\inetsrv\appcmd.exe unlock config /section:windowsAuthentication -commit:apphost"
		Add-Content -Path "$Destination\$($Prefix)ASAI\ASAI-VMIM01\Virtual Hard Disks\04-VMIMIISAuth.cmd" -value "iisreset /START"
		Add-Content -Path "$Destination\$($Prefix)ASAI\ASAI-VMIM01\Virtual Hard Disks\05-VMIMPortal.cmd" -value "powershell.exe -noexit C:\SetupTemp\05-VMIMPortal.ps1"
		Add-Content -Path "$Destination\$($Prefix)ASAI\ASAI-VMIM01\Virtual Hard Disks\05-VMIMPortal.ps1" -value "New-WebSite -Name `"MIM Privileged Access Management Example Portal`" -Port 8090 -PhysicalPath `"C:\Program Files\Microsoft Forefront Identity Manager\2010\Privileged Access Management Portal\`""
		
		#MIM Portal
		Write-Verbose "Creating automated setup files for MIM server web application."
		Add-Content -Path "$Destination\$($Prefix)ASAI\ASAI-VMIM01\Virtual Hard Disks\03-ASAI-VMIM01-MIMApp.ps1" -value "`$dbManagedAccount = Get-SPManagedAccount -Identity ASAI\SharePoint"
		Add-Content -Path "$Destination\$($Prefix)ASAI\ASAI-VMIM01\Virtual Hard Disks\03-ASAI-VMIM01-MIMApp.ps1" -value "New-SpWebApplication -Name `"MIM Portal`" -ApplicationPool `"MIMAppPool`" -ApplicationPoolAccount `$dbManagedAccount -AuthenticationMethod `"Kerberos`" -Port 82 -URL http://ASAI-VMIM01.asai-center.de"
		Add-Content -Path "$Destination\$($Prefix)ASAI\ASAI-VMIM01\Virtual Hard Disks\03-ASAI-VMIM01-MIMApp.ps1" -value "`$t = Get-SPWebTemplate -compatibilityLevel 15 -Identity `"STS#1`""
		Add-Content -Path "$Destination\$($Prefix)ASAI\ASAI-VMIM01\Virtual Hard Disks\03-ASAI-VMIM01-MIMApp.ps1" -value "`$w = Get-SPWebApplication http://ASAI-VMIM01.asai-center.de:82"
		Add-Content -Path "$Destination\$($Prefix)ASAI\ASAI-VMIM01\Virtual Hard Disks\03-ASAI-VMIM01-MIMApp.ps1" -value "New-SPSite -Url `$w.Url -Template `$t -OwnerAlias ASAI\MIMMan1 -CompatibilityLevel 15 -Name `"MIM Portal`" -SecondaryOwnerAlias ASAI\BackupAdmin"
		Add-Content -Path "$Destination\$($Prefix)ASAI\ASAI-VMIM01\Virtual Hard Disks\03-ASAI-VMIM01-MIMApp.ps1" -value "`$contentService = [Microsoft.SharePoint.Administration.SPWebService]::ContentService;"
		Add-Content -Path "$Destination\$($Prefix)ASAI\ASAI-VMIM01\Virtual Hard Disks\03-ASAI-VMIM01-MIMApp.ps1" -value "`$contentService.ViewStateOnServer = `$false;"
		Add-Content -Path "$Destination\$($Prefix)ASAI\ASAI-VMIM01\Virtual Hard Disks\03-ASAI-VMIM01-MIMApp.ps1" -value "`$contentService.Update`(`);"
		Add-Content -Path "$Destination\$($Prefix)ASAI\ASAI-VMIM01\Virtual Hard Disks\03-ASAI-VMIM01-MIMApp.ps1" -value "Get-SPTimerJob hourly-all-sptimerservice-health-analysis-job `| disable-SPTimerJob"
		
		Write-Verbose "Mounting ASAI-VMIM01.vhdx and copying the automated setup files."
		$driveb4 = (Get-PSDrive).Name
		Mount-VHD -Path "$Destination\$($Prefix)ASAI\ASAI-VMIM01\Virtual Hard Disks\ASAI-VMIM01.vhdx"
		$driveat = (Get-PSDrive).name
		$drive = (Compare-Object -ReferenceObject $driveb4 -DifferenceObject $driveat).inputobject[-1] + ':'
		New-Item -Path $drive\SetupTemp -ItemType Directory | Out-Null
		Set-Location -Path $drive\SetupTemp | Out-Null
		Copy-Item -Path "$Destination\$($Prefix)ASAI\ASAI-VMIM01\Virtual Hard Disks\01-ASAI-VMIM01.cmd" -Destination . | Out-Null
		Copy-Item -Path "$Destination\$($Prefix)ASAI\ASAI-VMIM01\Virtual Hard Disks\01-ASAI-VMIM01.ps1" -Destination . | Out-Null
		Copy-Item -Path "$Destination\$($Prefix)ASAI\ASAI-VMIM01\Virtual Hard Disks\02-VMIMSPSPrep.cmd" -Destination . | Out-Null
		Copy-Item -Path "$Destination\$($Prefix)ASAI\ASAI-VMIM01\Virtual Hard Disks\02-VMIMSPSPrep.ps1" -Destination . | Out-Null
		Copy-Item -Path "$Destination\$($Prefix)ASAI\ASAI-VMIM01\Virtual Hard Disks\03-ASAI-VMIM01-MIMApp.ps1" -Destination . | Out-Null
		Copy-Item -Path "$Destination\$($Prefix)ASAI\ASAI-VMIM01\Virtual Hard Disks\04-VMIMIISAuth.cmd" -Destination . | Out-Null
		Copy-Item -Path "$Destination\$($Prefix)ASAI\ASAI-VMIM01\Virtual Hard Disks\05-VMIMPortal.cmd" -Destination . | Out-Null
		Copy-Item -Path "$Destination\$($Prefix)ASAI\ASAI-VMIM01\Virtual Hard Disks\05-VMIMPortal.ps1" -Destination . | Out-Null
		Set-Location -Path c: | Out-Null
		Dismount-VHD -Path "$Destination\$($Prefix)ASAI\ASAI-VMIM01\Virtual Hard Disks\ASAI-VMIM01.vhdx"
		Write-Verbose "Dismounted ASAI-VMIM01.vhdx successfully."
		
		#VR
		Write-Verbose "Creating automated setup files for virtual router configuration."
		New-Item -Name 01-VR.cmd -ItemType file -Path "$Destination\$($Prefix)ASAI\ASAI-VR\Virtual Hard Disks\" | Out-Null
		New-Item -Name 01-VR.ps1 -ItemType file -Path "$Destination\$($Prefix)ASAI\ASAI-VR\Virtual Hard Disks\" | Out-Null
		Add-Content -Path "$Destination\$($Prefix)ASAI\ASAI-VR\Virtual Hard Disks\ASAI-01-VR.ps1" -value "Get-ScheduledTask -TaskName servermanager | Disable-ScheduledTask"
		Add-Content -Path "$Destination\$($Prefix)ASAI\ASAI-VR\Virtual Hard Disks\ASAI-01-VR.ps1" -value "Set-NetFirewallProfile -Profile Domain, Public, Private -Enabled false"
		Add-Content -Path "$Destination\$($Prefix)ASAI\ASAI-VR\Virtual Hard Disks\ASAI-01-VR.ps1" -value "Set-ItemProperty -Path `"HKLM:\System\CurrentControlSet\Control\Terminal Server`" -name `"fDenyTSConnections`" -Value 0"
		Add-Content -Path "$Destination\$($Prefix)ASAI\ASAI-VR\Virtual Hard Disks\ASAI-01-VR.ps1" -value "Enable-NetFirewallRule -DisplayGroup `"Remote Desktop`""
		Add-Content -Path "$Destination\$($Prefix)ASAI\ASAI-VR\Virtual Hard Disks\ASAI-01-VR.ps1" -value "Set-ItemProperty -Path `'HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp`' -name `"UserAuthentication`" -Value 1"
		Add-Content -Path "$Destination\$($Prefix)ASAI\ASAI-VR\Virtual Hard Disks\ASAI-01-VR.ps1" -value "Disable-NetAdapterBinding -InterfaceAlias * -ComponentID ms_tcpip6,ms_rspndr,ms_lltdio,ms_lldp,ms_implat,ms_msclient,ms_pacer,ms_server"
		Add-Content -Path "$Destination\$($Prefix)ASAI\ASAI-VR\Virtual Hard Disks\ASAI-01-VR.ps1" -value "(Get-WmiObject -Class Win32_NetworkAdapterConfiguration | Where-Object { `$PSItem.description -like `"*hyper*`" }).settcpipnetbios(2)"
		Add-Content -Path "$Destination\$($Prefix)ASAI\ASAI-VR\Virtual Hard Disks\ASAI-01-VR.ps1" -value "New-NetIPAddress -InterfaceAlias ethernet -IPAddress 192.168.50.254 -PrefixLength 24"
		Add-Content -Path "$Destination\$($Prefix)ASAI\ASAI-VR\Virtual Hard Disks\ASAI-01-VR.ps1" -value "Rename-NetAdapter -InterfaceAlias ethernet -NewName `"BastionForest`""
		Add-Content -Path "$Destination\$($Prefix)ASAI\ASAI-VR\Virtual Hard Disks\ASAI-01-VR.ps1" -value "New-NetIPAddress -InterfaceAlias `"ethernet 2`" -IPAddress 192.168.1.254 -PrefixLength 24"
		Add-Content -Path "$Destination\$($Prefix)ASAI\ASAI-VR\Virtual Hard Disks\ASAI-01-VR.ps1" -Value "Rename-NetAdapter -InterfaceAlias `"ethernet 2`" -NewName `"AccountingForest`""
		Add-Content -Path "$Destination\$($Prefix)ASAI\ASAI-VR\Virtual Hard Disks\ASAI-01-VR.ps1" -value "New-NetIPAddress -InterfaceAlias `"ethernet 3`" -IPAddress 192.168.160.254 -PrefixLength 24"
		Add-Content -Path "$Destination\$($Prefix)ASAI\ASAI-VR\Virtual Hard Disks\ASAI-01-VR.ps1" -Value "Rename-NetAdapter -InterfaceAlias `"ethernet 3`" -NewName `"ResourceForest`""
		Add-Content -Path "$Destination\$($Prefix)ASAI\ASAI-VR\Virtual Hard Disks\ASAI-01-VR.ps1" -value "New-NetIPAddress -InterfaceAlias `"ethernet 4`" -IPAddress 192.168.178.5 -PrefixLength 24"
		Add-Content -Path "$Destination\$($Prefix)ASAI\ASAI-VR\Virtual Hard Disks\ASAI-01-VR.ps1" -Value "Rename-NetAdapter -InterfaceAlias `"ethernet 4`" -NewName `"EXTERN`""
		Add-Content -Path "$Destination\$($Prefix)ASAI\ASAI-VR\Virtual Hard Disks\ASAI-01-VR.ps1" -value "New-NetIPAddress -InterfaceAlias `"ethernet 5`" -IPAddress 192.168.2.254 -PrefixLength 24"
		Add-Content -Path "$Destination\$($Prefix)ASAI\ASAI-VR\Virtual Hard Disks\ASAI-01-VR.ps1" -Value "Rename-NetAdapter -InterfaceAlias `"ethernet 5`" -NewName `"STGT`""
		Add-Content -Path "$Destination\$($Prefix)ASAI\ASAI-VR\Virtual Hard Disks\ASAI-01-VR.ps1" -value "New-NetIPAddress -InterfaceAlias `"ethernet 6`" -IPAddress 192.168.3.254 -PrefixLength 24"
		Add-Content -Path "$Destination\$($Prefix)ASAI\ASAI-VR\Virtual Hard Disks\ASAI-01-VR.ps1" -Value "Rename-NetAdapter -InterfaceAlias `"ethernet 6`" -NewName `"SAIGON`""
		Add-Content -Path "$Destination\$($Prefix)ASAI\ASAI-VR\Virtual Hard Disks\ASAI-01-VR.ps1" -value "Install-WindowsFeature -Name Routing -IncludeManagementTools"
		Add-Content -Path "$Destination\$($Prefix)ASAI\ASAI-VR\Virtual Hard Disks\ASAI-01-VR.ps1" -value "Rename-Computer -NewName ASAI-VR -Restart"
		Add-Content -Path "$Destination\$($Prefix)ASAI\ASAI-VR\Virtual Hard Disks\ASAI-01-VR.cmd" -value "powershell.exe Set-ExecutionPolicy -ExecutionPolicy Unrestricted"
		Add-Content -Path "$Destination\$($Prefix)ASAI\ASAI-VR\Virtual Hard Disks\ASAI-01-VR.cmd" -value "powershell.exe -noexit C:\SetupTemp\ASAI-01-VR.ps1"
		
		Write-Verbose "Mounting ASAI-VR.vhdx and copying the automated setup files."
		$driveb4 = (Get-PSDrive).Name
		Mount-VHD -Path "$Destination\$($Prefix)ASAI\ASAI-VR\Virtual Hard Disks\ASAI-VR.vhdx"
		$driveat = (Get-PSDrive).name
		$drive = (Compare-Object -ReferenceObject $driveb4 -DifferenceObject $driveat).inputobject[-1] + ':'
		New-Item -Path $drive\SetupTemp -ItemType Directory | Out-Null
		Set-Location -Path $drive\SetupTemp | Out-Null
		Copy-Item -Path "$Destination\$($Prefix)ASAI\ASAI-VR\Virtual Hard Disks\ASAI-01-VR.cmd" -Destination . | Out-Null
		Copy-Item -Path "$Destination\$($Prefix)ASAI\ASAI-VR\Virtual Hard Disks\ASAI-01-VR.ps1" -Destination . | Out-Null
		Set-Location -Path c: | Out-Null
		Dismount-VHD -Path "$Destination\$($Prefix)ASAI\ASAI-VR\Virtual Hard Disks\ASAI-VR.vhdx"
		Write-Verbose "Dismounted ASAI-VR.vhdx successfully."
		
		#ASAI - ASAI-VPAW01
		Write-Verbose "Creating automated setup files for ASAI-VPAW01."
		New-Item -Name 01-ASAI-VPAW01.cmd -ItemType file -Path "$Destination\$($Prefix)ASAI\ASAI-VPAW01\Virtual Hard Disks\" | Out-Null
		New-Item -Name 01-ASAI-VPAW01.ps1 -ItemType file -Path "$Destination\$($Prefix)ASAI\ASAI-VPAW01\Virtual Hard Disks\" | Out-Null
		Add-Content -Path "$Destination\$($Prefix)ASAI\ASAI-VPAW01\Virtual Hard Disks\01-ASAI-VPAW01.ps1" -value "Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled false"
		Add-Content -Path "$Destination\$($Prefix)ASAI\ASAI-VPAW01\Virtual Hard Disks\01-ASAI-VPAW01.ps1" -value "Set-ItemProperty -Path `'HKLM:\System\CurrentControlSet\Control\Terminal Server`'-name `"fDenyTSConnections`" -Value 0"
		Add-Content -Path "$Destination\$($Prefix)ASAI\ASAI-VPAW01\Virtual Hard Disks\01-ASAI-VPAW01.ps1" -value "Enable-NetFirewallRule -DisplayGroup `"Remote Desktop`""
		Add-Content -Path "$Destination\$($Prefix)ASAI\ASAI-VPAW01\Virtual Hard Disks\01-ASAI-VPAW01.ps1" -value "Set-ItemProperty -Path `'HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp`' -name `"UserAuthentication`" -Value 1"
		Add-Content -Path "$Destination\$($Prefix)ASAI\ASAI-VPAW01\Virtual Hard Disks\01-ASAI-VPAW01.ps1" -value "Disable-NetAdapterBinding -InterfaceAlias ethernet -ComponentID ms_tcpip6"
		Add-Content -Path "$Destination\$($Prefix)ASAI\ASAI-VPAW01\Virtual Hard Disks\01-ASAI-VPAW01.ps1" -value "New-NetIPAddress -InterfaceAlias ethernet -IPAddress 192.168.50.4 -PrefixLength 24 -DefaultGateway 192.168.50.254"
		Add-Content -Path "$Destination\$($Prefix)ASAI\ASAI-VPAW01\Virtual Hard Disks\01-ASAI-VPAW01.ps1" -value "(Get-WmiObject -Class Win32_NetworkAdapterConfiguration | Where-Object { `$PSItem.description -like `"*hyper*`" }).settcpipnetbios(2)"
		Add-Content -Path "$Destination\$($Prefix)ASAI\ASAI-VPAW01\Virtual Hard Disks\01-ASAI-VPAW01.ps1" -value "Set-DnsClientServerAddress -InterfaceAlias ethernet -ResetServerAddresses"
		Add-Content -Path "$Destination\$($Prefix)ASAI\ASAI-VPAW01\Virtual Hard Disks\01-ASAI-VPAW01.ps1" -value "Set-DnsClientServerAddress -InterfaceAlias ethernet -ServerAddresses `"192.168.50.1`""
		Add-Content -Path "$Destination\$($Prefix)ASAI\ASAI-VPAW01\Virtual Hard Disks\01-ASAI-VPAW01.ps1" -value "New-Item -Path C:\Users\Public\Desktop -ItemType SymbolicLink -Name PowerShell.exe -Target C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe"
		Add-Content -Path "$Destination\$($Prefix)ASAI\ASAI-VPAW01\Virtual Hard Disks\01-ASAI-VPAW01.ps1" -value "New-Item -Path C:\Users\Public\Desktop -ItemType SymbolicLink -Name PowerShelliSE.exe -Target C:\Windows\System32\WindowsPowerShell\v1.0\powershell_ise.exe"
		Add-Content -Path "$Destination\$($Prefix)ASAI\ASAI-VPAW01\Virtual Hard Disks\01-ASAI-VPAW01.ps1" -value "New-Item -Path C:\Users\Public\Desktop -ItemType SymbolicLink -Name CMD.exe -Target C:\Windows\System32\cmd.exe"
		Add-Content -Path "$Destination\$($Prefix)ASAI\ASAI-VPAW01\Virtual Hard Disks\01-ASAI-VPAW01.ps1" -value "`$Cred = New-object System.Management.Automation.PSCredential `"administrator@asai-center.de`", (ConvertTo-SecureString -String `"C0mplex`" -AsPlainText -Force)"
		Add-Content -Path "$Destination\$($Prefix)ASAI\ASAI-VPAW01\Virtual Hard Disks\01-ASAI-VPAW01.ps1" -value "Add-Computer -DomainCredential `$cred -DomainName asai-center.de -NewName ASAI-VPAW01 -OUPath `"OU=Desktop,OU=PAW,OU=ESAE,DC=ASAI-CENTER,DC=DE`" -Restart"
		Add-Content -Path "$Destination\$($Prefix)ASAI\ASAI-VPAW01\Virtual Hard Disks\01-ASAI-VPAW01.cmd" -value "powershell.exe Set-ExecutionPolicy -ExecutionPolicy Unrestricted"
		Add-Content -Path "$Destination\$($Prefix)ASAI\ASAI-VPAW01\Virtual Hard Disks\01-ASAI-VPAW01.cmd" -value "powershell.exe -noexit C:\SetupTemp\01-ASAI-VPAW01.ps1"
		
		Write-Verbose "Mounting ASAI-VPAW01.vhdx and copying the automated setup files."
		$driveb4 = (Get-PSDrive).Name
		Mount-VHD -Path "$Destination\$($Prefix)ASAI\ASAI-VPAW01\Virtual Hard Disks\ASAI-VPAW01.vhdx"
		$driveat = (Get-PSDrive).name
		$drive = (Compare-Object -ReferenceObject $driveb4 -DifferenceObject $driveat).inputobject[-1] + ':'
		New-Item -Path $drive\SetupTemp -ItemType Directory | Out-Null
		Set-Location -Path $drive\SetupTemp | Out-Null
		Copy-Item -Path "$Destination\$($Prefix)ASAI\ASAI-VPAW01\Virtual Hard Disks\01-ASAI-VPAW01.cmd" -Destination . | Out-Null
		Copy-Item -Path "$Destination\$($Prefix)ASAI\ASAI-VPAW01\Virtual Hard Disks\01-ASAI-VPAW01.ps1" -Destination . | Out-Null
		Set-Location -Path c: | Out-Null
		Dismount-VHD -Path "$Destination\$($Prefix)ASAI\ASAI-VPAW01\Virtual Hard Disks\ASAI-VPAW01.vhdx"
		Write-Verbose "Dismounted ASAI-VPAW01.vhdx successfully."
		
		### VM creation ###
		Write-Verbose "Creating and post configuration of ASAI VMs."
		new-vm -Name "$($Prefix)ASAI-VDC01" -MemoryStartupBytes 1024MB -Path "$Destination\$($Prefix)ASAI\" -VHDPath "$Destination\$($Prefix)ASAI\ASAI-VDC01\Virtual Hard Disks\ASAI-VDC01.vhdx" -SwitchName $Switchname -Generation 2 | out-null
		Set-VMProcessor -VMName "$($Prefix)ASAI-VDC01" -Count $([math]::Floor($CPUCount / 4))
		new-vm -Name "$($Prefix)ASAI-VSQL01" -MemoryStartupBytes 1024MB -Path "$Destination\$($Prefix)ASAI\" -VHDPath "$Destination\$($Prefix)ASAI\ASAI-VSQL01\Virtual Hard Disks\ASAI-VSQL01.vhdx" -SwitchName $Switchname -Generation 2 | out-null
		Add-VMDvdDrive -VMName "$($Prefix)ASAI-VSQL01"
		Set-VMProcessor -VMName "$($Prefix)ASAI-VSQL01" -Count $([math]::Floor($CPUCount / 2))
		new-vm -Name "$($Prefix)ASAI-VMIM01" -MemoryStartupBytes 1024MB -Path "$Destination\$($Prefix)ASAI\" -VHDPath "$Destination\$($Prefix)ASAI\ASAI-VMIM01\Virtual Hard Disks\ASAI-VMIM01.vhdx" -SwitchName $Switchname -Generation 2 | out-null
		Add-VMDvdDrive -VMName "$($Prefix)ASAI-VMIM01"
		Set-VMProcessor -VMName "$($Prefix)ASAI-VMIM01" -Count $([math]::Floor($CPUCount / 2))
		new-vm -Name "$($Prefix)ASAI-VR" -MemoryStartupBytes 1024MB -Path "$Destination\$($Prefix)ASAI\" -VHDPath "$Destination\$($Prefix)ASAI\ASAI-VR\Virtual Hard Disks\ASAI-VR.vhdx" -SwitchName $Switchname -Generation 2 | out-null
		Set-VMProcessor -VMName "$($Prefix)ASAI-VR" -Count $([math]::Floor($CPUCount / 4))
		new-vm -Name "$($Prefix)ASAI-VPAW01" -MemoryStartupBytes 1024MB -Path "$Destination\$($Prefix)ASAI\" -VHDPath "$Destination\$($Prefix)ASAI\ASAI-VPAW01\Virtual Hard Disks\ASAI-VPAW01.vhdx" -SwitchName $Switchname -Generation 2 | out-null
		Set-VMProcessor -VMName "$($Prefix)ASAI-VPAW01" -Count $([math]::Floor($CPUCount / 4))
		Add-VMDvdDrive -VMName "$($Prefix)ASAI-VPAW01"
		Add-VMNetworkAdapter -VMName "$($Prefix)ASAI-VR" -SwitchName $Switchname
		Add-VMNetworkAdapter -VMName "$($Prefix)ASAI-VR" -SwitchName $Switchname
		Add-VMNetworkAdapter -VMName "$($Prefix)ASAI-VR" -SwitchName $Switchname
		Add-VMNetworkAdapter -VMName "$($Prefix)ASAI-VR" -SwitchName $Switchname
		Add-VMNetworkAdapter -VMName "$($Prefix)ASAI-VR" -SwitchName $Switchname
		
		Write-Verbose "Configuring dynamicMemory on every ASAI VM."
		Set-VM -VM (Get-VM -Name "$($Prefix)ASAI-*") -DynamicMemory
	}
	end
	{
		Write-Host "Created......$($Prefix)ASAI-VDC01...successfully."
		Write-Host "Created......$($Prefix)ASAI-VSQL01..successfully."
		Write-Host "Created......$($Prefix)ASAI-VMIM01..successfully."
		Write-Host "Created......$($Prefix)ASAI-VPAW01..successfully."
		Write-Host "Created......$($Prefix)ASAI-VR......successfully."
	}
}

<#
	.SYNOPSIS
		Setup for Accounting Forest - aka ads-center.de.

	.DESCRIPTION
		One DC, one member server and one workstation will be setup.
		All VMs will be generation 2.

	.PARAMETER  Destination
		Absolute path to the destination folder for the VMs.

	.PARAMETER  Server2016PD
		Absolute path to the parent disk of a Server 2016.

	.PARAMETER  Windows10PD
		Absolute path to the parent disk of a Windows 10.

	.PARAMETER  Switchname
		Defines the Hyper-V switch name.

	.PARAMETER  LegacyForest
		Defines the Forest Functional Level 2008 R2.

	.EXAMPLE
		Enable-AccountingForest -Destination $Destination -Server2016PD C:\PD\2016.vhdx -Windows10PD C:\PD\Windows10.vhdx

	.EXAMPLE
		Enable-AccountingForest $Destination C:\PD\2016.vhdx C:\PD\Windows10.vhdx

	.NOTES
		01/30/2017 Martin Handl - Version 1.0
		01/31/2017 Martin Handl - Version 1.0.1 - Subnet fixed for reverse lookup zone + added probing for hyper-v module
												- Minor bug fixes
												- Improvements and adding LegacyForest Switch
		02/01/2017 Martin Handl - Version 1.0.2 - added sequence for setup scripts
		02/02/2017 Martin Handl - Version 1.0.3 - added registry patch for DCs (TcpIpClientSupport DWORD 1)
		02/07/2017 Martin Handl - Version 1.0.4 - Prefix for VMs added
		02/08/2017 Martin Handl - Version 1.0.5 - new OU strucute (Tier0 ... Tier2)
		02/23/2017 Martin Handl - Version 1.0.6 - trust fix for PIM_TRUST applied
		03/09/2017 Martin Handl - Version 1.0.7 - name resolution to xchange-center.de added
		03/20/2017 Martin Handl - Version 1.0.8 - BreakGlass- and RedCard-Users implemented
		05/30/2017 Martin Handl - Version 1.0.9 - CPU count corrected
		09/18/2017 Martin Handl - Version 1.1.0 - RODC added + OU substructure implemented
		09/20/2017 Martin Handl - Version 1.1.1 - small bug fix in supplying credentials

	.LINK
		about_functions_advanced

	.LINK
		about_comment_based_help

#>
function Enable-AccountingForest
{
	[cmdletbinding()]
	param
	(
		[parameter(Mandatory = $true,
				   ValueFromPipelineByPropertyName = $true,
				   Position = 0)]
		$Destination,
		[parameter(Mandatory = $true,
				   ValueFromPipelineByPropertyName = $true,
				   Position = 1)]
		$Server2016PD,
		[parameter(Mandatory = $true,
				   ValueFromPipelineByPropertyName = $true,
				   Position = 2)]
		$Windows10PD,
		[parameter(Mandatory = $true,
				   ValueFromPipelineByPropertyName = $true,
				   Position = 3)]
		$switchname,
		[parameter(Position = 4)]
		[switch]$LegacyForest,
		[parameter(Position = 5)]
		$Prefix
	)
	begin
	{
		
		Write-Debug "`$Destination is $Destination"
		Write-Debug "`$Server2016PD is $Server2016PD"
		Write-Debug "`$Windows10PD is $Windows10PD"
		Write-Debug "`$switchname is $switchname"
		Write-Debug "`$Prefix is $Prefix"
		
		Write-Verbose "Evaluating the number of logical processors..."
		$CPUCount = ((Get-CimInstance -ClassName win32_processor).NumberOfLogicalProcessors | Measure-Object -Sum).sum
		
		Write-Verbose "Probing path $Destination..."
		$PathDestExist = Test-Path -Path $Destination
		switch ($PathDestExist)
		{
			$false { Write-Host -ForegroundColor Yellow -BackgroundColor Black "Path to the VM Destination `($Destination`) does not exist! Please check path and retry again. `nTerminating Script"; Break }
			Default { }
		}
		
		Write-Verbose "Probing for Hyper-V switch..."
		$HVSwitchExists = (Get-VMSwitch -Name $switchname).name
		switch ($HVSwitchExists)
		{
			$null { Write-Host "Hyper-V switch not found. Create the Hyper-V switch $switchname and retry again. `nTerminanting Script"; Break }
			Default { }
		}
		
		Write-Verbose "Probing for Hyper-V Powershell Module..."
		$HVModuleExistes = Get-Module -Name Hyper-V
		switch ($HVModuleExistes)
		{
			$null { Write-Host "Hyper-V-Module for Windows Powershell not found on this host! Please install RSAT for Hyper-V on this host an retry again. `nTerminating Script"; Break }
			Default { }
		}
		
		Write-Verbose "Probing underlying paths..."
		$PathADSExist = Test-Path -Path $Destination"\ADS"
		if ($PathADSExist -eq $true)
		{
			Write-Host "Path $Destination\ADS is present (and should not be present). Clear the path an retry the script! `nTerminating the Script"; Break
		}
		else
		{
			Write-Debug "Non of the required underlying pathes have been found - continuing the script!"
		}
		
		Write-Verbose "Probing path $Server2016PD..."
		$PathPDServer2016Exist = Test-Path -Path $Server2016PD
		switch ($PathPDServer2016Exist)
		{
			$false { Write-Host -ForegroundColor Yellow -BackgroundColor Black "Path to the parent disk for Server 2016 `($Server2016PD`) does not exist! Please check path and retry again. `nTerminating Script"; Break }
			Default { }
		}
		
		Write-Verbose "Probing path $Windows10PD..."
		$PathPDWin10Exist = Test-Path -Path $Windows10PD
		switch ($PathPDWin10Exist)
		{
			$false { Write-Host -ForegroundColor Yellow -BackgroundColor Black "Path to the parent disk for Windows 10 `($Windows10PD`) does not exist! Please check path and retry again. `nTerminating Script"; Break }
			Default { }
		}
		
		Write-Verbose "Evaluation switch parameter LegacyForest"
		switch ($LegacyForest)
		{
			$true { $ForestDomainMode = 4 }
			Default { $ForestDomainMode = 7 }
		}
	}
	
	Process
	{
		#ADS
		Write-Verbose "Creating ADS-VDC01 hard disk."
		New-VHD -ParentPath $Server2016PD -Path "$Destination\$($Prefix)ADS\ADS-VDC01\Virtual Hard Disks\ADS-VDC01.vhdx" -Differencing | Out-Null
		Write-Verbose "Created ADS-VDC01.vhdx virtual hard disk."
		Write-Verbose "Creating ADS-VDC02 hard disk."
		New-VHD -ParentPath $Server2016PD -Path "$Destination\$($Prefix)ADS\ADS-VDC02\Virtual Hard Disks\ADS-VDC02.vhdx" -Differencing | Out-Null
		Write-Verbose "Created ADS-VDC02.vhdx virtual hard disk."
		Write-Verbose "Creating ADS-VRODC01 hard disk."
		New-VHD -ParentPath $Server2016PD -Path "$Destination\$($Prefix)ADS\ADS-VRODC01\Virtual Hard Disks\ADS-VRODC01.vhdx" -Differencing | Out-Null
		Write-Verbose "Created ADS-VRODC01.vhdx virtual hard disk."
		Write-Verbose "Creating ADS-VSV01 hard disk."
		New-VHD -ParentPath $Server2016PD -Path "$Destination\$($Prefix)ADS\ADS-VSV01\Virtual Hard Disks\ADS-VSV01.vhdx" -Differencing | Out-Null
		Write-Verbose "Created ADS-VSV01.vhdx virtual hard disk."
		Write-Verbose "Creating ADS-VCL01 hard disk."
		New-VHD -ParentPath $Windows10PD -Path "$Destination\$($Prefix)ADS\ADS-VCL01\Virtual Hard Disks\ADS-VCL01.vhdx" -Differencing | Out-Null
		Write-Verbose "Created ADS-VCL01.vhdx virtual hard disk."
		
		#ADS-VDC01
		Write-Verbose "Creating automated setup files for 01-ADS-VDC01."
		New-Item -Name 01-ADS-VDC01.cmd -ItemType file -Path "$Destination\$($Prefix)ADS\ADS-VDC01\Virtual Hard Disks\" | Out-Null
		New-Item -Name 01-ADS-VDC01.ps1 -ItemType file -Path "$Destination\$($Prefix)ADS\ADS-VDC01\Virtual Hard Disks\" | Out-Null
		New-Item -Name 02-ADS-VDC01-ADDeploy.ps1 -ItemType file -Path "$Destination\$($Prefix)ADS\ADS-VDC01\Virtual Hard Disks\" | Out-Null
		New-Item -Name 02-ADS-VDC01-ADDeploy.cmd -ItemType file -Path "$Destination\$($Prefix)ADS\ADS-VDC01\Virtual Hard Disks\" | Out-Null
		New-Item -Name 03-ADS-VDC01-ADCare.ps1 -ItemType file -Path "$Destination\$($Prefix)ADS\ADS-VDC01\Virtual Hard Disks\" | Out-Null
		New-Item -Name 03-ADS-VDC01-ADCare.cmd -ItemType file -Path "$Destination\$($Prefix)ADS\ADS-VDC01\Virtual Hard Disks\" | Out-Null
		New-Item -Name 04-ADS-VDC01-RegPatch.cmd -ItemType file -Path "$Destination\$($Prefix)ADS\ADS-VDC01\Virtual Hard Disks\" | Out-Null
		New-Item -Name 04-ADS-VDC01-RegPatch.ps1 -ItemType file -Path "$Destination\$($Prefix)ADS\ADS-VDC01\Virtual Hard Disks\" | Out-Null
		New-Item -Name 05-ADS-VDC01-NameResolution.cmd -ItemType file -Path "$Destination\$($Prefix)ADS\ADS-VDC01\Virtual Hard Disks\" | Out-Null
		New-Item -Name 05-ADS-VDC01-NameResolution.ps1 -ItemType file -Path "$Destination\$($Prefix)ADS\ADS-VDC01\Virtual Hard Disks\" | Out-Null
		Add-Content -Path "$Destination\$($Prefix)ADS\ADS-VDC01\Virtual Hard Disks\01-ADS-VDC01.ps1" -value "Get-ScheduledTask -TaskName servermanager | Disable-ScheduledTask"
		Add-Content -Path "$Destination\$($Prefix)ADS\ADS-VDC01\Virtual Hard Disks\01-ADS-VDC01.ps1" -value "Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled false"
		Add-Content -Path "$Destination\$($Prefix)ADS\ADS-VDC01\Virtual Hard Disks\01-ADS-VDC01.ps1" -value "Set-ItemProperty -Path `'HKLM:\System\CurrentControlSet\Control\Terminal Server`'-name `"fDenyTSConnections`" -Value 0"
		Add-Content -Path "$Destination\$($Prefix)ADS\ADS-VDC01\Virtual Hard Disks\01-ADS-VDC01.ps1" -value "Enable-NetFirewallRule -DisplayGroup `"Remote Desktop`""
		Add-Content -Path "$Destination\$($Prefix)ADS\ADS-VDC01\Virtual Hard Disks\01-ADS-VDC01.ps1" -value "Set-ItemProperty -Path `'HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp`' -name `"UserAuthentication`" -Value 1"
		Add-Content -Path "$Destination\$($Prefix)ADS\ADS-VDC01\Virtual Hard Disks\01-ADS-VDC01.ps1" -value "Disable-NetAdapterBinding -InterfaceAlias ethernet -ComponentID ms_tcpip6"
		Add-Content -Path "$Destination\$($Prefix)ADS\ADS-VDC01\Virtual Hard Disks\01-ADS-VDC01.ps1" -value "New-NetIPAddress -InterfaceAlias ethernet -IPAddress 192.168.1.1 -PrefixLength 24 -DefaultGateway 192.168.1.254"
		Add-Content -Path "$Destination\$($Prefix)ADS\ADS-VDC01\Virtual Hard Disks\01-ADS-VDC01.ps1" -value "(Get-WmiObject -Class Win32_NetworkAdapterConfiguration | Where-Object { `$PSItem.description -like `"*hyper*`" }).settcpipnetbios(2)"
		Add-Content -Path "$Destination\$($Prefix)ADS\ADS-VDC01\Virtual Hard Disks\01-ADS-VDC01.ps1" -value "Set-DnsClientServerAddress -InterfaceAlias ethernet -ResetServerAddresses"
		Add-Content -Path "$Destination\$($Prefix)ADS\ADS-VDC01\Virtual Hard Disks\01-ADS-VDC01.ps1" -value "Set-DnsClientServerAddress -InterfaceAlias ethernet -ServerAddresses `"192.168.1.1`""
		Add-Content -Path "$Destination\$($Prefix)ADS\ADS-VDC01\Virtual Hard Disks\01-ADS-VDC01.ps1" -value "Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools"
		Add-Content -Path "$Destination\$($Prefix)ADS\ADS-VDC01\Virtual Hard Disks\01-ADS-VDC01.ps1" -value "Rename-Computer -NewName ADS-VDC01 -Restart"
		Add-Content -Path "$Destination\$($Prefix)ADS\ADS-VDC01\Virtual Hard Disks\02-ADS-VDC01-ADDeploy.ps1" -value "Import-Module ADDSDeployment"
		Add-Content -Path "$Destination\$($Prefix)ADS\ADS-VDC01\Virtual Hard Disks\02-ADS-VDC01-ADDeploy.ps1" -value "Install-ADDSForest -CreateDnsDelegation:`$false -DatabasePath `"C:\Windows\NTDS`" -DomainMode $ForestDomainMode -DomainName `"ads-center.de`" -DomainNetbiosName `"ADS`" -ForestMode $ForestDomainMode -InstallDns:`$true -LogPath `"C:\Windows\NTDS`" -NoRebootOnCompletion:`$false -SafeModeAdministratorPassword (ConvertTo-SecureString -String `"C0mplex`" -AsPlainText -Force) -SysvolPath `"C:\Windows\SYSVOL`" -Force:`$true"
		Add-Content -Path "$Destination\$($Prefix)ADS\ADS-VDC01\Virtual Hard Disks\03-ADS-VDC01-ADCare.ps1" -value "Add-DnsServerPrimaryZone -Name 1.168.192.in-addr.arpa -DynamicUpdate Secure -ReplicationScope Forest"
		Add-Content -Path "$Destination\$($Prefix)ADS\ADS-VDC01\Virtual Hard Disks\03-ADS-VDC01-ADCare.ps1" -value "Set-DnsClientServerAddress -InterfaceAlias ethernet -ServerAddresses `"192.168.1.1`""
		Add-Content -Path "$Destination\$($Prefix)ADS\ADS-VDC01\Virtual Hard Disks\03-ADS-VDC01-ADCare.ps1" -value "Set-ADObject -Identity `"CN=DEFAULTIPSITELINK,CN=IP,CN=Inter-Site Transports,CN=Sites,CN=Configuration,DC=ads-center,DC=de`" -Replace `@{ options `= 7 }"
		Add-Content -Path "$Destination\$($Prefix)ADS\ADS-VDC01\Virtual Hard Disks\03-ADS-VDC01-ADCare.ps1" -value "New-ADReplicationSite -Name STGT"
		Add-Content -Path "$Destination\$($Prefix)ADS\ADS-VDC01\Virtual Hard Disks\03-ADS-VDC01-ADCare.ps1" -value "New-ADReplicationSubnet -Name `"192.168.2.0/24`" -Site STGT -Location `"Stuttgart, Germany`""
		Add-Content -Path "$Destination\$($Prefix)ADS\ADS-VDC01\Virtual Hard Disks\03-ADS-VDC01-ADCare.ps1" -value "New-ADReplicationSite -Name SAIGON"
		Add-Content -Path "$Destination\$($Prefix)ADS\ADS-VDC01\Virtual Hard Disks\03-ADS-VDC01-ADCare.ps1" -value "New-ADReplicationSubnet -Name `"192.168.3.0/24`" -Site SAIGON -Location `"SAIGON, Vietnam`""
		Add-Content -Path "$Destination\$($Prefix)ADS\ADS-VDC01\Virtual Hard Disks\03-ADS-VDC01-ADCare.ps1" -value "Rename-ADObject -NewName `"BB`" -Identity `"CN=Default-First-Site-Name,CN=Sites,CN=Configuration,DC=ads-center,DC=de`""
		Add-Content -Path "$Destination\$($Prefix)ADS\ADS-VDC01\Virtual Hard Disks\03-ADS-VDC01-ADCare.ps1" -value "New-ADReplicationSubnet -Name 192.168.1.0/24 -Location `"Boeblingen, Germany`" -Site `"BB`""
		Add-Content -Path "$Destination\$($Prefix)ADS\ADS-VDC01\Virtual Hard Disks\03-ADS-VDC01-ADCare.ps1" -value "Set-ADReplicationSiteLink -Identity defaultipsitelink -SitesIncluded @{ Add = `$((Get-ADReplicationSite -Filter { name -like `"*`" }).name) }"
		Add-Content -Path "$Destination\$($Prefix)ADS\ADS-VDC01\Virtual Hard Disks\03-ADS-VDC01-ADCare.ps1" -value "New-ADOrganizationalUnit -Name ESAE"
		Add-Content -Path "$Destination\$($Prefix)ADS\ADS-VDC01\Virtual Hard Disks\03-ADS-VDC01-ADCare.ps1" -value "New-ADOrganizationalUnit -Name PAW -Path `"OU=ESAE,DC=ADS-CENTER,DC=DE`""
		Add-Content -Path "$Destination\$($Prefix)ADS\ADS-VDC01\Virtual Hard Disks\03-ADS-VDC01-ADCare.ps1" -value "New-ADOrganizationalUnit -Name Desktop -Path `"OU=PAW,OU=ESAE,DC=ADS-CENTER,DC=DE`""
		Add-Content -Path "$Destination\$($Prefix)ADS\ADS-VDC01\Virtual Hard Disks\03-ADS-VDC01-ADCare.ps1" -value "New-ADOrganizationalUnit -Name Mobile -Path `"OU=PAW,OU=ESAE,DC=ADS-CENTER,DC=DE`""
		Add-Content -Path "$Destination\$($Prefix)ADS\ADS-VDC01\Virtual Hard Disks\03-ADS-VDC01-ADCare.ps1" -value "New-ADOrganizationalUnit -Name Tier0 -Path `"OU=ESAE,DC=ADS-CENTER,DC=DE`""
		Add-Content -Path "$Destination\$($Prefix)ADS\ADS-VDC01\Virtual Hard Disks\03-ADS-VDC01-ADCare.ps1" -value "New-ADOrganizationalUnit -Name AD -Path `"OU=Tier0,OU=ESAE,DC=ADS-CENTER,DC=DE`""
		Add-Content -Path "$Destination\$($Prefix)ADS\ADS-VDC01\Virtual Hard Disks\03-ADS-VDC01-ADCare.ps1" -value "New-ADOrganizationalUnit -Name PKI -Path `"OU=Tier0,OU=ESAE,DC=ADS-CENTER,DC=DE`""
		Add-Content -Path "$Destination\$($Prefix)ADS\ADS-VDC01\Virtual Hard Disks\03-ADS-VDC01-ADCare.ps1" -value "New-ADOrganizationalUnit -Name GroupPolicy -Path `"OU=Tier0,OU=ESAE,DC=ADS-CENTER,DC=DE`""
		Add-Content -Path "$Destination\$($Prefix)ADS\ADS-VDC01\Virtual Hard Disks\03-ADS-VDC01-ADCare.ps1" -value "New-ADOrganizationalUnit -Name Accounts -Path `"OU=AD,OU=Tier0,OU=ESAE,DC=ADS-CENTER,DC=DE`""
		Add-Content -Path "$Destination\$($Prefix)ADS\ADS-VDC01\Virtual Hard Disks\03-ADS-VDC01-ADCare.ps1" -value "New-ADOrganizationalUnit -Name Groups -Path `"OU=AD,OU=Tier0,OU=ESAE,DC=ADS-CENTER,DC=DE`""
		Add-Content -Path "$Destination\$($Prefix)ADS\ADS-VDC01\Virtual Hard Disks\03-ADS-VDC01-ADCare.ps1" -value "New-ADOrganizationalUnit -Name Servers -Path `"OU=AD,OU=Tier0,OU=ESAE,DC=ADS-CENTER,DC=DE`""
		Add-Content -Path "$Destination\$($Prefix)ADS\ADS-VDC01\Virtual Hard Disks\03-ADS-VDC01-ADCare.ps1" -value "New-ADOrganizationalUnit -Name Accounts -Path `"OU=PKI,OU=Tier0,OU=ESAE,DC=ADS-CENTER,DC=DE`""
		Add-Content -Path "$Destination\$($Prefix)ADS\ADS-VDC01\Virtual Hard Disks\03-ADS-VDC01-ADCare.ps1" -value "New-ADOrganizationalUnit -Name Groups -Path `"OU=PKI,OU=Tier0,OU=ESAE,DC=ADS-CENTER,DC=DE`""
		Add-Content -Path "$Destination\$($Prefix)ADS\ADS-VDC01\Virtual Hard Disks\03-ADS-VDC01-ADCare.ps1" -value "New-ADOrganizationalUnit -Name Servers -Path `"OU=PKI,OU=Tier0,OU=ESAE,DC=ADS-CENTER,DC=DE`""
		Add-Content -Path "$Destination\$($Prefix)ADS\ADS-VDC01\Virtual Hard Disks\03-ADS-VDC01-ADCare.ps1" -value "New-ADOrganizationalUnit -Name Accounts -Path `"OU=GroupPolicy,OU=Tier0,OU=ESAE,DC=ADS-CENTER,DC=DE`""
		Add-Content -Path "$Destination\$($Prefix)ADS\ADS-VDC01\Virtual Hard Disks\03-ADS-VDC01-ADCare.ps1" -value "New-ADOrganizationalUnit -Name Groups -Path `"OU=GroupPolicy,OU=Tier0,OU=ESAE,DC=ADS-CENTER,DC=DE`""
		Add-Content -Path "$Destination\$($Prefix)ADS\ADS-VDC01\Virtual Hard Disks\03-ADS-VDC01-ADCare.ps1" -value "New-ADOrganizationalUnit -Name Servers -Path `"OU=GroupPolicy,OU=Tier0,OU=ESAE,DC=ADS-CENTER,DC=DE`""
		Add-Content -Path "$Destination\$($Prefix)ADS\ADS-VDC01\Virtual Hard Disks\03-ADS-VDC01-ADCare.ps1" -value "New-ADUser -Name T0-DomAdmin1 -SamAccountName T0-DomAdmin1 -UserPrincipalName T0-DomAdmin1@ads-center.de -AccountPassword (ConvertTo-SecureString -AsPlainText -Force -String `"C0mplex`") -Path `"OU=Accounts,OU=AD,OU=Tier0,OU=ESAE,DC=ADS-CENTER,DC=DE`" -Enabled `$true"
		Add-Content -Path "$Destination\$($Prefix)ADS\ADS-VDC01\Virtual Hard Disks\03-ADS-VDC01-ADCare.ps1" -value "New-ADUser -Name T0-SchMhandl -SamAccountName T0-SchMhandl -UserPrincipalName T0-SchMhandl@ads-center.de -AccountPassword (ConvertTo-SecureString -AsPlainText -Force -String `"C0mplex`") -Path `"OU=Accounts,OU=AD,OU=Tier0,OU=ESAE,DC=ADS-CENTER,DC=DE`" -Enabled `$true -Description `"SCAMA User`""
		Add-Content -Path "$Destination\$($Prefix)ADS\ADS-VDC01\Virtual Hard Disks\03-ADS-VDC01-ADCare.ps1" -value "New-ADUser -Name T0-SchDturner -SamAccountName T0-SchDturner -UserPrincipalName T0-SchDturner@ads-center.de -AccountPassword (ConvertTo-SecureString -AsPlainText -Force -String `"C0mplex`") -Path `"OU=Accounts,OU=AD,OU=Tier0,OU=ESAE,DC=ADS-CENTER,DC=DE`" -Enabled `$true -Description `"SCAMA User`""
		Add-Content -Path "$Destination\$($Prefix)ADS\ADS-VDC01\Virtual Hard Disks\03-ADS-VDC01-ADCare.ps1" -value "New-ADUser -Name T0-SchTpham -SamAccountName T0-SchTpham -UserPrincipalName T0-SchTpham@ads-center.de -AccountPassword (ConvertTo-SecureString -AsPlainText -Force -String `"C0mplex`") -Path `"OU=Accounts,OU=AD,OU=Tier0,OU=ESAE,DC=ADS-CENTER,DC=DE`" -Enabled `$true -Description `"SCAMA User`""
		Add-Content -Path "$Destination\$($Prefix)ADS\ADS-VDC01\Virtual Hard Disks\03-ADS-VDC01-ADCare.ps1" -value "New-ADUser -Name T0-EntMhandl -SamAccountName T0-EntMhandl -UserPrincipalName T0-EntMhandl@ads-center.de -AccountPassword (ConvertTo-SecureString -AsPlainText -Force -String `"C0mplex`") -Path `"OU=Accounts,OU=AD,OU=Tier0,OU=ESAE,DC=ADS-CENTER,DC=DE`" -Enabled `$true -Description `"SCAMA User`""
		Add-Content -Path "$Destination\$($Prefix)ADS\ADS-VDC01\Virtual Hard Disks\03-ADS-VDC01-ADCare.ps1" -value "New-ADUser -Name T0-EntDturner -SamAccountName T0-EntDturner -UserPrincipalName T0-EntDturner@ads-center.de -AccountPassword (ConvertTo-SecureString -AsPlainText -Force -String `"C0mplex`") -Path `"OU=Accounts,OU=AD,OU=Tier0,OU=ESAE,DC=ADS-CENTER,DC=DE`" -Enabled `$true -Description `"SCAMA User`""
		Add-Content -Path "$Destination\$($Prefix)ADS\ADS-VDC01\Virtual Hard Disks\03-ADS-VDC01-ADCare.ps1" -value "New-ADUser -Name T0-EntTpham -SamAccountName T0-EntTpham -UserPrincipalName T0-EntTpham@ads-center.de -AccountPassword (ConvertTo-SecureString -AsPlainText -Force -String `"C0mplex`") -Path `"OU=Accounts,OU=AD,OU=Tier0,OU=ESAE,DC=ADS-CENTER,DC=DE`" -Enabled `$true -Description `"SCAMA User`""
		Add-Content -Path "$Destination\$($Prefix)ADS\ADS-VDC01\Virtual Hard Disks\03-ADS-VDC01-ADCare.ps1" -value "New-ADUser -Name T0-DomMhandl -SamAccountName T0-DomMhandl -UserPrincipalName T0-DomMhandl@ads-center.de -AccountPassword (ConvertTo-SecureString -AsPlainText -Force -String `"C0mplex`") -Path `"OU=Accounts,OU=AD,OU=Tier0,OU=ESAE,DC=ADS-CENTER,DC=DE`" -Enabled `$true -Description `"SCAMA User`""
		Add-Content -Path "$Destination\$($Prefix)ADS\ADS-VDC01\Virtual Hard Disks\03-ADS-VDC01-ADCare.ps1" -value "New-ADUser -Name T0-DomDturner -SamAccountName T0-DomDturner -UserPrincipalName T0-DomDturner@ads-center.de -AccountPassword (ConvertTo-SecureString -AsPlainText -Force -String `"C0mplex`") -Path `"OU=Accounts,OU=AD,OU=Tier0,OU=ESAE,DC=ADS-CENTER,DC=DE`" -Enabled `$true -Description `"SCAMA User`""
		Add-Content -Path "$Destination\$($Prefix)ADS\ADS-VDC01\Virtual Hard Disks\03-ADS-VDC01-ADCare.ps1" -value "New-ADUser -Name T0-DomTpham -SamAccountName T0-DomTpham -UserPrincipalName T0-DomTpham@ads-center.de -AccountPassword (ConvertTo-SecureString -AsPlainText -Force -String `"C0mplex`") -Path `"OU=Accounts,OU=AD,OU=Tier0,OU=ESAE,DC=ADS-CENTER,DC=DE`" -Enabled `$true -Description `"SCAMA User`""
		Add-Content -Path "$Destination\$($Prefix)ADS\ADS-VDC01\Virtual Hard Disks\03-ADS-VDC01-ADCare.ps1" -value "New-ADGroup -Name T0-SchAdmins -GroupCategory Security -GroupScope Universal -Path `"OU=Groups,OU=AD,OU=Tier0,OU=ESAE,DC=ADS-CENTER,DC=DE`" -Description `"BreakGlass User`""
		Add-Content -Path "$Destination\$($Prefix)ADS\ADS-VDC01\Virtual Hard Disks\03-ADS-VDC01-ADCare.ps1" -value "New-ADGroup -Name T0-EntAdmins -GroupCategory Security -GroupScope Universal -Path `"OU=Groups,OU=AD,OU=Tier0,OU=ESAE,DC=ADS-CENTER,DC=DE`" -Description `"BreakGlass User`""
		Add-Content -Path "$Destination\$($Prefix)ADS\ADS-VDC01\Virtual Hard Disks\03-ADS-VDC01-ADCare.ps1" -value "New-ADGroup -Name T0-DomAdmins -GroupCategory Security -GroupScope Universal -Path `"OU=Groups,OU=AD,OU=Tier0,OU=ESAE,DC=ADS-CENTER,DC=DE`" -Description `"BreakGlass User`""
		Add-Content -Path "$Destination\$($Prefix)ADS\ADS-VDC01\Virtual Hard Disks\03-ADS-VDC01-ADCare.ps1" -value "New-ADUser -Name T0-Mhandl -SamAccountName T0-Mhandl -UserPrincipalName T0-Mhandl@ads-center.de -AccountPassword (ConvertTo-SecureString -AsPlainText -Force -String `"C0mplex`") -Path `"OU=Accounts,OU=AD,OU=Tier0,OU=ESAE,DC=ADS-CENTER,DC=DE`" -Enabled `$true -Description `"PAM User`""
		Add-Content -Path "$Destination\$($Prefix)ADS\ADS-VDC01\Virtual Hard Disks\03-ADS-VDC01-ADCare.ps1" -value "New-ADUser -Name T0-Dturner -SamAccountName T0-Dturner -UserPrincipalName T0-Dturner@ads-center.de -AccountPassword (ConvertTo-SecureString -AsPlainText -Force -String `"C0mplex`") -Path `"OU=Accounts,OU=AD,OU=Tier0,OU=ESAE,DC=ADS-CENTER,DC=DE`" -Enabled `$true -Description `"PAM User`""
		Add-Content -Path "$Destination\$($Prefix)ADS\ADS-VDC01\Virtual Hard Disks\03-ADS-VDC01-ADCare.ps1" -value "New-ADUser -Name T0-Tpham -SamAccountName T0-Tpham -UserPrincipalName T0-Tpham@ads-center.de -AccountPassword (ConvertTo-SecureString -AsPlainText -Force -String `"C0mplex`") -Path `"OU=Accounts,OU=AD,OU=Tier0,OU=ESAE,DC=ADS-CENTER,DC=DE`" -Enabled `$true -Description `"PAM User`""
		Add-Content -Path "$Destination\$($Prefix)ADS\ADS-VDC01\Virtual Hard Disks\03-ADS-VDC01-ADCare.ps1" -value "Add-ADGroupMember -Identity `"Schema Admins`" -Members `"T0-SchAdmins`""
		Add-Content -Path "$Destination\$($Prefix)ADS\ADS-VDC01\Virtual Hard Disks\03-ADS-VDC01-ADCare.ps1" -value "Add-ADGroupMember -Identity `"Enterprise Admins`" -Members `"T0-EntAdmins`""
		Add-Content -Path "$Destination\$($Prefix)ADS\ADS-VDC01\Virtual Hard Disks\03-ADS-VDC01-ADCare.ps1" -value "New-ADOrganizationalUnit -Name Tier1 -Path `"OU=ESAE,DC=ADS-CENTER,DC=DE`""
		Add-Content -Path "$Destination\$($Prefix)ADS\ADS-VDC01\Virtual Hard Disks\03-ADS-VDC01-ADCare.ps1" -value "New-ADOrganizationalUnit -Name Accounts -Path `"OU=Tier1,OU=ESAE,DC=ADS-CENTER,DC=DE`""
		Add-Content -Path "$Destination\$($Prefix)ADS\ADS-VDC01\Virtual Hard Disks\03-ADS-VDC01-ADCare.ps1" -value "New-ADOrganizationalUnit -Name Groups -Path `"OU=Tier1,OU=ESAE,DC=ADS-CENTER,DC=DE`""
		Add-Content -Path "$Destination\$($Prefix)ADS\ADS-VDC01\Virtual Hard Disks\03-ADS-VDC01-ADCare.ps1" -value "New-ADOrganizationalUnit -Name Servers -Path `"OU=Tier1,OU=ESAE,DC=ADS-CENTER,DC=DE`""
		Add-Content -Path "$Destination\$($Prefix)ADS\ADS-VDC01\Virtual Hard Disks\03-ADS-VDC01-ADCare.ps1" -value "New-ADUser -Name T1-Admin1 -SamAccountName T1-Admin1 -UserPrincipalName T1-Admin1@ads-center.de -AccountPassword (ConvertTo-SecureString -AsPlainText -Force -String `"C0mplex`") -Path `"OU=Accounts,OU=Tier1,OU=ESAE,DC=ADS-CENTER,DC=DE`" -Enabled `$true"
		Add-Content -Path "$Destination\$($Prefix)ADS\ADS-VDC01\Virtual Hard Disks\03-ADS-VDC01-ADCare.ps1" -value "New-ADUser -Name T1-Admin2 -SamAccountName T1-Admin2 -UserPrincipalName T1-Admin2@ads-center.de -AccountPassword (ConvertTo-SecureString -AsPlainText -Force -String `"C0mplex`") -Path `"OU=Accounts,OU=Tier1,OU=ESAE,DC=ADS-CENTER,DC=DE`" -Enabled `$true"
		Add-Content -Path "$Destination\$($Prefix)ADS\ADS-VDC01\Virtual Hard Disks\03-ADS-VDC01-ADCare.ps1" -value "New-ADUser -Name T1-Admin3 -SamAccountName T1-Admin3 -UserPrincipalName T1-Admin3@ads-center.de -AccountPassword (ConvertTo-SecureString -AsPlainText -Force -String `"C0mplex`") -Path `"OU=Accounts,OU=Tier1,OU=ESAE,DC=ADS-CENTER,DC=DE`" -Enabled `$true"
		Add-Content -Path "$Destination\$($Prefix)ADS\ADS-VDC01\Virtual Hard Disks\03-ADS-VDC01-ADCare.ps1" -value "New-ADOrganizationalUnit -Name Tier2 -Path `"OU=ESAE,DC=ADS-CENTER,DC=DE`""
		Add-Content -Path "$Destination\$($Prefix)ADS\ADS-VDC01\Virtual Hard Disks\03-ADS-VDC01-ADCare.ps1" -value "New-ADOrganizationalUnit -Name Accounts -Path `"OU=Tier2,OU=ESAE,DC=ADS-CENTER,DC=DE`""
		Add-Content -Path "$Destination\$($Prefix)ADS\ADS-VDC01\Virtual Hard Disks\03-ADS-VDC01-ADCare.ps1" -value "New-ADOrganizationalUnit -Name Groups -Path `"OU=Tier2,OU=ESAE,DC=ADS-CENTER,DC=DE`""
		Add-Content -Path "$Destination\$($Prefix)ADS\ADS-VDC01\Virtual Hard Disks\03-ADS-VDC01-ADCare.ps1" -value "New-ADOrganizationalUnit -Name Servers -Path `"OU=Tier2,OU=ESAE,DC=ADS-CENTER,DC=DE`""
		Add-Content -Path "$Destination\$($Prefix)ADS\ADS-VDC01\Virtual Hard Disks\03-ADS-VDC01-ADCare.ps1" -value "New-ADOrganizationalUnit -Name IT -Path `"DC=ADS-CENTER,DC=DE`""
		Add-Content -Path "$Destination\$($Prefix)ADS\ADS-VDC01\Virtual Hard Disks\03-ADS-VDC01-ADCare.ps1" -value "New-ADOrganizationalUnit -Name Users -Path `"OU=IT,DC=ADS-CENTER,DC=DE`""
		Add-Content -Path "$Destination\$($Prefix)ADS\ADS-VDC01\Virtual Hard Disks\03-ADS-VDC01-ADCare.ps1" -value "New-ADOrganizationalUnit -Name Groups -Path `"OU=IT,DC=ADS-CENTER,DC=DE`""
		Add-Content -Path "$Destination\$($Prefix)ADS\ADS-VDC01\Virtual Hard Disks\03-ADS-VDC01-ADCare.ps1" -value "New-ADUser -Name Tpham -SamAccountName Tpham -UserPrincipalName Tpham@ads-center.de -AccountPassword (ConvertTo-SecureString -AsPlainText -Force -String `"C0mplex`") -Path `"OU=Users,OU=IT,DC=ADS-CENTER,DC=DE`" -Enabled `$true -EmailAddress Tpham@ads-center.de -Description `"Regular User Account`""
		Add-Content -Path "$Destination\$($Prefix)ADS\ADS-VDC01\Virtual Hard Disks\03-ADS-VDC01-ADCare.ps1" -value "New-ADUser -Name DTurner -SamAccountName DTurner -UserPrincipalName DTurner@ads-center.de -AccountPassword (ConvertTo-SecureString -AsPlainText -Force -String `"C0mplex`") -Path `"OU=Users,OU=IT,DC=ADS-CENTER,DC=DE`" -Enabled `$true -EmailAddress Dturner@ads-center.de -Description `"Regular User Account`""
		Add-Content -Path "$Destination\$($Prefix)ADS\ADS-VDC01\Virtual Hard Disks\03-ADS-VDC01-ADCare.ps1" -value "New-ADUser -Name MHandl -SamAccountName MHandl -UserPrincipalName MHandl@ads-center.de -AccountPassword (ConvertTo-SecureString -AsPlainText -Force -String `"C0mplex`") -Path `"OU=Users,OU=IT,DC=ADS-CENTER,DC=DE`" -Enabled `$true -EmailAddress Mhandl@ads-center.de -Description `"Regular User Account`""
		Add-Content -Path "$Destination\$($Prefix)ADS\ADS-VDC01\Virtual Hard Disks\03-ADS-VDC01-ADCare.ps1" -value "New-ADUser -Name T2-Admin1 -SamAccountName T2-Admin1 -UserPrincipalName T2-Admin1@ads-center.de -AccountPassword (ConvertTo-SecureString -AsPlainText -Force -String `"C0mplex`") -Path `"OU=Accounts,OU=Tier2,OU=ESAE,DC=ADS-CENTER,DC=DE`" -Enabled `$true"
		Add-Content -Path "$Destination\$($Prefix)ADS\ADS-VDC01\Virtual Hard Disks\03-ADS-VDC01-ADCare.ps1" -value "New-ADUser -Name T2-Admin2 -SamAccountName T2-Admin2 -UserPrincipalName T2-Admin2@ads-center.de -AccountPassword (ConvertTo-SecureString -AsPlainText -Force -String `"C0mplex`") -Path `"OU=Accounts,OU=Tier2,OU=ESAE,DC=ADS-CENTER,DC=DE`" -Enabled `$true"
		Add-Content -Path "$Destination\$($Prefix)ADS\ADS-VDC01\Virtual Hard Disks\03-ADS-VDC01-ADCare.ps1" -value "New-ADUser -Name T2-Admin3 -SamAccountName T2-Admin3 -UserPrincipalName T2-Admin3@ads-center.de -AccountPassword (ConvertTo-SecureString -AsPlainText -Force -String `"C0mplex`") -Path `"OU=Accounts,OU=Tier2,OU=ESAE,DC=ADS-CENTER,DC=DE`" -Enabled `$true"
		Add-Content -Path "$Destination\$($Prefix)ADS\ADS-VDC01\Virtual Hard Disks\03-ADS-VDC01-ADCare.ps1" -value "New-ADGroup -Name `'ADS`$`$`$`' -GroupCategory Security -GroupScope DomainLocal -Path `"CN=Users,DC=ads-center,dc=de`""
		Add-Content -Path "$Destination\$($Prefix)ADS\ADS-VDC01\Virtual Hard Disks\03-ADS-VDC01-ADCare.ps1" -value "New-ADGroup -Name `'ADS-CENTER.DE`$`$`$`' -GroupCategory Security -GroupScope DomainLocal -Path `"CN=Users,DC=ads-center,dc=de`""
		Add-Content -Path "$Destination\$($Prefix)ADS\ADS-VDC01\Virtual Hard Disks\01-ADS-VDC01.cmd" -value "powershell.exe Set-ExecutionPolicy -ExecutionPolicy Unrestricted"
		Add-Content -Path "$Destination\$($Prefix)ADS\ADS-VDC01\Virtual Hard Disks\01-ADS-VDC01.cmd" -value "powershell.exe -noexit C:\SetupTemp\01-ADS-VDC01.ps1"
		Add-Content -Path "$Destination\$($Prefix)ADS\ADS-VDC01\Virtual Hard Disks\02-ADS-VDC01-ADDeploy.cmd" -value "powershell.exe Set-ExecutionPolicy -ExecutionPolicy Unrestricted"
		Add-Content -Path "$Destination\$($Prefix)ADS\ADS-VDC01\Virtual Hard Disks\02-ADS-VDC01-ADDeploy.cmd" -value "powershell.exe -noexit C:\SetupTemp\02-ADS-VDC01-ADDeploy.ps1"
		Add-Content -Path "$Destination\$($Prefix)ADS\ADS-VDC01\Virtual Hard Disks\03-ADS-VDC01-ADCare.cmd" -value "powershell.exe Set-ExecutionPolicy -ExecutionPolicy Unrestricted"
		Add-Content -Path "$Destination\$($Prefix)ADS\ADS-VDC01\Virtual Hard Disks\03-ADS-VDC01-ADCare.cmd" -value "powershell.exe -noexit C:\SetupTemp\03-ADS-VDC01-ADCare.ps1"
		Add-Content -Path "$Destination\$($Prefix)ADS\ADS-VDC01\Virtual Hard Disks\04-ADS-VDC01-RegPatch.cmd" -value "powershell.exe -noexit C:\SetupTemp\04-ADS-VDC01-RegPatch.ps1"
		Add-Content -Path "$Destination\$($Prefix)ADS\ADS-VDC01\Virtual Hard Disks\04-ADS-VDC01-RegPatch.ps1" -value "Set-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\Control\Lsa\ -Name TcpIpClientSupport -Type DWORD -Value 1"
		Add-Content -Path "$Destination\$($Prefix)ADS\ADS-VDC01\Virtual Hard Disks\05-ADS-VDC01-NameResolution.cmd" -value "powershell.exe -noexit C:\SetupTemp\05-ADS-VDC01-NameResolution.ps1"
		Add-Content -Path "$Destination\$($Prefix)ADS\ADS-VDC01\Virtual Hard Disks\05-ADS-VDC01-NameResolution.ps1" -value "Add-DnsServerConditionalForwarderZone -ZoneName asai-center.de -ReplicationScope Forest -MasterServers 192.168.50.1"
		Add-Content -Path "$Destination\$($Prefix)ADS\ADS-VDC01\Virtual Hard Disks\05-ADS-VDC01-NameResolution.ps1" -value "Add-DnsServerConditionalForwarderZone -ZoneName 50.168.192.in-addr.arpa -ReplicationScope Forest -MasterServers 192.168.50.1"
		Add-Content -Path "$Destination\$($Prefix)ADS\ADS-VDC01\Virtual Hard Disks\05-ADS-VDC01-NameResolution.ps1" -value "Add-DnsServerConditionalForwarderZone -ZoneName xchange-center.de -ReplicationScope Forest -MasterServers 192.168.160.1"
		Add-Content -Path "$Destination\$($Prefix)ADS\ADS-VDC01\Virtual Hard Disks\05-ADS-VDC01-NameResolution.ps1" -value "Add-DnsServerConditionalForwarderZone -ZoneName 160.168.192.in-addr.arpa -ReplicationScope Forest -MasterServers 192.168.160.1"
		Add-Content -Path "$Destination\$($Prefix)ADS\ADS-VDC01\Virtual Hard Disks\06-ADS-VDC01-TrustFix.cmd" -value "netdom trust ads-center.de /domain:asai-center.de /quarantine:no /userd:administrator /passwordd:C0mplex"
		
		Write-Verbose "Mounting ADS-VDC01.vhdx and copying the automated setup files."
		$driveb4 = (Get-PSDrive).Name
		Mount-VHD -Path "$Destination\$($Prefix)ADS\ADS-VDC01\Virtual Hard Disks\ADS-VDC01.vhdx"
		$driveat = (Get-PSDrive).name
		$drive = (Compare-Object -ReferenceObject $driveb4 -DifferenceObject $driveat).inputobject[-1] + ':'
		New-Item -Path $drive\SetupTemp -ItemType Directory | Out-Null
		Set-Location -Path $drive\SetupTemp | Out-Null
		Copy-Item -Path "$Destination\$($Prefix)ADS\ADS-VDC01\Virtual Hard Disks\01-ADS-VDC01.cmd" -Destination . | Out-Null
		Copy-Item -Path "$Destination\$($Prefix)ADS\ADS-VDC01\Virtual Hard Disks\01-ADS-VDC01.ps1" -Destination . | Out-Null
		Copy-Item -Path "$Destination\$($Prefix)ADS\ADS-VDC01\Virtual Hard Disks\02-ADS-VDC01-ADDeploy.ps1" -Destination . | Out-Null
		Copy-Item -Path "$Destination\$($Prefix)ADS\ADS-VDC01\Virtual Hard Disks\02-ADS-VDC01-ADDeploy.cmd" -Destination . | Out-Null
		Copy-Item -Path "$Destination\$($Prefix)ADS\ADS-VDC01\Virtual Hard Disks\03-ADS-VDC01-ADCare.ps1" -Destination . | Out-Null
		Copy-Item -Path "$Destination\$($Prefix)ADS\ADS-VDC01\Virtual Hard Disks\03-ADS-VDC01-ADCare.cmd" -Destination . | Out-Null
		Copy-Item -Path "$Destination\$($Prefix)ADS\ADS-VDC01\Virtual Hard Disks\04-ADS-VDC01-RegPatch.cmd" -Destination . | Out-Null
		Copy-Item -Path "$Destination\$($Prefix)ADS\ADS-VDC01\Virtual Hard Disks\04-ADS-VDC01-RegPatch.ps1" -Destination . | Out-Null
		Copy-Item -Path "$Destination\$($Prefix)ADS\ADS-VDC01\Virtual Hard Disks\05-ADS-VDC01-NameResolution.cmd" -Destination . | Out-Null
		Copy-Item -Path "$Destination\$($Prefix)ADS\ADS-VDC01\Virtual Hard Disks\05-ADS-VDC01-NameResolution.ps1" -Destination . | Out-Null
		Copy-Item -Path "$Destination\$($Prefix)ADS\ADS-VDC01\Virtual Hard Disks\06-ADS-VDC01-TrustFix.cmd" -Destination . | Out-Null
		Set-Location -Path c: | Out-Null
		Dismount-VHD -Path "$Destination\$($Prefix)ADS\ADS-VDC01\Virtual Hard Disks\ADS-VDC01.vhdx"
		Write-Verbose "Dismounted ADS-VDC01.vhdx successfully."
		
		#ADS-VDC02
		New-Item -Name 01-ADS-VDC02.cmd -ItemType file -Path "$Destination\$($Prefix)ADS\ADS-VDC02\Virtual Hard Disks\" | Out-Null
		New-Item -Name 01-ADS-VDC02.ps1 -ItemType file -Path "$Destination\$($Prefix)ADS\ADS-VDC02\Virtual Hard Disks\" | Out-Null
		New-Item -Name 02-ADS-VDC02-ADDeploy.ps1 -ItemType file -Path "$Destination\$($Prefix)ADS\ADS-VDC02\Virtual Hard Disks\" | Out-Null
		New-Item -Name 02-ADS-VDC02-ADDeploy.cmd -ItemType file -Path "$Destination\$($Prefix)ADS\ADS-VDC02\Virtual Hard Disks\" | Out-Null
		Add-Content -Path "$Destination\$($Prefix)ADS\ADS-VDC02\Virtual Hard Disks\01-ADS-VDC02.cmd" -value "powershell.exe Set-ExecutionPolicy -ExecutionPolicy Unrestricted"
		Add-Content -Path "$Destination\$($Prefix)ADS\ADS-VDC02\Virtual Hard Disks\01-ADS-VDC02.cmd" -value "powershell.exe -noexit C:\SetupTemp\01-ADS-VDC02.ps1"
		Add-Content -Path "$Destination\$($Prefix)ADS\ADS-VDC02\Virtual Hard Disks\02-ADS-VDC02-ADDeploy.cmd" -value "powershell.exe Set-ExecutionPolicy -ExecutionPolicy Unrestricted"
		Add-Content -Path "$Destination\$($Prefix)ADS\ADS-VDC02\Virtual Hard Disks\02-ADS-VDC02-ADDeploy.cmd" -value "powershell.exe -noexit C:\SetupTemp\02-ADS-VDC02-ADDeploy.ps1"
		Add-Content -Path "$Destination\$($Prefix)ADS\ADS-VDC02\Virtual Hard Disks\01-ADS-VDC02.ps1" -value "Get-ScheduledTask -TaskName servermanager | Disable-ScheduledTask"
		Add-Content -Path "$Destination\$($Prefix)ADS\ADS-VDC02\Virtual Hard Disks\01-ADS-VDC02.ps1" -value "Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled false"
		Add-Content -Path "$Destination\$($Prefix)ADS\ADS-VDC02\Virtual Hard Disks\01-ADS-VDC02.ps1" -value "Set-ItemProperty -Path `'HKLM:\System\CurrentControlSet\Control\Terminal Server`'-name `"fDenyTSConnections`" -Value 0"
		Add-Content -Path "$Destination\$($Prefix)ADS\ADS-VDC02\Virtual Hard Disks\01-ADS-VDC02.ps1" -value "Enable-NetFirewallRule -DisplayGroup `"Remote Desktop`""
		Add-Content -Path "$Destination\$($Prefix)ADS\ADS-VDC02\Virtual Hard Disks\01-ADS-VDC02.ps1" -value "Set-ItemProperty -Path `'HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp`' -name `"UserAuthentication`" -Value 1"
		Add-Content -Path "$Destination\$($Prefix)ADS\ADS-VDC02\Virtual Hard Disks\01-ADS-VDC02.ps1" -value "Disable-NetAdapterBinding -InterfaceAlias ethernet -ComponentID ms_tcpip6"
		Add-Content -Path "$Destination\$($Prefix)ADS\ADS-VDC02\Virtual Hard Disks\01-ADS-VDC02.ps1" -value "New-NetIPAddress -InterfaceAlias ethernet -IPAddress 192.168.2.1 -PrefixLength 24 -DefaultGateway 192.168.2.254"
		Add-Content -Path "$Destination\$($Prefix)ADS\ADS-VDC02\Virtual Hard Disks\01-ADS-VDC02.ps1" -value "(Get-WmiObject -Class Win32_NetworkAdapterConfiguration | Where-Object { `$PSItem.description -like `"*hyper*`" }).settcpipnetbios(2)"
		Add-Content -Path "$Destination\$($Prefix)ADS\ADS-VDC02\Virtual Hard Disks\01-ADS-VDC02.ps1" -value "Set-DnsClientServerAddress -InterfaceAlias ethernet -ResetServerAddresses"
		Add-Content -Path "$Destination\$($Prefix)ADS\ADS-VDC02\Virtual Hard Disks\01-ADS-VDC02.ps1" -value "Set-DnsClientServerAddress -InterfaceAlias ethernet -ServerAddresses `"192.168.1.1`""
		Add-Content -Path "$Destination\$($Prefix)ADS\ADS-VDC02\Virtual Hard Disks\01-ADS-VDC02.ps1" -value "Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools"
		Add-Content -Path "$Destination\$($Prefix)ADS\ADS-VDC02\Virtual Hard Disks\01-ADS-VDC02.ps1" -value "Rename-Computer -NewName ADS-VDC02 -Restart"
		
		Add-Content -Path "$Destination\$($Prefix)ADS\ADS-VDC02\Virtual Hard Disks\02-ADS-VDC02-ADDeploy.ps1" -Value "Import-Module ADDSDeployment"
		Add-Content -Path "$Destination\$($Prefix)ADS\ADS-VDC02\Virtual Hard Disks\02-ADS-VDC02-ADDeploy.ps1" -Value "Install-ADDSDomainController -Credential (New-Object System.Management.Automation.PSCredential ADS\Administrator,(ConvertTo-SecureString -AsPlainText -Force -String `"C0mplex`")) -NoGlobalCatalog:`$false -CreateDnsDelegation:`$false -CriticalReplicationOnly:`$false -DatabasePath `"C:\Windows\NTDS`" -DomainName `"ads-center.de`" -InstallDns:`$true -LogPath `"C:\Windows\NTDS`" -NoRebootOnCompletion:`$false -ReplicationSourceDC `"ADS-VDC01.ADS-CENTER.DE`" -SiteName `"STGT`" -SysvolPath `"C:\Windows\SYSVOL`" -SafeModeAdministratorPassword (ConvertTo-SecureString -AsPlainText -Force -String `"C0mplex`") -Force:`$true"
		
		Write-Verbose "Mounting ADS-VDC02.vhdx and copying the automated setup files."
		$driveb4 = (Get-PSDrive).Name
		Mount-VHD -Path "$Destination\$($Prefix)ADS\ADS-VDC02\Virtual Hard Disks\ADS-VDC02.vhdx"
		$driveat = (Get-PSDrive).name
		$drive = (Compare-Object -ReferenceObject $driveb4 -DifferenceObject $driveat).inputobject[-1] + ':'
		New-Item -Path $drive\SetupTemp -ItemType Directory | Out-Null
		Set-Location -Path $drive\SetupTemp | Out-Null
		Copy-Item -Path "$Destination\$($Prefix)ADS\ADS-VDC02\Virtual Hard Disks\01-ADS-VDC02.cmd" -Destination . | Out-Null
		Copy-Item -Path "$Destination\$($Prefix)ADS\ADS-VDC02\Virtual Hard Disks\01-ADS-VDC02.ps1" -Destination . | Out-Null
		Copy-Item -Path "$Destination\$($Prefix)ADS\ADS-VDC02\Virtual Hard Disks\02-ADS-VDC02-ADDeploy.ps1" -Destination . | Out-Null
		Copy-Item -Path "$Destination\$($Prefix)ADS\ADS-VDC02\Virtual Hard Disks\02-ADS-VDC02-ADDeploy.cmd" -Destination . | Out-Null
		Set-Location -Path c: | Out-Null
		Dismount-VHD -Path "$Destination\$($Prefix)ADS\ADS-VDC02\Virtual Hard Disks\ADS-VDC02.vhdx"
		Write-Verbose "Dismounted ADS-VDC02.vhdx successfully."
		
		#ADS-VRODC01
		New-Item -Name 01-ADS-VRODC01.cmd -ItemType file -Path "$Destination\$($Prefix)ADS\ADS-VRODC01\Virtual Hard Disks\" | Out-Null
		New-Item -Name 01-ADS-VRODC01.ps1 -ItemType file -Path "$Destination\$($Prefix)ADS\ADS-VRODC01\Virtual Hard Disks\" | Out-Null
		New-Item -Name 02-ADS-VRODC01-ADDeploy.ps1 -ItemType file -Path "$Destination\$($Prefix)ADS\ADS-VRODC01\Virtual Hard Disks\" | Out-Null
		New-Item -Name 02-ADS-VRODC01-ADDeploy.cmd -ItemType file -Path "$Destination\$($Prefix)ADS\ADS-VRODC01\Virtual Hard Disks\" | Out-Null
		Add-Content -Path "$Destination\$($Prefix)ADS\ADS-VRODC01\Virtual Hard Disks\01-ADS-VRODC01.cmd" -value "powershell.exe Set-ExecutionPolicy -ExecutionPolicy Unrestricted"
		Add-Content -Path "$Destination\$($Prefix)ADS\ADS-VRODC01\Virtual Hard Disks\01-ADS-VRODC01.cmd" -value "powershell.exe -noexit C:\SetupTemp\01-ADS-VRODC01.ps1"
		Add-Content -Path "$Destination\$($Prefix)ADS\ADS-VRODC01\Virtual Hard Disks\02-ADS-VRODC01-ADDeploy.cmd" -value "powershell.exe Set-ExecutionPolicy -ExecutionPolicy Unrestricted"
		Add-Content -Path "$Destination\$($Prefix)ADS\ADS-VRODC01\Virtual Hard Disks\02-ADS-VRODC01-ADDeploy.cmd" -value "powershell.exe -noexit C:\SetupTemp\02-ADS-VRODC01-ADDeploy.ps1"
		Add-Content -Path "$Destination\$($Prefix)ADS\ADS-VRODC01\Virtual Hard Disks\01-ADS-VRODC01.ps1" -value "Get-ScheduledTask -TaskName servermanager | Disable-ScheduledTask"
		Add-Content -Path "$Destination\$($Prefix)ADS\ADS-VRODC01\Virtual Hard Disks\01-ADS-VRODC01.ps1" -value "Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled false"
		Add-Content -Path "$Destination\$($Prefix)ADS\ADS-VRODC01\Virtual Hard Disks\01-ADS-VRODC01.ps1" -value "Set-ItemProperty -Path `'HKLM:\System\CurrentControlSet\Control\Terminal Server`'-name `"fDenyTSConnections`" -Value 0"
		Add-Content -Path "$Destination\$($Prefix)ADS\ADS-VRODC01\Virtual Hard Disks\01-ADS-VRODC01.ps1" -value "Enable-NetFirewallRule -DisplayGroup `"Remote Desktop`""
		Add-Content -Path "$Destination\$($Prefix)ADS\ADS-VRODC01\Virtual Hard Disks\01-ADS-VRODC01.ps1" -value "Set-ItemProperty -Path `'HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp`' -name `"UserAuthentication`" -Value 1"
		Add-Content -Path "$Destination\$($Prefix)ADS\ADS-VRODC01\Virtual Hard Disks\01-ADS-VRODC01.ps1" -value "Disable-NetAdapterBinding -InterfaceAlias ethernet -ComponentID ms_tcpip6"
		Add-Content -Path "$Destination\$($Prefix)ADS\ADS-VRODC01\Virtual Hard Disks\01-ADS-VRODC01.ps1" -value "New-NetIPAddress -InterfaceAlias ethernet -IPAddress 192.168.3.1 -PrefixLength 24 -DefaultGateway 192.168.3.254"
		Add-Content -Path "$Destination\$($Prefix)ADS\ADS-VRODC01\Virtual Hard Disks\01-ADS-VRODC01.ps1" -value "(Get-WmiObject -Class Win32_NetworkAdapterConfiguration | Where-Object { `$PSItem.description -like `"*hyper*`" }).settcpipnetbios(2)"
		Add-Content -Path "$Destination\$($Prefix)ADS\ADS-VRODC01\Virtual Hard Disks\01-ADS-VRODC01.ps1" -value "Set-DnsClientServerAddress -InterfaceAlias ethernet -ResetServerAddresses"
		Add-Content -Path "$Destination\$($Prefix)ADS\ADS-VRODC01\Virtual Hard Disks\01-ADS-VRODC01.ps1" -value "Set-DnsClientServerAddress -InterfaceAlias ethernet -ServerAddresses `"192.168.1.1`""
		Add-Content -Path "$Destination\$($Prefix)ADS\ADS-VRODC01\Virtual Hard Disks\01-ADS-VRODC01.ps1" -value "Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools"
		Add-Content -Path "$Destination\$($Prefix)ADS\ADS-VRODC01\Virtual Hard Disks\01-ADS-VRODC01.ps1" -value "Rename-Computer -NewName ADS-VRODC01 -Restart"
		Add-Content -Path "$Destination\$($Prefix)ADS\ADS-VRODC01\Virtual Hard Disks\02-ADS-VRODC01-ADDeploy.ps1" -Value "Import-Module ADDSDeployment"
		Add-Content -Path "$Destination\$($Prefix)ADS\ADS-VRODC01\Virtual Hard Disks\02-ADS-VRODC01-ADDeploy.ps1" -Value "Install-ADDSDomainController -Credential (New-Object System.Management.Automation.PSCredential ADS\Administrator,(ConvertTo-SecureString -AsPlainText -Force -String `"C0mplex`")) -AllowPasswordReplicationAccountName `@`(`"ADS\Allowed RODC Password Replication Group`"`) -NoGlobalCatalog:`$false -CriticalReplicationOnly:`$false -DatabasePath `"C:\Windows\NTDS`" -DelegatedAdministratorAccountName `"ADS\Administrator`" -DenyPasswordReplicationAccountName `@`(`"BUILTIN\Administrators`", `"BUILTIN\Server Operators`", `"BUILTIN\Backup Operators`", `"BUILTIN\Account Operators`", `"ADS\Denied RODC Password Replication Group`"`) -DomainName `"ads-center.de`" -InstallDns:`$true -LogPath `"C:\Windows\NTDS`" -NoRebootOnCompletion:`$false -ReadOnlyReplica:`$true -ReplicationSourceDC `"ADS-VDC01.ADS-CENTER.DE`" -SiteName `"SAIGON`" -SysvolPath `"C:\Windows\SYSVOL`" -SafeModeAdministratorPassword (ConvertTo-SecureString -AsPlainText -Force -String `"C0mplex`") -Force:`$true"
		
		Write-Verbose "Mounting ADS-VRODC01.vhdx and copying the automated setup files."
		$driveb4 = (Get-PSDrive).Name
		Mount-VHD -Path "$Destination\$($Prefix)ADS\ADS-VRODC01\Virtual Hard Disks\ADS-VRODC01.vhdx"
		$driveat = (Get-PSDrive).name
		$drive = (Compare-Object -ReferenceObject $driveb4 -DifferenceObject $driveat).inputobject[-1] + ':'
		New-Item -Path $drive\SetupTemp -ItemType Directory | Out-Null
		Set-Location -Path $drive\SetupTemp | Out-Null
		Copy-Item -Path "$Destination\$($Prefix)ADS\ADS-VRODC01\Virtual Hard Disks\01-ADS-VRODC01.cmd" -Destination . | Out-Null
		Copy-Item -Path "$Destination\$($Prefix)ADS\ADS-VRODC01\Virtual Hard Disks\01-ADS-VRODC01.ps1" -Destination . | Out-Null
		Copy-Item -Path "$Destination\$($Prefix)ADS\ADS-VRODC01\Virtual Hard Disks\02-ADS-VRODC01-ADDeploy.ps1" -Destination . | Out-Null
		Copy-Item -Path "$Destination\$($Prefix)ADS\ADS-VRODC01\Virtual Hard Disks\02-ADS-VRODC01-ADDeploy.cmd" -Destination . | Out-Null
		Set-Location -Path c: | Out-Null
		Dismount-VHD -Path "$Destination\$($Prefix)ADS\ADS-VRODC01\Virtual Hard Disks\ADS-VRODC01.vhdx"
		Write-Verbose "Dismounted ADS-VRODC01.vhdx successfully."
		
		#ADS-VSV01
		Write-Verbose "Creating autmated setup files for ADS-VSV01."
		New-Item -Name 01-ADS-VSV01.cmd -ItemType file -Path "$Destination\$($Prefix)ADS\ADS-VSV01\Virtual Hard Disks\" | Out-Null
		New-Item -Name 01-ADS-VSV01.ps1 -ItemType file -Path "$Destination\$($Prefix)ADS\ADS-VSV01\Virtual Hard Disks\" | Out-Null
		Add-Content -Path "$Destination\$($Prefix)ADS\ADS-VSV01\Virtual Hard Disks\01-ADS-VSV01.ps1" -value "Get-ScheduledTask -TaskName servermanager | Disable-ScheduledTask"
		Add-Content -Path "$Destination\$($Prefix)ADS\ADS-VSV01\Virtual Hard Disks\01-ADS-VSV01.ps1" -value "Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled false"
		Add-Content -Path "$Destination\$($Prefix)ADS\ADS-VSV01\Virtual Hard Disks\01-ADS-VSV01.ps1" -value "Set-ItemProperty -Path `'HKLM:\System\CurrentControlSet\Control\Terminal Server`'-name `"fDenyTSConnections`" -Value 0"
		Add-Content -Path "$Destination\$($Prefix)ADS\ADS-VSV01\Virtual Hard Disks\01-ADS-VSV01.ps1" -value "Enable-NetFirewallRule -DisplayGroup `"Remote Desktop`""
		Add-Content -Path "$Destination\$($Prefix)ADS\ADS-VSV01\Virtual Hard Disks\01-ADS-VSV01.ps1" -value "Set-ItemProperty -Path `'HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp`' -name `"UserAuthentication`" -Value 1"
		Add-Content -Path "$Destination\$($Prefix)ADS\ADS-VSV01\Virtual Hard Disks\01-ADS-VSV01.ps1" -value "Disable-NetAdapterBinding -InterfaceAlias ethernet -ComponentID ms_tcpip6"
		Add-Content -Path "$Destination\$($Prefix)ADS\ADS-VSV01\Virtual Hard Disks\01-ADS-VSV01.ps1" -value "New-NetIPAddress -InterfaceAlias ethernet -IPAddress 192.168.1.2 -PrefixLength 24 -DefaultGateway 192.168.1.254"
		Add-Content -Path "$Destination\$($Prefix)ADS\ADS-VSV01\Virtual Hard Disks\01-ADS-VSV01.ps1" -value "(Get-WmiObject -Class Win32_NetworkAdapterConfiguration | Where-Object { `$PSItem.description -like `"*hyper*`" }).settcpipnetbios(2)"
		Add-Content -Path "$Destination\$($Prefix)ADS\ADS-VSV01\Virtual Hard Disks\01-ADS-VSV01.ps1" -value "Set-DnsClientServerAddress -InterfaceAlias ethernet -ResetServerAddresses"
		Add-Content -Path "$Destination\$($Prefix)ADS\ADS-VSV01\Virtual Hard Disks\01-ADS-VSV01.ps1" -value "Set-DnsClientServerAddress -InterfaceAlias ethernet -ServerAddresses `"192.168.1.1`""
		Add-Content -Path "$Destination\$($Prefix)ADS\ADS-VSV01\Virtual Hard Disks\01-ADS-VSV01.ps1" -value "`$Cred = New-object System.Management.Automation.PSCredential `"administrator@ads-center.de`", (ConvertTo-SecureString -String `"C0mplex`" -AsPlainText -Force)"
		Add-Content -Path "$Destination\$($Prefix)ADS\ADS-VSV01\Virtual Hard Disks\01-ADS-VSV01.ps1" -value "Add-Computer -DomainCredential `$cred -DomainName ads-center.de -NewName ADS-VSV01 -Restart"
		Add-Content -Path "$Destination\$($Prefix)ADS\ADS-VSV01\Virtual Hard Disks\01-ADS-VSV01.cmd" -value "powershell.exe Set-ExecutionPolicy -ExecutionPolicy Unrestricted"
		Add-Content -Path "$Destination\$($Prefix)ADS\ADS-VSV01\Virtual Hard Disks\01-ADS-VSV01.cmd" -value "powershell.exe -noexit C:\SetupTemp\01-ADS-VSV01.ps1"
		
		Write-Verbose "Mounting ADS-VSV01.vhdx and copying the automated setup files."
		$driveb4 = (Get-PSDrive).Name
		Mount-VHD -Path "$Destination\$($Prefix)ADS\ADS-VSV01\Virtual Hard Disks\ADS-VSV01.vhdx"
		$driveat = (Get-PSDrive).name
		$drive = (Compare-Object -ReferenceObject $driveb4 -DifferenceObject $driveat).inputobject[-1] + ':'
		New-Item -Path $drive\SetupTemp -ItemType Directory | Out-Null
		Set-Location -Path $drive\SetupTemp | Out-Null
		Copy-Item -Path "$Destination\$($Prefix)ADS\ADS-VSV01\Virtual Hard Disks\01-ADS-VSV01.cmd" -Destination . | Out-Null
		Copy-Item -Path "$Destination\$($Prefix)ADS\ADS-VSV01\Virtual Hard Disks\01-ADS-VSV01.ps1" -Destination . | Out-Null
		Set-Location -Path c: | Out-Null
		Dismount-VHD -Path "$Destination\$($Prefix)ADS\ADS-VSV01\Virtual Hard Disks\ADS-VSV01.vhdx"
		Write-Verbose "Dismounted ADS-VSV01.vhdx successfully."
		
		#ADS - ADS-VCL01
		Write-Verbose "Creating automated setup files for ADS-VCL01."
		New-Item -Name ADS-VCL01.cmd -ItemType file -Path "$Destination\$($Prefix)ADS\ADS-VCL01\Virtual Hard Disks\" | Out-Null
		New-Item -Name ADS-VCL01.ps1 -ItemType file -Path "$Destination\$($Prefix)ADS\ADS-VCL01\Virtual Hard Disks\" | Out-Null
		Add-Content -Path "$Destination\$($Prefix)ADS\ADS-VCL01\Virtual Hard Disks\ADS-VCL01.ps1" -value "Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled false"
		Add-Content -Path "$Destination\$($Prefix)ADS\ADS-VCL01\Virtual Hard Disks\ADS-VCL01.ps1" -value "Set-ItemProperty -Path `'HKLM:\System\CurrentControlSet\Control\Terminal Server`'-name `"fDenyTSConnections`" -Value 0"
		Add-Content -Path "$Destination\$($Prefix)ADS\ADS-VCL01\Virtual Hard Disks\ADS-VCL01.ps1" -value "Enable-NetFirewallRule -DisplayGroup `"Remote Desktop`""
		Add-Content -Path "$Destination\$($Prefix)ADS\ADS-VCL01\Virtual Hard Disks\ADS-VCL01.ps1" -value "Set-ItemProperty -Path `'HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp`' -name `"UserAuthentication`" -Value 1"
		Add-Content -Path "$Destination\$($Prefix)ADS\ADS-VCL01\Virtual Hard Disks\ADS-VCL01.ps1" -value "Disable-NetAdapterBinding -InterfaceAlias ethernet -ComponentID ms_tcpip6"
		Add-Content -Path "$Destination\$($Prefix)ADS\ADS-VCL01\Virtual Hard Disks\ADS-VCL01.ps1" -value "New-NetIPAddress -InterfaceAlias ethernet -IPAddress 192.168.1.3 -PrefixLength 24 -DefaultGateway 192.168.1.254"
		Add-Content -Path "$Destination\$($Prefix)ADS\ADS-VCL01\Virtual Hard Disks\ADS-VCL01.ps1" -value "(Get-WmiObject -Class Win32_NetworkAdapterConfiguration | Where-Object { `$PSItem.description -like `"*hyper*`" }).settcpipnetbios(2)"
		Add-Content -Path "$Destination\$($Prefix)ADS\ADS-VCL01\Virtual Hard Disks\ADS-VCL01.ps1" -value "Set-DnsClientServerAddress -InterfaceAlias ethernet -ResetServerAddresses"
		Add-Content -Path "$Destination\$($Prefix)ADS\ADS-VCL01\Virtual Hard Disks\ADS-VCL01.ps1" -value "Set-DnsClientServerAddress -InterfaceAlias ethernet -ServerAddresses `"192.168.1.1`""
		Add-Content -Path "$Destination\$($Prefix)ADS\ADS-VCL01\Virtual Hard Disks\ADS-VCL01.ps1" -value "`$Cred = New-object System.Management.Automation.PSCredential `"administrator@ads-center.de`", (ConvertTo-SecureString -String `"C0mplex`" -AsPlainText -Force)"
		Add-Content -Path "$Destination\$($Prefix)ADS\ADS-VCL01\Virtual Hard Disks\ADS-VCL01.ps1" -value "Add-Computer -DomainCredential `$cred -DomainName ads-center.de -NewName ADS-VCL01 -Restart"
		Add-Content -Path "$Destination\$($Prefix)ADS\ADS-VCL01\Virtual Hard Disks\ADS-VCL01.cmd" -value "powershell.exe Set-ExecutionPolicy -ExecutionPolicy Unrestricted"
		Add-Content -Path "$Destination\$($Prefix)ADS\ADS-VCL01\Virtual Hard Disks\ADS-VCL01.cmd" -value "powershell.exe -noexit C:\SetupTemp\ADS-VCL01.ps1"
		
		Write-Verbose "Mounting ADS-VCL01.vhdx and copying the automated setup files."
		$driveb4 = (Get-PSDrive).Name
		Mount-VHD -Path "$Destination\$($Prefix)ADS\ADS-VCL01\Virtual Hard Disks\ADS-VCL01.vhdx"
		$driveat = (Get-PSDrive).name
		$drive = (Compare-Object -ReferenceObject $driveb4 -DifferenceObject $driveat).inputobject[-1] + ':'
		New-Item -Path $drive\SetupTemp -ItemType Directory | Out-Null
		Set-Location -Path $drive\SetupTemp | Out-Null
		Copy-Item -Path "$Destination\$($Prefix)ADS\ADS-VCL01\Virtual Hard Disks\ADS-VCL01.cmd" -Destination . | Out-Null
		Copy-Item -Path "$Destination\$($Prefix)ADS\ADS-VCL01\Virtual Hard Disks\ADS-VCL01.ps1" -Destination . | Out-Null
		Set-Location -Path c: | Out-Null
		Dismount-VHD -Path "$Destination\$($Prefix)ADS\ADS-VCL01\Virtual Hard Disks\ADS-VCL01.vhdx"
		Write-Verbose "Dismounted ADS-VCL01.vhdx successfully."
		
		#Create VMs
		Write-Verbose "Creating ADS VMs."
		new-vm -Name "$($Prefix)ADS-VDC01" -MemoryStartupBytes 1024MB -Path "$Destination\$($Prefix)ADS\" -VHDPath "$Destination\$($Prefix)ADS\ADS-VDC01\Virtual Hard Disks\ADS-VDC01.vhdx" -SwitchName $switchname -Generation 2 | out-null
		Set-VMProcessor -VMName "$($Prefix)ADS-VDC01" -Count $([math]::Floor($CPUCount / 4))
		Add-VMDvdDrive -VMName "$($Prefix)ADS-VDC01"
		new-vm -Name "$($Prefix)ADS-VDC02" -MemoryStartupBytes 1024MB -Path "$Destination\$($Prefix)ADS\" -VHDPath "$Destination\$($Prefix)ADS\ADS-VDC02\Virtual Hard Disks\ADS-VDC02.vhdx" -SwitchName $switchname -Generation 2 | out-null
		Set-VMProcessor -VMName "$($Prefix)ADS-VDC02" -Count $([math]::Floor($CPUCount / 4))
		Add-VMDvdDrive -VMName "$($Prefix)ADS-VDC02"
		new-vm -Name "$($Prefix)ADS-VRODC01" -MemoryStartupBytes 1024MB -Path "$Destination\$($Prefix)ADS\" -VHDPath "$Destination\$($Prefix)ADS\ADS-VRODC01\Virtual Hard Disks\ADS-VRODC01.vhdx" -SwitchName $switchname -Generation 2 | out-null
		Set-VMProcessor -VMName "$($Prefix)ADS-VRODC01" -Count $([math]::Floor($CPUCount / 4))
		Add-VMDvdDrive -VMName "$($Prefix)ADS-VRODC01"
		new-vm -Name "$($Prefix)ADS-VSV01" -MemoryStartupBytes 1024MB -Path "$Destination\$($Prefix)ADS\" -VHDPath "$Destination\$($Prefix)ADS\ADS-VSV01\Virtual Hard Disks\ADS-VSV01.vhdx" -SwitchName $switchname -Generation 2 | out-null
		Set-VMProcessor -VMName "$($Prefix)ADS-VSV01" -Count $([math]::Floor($CPUCount / 4))
		Add-VMDvdDrive -VMName "$($Prefix)ADS-VSV01"
		new-vm -Name "$($Prefix)ADS-VCL01" -MemoryStartupBytes 1024MB -Path "$Destination\$($Prefix)ADS\" -VHDPath "$Destination\$($Prefix)ADS\ADS-VCL01\Virtual Hard Disks\ADS-VCL01.vhdx" -SwitchName $switchname -Generation 2 | out-null
		Set-VMProcessor -VMName "$($Prefix)ADS-VCL01" -Count $([math]::Floor($CPUCount / 4))
		Add-VMDvdDrive -VMName "$($Prefix)ADS-VCL01"
		
		Write-Verbose "Configuring dynamicMemory on every ADS VM."
		Set-VM -VM (Get-VM -Name "$($Prefix)ADS-*") -DynamicMemory
	}
	
	end
	{
		Write-Host "Created......$($Prefix)ADS-VDC01......successfully."
		Write-Host "Created......$($Prefix)ADS-VDC02......successfully."
		Write-Host "Created......$($Prefix)ADS-VRODC01....successfully."
		Write-Host "Created......$($Prefix)ADS-VSV01......successfully."
		Write-Host "Created......$($Prefix)ADS-VCL01......successfully."
	}
}

<#
	.SYNOPSIS
		Setup for Resource Forest - aka xchange-center.de.

	.DESCRIPTION
		One DC, one exchange server and one sharepoint server will be setup.
		All VMs will be generation 2.

	.PARAMETER  Destination
		Absolute path to the destination folder for the VMs.

	.PARAMETER  Server2016PD
		Absolute path to the parent disk of a Server 2016.

	.PARAMETER  Windows10PD
		Absolute path to the parent disk of a Windows 10.

	.PARAMETER  Switchname
		Defines the Hyper-V switch name.

	.PARAMETER  LegacyForest
		Defines the Forest Functional Level 2008 R2.

	.EXAMPLE
		Enable-ResourceForest -Destination $Destination -Server2016PD C:\PD\2016.vhdx -Windows10PD C:\PD\Windows10.vhdx

	.EXAMPLE
		Enable-ResourceForest $Destination C:\PD\2016.vhdx C:\PD\Windows10.vhdx

	.NOTES
		01/30/2017 Martin Handl - Version 1.0
		01/31/2017 Martin Handl - Version 1.0.1 - Subnet fixed for reverse lookup zone + added probing for hyper-v module
												- Minor bug fixes
												- Improvements and adding LegacyForest Switch
		02/01/2017 Martin Handl - Version 1.0.2 - added sequence for setup scripts
		02/02/2017 Martin Handl - Version 1.0.3 - added registry patch for DCs (TcpIpClientSupport DWORD 1)
		02/07/2017 Martin Handl - Version 1.0.4 - Prefix for VMs added
		02/08/2017 Martin Handl - Version 1.0.5 - new OU strucute (Tier0 ... Tier2)
		02/23/2017 Martin Handl - Version 1.0.6 - trust fix for PIM_TRUST applied
		02/27/2017 Martin Handl - Version 1.0.7 - bugfix on DC name applied
		03/07/2017 Martin Handl - Version 1.0.8 - Exchange prep applied + CPU count for exchange raised to 4 CPUs
												- turned VSV to a VCA machine
		03/09/2017 Martin Handl - Version 1.0.9 - Exchange unatted setup routine added
												- name resolution to ads-center.de added
		03/20/2017 Martin Handl - Version 1.0.10 - BreakGlass- and RedCard-User implemented + Exchange 2016 unattend setup added
		05/30/2017 Martin Handl - Version 1.0.11 - CPU count corrected

	.LINK
		about_functions_advanced

	.LINK
		about_comment_based_help

#>
function Enable-ResourceForest
{
	[cmdletbinding()]
	param
	(
		[parameter(Mandatory = $true,
				   ValueFromPipelineByPropertyName = $true,
				   Position = 0)]
		$Destination,
		[parameter(Mandatory = $true,
				   ValueFromPipelineByPropertyName = $true,
				   Position = 1)]
		$Server2016PD,
		[parameter(Mandatory = $true,
				   ValueFromPipelineByPropertyName = $true,
				   Position = 2)]
		$Windows10PD,
		[parameter(Mandatory = $true,
				   ValueFromPipelineByPropertyName = $true,
				   Position = 3)]
		$switchname,
		[parameter(Position = 4)]
		[switch]$LegacyForest,
		[parameter(Position = 5)]
		$Prefix
	)
	begin
	{
		
		Write-Debug "`$Destination is $Destination"
		Write-Debug "`$Server2016PD is $Server2016PD"
		Write-Debug "`$Windows10PD is $Windows10PD"
		Write-Debug "`$switchname is $switchname"
		Write-Debug "`$Prefix is $Prefix"
		
		Write-Verbose "Evaluating the number of logical processors..."
		$CPUCount = ((Get-CimInstance -ClassName win32_processor).NumberOfLogicalProcessors | Measure-Object -Sum).sum
		
		Write-Verbose "Probing path $Destination..."
		$PathDestExist = Test-Path -Path $Destination
		switch ($PathDestExist)
		{
			$false { Write-Host -ForegroundColor Yellow -BackgroundColor Black "Path to the VM Destination `($Destination`) does not exist! Please check path and retry again. `nTerminating Script"; Break }
			Default { }
		}
		
		Write-Verbose "Probing for Hyper-V Powershell Module..."
		$HVModuleExistes = Get-Module -Name Hyper-V
		switch ($HVModuleExistes)
		{
			$null { Write-Host "Hyper-V-Module for Windows Powershell not found on this host! Please install RSAT for Hyper-V on this host an retry again. `nTerminating Script"; Break }
			Default { }
		}
		
		Write-Verbose "Probing for Hyper-V switch..."
		$HVSwitchExists = (Get-VMSwitch -Name $switchname).name
		switch ($HVSwitchExists)
		{
			$null { Write-Host "Hyper-V switch not found. Create the Hyper-V switch $switchname and retry again. `nTerminanting Script"; Break }
			Default { }
		}
		
		Write-Verbose "Probing underlying paths..."
		$PathXCExist = Test-Path -Path $Destination"\XC"
		if ($PathXCExist -eq $true)
		{
			Write-Host "Path $Destination\XC is present (and should not be present). Clear the path an retry the script! `nTerminating the Script"; Break
		}
		else
		{
			Write-Debug "Non of the required underlying pathes have been found - continuing the script!"
		}
		
		Write-Verbose "Probing path $Server2016PD..."
		$PathPDServer2016Exist = Test-Path -Path $Server2016PD
		switch ($PathPDServer2016Exist)
		{
			$false { Write-Host -ForegroundColor Yellow -BackgroundColor Black "Path to the parent disk for Server 2016 `($Server2016PD`) does not exist! Please check path and retry again. `nTerminating Script"; Break }
			Default { }
		}
		
		Write-Verbose "Probing path $Windows10PD..."
		$PathPDWin10Exist = Test-Path -Path $Windows10PD
		switch ($PathPDWin10Exist)
		{
			$false { Write-Host -ForegroundColor Yellow -BackgroundColor Black "Path to the parent disk for Windows 10 `($Windows10PD`) does not exist! Please check path and retry again. `nTerminating Script"; Break }
			Default { }
		}
		
		Write-Verbose "Evaluation switch parameter LegacyForest"
		switch ($LegacyForest)
		{
			$true { $ForestDomainMode = 4 }
			Default { $ForestDomainMode = 7 }
		}
	}
	
	Process
	{
		#XC hard disk creation
		Write-Verbose "Creating XC-VDC01 hard disk."
		New-VHD -ParentPath $Server2016PD -Path "$Destination\$($Prefix)XC\XC-VDC01\Virtual Hard Disks\XC-VDC01.vhdx" -Differencing | Out-Null
		Write-Verbose "Created XC-VDC01.vhdx virtual hard disk."
		Write-Verbose "Creating XC-VEX01 hard disk."
		New-VHD -ParentPath $Server2016PD -Path "$Destination\$($Prefix)XC\XC-VEX01\Virtual Hard Disks\XC-VEX01.vhdx" -Differencing | Out-Null
		Write-Verbose "Created XC-VEX01.vhdx virtual hard disk."
		Write-Verbose "Creating XC-VCA01 hard disk."
		New-VHD -ParentPath $Server2016PD -Path "$Destination\$($Prefix)XC\XC-VCA01\Virtual Hard Disks\XC-VCA01.vhdx" -Differencing | Out-Null
		Write-Verbose "Created XC-VCA01.vhdx virtual hard disk."
		
		#XC-VDC01
		Write-Verbose "Creating automated setup files for XC-VDC01."
		New-Item -Name 01-XC-VDC01.cmd -ItemType file -Path "$Destination\$($Prefix)XC\XC-VDC01\Virtual Hard Disks\" | Out-Null
		New-Item -Name 01-XC-VDC01.ps1 -ItemType file -Path "$Destination\$($Prefix)XC\XC-VDC01\Virtual Hard Disks\" | Out-Null
		New-Item -Name 02-XC-VDC01-ADDeploy.ps1 -ItemType file -Path "$Destination\$($Prefix)XC\XC-VDC01\Virtual Hard Disks\" | Out-Null
		New-Item -Name 02-XC-VDC01-ADDeploy.cmd -ItemType file -Path "$Destination\$($Prefix)XC\XC-VDC01\Virtual Hard Disks\" | Out-Null
		New-Item -Name 03-XC-VDC01-ADCare.ps1 -ItemType file -Path "$Destination\$($Prefix)XC\XC-VDC01\Virtual Hard Disks\" | Out-Null
		New-Item -Name 03-XC-VDC01-ADCare.cmd -ItemType file -Path "$Destination\$($Prefix)XC\XC-VDC01\Virtual Hard Disks\" | Out-Null
		New-Item -Name 04-XC-VDC01-RegPatch.cmd -ItemType file -Path "$Destination\$($Prefix)XC\XC-VDC01\Virtual Hard Disks\" | Out-Null
		New-Item -Name 04-XC-VDC01-RegPatch.ps1 -ItemType file -Path "$Destination\$($Prefix)XC\XC-VDC01\Virtual Hard Disks\" | Out-Null
		New-Item -Name 05-XC-VDC01-NameResolution.cmd -ItemType file -Path "$Destination\$($Prefix)XC\XC-VDC01\Virtual Hard Disks\" | Out-Null
		New-Item -Name 05-XC-VDC01-NameResolution.ps1 -ItemType file -Path "$Destination\$($Prefix)XC\XC-VDC01\Virtual Hard Disks\" | Out-Null
		Add-Content -Path "$Destination\$($Prefix)XC\XC-VDC01\Virtual Hard Disks\01-XC-VDC01.ps1" -value "Get-ScheduledTask -TaskName servermanager | Disable-ScheduledTask"
		Add-Content -Path "$Destination\$($Prefix)XC\XC-VDC01\Virtual Hard Disks\01-XC-VDC01.ps1" -value "Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled false"
		Add-Content -Path "$Destination\$($Prefix)XC\XC-VDC01\Virtual Hard Disks\01-XC-VDC01.ps1" -value "Set-ItemProperty -Path `'HKLM:\System\CurrentControlSet\Control\Terminal Server`'-name `"fDenyTSConnections`" -Value 0"
		Add-Content -Path "$Destination\$($Prefix)XC\XC-VDC01\Virtual Hard Disks\01-XC-VDC01.ps1" -value "Enable-NetFirewallRule -DisplayGroup `"Remote Desktop`""
		Add-Content -Path "$Destination\$($Prefix)XC\XC-VDC01\Virtual Hard Disks\01-XC-VDC01.ps1" -value "Set-ItemProperty -Path `'HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp`' -name `"UserAuthentication`" -Value 1"
		Add-Content -Path "$Destination\$($Prefix)XC\XC-VDC01\Virtual Hard Disks\01-XC-VDC01.ps1" -value "Disable-NetAdapterBinding -InterfaceAlias ethernet -ComponentID ms_tcpip6"
		Add-Content -Path "$Destination\$($Prefix)XC\XC-VDC01\Virtual Hard Disks\01-XC-VDC01.ps1" -value "New-NetIPAddress -InterfaceAlias ethernet -IPAddress 192.168.160.1 -PrefixLength 24 -DefaultGateway 192.168.160.254"
		Add-Content -Path "$Destination\$($Prefix)XC\XC-VDC01\Virtual Hard Disks\01-XC-VDC01.ps1" -value "(Get-WmiObject -Class Win32_NetworkAdapterConfiguration | Where-Object { `$PSItem.description -like `"*hyper*`" }).settcpipnetbios(2)"
		Add-Content -Path "$Destination\$($Prefix)XC\XC-VDC01\Virtual Hard Disks\01-XC-VDC01.ps1" -value "Set-DnsClientServerAddress -InterfaceAlias ethernet -ResetServerAddresses"
		Add-Content -Path "$Destination\$($Prefix)XC\XC-VDC01\Virtual Hard Disks\01-XC-VDC01.ps1" -value "Set-DnsClientServerAddress -InterfaceAlias ethernet -ServerAddresses `"192.168.160.1`""
		Add-Content -Path "$Destination\$($Prefix)XC\XC-VDC01\Virtual Hard Disks\01-XC-VDC01.ps1" -value "Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools"
		Add-Content -Path "$Destination\$($Prefix)XC\XC-VDC01\Virtual Hard Disks\01-XC-VDC01.ps1" -value "Rename-Computer -NewName XC-VDC01 -Restart"
		Add-Content -Path "$Destination\$($Prefix)XC\XC-VDC01\Virtual Hard Disks\02-XC-VDC01-ADDeploy.ps1" -value "Import-Module ADDSDeployment"
		Add-Content -Path "$Destination\$($Prefix)XC\XC-VDC01\Virtual Hard Disks\02-XC-VDC01-ADDeploy.ps1" -value "Install-ADDSForest -CreateDnsDelegation:`$false -DatabasePath `"C:\Windows\NTDS`" -DomainMode $ForestDomainMode -DomainName `"xchange-center.de`" -DomainNetbiosName `"XC`" -ForestMode $ForestDomainMode -InstallDns:`$true -LogPath `"C:\Windows\NTDS`" -NoRebootOnCompletion:`$false -SafeModeAdministratorPassword (ConvertTo-SecureString -String `"C0mplex`" -AsPlainText -Force) -SysvolPath `"C:\Windows\SYSVOL`" -Force:`$true"
		Add-Content -Path "$Destination\$($Prefix)XC\XC-VDC01\Virtual Hard Disks\03-XC-VDC01-ADCare.ps1" -value "Add-DnsServerPrimaryZone -Name 160.168.192.in-addr.arpa -DynamicUpdate Secure -ReplicationScope Forest"
		Add-Content -Path "$Destination\$($Prefix)XC\XC-VDC01\Virtual Hard Disks\03-XC-VDC01-ADCare.ps1" -value "Set-DnsClientServerAddress -InterfaceAlias ethernet -ServerAddresses `"192.168.160.1`""
		Add-Content -Path "$Destination\$($Prefix)XC\XC-VDC01\Virtual Hard Disks\03-XC-VDC01-ADCare.ps1" -value "Rename-ADObject -NewName `"BB`" -Identity `"CN=Default-First-Site-Name,CN=Sites,CN=Configuration,DC=xchange-center,DC=de`""
		Add-Content -Path "$Destination\$($Prefix)XC\XC-VDC01\Virtual Hard Disks\03-XC-VDC01-ADCare.ps1" -value "New-ADReplicationSubnet -Name 192.168.160.0/24 -Location `"BB`" -Site `"BB`""
		Add-Content -Path "$Destination\$($Prefix)XC\XC-VDC01\Virtual Hard Disks\03-XC-VDC01-ADCare.ps1" -value "New-ADOrganizationalUnit -Name ESAE"
		Add-Content -Path "$Destination\$($Prefix)XC\XC-VDC01\Virtual Hard Disks\03-XC-VDC01-ADCare.ps1" -value "New-ADOrganizationalUnit -Name PAW -Path `"OU=ESAE,DC=XCHANGE-CENTER,DC=DE`""
		Add-Content -Path "$Destination\$($Prefix)XC\XC-VDC01\Virtual Hard Disks\03-XC-VDC01-ADCare.ps1" -value "New-ADOrganizationalUnit -Name Desktop -Path `"OU=PAW,OU=ESAE,DC=XCHANGE-CENTER,DC=DE`""
		Add-Content -Path "$Destination\$($Prefix)XC\XC-VDC01\Virtual Hard Disks\03-XC-VDC01-ADCare.ps1" -value "New-ADOrganizationalUnit -Name Mobile -Path `"OU=PAW,OU=ESAE,DC=XCHANGE-CENTER,DC=DE`""
		Add-Content -Path "$Destination\$($Prefix)XC\XC-VDC01\Virtual Hard Disks\03-XC-VDC01-ADCare.ps1" -value "New-ADOrganizationalUnit -Name Tier0 -Path `"OU=ESAE,DC=XCHANGE-CENTER,DC=DE`""
		Add-Content -Path "$Destination\$($Prefix)XC\XC-VDC01\Virtual Hard Disks\03-XC-VDC01-ADCare.ps1" -value "New-ADOrganizationalUnit -Name Accounts -Path `"OU=Tier0,OU=ESAE,DC=XCHANGE-CENTER,DC=DE`""
		Add-Content -Path "$Destination\$($Prefix)XC\XC-VDC01\Virtual Hard Disks\03-XC-VDC01-ADCare.ps1" -value "New-ADOrganizationalUnit -Name Groups -Path `"OU=Tier0,OU=ESAE,DC=XCHANGE-CENTER,DC=DE`""
		Add-Content -Path "$Destination\$($Prefix)XC\XC-VDC01\Virtual Hard Disks\03-XC-VDC01-ADCare.ps1" -value "New-ADOrganizationalUnit -Name Servers -Path `"OU=Tier0,OU=ESAE,DC=XCHANGE-CENTER,DC=DE`""
		Add-Content -Path "$Destination\$($Prefix)XC\XC-VDC01\Virtual Hard Disks\03-XC-VDC01-ADCare.ps1" -value "New-ADOrganizationalUnit -Name Tier1 -Path `"OU=ESAE,DC=XCHANGE-CENTER,DC=DE`""
		Add-Content -Path "$Destination\$($Prefix)XC\XC-VDC01\Virtual Hard Disks\03-XC-VDC01-ADCare.ps1" -value "New-ADOrganizationalUnit -Name Accounts -Path `"OU=Tier1,OU=ESAE,DC=XCHANGE-CENTER,DC=DE`""
		Add-Content -Path "$Destination\$($Prefix)XC\XC-VDC01\Virtual Hard Disks\03-XC-VDC01-ADCare.ps1" -value "New-ADOrganizationalUnit -Name Groups -Path `"OU=Tier1,OU=ESAE,DC=XCHANGE-CENTER,DC=DE`""
		Add-Content -Path "$Destination\$($Prefix)XC\XC-VDC01\Virtual Hard Disks\03-XC-VDC01-ADCare.ps1" -value "New-ADOrganizationalUnit -Name Servers -Path `"OU=Tier1,OU=ESAE,DC=XCHANGE-CENTER,DC=DE`""
		Add-Content -Path "$Destination\$($Prefix)XC\XC-VDC01\Virtual Hard Disks\03-XC-VDC01-ADCare.ps1" -value "New-ADOrganizationalUnit -Name Tier2 -Path `"OU=ESAE,DC=XCHANGE-CENTER,DC=DE`""
		Add-Content -Path "$Destination\$($Prefix)XC\XC-VDC01\Virtual Hard Disks\03-XC-VDC01-ADCare.ps1" -value "New-ADOrganizationalUnit -Name Accounts -Path `"OU=Tier2,OU=ESAE,DC=XCHANGE-CENTER,DC=DE`""
		Add-Content -Path "$Destination\$($Prefix)XC\XC-VDC01\Virtual Hard Disks\03-XC-VDC01-ADCare.ps1" -value "New-ADOrganizationalUnit -Name Groups -Path `"OU=Tier2,OU=ESAE,DC=XCHANGE-CENTER,DC=DE`""
		Add-Content -Path "$Destination\$($Prefix)XC\XC-VDC01\Virtual Hard Disks\03-XC-VDC01-ADCare.ps1" -value "New-ADOrganizationalUnit -Name Servers -Path `"OU=Tier2,OU=ESAE,DC=XCHANGE-CENTER,DC=DE`""
		Add-Content -Path "$Destination\$($Prefix)XC\XC-VDC01\Virtual Hard Disks\03-XC-VDC01-ADCare.ps1" -value "New-ADUser -Name T0-Admin1 -SamAccountName T0-Admin1 -UserPrincipalName T0-Admin1@xchange-center.de -AccountPassword (ConvertTo-SecureString -AsPlainText -Force -String `"C0mplex`") -Path `"OU=Accounts,OU=Tier0,OU=ESAE,DC=XCHANGE-CENTER,DC=DE`" -Enabled `$true"
		Add-Content -Path "$Destination\$($Prefix)XC\XC-VDC01\Virtual Hard Disks\03-XC-VDC01-ADCare.ps1" -value "New-ADUser -Name T0-SchMhandl -SamAccountName T0-SchMhandl -UserPrincipalName T0-SchMhandl@xchange-center.de -AccountPassword (ConvertTo-SecureString -AsPlainText -Force -String `"C0mplex`") -Path `"OU=Accounts,OU=Tier0,OU=ESAE,DC=XCHANGE-CENTER,DC=DE`" -Enabled `$true"
		Add-Content -Path "$Destination\$($Prefix)XC\XC-VDC01\Virtual Hard Disks\03-XC-VDC01-ADCare.ps1" -value "New-ADUser -Name T0-SchDturner -SamAccountName T0-SchDturner -UserPrincipalName T0-SchDturner@xchange-center.de -AccountPassword (ConvertTo-SecureString -AsPlainText -Force -String `"C0mplex`") -Path `"OU=Accounts,OU=Tier0,OU=ESAE,DC=XCHANGE-CENTER,DC=DE`" -Enabled `$true"
		Add-Content -Path "$Destination\$($Prefix)XC\XC-VDC01\Virtual Hard Disks\03-XC-VDC01-ADCare.ps1" -value "New-ADUser -Name T0-SchTpham -SamAccountName T0-SchTpham -UserPrincipalName T0-SchTpham@xchange-center.de -AccountPassword (ConvertTo-SecureString -AsPlainText -Force -String `"C0mplex`") -Path `"OU=Accounts,OU=Tier0,OU=ESAE,DC=XCHANGE-CENTER,DC=DE`" -Enabled `$true"
		Add-Content -Path "$Destination\$($Prefix)XC\XC-VDC01\Virtual Hard Disks\03-XC-VDC01-ADCare.ps1" -value "New-ADUser -Name T0-EntMhandl -SamAccountName T0-EntMhandl -UserPrincipalName T0-EntMhandl@xchange-center.de -AccountPassword (ConvertTo-SecureString -AsPlainText -Force -String `"C0mplex`") -Path `"OU=Accounts,OU=Tier0,OU=ESAE,DC=XCHANGE-CENTER,DC=DE`" -Enabled `$true"
		Add-Content -Path "$Destination\$($Prefix)XC\XC-VDC01\Virtual Hard Disks\03-XC-VDC01-ADCare.ps1" -value "New-ADUser -Name T0-EntDturner -SamAccountName T0-EntDturner -UserPrincipalName T0-EntDturner@xchange-center.de -AccountPassword (ConvertTo-SecureString -AsPlainText -Force -String `"C0mplex`") -Path `"OU=Accounts,OU=Tier0,OU=ESAE,DC=XCHANGE-CENTER,DC=DE`" -Enabled `$true"
		Add-Content -Path "$Destination\$($Prefix)XC\XC-VDC01\Virtual Hard Disks\03-XC-VDC01-ADCare.ps1" -value "New-ADUser -Name T0-EntTpham -SamAccountName T0-EntTpham -UserPrincipalName T0-EntTpham@xchange-center.de -AccountPassword (ConvertTo-SecureString -AsPlainText -Force -String `"C0mplex`") -Path `"OU=Accounts,OU=Tier0,OU=ESAE,DC=XCHANGE-CENTER,DC=DE`" -Enabled `$true"
		Add-Content -Path "$Destination\$($Prefix)XC\XC-VDC01\Virtual Hard Disks\03-XC-VDC01-ADCare.ps1" -value "New-ADUser -Name T0-DomMhandl -SamAccountName T0-DomMhandl -UserPrincipalName T0-DomMhandl@xchange-center.de -AccountPassword (ConvertTo-SecureString -AsPlainText -Force -String `"C0mplex`") -Path `"OU=Accounts,OU=Tier0,OU=ESAE,DC=XCHANGE-CENTER,DC=DE`" -Enabled `$true"
		Add-Content -Path "$Destination\$($Prefix)XC\XC-VDC01\Virtual Hard Disks\03-XC-VDC01-ADCare.ps1" -value "New-ADUser -Name T0-DomDturner -SamAccountName T0-DomDturner -UserPrincipalName T0-DomDturner@xchange-center.de -AccountPassword (ConvertTo-SecureString -AsPlainText -Force -String `"C0mplex`") -Path `"OU=Accounts,OU=Tier0,OU=ESAE,DC=XCHANGE-CENTER,DC=DE`" -Enabled `$true"
		Add-Content -Path "$Destination\$($Prefix)XC\XC-VDC01\Virtual Hard Disks\03-XC-VDC01-ADCare.ps1" -value "New-ADUser -Name T0-DomTpham -SamAccountName T0-DomTpham -UserPrincipalName T0-DomTpham@xchange-center.de -AccountPassword (ConvertTo-SecureString -AsPlainText -Force -String `"C0mplex`") -Path `"OU=Accounts,OU=Tier0,OU=ESAE,DC=XCHANGE-CENTER,DC=DE`" -Enabled `$true"
		Add-Content -Path "$Destination\$($Prefix)XC\XC-VDC01\Virtual Hard Disks\03-XC-VDC01-ADCare.ps1" -value "New-ADUser -Name T0-GpoMhandl -SamAccountName T0-GpoMhandl -UserPrincipalName T0-GpoMhandl@xchange-center.de -AccountPassword (ConvertTo-SecureString -AsPlainText -Force -String `"C0mplex`") -Path `"OU=Accounts,OU=Tier0,OU=ESAE,DC=XCHANGE-CENTER,DC=DE`" -Enabled `$true"
		Add-Content -Path "$Destination\$($Prefix)XC\XC-VDC01\Virtual Hard Disks\03-XC-VDC01-ADCare.ps1" -value "New-ADUser -Name T0-GpoDturner -SamAccountName T0-GpoDturner -UserPrincipalName T0-GpoDturner@xchange-center.de -AccountPassword (ConvertTo-SecureString -AsPlainText -Force -String `"C0mplex`") -Path `"OU=Accounts,OU=Tier0,OU=ESAE,DC=XCHANGE-CENTER,DC=DE`" -Enabled `$true"
		Add-Content -Path "$Destination\$($Prefix)XC\XC-VDC01\Virtual Hard Disks\03-XC-VDC01-ADCare.ps1" -value "New-ADUser -Name T0-GpoTpham -SamAccountName T0-GpoTpham -UserPrincipalName T0-GpoTpham@xchange-center.de -AccountPassword (ConvertTo-SecureString -AsPlainText -Force -String `"C0mplex`") -Path `"OU=Accounts,OU=Tier0,OU=ESAE,DC=XCHANGE-CENTER,DC=DE`" -Enabled `$true"
		Add-Content -Path "$Destination\$($Prefix)XC\XC-VDC01\Virtual Hard Disks\03-XC-VDC01-ADCare.ps1" -value "New-ADGroup -Name T0-SchAdmins -GroupCategory Security -GroupScope Universal -Path `"OU=Groups,OU=Tier0,OU=ESAE,DC=XCHANGE-CENTER,DC=DE`""
		Add-Content -Path "$Destination\$($Prefix)XC\XC-VDC01\Virtual Hard Disks\03-XC-VDC01-ADCare.ps1" -value "New-ADGroup -Name T0-EntAdmins -GroupCategory Security -GroupScope Universal -Path `"OU=Groups,OU=Tier0,OU=ESAE,DC=XCHANGE-CENTER,DC=DE`""
		Add-Content -Path "$Destination\$($Prefix)XC\XC-VDC01\Virtual Hard Disks\03-XC-VDC01-ADCare.ps1" -value "New-ADGroup -Name T0-DomAdmins -GroupCategory Security -GroupScope Universal -Path `"OU=Groups,OU=Tier0,OU=ESAE,DC=XCHANGE-CENTER,DC=DE`""
		Add-Content -Path "$Destination\$($Prefix)XC\XC-VDC01\Virtual Hard Disks\03-XC-VDC01-ADCare.ps1" -value "New-ADGroup -Name T0-GpoAdmins -GroupCategory Security -GroupScope Universal -Path `"OU=Groups,OU=Tier0,OU=ESAE,DC=XCHANGE-CENTER,DC=DE`""
		Add-Content -Path "$Destination\$($Prefix)XC\XC-VDC01\Virtual Hard Disks\03-XC-VDC01-ADCare.ps1" -value "Add-ADGroupMember -Identity `"Schema Admins`" -Members `"T0-SchAdmins`""
		Add-Content -Path "$Destination\$($Prefix)XC\XC-VDC01\Virtual Hard Disks\03-XC-VDC01-ADCare.ps1" -value "Add-ADGroupMember -Identity `"Enterprise Admins`" -Members `"T0-EntAdmins`""
		Add-Content -Path "$Destination\$($Prefix)XC\XC-VDC01\Virtual Hard Disks\01-XC-VDC01.cmd" -value "powershell.exe Set-ExecutionPolicy -ExecutionPolicy Unrestricted"
		Add-Content -Path "$Destination\$($Prefix)XC\XC-VDC01\Virtual Hard Disks\01-XC-VDC01.cmd" -value "powershell.exe -noexit C:\SetupTemp\01-XC-VDC01.ps1"
		Add-Content -Path "$Destination\$($Prefix)XC\XC-VDC01\Virtual Hard Disks\02-XC-VDC01-ADDeploy.cmd" -value "powershell.exe Set-ExecutionPolicy -ExecutionPolicy Unrestricted"
		Add-Content -Path "$Destination\$($Prefix)XC\XC-VDC01\Virtual Hard Disks\02-XC-VDC01-ADDeploy.cmd" -value "powershell.exe -noexit C:\SetupTemp\02-XC-VDC01-ADDeploy.ps1"
		Add-Content -Path "$Destination\$($Prefix)XC\XC-VDC01\Virtual Hard Disks\03-XC-VDC01-ADCare.cmd" -value "powershell.exe Set-ExecutionPolicy -ExecutionPolicy Unrestricted"
		Add-Content -Path "$Destination\$($Prefix)XC\XC-VDC01\Virtual Hard Disks\03-XC-VDC01-ADCare.cmd" -value "powershell.exe -noexit C:\SetupTemp\03-XC-VDC01-ADCare.ps1"
		Add-Content -Path "$Destination\$($Prefix)XC\XC-VDC01\Virtual Hard Disks\04-XC-VDC01-RegPatch.cmd" -value "powershell.exe -noexit C:\SetupTemp\04-XC-VDC01-RegPatch.ps1"
		Add-Content -Path "$Destination\$($Prefix)XC\XC-VDC01\Virtual Hard Disks\04-XC-VDC01-RegPatch.ps1" -value "Set-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\Control\Lsa\ -Name TcpIpClientSupport -Type DWORD -Value 1"
		Add-Content -Path "$Destination\$($Prefix)XC\XC-VDC01\Virtual Hard Disks\05-XC-VDC01-NameResolution.cmd" -value "powershell.exe -noexit C:\SetupTemp\05-XC-VDC01-NameResolution.ps1"
		Add-Content -Path "$Destination\$($Prefix)XC\XC-VDC01\Virtual Hard Disks\05-XC-VDC01-NameResolution.ps1" -value "Add-DnsServerConditionalForwarderZone -ZoneName asai-center.de -ReplicationScope Forest -MasterServers 192.168.50.1"
		Add-Content -Path "$Destination\$($Prefix)XC\XC-VDC01\Virtual Hard Disks\05-XC-VDC01-NameResolution.ps1" -value "Add-DnsServerConditionalForwarderZone -ZoneName 50.168.192.in-addr.arpa -ReplicationScope Forest -MasterServers 192.168.50.1"
		Add-Content -Path "$Destination\$($Prefix)XC\XC-VDC01\Virtual Hard Disks\05-XC-VDC01-NameResolution.ps1" -value "Add-DnsServerConditionalForwarderZone -ZoneName ads-center.de -ReplicationScope Forest -MasterServers 192.168.1.1"
		Add-Content -Path "$Destination\$($Prefix)XC\XC-VDC01\Virtual Hard Disks\05-XC-VDC01-NameResolution.ps1" -value "Add-DnsServerConditionalForwarderZone -ZoneName 1.168.192.in-addr.arpa -ReplicationScope Forest -MasterServers 192.168.1.1"
		Add-Content -Path "$Destination\$($Prefix)XC\XC-VDC01\Virtual Hard Disks\06-XC-VDC01-TrustFix.cmd" -value "netdom trust xchange-center.de /domain:asai-center.de /quarantine:no /userd:administrator /passwordd:C0mplex"
		
		Write-Verbose "Mounting XC-VDC01.vhdx and copying the automated setup files."
		$driveb4 = (Get-PSDrive).Name
		Mount-VHD -Path "$Destination\$($Prefix)XC\XC-VDC01\Virtual Hard Disks\XC-VDC01.vhdx"
		$driveat = (Get-PSDrive).name
		$drive = (Compare-Object -ReferenceObject $driveb4 -DifferenceObject $driveat).inputobject[-1] + ':'
		New-Item -Path $drive\SetupTemp -ItemType Directory | Out-Null
		Set-Location -Path $drive\SetupTemp | Out-Null
		Copy-Item -Path "$Destination\$($Prefix)XC\XC-VDC01\Virtual Hard Disks\01-XC-VDC01.cmd" -Destination . | Out-Null
		Copy-Item -Path "$Destination\$($Prefix)XC\XC-VDC01\Virtual Hard Disks\01-XC-VDC01.ps1" -Destination . | Out-Null
		Copy-Item -Path "$Destination\$($Prefix)XC\XC-VDC01\Virtual Hard Disks\02-XC-VDC01-ADDeploy.ps1" -Destination . | Out-Null
		Copy-Item -Path "$Destination\$($Prefix)XC\XC-VDC01\Virtual Hard Disks\02-XC-VDC01-ADDeploy.cmd" -Destination . | Out-Null
		Copy-Item -Path "$Destination\$($Prefix)XC\XC-VDC01\Virtual Hard Disks\03-XC-VDC01-ADCare.ps1" -Destination . | Out-Null
		Copy-Item -Path "$Destination\$($Prefix)XC\XC-VDC01\Virtual Hard Disks\03-XC-VDC01-ADCare.cmd" -Destination . | Out-Null
		Copy-Item -Path "$Destination\$($Prefix)XC\XC-VDC01\Virtual Hard Disks\04-XC-VDC01-RegPatch.cmd" -Destination . | Out-Null
		Copy-Item -Path "$Destination\$($Prefix)XC\XC-VDC01\Virtual Hard Disks\04-XC-VDC01-RegPatch.ps1" -Destination . | Out-Null
		Copy-Item -Path "$Destination\$($Prefix)XC\XC-VDC01\Virtual Hard Disks\05-XC-VDC01-NameResolution.cmd" -Destination . | Out-Null
		Copy-Item -Path "$Destination\$($Prefix)XC\XC-VDC01\Virtual Hard Disks\05-XC-VDC01-NameResolution.ps1" -Destination . | Out-Null
		Copy-Item -Path "$Destination\$($Prefix)XC\XC-VDC01\Virtual Hard Disks\06-XC-VDC01-TrustFix.cmd" -Destination . | Out-Null
		Set-Location -Path c: | Out-Null
		Dismount-VHD -Path "$Destination\$($Prefix)XC\XC-VDC01\Virtual Hard Disks\XC-VDC01.vhdx"
		Write-Verbose "Dismounted XC-VDC01.vhdx successfully."
		
		#XC-VEX01
		Write-Verbose "Creating autmated setup files for XC-VEX01."
		New-Item -Name 01-XC-VEX01.cmd -ItemType file -Path "$Destination\$($Prefix)XC\XC-VEX01\Virtual Hard Disks\" | Out-Null
		New-Item -Name 01-XC-VEX01.ps1 -ItemType file -Path "$Destination\$($Prefix)XC\XC-VEX01\Virtual Hard Disks\" | Out-Null
		New-Item -Name 01-XC-VEX01Prep.cmd -ItemType file -Path "$Destination\$($Prefix)XC\XC-VEX01\Virtual Hard Disks\" | Out-Null
		New-Item -Name 01-XC-VEX01Prep.ps1 -ItemType file -Path "$Destination\$($Prefix)XC\XC-VEX01\Virtual Hard Disks\" | Out-Null
		Add-Content -Path "$Destination\$($Prefix)XC\XC-VEX01\Virtual Hard Disks\01-XC-VEX01.ps1" -value "Get-ScheduledTask -TaskName servermanager | Disable-ScheduledTask"
		Add-Content -Path "$Destination\$($Prefix)XC\XC-VEX01\Virtual Hard Disks\01-XC-VEX01.ps1" -value "Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled false"
		Add-Content -Path "$Destination\$($Prefix)XC\XC-VEX01\Virtual Hard Disks\01-XC-VEX01.ps1" -value "Set-ItemProperty -Path `'HKLM:\System\CurrentControlSet\Control\Terminal Server`'-name `"fDenyTSConnections`" -Value 0"
		Add-Content -Path "$Destination\$($Prefix)XC\XC-VEX01\Virtual Hard Disks\01-XC-VEX01.ps1" -value "Enable-NetFirewallRule -DisplayGroup `"Remote Desktop`""
		Add-Content -Path "$Destination\$($Prefix)XC\XC-VEX01\Virtual Hard Disks\01-XC-VEX01.ps1" -value "Set-ItemProperty -Path `'HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp`' -name `"UserAuthentication`" -Value 1"
		Add-Content -Path "$Destination\$($Prefix)XC\XC-VEX01\Virtual Hard Disks\01-XC-VEX01.ps1" -value "Disable-NetAdapterBinding -InterfaceAlias ethernet -ComponentID ms_tcpip6"
		Add-Content -Path "$Destination\$($Prefix)XC\XC-VEX01\Virtual Hard Disks\01-XC-VEX01.ps1" -value "New-NetIPAddress -InterfaceAlias ethernet -IPAddress 192.168.160.2 -PrefixLength 24 -DefaultGateway 192.168.160.254"
		Add-Content -Path "$Destination\$($Prefix)XC\XC-VEX01\Virtual Hard Disks\01-XC-VEX01.ps1" -value "(Get-WmiObject -Class Win32_NetworkAdapterConfiguration | Where-Object { `$PSItem.description -like `"*hyper*`" }).settcpipnetbios(2)"
		Add-Content -Path "$Destination\$($Prefix)XC\XC-VEX01\Virtual Hard Disks\01-XC-VEX01.ps1" -value "Set-DnsClientServerAddress -InterfaceAlias ethernet -ResetServerAddresses"
		Add-Content -Path "$Destination\$($Prefix)XC\XC-VEX01\Virtual Hard Disks\01-XC-VEX01.ps1" -value "Set-DnsClientServerAddress -InterfaceAlias ethernet -ServerAddresses `"192.168.160.1`""
		Add-Content -Path "$Destination\$($Prefix)XC\XC-VEX01\Virtual Hard Disks\01-XC-VEX01.ps1" -value "`$Cred = New-object System.Management.Automation.PSCredential `"administrator@xchange-center.de`", (ConvertTo-SecureString -String `"C0mplex`" -AsPlainText -Force)"
		Add-Content -Path "$Destination\$($Prefix)XC\XC-VEX01\Virtual Hard Disks\01-XC-VEX01.ps1" -value "Add-Computer -DomainCredential `$cred -DomainName xchange-center.de -NewName XC-VEX01 -Restart"
		Add-Content -Path "$Destination\$($Prefix)XC\XC-VEX01\Virtual Hard Disks\01-XC-VEX01.cmd" -value "powershell.exe Set-ExecutionPolicy -ExecutionPolicy Unrestricted"
		Add-Content -Path "$Destination\$($Prefix)XC\XC-VEX01\Virtual Hard Disks\01-XC-VEX01.cmd" -value "powershell.exe -noexit C:\SetupTemp\01-XC-VEX01.ps1"
		Add-Content -Path "$Destination\$($Prefix)XC\XC-VEX01\Virtual Hard Disks\02-XC-VEX01Prep.cmd" -value "powershell.exe Set-ExecutionPolicy -ExecutionPolicy Unrestricted"
		Add-Content -Path "$Destination\$($Prefix)XC\XC-VEX01\Virtual Hard Disks\02-XC-VEX01Prep.cmd" -value "powershell.exe -noexit C:\SetupTemp\02-XC-VEX01Prep.ps1"
		Add-Content -Path "$Destination\$($Prefix)XC\XC-VEX01\Virtual Hard Disks\02-XC-VEX01Prep.ps1" -value "Install-WindowsFeature NET-Framework-45-Features, RPC-over-HTTP-proxy, RSAT-Clustering, RSAT-Clustering-CmdInterface, RSAT-Clustering-Mgmt, RSAT-Clustering-PowerShell, Web-Mgmt-Console, WAS-Process-Model, Web-Asp-Net45, Web-Basic-Auth, Web-Client-Auth, Web-Digest-Auth, Web-Dir-Browsing, Web-Dyn-Compression, Web-Http-Errors, Web-Http-Logging, Web-Http-Redirect, Web-Http-Tracing, Web-ISAPI-Ext, Web-ISAPI-Filter, Web-Lgcy-Mgmt-Console, Web-Metabase, Web-Mgmt-Console, Web-Mgmt-Service, Web-Net-Ext45, Web-Request-Monitor, Web-Server, Web-Stat-Compression, Web-Static-Content, Web-Windows-Auth, Web-WMI, Windows-Identity-Foundation, RSAT-ADDS"
		Add-Content -Path "$Destination\$($Prefix)XC\XC-VEX01\Virtual Hard Disks\02-XC-VEX01Prep.ps1" -value "Set-ItemProperty -Path `"HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}`" -Name IsInstalled -Type DWord -Value 0"
		Add-Content -Path "$Destination\$($Prefix)XC\XC-VEX01\Virtual Hard Disks\02-XC-VEX01Prep.ps1" -value "Set-ItemProperty -Path `"HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}`" -Name IsInstalled -Type DWord -Value 0"
		Add-Content -Path "$Destination\$($Prefix)XC\XC-VEX01\Virtual Hard Disks\03-XC-VEX01EX2016Inst.cmd" -value "d:\setup.exe /PrepareAD /OrganizationName:`"XCHANGE CENTER`" /IAcceptExchangeServerLicenseTerms"
		Add-Content -Path "$Destination\$($Prefix)XC\XC-VEX01\Virtual Hard Disks\03-XC-VEX01EX2016Inst.cmd" -value "d:\setup.exe /Mode:Install /Role:Mailbox /IAcceptExchangeServerLicenseTerms"
		Add-Content -Path "$Destination\$($Prefix)XC\XC-VEX01\Virtual Hard Disks\04-XC-VEX01LinkedMBX.ps1" -value "`$credads = New-Object System.Management.Automation.PSCredential `"ads\administrator`",(ConvertTo-SecureString -AsPlainText -Force -String `"C0mplex`")"
		Add-Content -Path "$Destination\$($Prefix)XC\XC-VEX01\Virtual Hard Disks\04-XC-VEX01LinkedMBX.ps1" -value "`$credasai = New-Object System.Management.Automation.PSCredential `"asai\administrator`",(ConvertTo-SecureString -AsPlainText -Force -String `"C0mplex`")"
		Add-Content -Path "$Destination\$($Prefix)XC\XC-VEX01\Virtual Hard Disks\04-XC-VEX01LinkedMBX.ps1" -value "New-AcceptedDomain -Name ADS-CENTER.DE -DomainName ADS-CENTER.DE"
		Add-Content -Path "$Destination\$($Prefix)XC\XC-VEX01\Virtual Hard Disks\04-XC-VEX01LinkedMBX.ps1" -value "Set-AcceptedDomain -Name ADS-CENTER.DE -Identity ADS-CENTER.DE -MakeDefault $true"
		Add-Content -Path "$Destination\$($Prefix)XC\XC-VEX01\Virtual Hard Disks\04-XC-VEX01LinkedMBX.ps1" -value "New-AcceptedDomain -Name ASAI-CENTER.DE -DomainName ASAI-CENTER.DE"
		Add-Content -Path "$Destination\$($Prefix)XC\XC-VEX01\Virtual Hard Disks\04-XC-VEX01LinkedMBX.ps1" -value "New-Mailbox -Alias ADS.Tpham -Name ADS.Tpham -OrganizationalUnit users -LinkedMasterAccount Tpham@ads-center.de -LinkedDomainController ads-vdc01.ads-center.de -UserPrincipalName ADS.Tpham@xchange-center.de -LinkedCredential `$credads  -PrimarySmtpAddress tpham@ads-center.de"
		Add-Content -Path "$Destination\$($Prefix)XC\XC-VEX01\Virtual Hard Disks\04-XC-VEX01LinkedMBX.ps1" -value "New-Mailbox -Alias ADS.Dturner -Name ADS.Dturner -OrganizationalUnit users -LinkedMasterAccount Dturner@ads-center.de -LinkedDomainController ads-vdc01.ads-center.de -UserPrincipalName ADS.Dturner@xchange-center.de -LinkedCredential `$credads -PrimarySmtpAddress dturner@ads-center.de"
		Add-Content -Path "$Destination\$($Prefix)XC\XC-VEX01\Virtual Hard Disks\04-XC-VEX01LinkedMBX.ps1" -value "New-Mailbox -Alias ADS.Mhandl -Name ADS.Mhandl -OrganizationalUnit users -LinkedMasterAccount Mhandl@ads-center.de -LinkedDomainController ads-vdc01.ads-center.de -UserPrincipalName ADS.Mhandl@xchange-center.de -LinkedCredential `$credads -PrimarySmtpAddress mhandl@ads-center.de"
		Add-Content -Path "$Destination\$($Prefix)XC\XC-VEX01\Virtual Hard Disks\04-XC-VEX01LinkedMBX.ps1" -value "New-Mailbox -Alias ASAI.MIMService -Name ASAI.MIMService -OrganizationalUnit users -LinkedMasterAccount MIMService@asai-center.de -LinkedDomainController asai-vdc01.asai-center.de -UserPrincipalName ASAI.MIMService@xchange-center.de -LinkedCredential `$credasai -PrimarySmtpAddress mimservice@asai-center.de"
		
		Write-Verbose "Mounting XC-VEX01.vhdx and copying the automated setup files."
		$driveb4 = (Get-PSDrive).Name
		Mount-VHD -Path "$Destination\$($Prefix)XC\XC-VEX01\Virtual Hard Disks\XC-VEX01.vhdx"
		$driveat = (Get-PSDrive).name
		$drive = (Compare-Object -ReferenceObject $driveb4 -DifferenceObject $driveat).inputobject[-1] + ':'
		New-Item -Path $drive\SetupTemp -ItemType Directory | Out-Null
		Set-Location -Path $drive\SetupTemp | Out-Null
		Copy-Item -Path "$Destination\$($Prefix)XC\XC-VEX01\Virtual Hard Disks\01-XC-VEX01.cmd" -Destination . | Out-Null
		Copy-Item -Path "$Destination\$($Prefix)XC\XC-VEX01\Virtual Hard Disks\01-XC-VEX01.ps1" -Destination . | Out-Null
		Copy-Item -Path "$Destination\$($Prefix)XC\XC-VEX01\Virtual Hard Disks\02-XC-VEX01Prep.cmd" -Destination . | Out-Null
		Copy-Item -Path "$Destination\$($Prefix)XC\XC-VEX01\Virtual Hard Disks\02-XC-VEX01Prep.ps1" -Destination . | Out-Null
		Copy-Item -Path "$Destination\$($Prefix)XC\XC-VEX01\Virtual Hard Disks\03-XC-VEX01EX2016Inst.cmd" -Destination . | Out-Null
		Copy-Item -Path "$Destination\$($Prefix)XC\XC-VEX01\Virtual Hard Disks\04-XC-VEX01LinkedMBX.ps1" -Destination . | Out-Null
		Set-Location -Path c: | Out-Null
		Dismount-VHD -Path "$Destination\$($Prefix)XC\XC-VEX01\Virtual Hard Disks\XC-VEX01.vhdx"
		Write-Verbose "Dismounted XC-VEX01.vhdx successfully."
		
		#ADS - XC-VCA01
		Write-Verbose "Creating automated setup files for XC-VCA01."
		New-Item -Name 01-XC-VCA01.cmd -ItemType file -Path "$Destination\$($Prefix)XC\XC-VCA01\Virtual Hard Disks\" | Out-Null
		New-Item -Name 01-XC-VCA01.ps1 -ItemType file -Path "$Destination\$($Prefix)XC\XC-VCA01\Virtual Hard Disks\" | Out-Null
		Add-Content -Path "$Destination\$($Prefix)XC\XC-VCA01\Virtual Hard Disks\01-XC-VCA01.ps1" -value "Get-ScheduledTask -TaskName servermanager | Disable-ScheduledTask"
		Add-Content -Path "$Destination\$($Prefix)XC\XC-VCA01\Virtual Hard Disks\01-XC-VCA01.ps1" -value "Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled false"
		Add-Content -Path "$Destination\$($Prefix)XC\XC-VCA01\Virtual Hard Disks\01-XC-VCA01.ps1" -value "Set-ItemProperty -Path `'HKLM:\System\CurrentControlSet\Control\Terminal Server`'-name `"fDenyTSConnections`" -Value 0"
		Add-Content -Path "$Destination\$($Prefix)XC\XC-VCA01\Virtual Hard Disks\01-XC-VCA01.ps1" -value "Enable-NetFirewallRule -DisplayGroup `"Remote Desktop`""
		Add-Content -Path "$Destination\$($Prefix)XC\XC-VCA01\Virtual Hard Disks\01-XC-VCA01.ps1" -value "Set-ItemProperty -Path `'HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp`' -name `"UserAuthentication`" -Value 1"
		Add-Content -Path "$Destination\$($Prefix)XC\XC-VCA01\Virtual Hard Disks\01-XC-VCA01.ps1" -value "Disable-NetAdapterBinding -InterfaceAlias ethernet -ComponentID ms_tcpip6"
		Add-Content -Path "$Destination\$($Prefix)XC\XC-VCA01\Virtual Hard Disks\01-XC-VCA01.ps1" -value "New-NetIPAddress -InterfaceAlias ethernet -IPAddress 192.168.160.3 -PrefixLength 24 -DefaultGateway 192.168.160.254"
		Add-Content -Path "$Destination\$($Prefix)XC\XC-VCA01\Virtual Hard Disks\01-XC-VCA01.ps1" -value "(Get-WmiObject -Class Win32_NetworkAdapterConfiguration | Where-Object { `$PSItem.description -like `"*hyper*`" }).settcpipnetbios(2)"
		Add-Content -Path "$Destination\$($Prefix)XC\XC-VCA01\Virtual Hard Disks\01-XC-VCA01.ps1" -value "Set-DnsClientServerAddress -InterfaceAlias ethernet -ResetServerAddresses"
		Add-Content -Path "$Destination\$($Prefix)XC\XC-VCA01\Virtual Hard Disks\01-XC-VCA01.ps1" -value "Set-DnsClientServerAddress -InterfaceAlias ethernet -ServerAddresses `"192.168.160.1`""
		Add-Content -Path "$Destination\$($Prefix)XC\XC-VCA01\Virtual Hard Disks\01-XC-VCA01.ps1" -value "`$Cred = New-object System.Management.Automation.PSCredential `"administrator@xchange-center.de`", (ConvertTo-SecureString -String `"C0mplex`" -AsPlainText -Force)"
		Add-Content -Path "$Destination\$($Prefix)XC\XC-VCA01\Virtual Hard Disks\01-XC-VCA01.ps1" -value "Add-Computer -DomainCredential `$cred -DomainName xchange-center.de -NewName XC-VCA01 -Restart"
		Add-Content -Path "$Destination\$($Prefix)XC\XC-VCA01\Virtual Hard Disks\01-XC-VCA01.cmd" -value "powershell.exe Set-ExecutionPolicy -ExecutionPolicy Unrestricted"
		Add-Content -Path "$Destination\$($Prefix)XC\XC-VCA01\Virtual Hard Disks\01-XC-VCA01.cmd" -value "powershell.exe -noexit C:\SetupTemp\01-XC-VCA01.ps1"
		
		Write-Verbose "Mounting $($Prefix)XC-VCA01.vhdx and copying the automated setup files."
		$driveb4 = (Get-PSDrive).Name
		Mount-VHD -Path "$Destination\$($Prefix)XC\XC-VCA01\Virtual Hard Disks\XC-VCA01.vhdx"
		$driveat = (Get-PSDrive).name
		$drive = (Compare-Object -ReferenceObject $driveb4 -DifferenceObject $driveat).inputobject[-1] + ':'
		New-Item -Path $drive\SetupTemp -ItemType Directory | Out-Null
		Set-Location -Path $drive\SetupTemp | Out-Null
		Copy-Item -Path "$Destination\$($Prefix)XC\XC-VCA01\Virtual Hard Disks\01-XC-VCA01.cmd" -Destination . | Out-Null
		Copy-Item -Path "$Destination\$($Prefix)XC\XC-VCA01\Virtual Hard Disks\01-XC-VCA01.ps1" -Destination . | Out-Null
		Set-Location -Path c: | Out-Null
		Dismount-VHD -Path "$Destination\$($Prefix)XC\XC-VCA01\Virtual Hard Disks\XC-VCA01.vhdx"
		Write-Verbose "Dismounted $($Prefix)XC-VCA01.vhdx successfully."
		
		#Create VMs
		Write-Verbose "Creating XC VMs."
		new-vm -Name "$($Prefix)XC-VDC01" -MemoryStartupBytes 1024MB -Path "$Destination\$($Prefix)XC\" -VHDPath "$Destination\$($Prefix)XC\XC-VDC01\Virtual Hard Disks\XC-VDC01.vhdx" -SwitchName $switchname -Generation 2 | out-null
		Set-VMProcessor -VMName "$($Prefix)XC-VDC01" -Count $([math]::Floor($CPUCount / 4))
		Add-VMDvdDrive -VMName "$($Prefix)XC-VDC01"
		new-vm -Name "$($Prefix)XC-VEX01" -MemoryStartupBytes 1024MB -Path "$Destination\$($Prefix)XC\" -VHDPath "$Destination\$($Prefix)XC\XC-VEX01\Virtual Hard Disks\XC-VEX01.vhdx" -SwitchName $switchname -Generation 2 | out-null
		Add-VMDvdDrive -VMName "$($Prefix)XC-VEX01"
		Set-VMProcessor -VMName "$($Prefix)XC-VEX01" -Count $([math]::Floor($CPUCount / 2))
		new-vm -Name "$($Prefix)XC-VCA01" -MemoryStartupBytes 1024MB -Path "$Destination\$($Prefix)XC\" -VHDPath "$Destination\$($Prefix)XC\XC-VCA01\Virtual Hard Disks\XC-VCA01.vhdx" -SwitchName $switchname -Generation 2 | out-null
		Set-VMProcessor -VMName "$($Prefix)XC-VCA01" -Count $([math]::Floor($CPUCount / 4))
		Add-VMDvdDrive -VMName "$($Prefix)XC-VCA01"
				
		Write-Verbose "Configuring dynamicMemory on every XC VM."
		Set-VM -VM (Get-VM -Name "$($Prefix)XC-*") -DynamicMemory
	}
	
	end
	{
		Write-Host "Created......$($Prefix)XC-VDC01......successfully."
		Write-Host "Created......$($Prefix)XC-VEX01......successfully."
		Write-Host "Created......$($Prefix)XC-VCA01.....successfully."
	}
}