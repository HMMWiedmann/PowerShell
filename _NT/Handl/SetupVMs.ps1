<#
.Synopsis
   Creates course setup scripts for ADS2016
.DESCRIPTION
   Creates course setup scripts for ADS2016
.EXAMPLE
   .\SetupVM.ps1 -seatnumber 01,02,15 -ParentDiskPath c:\PD -VMPath v:\VMs\ADS2016
.EXAMPLE
   . .\SetupVM.ps1
   Create-ADS2016Environment -seatnumber 01,02,15 -ParentDiskPath c:\PD -VMPath v:\VMs\ADS2016
.NOTES
   05.05.2016: Version 1.0
   12.09.2016: Version 1.1
		- Setup Files werden in die VHDs injected
		- Korrektur der Maschinenanzahl
   09.05.2017: Version 1.2
		- Korrektur des Domain- und ForestFunctionalLevels
   11.06.2017: Version 1.3
		- Legacy Universal Groups hinzugefügt
   24.07.2017: Version 1.4
		- AutoLogin hinzugefügt
   03.09.2017: Version 1.5
		- Fehler in Forest Root Domain korrigiert
   11.09.2017: Version 1.6
		- Namen aus ASAI-Struktur (ADS-CENTER.DE) angepasst
#>
function Create-ADS2016Environment
{
	[CmdletBinding(SupportsShouldProcess = $true)]
	[Alias('Create-ADS2016Env')]
	[OutputType([int])]
	Param
	(
		# Seat numbers of students
		[Parameter(Mandatory = $true,
				   ValueFromPipelineByPropertyName = $true,
				   Position = 0)]
		$seatnumber,
		# parent disk path

		[Parameter(Mandatory = $true,
				   ValueFromPipelineByPropertyName = $true,
				   Position = 1)]
		$ParentDiskPath,
		# vm path

		[parameter(Mandatory = $true,
				   ValueFromPipelineByPropertyName = $true,
				   Position = 2)]
		$VMPath
	)
	
	Begin
	{
		## Test path parent disks ##
		$PDPath = Test-Path -Path $ParentDiskPath -ErrorAction Stop
		switch ($PDPath)
		{
			$false { Write-Host "Der Pfad zu den Parentdisks ist nicht vorhanden oder inkorrekt." }
			default { }
		}
		
		## machine count ##
		$2008R2DCs = 5
		$2012R2DCs = 2
		$2016DCs = 5
		$Win7 = 1
		$Win10 = 1
		$FR2008R2DCs = 3
		$FR2012R2DCs = 2
		$FR2016DCs = 3
		$FRVR = 1
		
		## domain names ##
		$DomainNameFR = "ads-center.de"
		$DomainNames = foreach ($dn in $seatnumber) { "SUB" + "{0:D2}" -f $dn + "." + "ads-center.de" }
		
		## DC names ##
		$NetBIOSFR = "ADS"
		$NetBIOSDN = foreach ($ndn in $seatnumber) { "SUB" + "{0:D2}" -f $ndn }
		$DCNames2008R2 = foreach ($b in $NetBIOSDN)
		{
			for ($i = 1; $i -le $2008R2DCs; $i++) { $b + "-VDC" + "{0:D2}" -f $i }
		}
		$DCNames2012R2 = foreach ($b in $NetBIOSDN)
		{
			for ($i = $($2008R2DCs + 1); $i -le $2008R2DCs + $2012R2DCs; $i++) { $b + "-VDC" + "{0:D2}" -f $i }
		}
		$DCNames2016 = foreach ($b in $NetBIOSDN)
		{
			for ($i = $($2008R2DCs + $2012R2DCs + 1); $i -le $2008R2DCs + $2012R2DCs + $2016DCs; $i++) { $b + "-VDC" + "{0:D2}" -f $i }
		}
		$NamesWin7 = foreach ($b in $NetBIOSDN)
		{
			for ($i = $($2008R2DCs + $2012R2DCs + $2016DCs + 1); $i -le $2008R2DCs + $2012R2DCs + $2016DCs + $Win7; $i++) { $b + "-VWin7" + "{0:D2}" -f $i }
		}
		$NamesWin10 = foreach ($b in $NetBIOSDN)
		{
			for ($i = $($2008R2DCs + $2012R2DCs + $2016DCs + $Win7 + 1); $i -le $2008R2DCs + $2012R2DCs + $2016DCs + $Win7 + $Win10; $i++) { $b + "-VWin10" + "{0:D2}" -f $i }
		}
		$DCNamesForestRoot2008R2 =
		foreach ($b in $NetBIOSFR)
		{
			for ($i = 1; $i -le $FR2008R2DCs; $i++)
			{ $b + "-VDC" + "{0:D2}" -f $i }
		}
		$DCNamesForestRoot2012R2 =
		foreach ($b in $NetBIOSFR)
		{
			for ($i = $FR2008R2DCs + 1; $i -le $FR2008R2DCs + $FR2012R2DCs; $i++)
			{ $b + "-VDC" + "{0:D2}" -f $i }
		}
		$DCNamesForestRoot2016 =
		foreach ($b in $NetBIOSFR)
		{
			for ($i = $FR2008R2DCs + $FR2012R2DCs + 1; $i -le $FR2008R2DCs + $FR2012R2DCs + $FR2016DCs; $i++)
			{ $b + "-VDC" + "{0:D2}" -f $i }
		}
		
		$DCNamesFirstDCs =
		for ($i = 0; $i -lt $DCNames2008R2.count; $i += ($2008R2DCs))
		{
			$DCNames2008R2[$i]
		}
		
		$DCNamesReplicADSs = $DCNames2008R2 | Where-Object { $PSItem -notlike "*01" }
		
		
	} #begin
	Process
	{
		## Setup Differencing Disks ##
		## Forest Root Domain ##
		for ($i = 0; $i -lt $DCNamesForestRoot2008R2.count; $i++)
		{
			New-VHD -ParentPath "$ParentDiskPath\2008R2\2008R2.vhdx" -Path "$VMPath\$($DCNamesForestRoot2008R2[$i])\Virtual Hard Disks\$($DCNamesForestRoot2008R2[$i]).vhdx" -Differencing | Out-Null
		}
		for ($i = 0; $i -lt $DCNamesForestRoot2012R2.count; $i++)
		{
			New-VHD -ParentPath "$ParentDiskPath\2012R2\2012R2.vhdx" -Path "$VMPath\$($DCNamesForestRoot2012R2[$i])\Virtual Hard Disks\$($DCNamesForestRoot2012R2[$i]).vhdx" -Differencing | Out-Null
		}
		for ($i = 0; $i -lt $DCNamesForestRoot2016.count; $i++)
		{
			New-VHD -ParentPath "$ParentDiskPath\2016\2016.vhdx" -Path "$VMPath\$($DCNamesForestRoot2016[$i])\Virtual Hard Disks\$($DCNamesForestRoot2016[$i]).vhdx" -Differencing | Out-Null
		}
		
		## SUBDoms ##
		for ($i = 0; $i -lt $DCNames2008R2.count; $i++)
		{
			New-VHD -ParentPath "$ParentDiskPath\2008R2\2008R2.vhdx" -Path "$VMPath\$($DCNames2008R2[$i])\Virtual Hard Disks\$($DCNames2008R2[$i]).vhdx" -Differencing | Out-Null
		}
		for ($i = 0; $i -lt $DCNames2012R2.count; $i++)
		{
			New-VHD -ParentPath "$ParentDiskPath\2012R2\2012R2.vhdx" -Path "$VMPath\$($DCNames2012R2[$i])\Virtual Hard Disks\$($DCNames2012R2[$i]).vhdx" -Differencing | Out-Null
		}
		for ($i = 0; $i -lt $DCNames2016.count; $i++)
		{
			New-VHD -ParentPath "$ParentDiskPath\2016\2016.vhdx" -Path "$VMPath\$($DCNames2016[$i])\Virtual Hard Disks\$($DCNames2016[$i]).vhdx" -Differencing | Out-Null
		}
		
		## subdom wks ##
		#Win7##
		for ($i = 0; $i -lt $NamesWin7.count; $i++)
		{
			New-VHD -ParentPath "$ParentDiskPath\Win7\Win7.vhdx" -Path "$VMPath\$($NamesWin7[$i])\Virtual Hard Disks\$($NamesWin7[$i]).vhdx" -Differencing | Out-Null
		}
		##win10##
		for ($i = 0; $i -lt $NamesWin10.count; $i++)
		{
			New-VHD -ParentPath "$ParentDiskPath\Win10\Win10.vhdx" -Path "$VMPath\$($NamesWin10[$i])\Virtual Hard Disks\$($NamesWin10[$i]).vhdx" -Differencing | Out-Null
		}
		
		## VR ##
		New-VHD -ParentPath "$ParentDiskPath\2012R2\2012R2.vhdx" -Path "$VMPath\ADS-FRVR\Virtual Hard Disks\ADS-FRVR.vhdx" -Differencing | Out-Null
		
		## create setup files ##
		## General setup files ##
		
		New-Item -Name "RestartServices.cmd" -ItemType File -Path $VMPath
		Add-Content -Path "$VMPath\RestartServices.cmd" -Value "powershell.exe -executionpolicy bypass -file RestartServices.ps1"
		New-Item -Name "RestartServices.ps1" -ItemType File -Path $VMPath
		Add-Content -Path "$VMPath\RestartServices.ps1" -Value "(1..3).foreach{ Restart-Service -Name dnscache,netlogon -Force }"
		
		## create dc promo files ##
		## ADS-CENTER.DE ##
		## Forest Promotion ##
		New-Item -Name "DCPromo-$NetBIOSFR.txt" -ItemType File -Path $VMPath | Out-Null
		Add-Content -Path "$VMPath\DCPromo-$NetBIOSFR.txt" -Value "; DCPROMO unattend file (automatically generated by dcpromo)"
		Add-Content -Path "$VMPath\DCPromo-$NetBIOSFR.txt" -Value "; Usage:"
		Add-Content -Path "$VMPath\DCPromo-$NetBIOSFR.txt" -Value "; dcpromo.exe /unattend:C:\dcpromo.txt"
		Add-Content -Path "$VMPath\DCPromo-$NetBIOSFR.txt" -Value ";"
		Add-Content -Path "$VMPath\DCPromo-$NetBIOSFR.txt" -Value "`[DCInstall`]"
		Add-Content -Path "$VMPath\DCPromo-$NetBIOSFR.txt" -Value "; New forest promotion"
		Add-Content -Path "$VMPath\DCPromo-$NetBIOSFR.txt" -Value "ReplicaOrNewDomain`=Domain"
		Add-Content -Path "$VMPath\DCPromo-$NetBIOSFR.txt" -Value "NewDomain`=Forest"
		Add-Content -Path "$VMPath\DCPromo-$NetBIOSFR.txt" -Value "NewDomainDNSName`=$DomainNameFR"
		Add-Content -Path "$VMPath\DCPromo-$NetBIOSFR.txt" -Value "ForestLevel`=0"
		Add-Content -Path "$VMPath\DCPromo-$NetBIOSFR.txt" -Value "DomainNetbiosName`=$NetBIOSFR"
		Add-Content -Path "$VMPath\DCPromo-$NetBIOSFR.txt" -Value "DomainLevel`=0"
		Add-Content -Path "$VMPath\DCPromo-$NetBIOSFR.txt" -Value "InstallDNS`=Yes"
		Add-Content -Path "$VMPath\DCPromo-$NetBIOSFR.txt" -Value "ConfirmGc`=Yes"
		Add-Content -Path "$VMPath\DCPromo-$NetBIOSFR.txt" -Value "CreateDNSDelegation`=No"
		Add-Content -Path "$VMPath\DCPromo-$NetBIOSFR.txt" -Value "DatabasePath`=`"C:\Windows\NTDS`""
		Add-Content -Path "$VMPath\DCPromo-$NetBIOSFR.txt" -Value "LogPath`=`"C:\Windows\NTDS`""
		Add-Content -Path "$VMPath\DCPromo-$NetBIOSFR.txt" -Value "SYSVOLPath`=`"C:\Windows\SYSVOL`""
		Add-Content -Path "$VMPath\DCPromo-$NetBIOSFR.txt" -Value "; Set SafeModeAdminPassword to the correct value prior to using the unattend file"
		Add-Content -Path "$VMPath\DCPromo-$NetBIOSFR.txt" -Value "SafeModeAdminPassword`=C0mplex"
		Add-Content -Path "$VMPath\DCPromo-$NetBIOSFR.txt" -Value "; Run-time flags (optional)"
		Add-Content -Path "$VMPath\DCPromo-$NetBIOSFR.txt" -Value "RebootOnCompletion`=Yes"
		New-Item -Name "DCPromo-$NetBIOSFR.cmd" -ItemType File -Path $VMPath
		Add-Content -Path "$VMPath\DCPromo-$NetBIOSFR.cmd" -Value "powershell.exe -ExecutionPolicy bypass -file DCPromo-$NetBIOSFR.ps1"
		Add-Content -Path "$VMPath\DCPromo-$NetBIOSFR.cmd" -Value "dcpromo.exe /answer:DCPromo-$NetBIOSFR.txt"
		
		## AutoLogin ##
		Add-Content -Path "$VMPath\DCPromo-$NetBIOSFR.ps1" -Value "Set-ItemProperty -Path 'HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name AutoAdminLogon -Value 1"
		Add-Content -Path "$VMPath\DCPromo-$NetBIOSFR.ps1" -Value "Set-ItemProperty -Path 'HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name DefaultUserName -Value `"Administrator`""
		Add-Content -Path "$VMPath\DCPromo-$NetBIOSFR.ps1" -Value "Set-ItemProperty -Path 'HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name DefaultPassword -Value `"C0mplex`""
		Add-Content -Path "$VMPath\DCPromo-$NetBIOSFR.ps1" -Value "Set-ItemProperty -Path 'HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name DefaultDomain -Value `"ADS-CENTER.DE`""
		
		## Remove AutoLogin ###
		New-Item -Name "Remove-AutoLogin.cmd" -ItemType File -Path $VMPath
		Add-Content -Path "$VMPath\Remove-AutoLogin.cmd" -Value "powershell.exe -executionpolicy bypass -file Remove-AutoLogin.ps1"
		New-Item -Name "Remove-AutoLogin.ps1" -ItemType File -Path $VMPath
		Add-Content -Path "$VMPath\Remove-AutoLogin.ps1" -Value "Remove-ItemProperty -Path `'HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon`' -Name AutoAdminLogon"
		Add-Content -Path "$VMPath\Remove-AutoLogin.ps1" -Value "Remove-ItemProperty -Path `'HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon`' -Name DefaultUserName"
		Add-Content -Path "$VMPath\Remove-AutoLogin.ps1" -Value "Remove-ItemProperty -Path `'HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon`' -Name DefaultPassword"
		Add-Content -Path "$VMPath\Remove-AutoLogin.ps1" -Value "Remove-ItemProperty -Path `'HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon`' -Name DefaultDomain"
		
		## AD Care ##
		New-Item -Name ADCARE-FR.ps1 -ItemType File -Path $VMPath | Out-Null
		Add-Content -Path "$VMPath\ADCARE-FR.cmd" -Value "dnscmd.exe /zoneadd 6.168.192.in-addr.arpa /dsprimary /dp /forest"
		Add-Content -Path "$VMPath\ADCARE-FR.cmd" -Value "netsh interface ipv4 set dns `"Local Area Connection`" static 192.168.6.241 validate=no"
		Add-Content -Path "$VMPath\ADCARE-FR.cmd" -Value "netsh interface ipv4 add dns `"Local Area Connection`" address=192.168.6.242 validate=no"
		Add-Content -Path "$VMPath\ADCARE-FR.cmd" -Value "netsh interface ipv4 add dns `"Local Area Connection`" address=192.168.6.243 validate=no"
		Add-Content -Path "$VMPath\ADCARE-FR.cmd" -Value "Powershell.exe -ExecutionPolicy bypass -file ADCARE-FR.ps1"
		Add-Content -Path "$VMPath\ADCARE-FR.ps1" -Value "Rename-ADObject -NewName `"GER-BB`" -Identity `"CN=Default-First-Site-Name,CN=Sites,CN=Configuration,DC=ads-center,DC=de`""
		Add-Content -Path "$VMPath\ADCARE-FR.ps1" -Value "New-ADObject -Path `"CN=Subnets,CN=Sites,CN=Configuration,DC=ads-center,DC=de`" -Type subnet -Name `"192.168.6.0/24`" -OtherAttributes `@`{ siteobject = `"CN=GER-BB,CN=Sites,CN=Configuration,DC=ads-center,DC=de`" `}"
		Add-Content -Path "$VMPath\ADCARE-FR.ps1" -Value "New-ADGroup -Name UG-Legacy-1 -GroupCategory Security -GroupScope Universal"
		Add-Content -Path "$VMPath\ADCARE-FR.ps1" -Value "Add-ADGroupMember -Identity `"UG-Legacy-1`" -Members `"Administrator`""
		Add-Content -Path "$VMPath\ADCARE-FR.ps1" -Value "Set-ADDomainMode -Identity ads-center.de -DomainMode Windows2003Domain -Confirm:`$false"
		Add-Content -Path "$VMPath\ADCARE-FR.ps1" -Value "Set-ADForestMode -Identity ads-center.de -ForestMode Windows2003Forest -Confirm:`$false"
		Add-Content -Path "$VMPath\ADCARE-FR.ps1" -Value "Remove-ItemProperty -Path `'HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon`' -Name AutoAdminLogon"
		Add-Content -Path "$VMPath\ADCARE-FR.ps1" -Value "Remove-ItemProperty -Path `'HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon`' -Name DefaultUserName"
		Add-Content -Path "$VMPath\ADCARE-FR.ps1" -Value "Remove-ItemProperty -Path `'HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon`' -Name DefaultPassword"
		Add-Content -Path "$VMPath\ADCARE-FR.ps1" -Value "Remove-ItemProperty -Path `'HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon`' -Name DefaultDomain"
		
		$NetBIOSDN = foreach ($name in $seatnumber)
		{
			"SUB" + "{0:D2}" -f $name
		}
		
		foreach ($NetBIOSName in $NetBIOSDN)
		{
			New-Item -Name ADCARETrust-$NetBIOSName.cmd -ItemType File -Path $VMPath | Out-Null
			Add-Content -Path "$VMPath\ADCARETrust-$NetBIOSName.cmd" -Value "netdom trust ads-center.de /d:$NetBIOSName.ads-center.de /usero:administrator /passwordo:C0mplex /reset"
		}
		
		## Replica Promotion ##
		New-Item -Name "DCPromo-Replica-$NetBIOSFR.txt" -ItemType File -Path $VMPath | Out-Null
		Add-Content -Path "$VMPath\DCPromo-Replica-$NetBIOSFR.txt" -Value "; DCPROMO unattend file (automatically generated by dcpromo)"
		Add-Content -Path "$VMPath\DCPromo-Replica-$NetBIOSFR.txt" -Value "; Usage:"
		Add-Content -Path "$VMPath\DCPromo-Replica-$NetBIOSFR.txt" -Value ";   dcpromo.exe /unattend:C:\dcpromo-replica.txt"
		Add-Content -Path "$VMPath\DCPromo-Replica-$NetBIOSFR.txt" -Value ";"
		Add-Content -Path "$VMPath\DCPromo-Replica-$NetBIOSFR.txt" -Value "; You may need to fill in password fields prior to using the unattend file."
		Add-Content -Path "$VMPath\DCPromo-Replica-$NetBIOSFR.txt" -Value "; If you leave the values for `"Password`" and/or `"DNSDelegationPassword`""
		Add-Content -Path "$VMPath\DCPromo-Replica-$NetBIOSFR.txt" -Value "; as `"*`", then you will be asked for credentials at runtime."
		Add-Content -Path "$VMPath\DCPromo-Replica-$NetBIOSFR.txt" -Value ";"
		Add-Content -Path "$VMPath\DCPromo-Replica-$NetBIOSFR.txt" -Value "[DCInstall]"
		Add-Content -Path "$VMPath\DCPromo-Replica-$NetBIOSFR.txt" -Value "; Replica DC promotion"
		Add-Content -Path "$VMPath\DCPromo-Replica-$NetBIOSFR.txt" -Value "ReplicaOrNewDomain`=Replica"
		Add-Content -Path "$VMPath\DCPromo-Replica-$NetBIOSFR.txt" -Value "ReplicaDomainDNSName`=ads-center.de"
		Add-Content -Path "$VMPath\DCPromo-Replica-$NetBIOSFR.txt" -Value "SiteName`=GER-BB"
		Add-Content -Path "$VMPath\DCPromo-Replica-$NetBIOSFR.txt" -Value "InstallDNS`=Yes"
		Add-Content -Path "$VMPath\DCPromo-Replica-$NetBIOSFR.txt" -Value "ConfirmGc`=Yes"
		Add-Content -Path "$VMPath\DCPromo-Replica-$NetBIOSFR.txt" -Value "CreateDNSDelegation`=No"
		Add-Content -Path "$VMPath\DCPromo-Replica-$NetBIOSFR.txt" -Value "UserDomain`=$DomainNameFR"
		Add-Content -Path "$VMPath\DCPromo-Replica-$NetBIOSFR.txt" -Value "UserName`=$DomainNameFR\administrator"
		Add-Content -Path "$VMPath\DCPromo-Replica-$NetBIOSFR.txt" -Value "Password`=C0mplex"
		Add-Content -Path "$VMPath\DCPromo-Replica-$NetBIOSFR.txt" -Value "ReplicationSourceDC`=$($DCNamesForestRoot2008R2[0]).$DomainNameFR"
		Add-Content -Path "$VMPath\DCPromo-Replica-$NetBIOSFR.txt" -Value "DatabasePath`=`"C:\Windows\NTDS`""
		Add-Content -Path "$VMPath\DCPromo-Replica-$NetBIOSFR.txt" -Value "LogPath`=`"C:\Windows\NTDS`""
		Add-Content -Path "$VMPath\DCPromo-Replica-$NetBIOSFR.txt" -Value "SYSVOLPath`=`"C:\Windows\SYSVOL`""
		Add-Content -Path "$VMPath\DCPromo-Replica-$NetBIOSFR.txt" -Value "; Set SafeModeAdminPassword to the correct value prior to using the unattend file"
		Add-Content -Path "$VMPath\DCPromo-Replica-$NetBIOSFR.txt" -Value "SafeModeAdminPassword`=C0mplex"
		Add-Content -Path "$VMPath\DCPromo-Replica-$NetBIOSFR.txt" -Value "; Run-time flags (optional)"
		Add-Content -Path "$VMPath\DCPromo-Replica-$NetBIOSFR.txt" -Value "; CriticalReplicationOnly`=Yes"
		Add-Content -Path "$VMPath\DCPromo-Replica-$NetBIOSFR.txt" -Value "RebootOnCompletion`=Yes"
		New-Item -Name "DCPromo-Replica-$NetBIOSFR.cmd" -ItemType File -Path $VMPath
		Add-Content -Path "$VMPath\DCPromo-Replica-$NetBIOSFR.cmd" -Value "dcpromo.exe /answer:DCPromo-Replica-$NetBIOSFR.txt"
		Add-Content -Path "$VMPath\DCPromo-Replica-$NetBIOSFR.cmd" -Value "powershell.exe -ExecutionPolicy bypass -file DCPromo-Replica-$NetBIOSFR.ps1"
		
		## AutoLogin ##
		New-Item -Name "DCPromo-Replica-$NetBIOSFR.ps1" -ItemType File -Path $VMPath
		Add-Content -Path "$VMPath\DCPromo-Replica-$NetBIOSFR.ps1" -Value "Set-ItemProperty -Path 'HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name AutoAdminLogon -Value 1"
		Add-Content -Path "$VMPath\DCPromo-Replica-$NetBIOSFR.ps1" -Value "Set-ItemProperty -Path 'HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name DefaultUserName -Value `"Administrator`""
		Add-Content -Path "$VMPath\DCPromo-Replica-$NetBIOSFR.ps1" -Value "Set-ItemProperty -Path 'HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name DefaultPassword -Value `"C0mplex`""
		Add-Content -Path "$VMPath\DCPromo-Replica-$NetBIOSFR.ps1" -Value "Set-ItemProperty -Path 'HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name DefaultDomain -Value `"ADS-CENTER.DE`""
		
		## Subdoms ##
		## Domain creation ##
		for ($i = 1; $i -le $DomainNames.count; $i++)
		{
			New-Item -Name "DCPromo-$($DomainNames[$i - 1]).txt" -ItemType File -Path $VMPath | Out-Null
			Add-Content -Path "$VMPath\DCPromo-$($DomainNames[$i - 1]).txt" -Value "; DCPROMO unattend file (automatically generated by dcpromo)"
			Add-Content -Path "$VMPath\DCPromo-$($DomainNames[$i - 1]).txt" -Value "; Usage:"
			Add-Content -Path "$VMPath\DCPromo-$($DomainNames[$i - 1]).txt" -Value "; dcpromo.exe /unattend:C:\dcpromo.txt"
			Add-Content -Path "$VMPath\DCPromo-$($DomainNames[$i - 1]).txt" -Value "; "
			Add-Content -Path "$VMPath\DCPromo-$($DomainNames[$i - 1]).txt" -Value "; You may need to fill in password fields prior to using the unattend file."
			Add-Content -Path "$VMPath\DCPromo-$($DomainNames[$i - 1]).txt" -Value "; If you leave the values for `"Password`" and/or `"DNSDelegationPassword`""
			Add-Content -Path "$VMPath\DCPromo-$($DomainNames[$i - 1]).txt" -Value "; as `"*`", then you will be asked for credentials at runtime."
			Add-Content -Path "$VMPath\DCPromo-$($DomainNames[$i - 1]).txt" -Value "; "
			Add-Content -Path "$VMPath\DCPromo-$($DomainNames[$i - 1]).txt" -Value "[DCInstall]"
			Add-Content -Path "$VMPath\DCPromo-$($DomainNames[$i - 1]).txt" -Value "; New child domain promotion"
			Add-Content -Path "$VMPath\DCPromo-$($DomainNames[$i - 1]).txt" -Value "ReplicaOrNewDomain=Domain"
			Add-Content -Path "$VMPath\DCPromo-$($DomainNames[$i - 1]).txt" -Value "NewDomain=Child"
			Add-Content -Path "$VMPath\DCPromo-$($DomainNames[$i - 1]).txt" -Value "ParentDomainDNSName=$DomainNameFR"
			Add-Content -Path "$VMPath\DCPromo-$($DomainNames[$i - 1]).txt" -Value "ChildName=$($NetBIOSDN[$i - 1])"
			Add-Content -Path "$VMPath\DCPromo-$($DomainNames[$i - 1]).txt" -Value "DomainNetbiosName=$($NetBIOSDN[$i - 1])"
			Add-Content -Path "$VMPath\DCPromo-$($DomainNames[$i - 1]).txt" -Value "DomainLevel=2"
			Add-Content -Path "$VMPath\DCPromo-$($DomainNames[$i - 1]).txt" -Value "SiteName=GER-BB"
			Add-Content -Path "$VMPath\DCPromo-$($DomainNames[$i - 1]).txt" -Value "InstallDNS=No"
			Add-Content -Path "$VMPath\DCPromo-$($DomainNames[$i - 1]).txt" -Value "ConfirmGc=Yes"
			Add-Content -Path "$VMPath\DCPromo-$($DomainNames[$i - 1]).txt" -Value "CreateDNSDelegation=No"
			Add-Content -Path "$VMPath\DCPromo-$($DomainNames[$i - 1]).txt" -Value "UserDomain=$DomainNameFR"
			Add-Content -Path "$VMPath\DCPromo-$($DomainNames[$i - 1]).txt" -Value "UserName=$DomainNameFR\administrator"
			Add-Content -Path "$VMPath\DCPromo-$($DomainNames[$i - 1]).txt" -Value "Password=C0mplex"
			Add-Content -Path "$VMPath\DCPromo-$($DomainNames[$i - 1]).txt" -Value "ReplicationSourceDC=ADS-VDC01.ads-center.de"
			Add-Content -Path "$VMPath\DCPromo-$($DomainNames[$i - 1]).txt" -Value "DatabasePath=`"C:\Windows\NTDS`""
			Add-Content -Path "$VMPath\DCPromo-$($DomainNames[$i - 1]).txt" -Value "LogPath=`"C:\Windows\NTDS`""
			Add-Content -Path "$VMPath\DCPromo-$($DomainNames[$i - 1]).txt" -Value "SYSVOLPath=`"C:\Windows\SYSVOL`""
			Add-Content -Path "$VMPath\DCPromo-$($DomainNames[$i - 1]).txt" -Value "; Set SafeModeAdminPassword to the correct value prior to using the unattend file"
			Add-Content -Path "$VMPath\DCPromo-$($DomainNames[$i - 1]).txt" -Value "SafeModeAdminPassword=C0mplex"
			Add-Content -Path "$VMPath\DCPromo-$($DomainNames[$i - 1]).txt" -Value "; Run-time flags (optional)"
			Add-Content -Path "$VMPath\DCPromo-$($DomainNames[$i - 1]).txt" -Value "RebootOnCompletion=Yes"
			New-Item -Name "DCPromo-$($DomainNames[$i - 1]).cmd" -ItemType File -Path $VMPath
			Add-Content -Path "$VMPath\DCPromo-$($DomainNames[$i - 1]).cmd" -Value "dcpromo.exe /answer:DCPromo-$($DomainNames[$i - 1]).txt"
			Add-Content -Path "$VMPath\DCPromo-$($DomainNames[$i - 1]).cmd" -Value "powershell.exe -executionpolicy bypass -file DCPromo-$($DomainNames[$i - 1]).ps1"
			
			New-Item -Name "DCPromo-$($DomainNames[$i - 1]).ps1" -ItemType File -Path $VMPath
			Add-Content -Path "$VMPath\DCPromo-$($DomainNames[$i - 1]).ps1" -Value "Set-ItemProperty -Path 'HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name AutoAdminLogon -Value 1"
			Add-Content -Path "$VMPath\DCPromo-$($DomainNames[$i - 1]).ps1" -Value "Set-ItemProperty -Path 'HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name DefaultUserName -Value `"Administrator`""
			Add-Content -Path "$VMPath\DCPromo-$($DomainNames[$i - 1]).ps1" -Value "Set-ItemProperty -Path 'HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name DefaultPassword -Value `"C0mplex`""
			Add-Content -Path "$VMPath\DCPromo-$($DomainNames[$i - 1]).ps1" -Value "Set-ItemProperty -Path 'HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name DefaultDomain -Value `"$($DomainNames[$i - 1])`""
			
		}
		
		## replica promotion ##
		for ($i = 1; $i -le $DomainNames.count; $i++)
		{
			New-Item -Name "DCPromo-Replica-$($NetBIOSDN[$i - 1]).txt" -ItemType File -Path $VMPath | Out-Null
			Add-Content -Path "$VMPath\DCPromo-Replica-$($NetBIOSDN[$i - 1]).txt" -Value "; DCPROMO unattend file (automatically generated by dcpromo)"
			Add-Content -Path "$VMPath\DCPromo-Replica-$($NetBIOSDN[$i - 1]).txt" -Value "; Usage:"
			Add-Content -Path "$VMPath\DCPromo-Replica-$($NetBIOSDN[$i - 1]).txt" -Value ";   dcpromo.exe /unattend:C:\dcpromo-replica.txt"
			Add-Content -Path "$VMPath\DCPromo-Replica-$($NetBIOSDN[$i - 1]).txt" -Value ";"
			Add-Content -Path "$VMPath\DCPromo-Replica-$($NetBIOSDN[$i - 1]).txt" -Value "; You may need to fill in password fields prior to using the unattend file."
			Add-Content -Path "$VMPath\DCPromo-Replica-$($NetBIOSDN[$i - 1]).txt" -Value "; If you leave the values for `"Password`" and/or `"DNSDelegationPassword`""
			Add-Content -Path "$VMPath\DCPromo-Replica-$($NetBIOSDN[$i - 1]).txt" -Value "; as `"*`", then you will be asked for credentials at runtime."
			Add-Content -Path "$VMPath\DCPromo-Replica-$($NetBIOSDN[$i - 1]).txt" -Value ";"
			Add-Content -Path "$VMPath\DCPromo-Replica-$($NetBIOSDN[$i - 1]).txt" -Value "[DCInstall]"
			Add-Content -Path "$VMPath\DCPromo-Replica-$($NetBIOSDN[$i - 1]).txt" -Value "; Replica DC promotion"
			Add-Content -Path "$VMPath\DCPromo-Replica-$($NetBIOSDN[$i - 1]).txt" -Value "ReplicaOrNewDomain=Replica"
			Add-Content -Path "$VMPath\DCPromo-Replica-$($NetBIOSDN[$i - 1]).txt" -Value "ReplicaDomainDNSName=$($DomainNames[$i - 1])"
			Add-Content -Path "$VMPath\DCPromo-Replica-$($NetBIOSDN[$i - 1]).txt" -Value "SiteName=GER-BB"
			Add-Content -Path "$VMPath\DCPromo-Replica-$($NetBIOSDN[$i - 1]).txt" -Value "InstallDNS=No"
			Add-Content -Path "$VMPath\DCPromo-Replica-$($NetBIOSDN[$i - 1]).txt" -Value "ConfirmGc=Yes"
			Add-Content -Path "$VMPath\DCPromo-Replica-$($NetBIOSDN[$i - 1]).txt" -Value "CreateDNSDelegation=No"
			Add-Content -Path "$VMPath\DCPromo-Replica-$($NetBIOSDN[$i - 1]).txt" -Value "UserDomain=$($DomainNames[$i - 1])"
			Add-Content -Path "$VMPath\DCPromo-Replica-$($NetBIOSDN[$i - 1]).txt" -Value "UserName=$($DomainNames[$i - 1])\administrator"
			Add-Content -Path "$VMPath\DCPromo-Replica-$($NetBIOSDN[$i - 1]).txt" -Value "Password=C0mplex"
			Add-Content -Path "$VMPath\DCPromo-Replica-$($NetBIOSDN[$i - 1]).txt" -Value "ReplicationSourceDC=$($NetBIOSDN[$i - 1])-VDC01.$($DomainNames[$i - 1])"
			Add-Content -Path "$VMPath\DCPromo-Replica-$($NetBIOSDN[$i - 1]).txt" -Value "DatabasePath=`"C:\Windows\NTDS`""
			Add-Content -Path "$VMPath\DCPromo-Replica-$($NetBIOSDN[$i - 1]).txt" -Value "LogPath=`"C:\Windows\NTDS`""
			Add-Content -Path "$VMPath\DCPromo-Replica-$($NetBIOSDN[$i - 1]).txt" -Value "SYSVOLPath=`"C:\Windows\SYSVOL`""
			Add-Content -Path "$VMPath\DCPromo-Replica-$($NetBIOSDN[$i - 1]).txt" -Value "; Set SafeModeAdminPassword to the correct value prior to using the unattend file"
			Add-Content -Path "$VMPath\DCPromo-Replica-$($NetBIOSDN[$i - 1]).txt" -Value "SafeModeAdminPassword=C0mplex"
			Add-Content -Path "$VMPath\DCPromo-Replica-$($NetBIOSDN[$i - 1]).txt" -Value "; Run-time flags (optional)"
			Add-Content -Path "$VMPath\DCPromo-Replica-$($NetBIOSDN[$i - 1]).txt" -Value "; CriticalReplicationOnly=Yes"
			Add-Content -Path "$VMPath\DCPromo-Replica-$($NetBIOSDN[$i - 1]).txt" -Value "RebootOnCompletion=Yes"
			New-Item -Name "DCPromo-Replica-$($NetBIOSDN[$i - 1]).cmd" -ItemType File -Path $VMPath
			Add-Content -Path "$VMPath\DCPromo-Replica-$($NetBIOSDN[$i - 1]).cmd" -Value "dcpromo.exe /answer:DCPromo-Replica-$($NetBIOSDN[$i - 1]).txt"
			Add-Content -Path "$VMPath\DCPromo-Replica-$($NetBIOSDN[$i - 1]).cmd" -Value "powershell.exe -executionpolicy bypass -file DCPromo-Replica-$($NetBIOSDN[$i - 1]).ps1"
			
			New-Item -Name "DCPromo-Replica-$($NetBIOSDN[$i - 1]).ps1" -ItemType File -Path $VMPath
			Add-Content -Path "$VMPath\DCPromo-Replica-$($NetBIOSDN[$i - 1]).ps1" -Value "Set-ItemProperty -Path 'HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name AutoAdminLogon -Value 1"
			Add-Content -Path "$VMPath\DCPromo-Replica-$($NetBIOSDN[$i - 1]).ps1" -Value "Set-ItemProperty -Path 'HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name DefaultUserName -Value `"Administrator`""
			Add-Content -Path "$VMPath\DCPromo-Replica-$($NetBIOSDN[$i - 1]).ps1" -Value "Set-ItemProperty -Path 'HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name DefaultPassword -Value `"C0mplex`""
			Add-Content -Path "$VMPath\DCPromo-Replica-$($NetBIOSDN[$i - 1]).ps1" -Value "Set-ItemProperty -Path 'HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name DefaultDomain -Value `"$($NetBIOSDN[$i - 1])`""
			
		}
		
		## Forest Root ##
		## FR2008R2 ##
		for ($i = 0; $i -lt $DCNamesForestRoot2008R2.count; $i++)
		{
			New-Item -Name "$($DCNamesForestRoot2008R2[$i]).cmd" -ItemType File -Path "$VMPath\$($DCNamesForestRoot2008R2[$i])\Virtual Hard Disks\" | Out-Null
			Add-Content -Path "$VMPath\$($DCNamesForestRoot2008R2[$i])\Virtual Hard Disks\$($DCNamesForestRoot2008R2[$i]).cmd" -Value "netsh interface ipv6 delete dnsserver `"Local Area Connection`" ::1"
			Add-Content -Path "$VMPath\$($DCNamesForestRoot2008R2[$i])\Virtual Hard Disks\$($DCNamesForestRoot2008R2[$i]).cmd" -Value "netsh interface ipv4 set address `"Local Area Connection`" static 192.168.6.24$($i + 1) 255.255.255.0 192.168.6.254 1"
			Add-Content -Path "$VMPath\$($DCNamesForestRoot2008R2[$i])\Virtual Hard Disks\$($DCNamesForestRoot2008R2[$i]).cmd" -Value "netsh interface ipv4 set dns `"Local Area Connection`" static 192.168.6.241"
			Add-Content -Path "$VMPath\$($DCNamesForestRoot2008R2[$i])\Virtual Hard Disks\$($DCNamesForestRoot2008R2[$i]).cmd" -Value "netsh interface ipv4 add dns `"Local Area Connection`" address=192.168.6.242 validate=no"
			Add-Content -Path "$VMPath\$($DCNamesForestRoot2008R2[$i])\Virtual Hard Disks\$($DCNamesForestRoot2008R2[$i]).cmd" -Value "netsh interface ipv4 add dns `"Local Area Connection`" address=192.168.6.243 validate=no"
			Add-Content -Path "$VMPath\$($DCNamesForestRoot2008R2[$i])\Virtual Hard Disks\$($DCNamesForestRoot2008R2[$i]).cmd" -Value "powershell.exe -ExecutionPolicy bypass -file $($DCNamesForestRoot2008R2[$i]).ps1"
			Add-Content -Path "$VMPath\$($DCNamesForestRoot2008R2[$i])\Virtual Hard Disks\$($DCNamesForestRoot2008R2[$i]).cmd" -Value "netdom renamecomputer localhost /newname:$($DCNamesForestRoot2008R2[$i]) /Force /Reboot"
			
			New-Item -Name "$($DCNamesForestRoot2008R2[$i]).ps1" -ItemType File -Path "$VMPath\$($DCNamesForestRoot2008R2[$i])\Virtual Hard Disks\" | Out-Null
			Add-Content -Path "$VMPath\$($DCNamesForestRoot2008R2[$i])\Virtual Hard Disks\$($DCNamesForestRoot2008R2[$i]).ps1" -Value "Set-ItemProperty -Path 'HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name AutoAdminLogon -Value 1"
			Add-Content -Path "$VMPath\$($DCNamesForestRoot2008R2[$i])\Virtual Hard Disks\$($DCNamesForestRoot2008R2[$i]).ps1" -Value "Set-ItemProperty -Path 'HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name DefaultUserName -Value `"Administrator`""
			Add-Content -Path "$VMPath\$($DCNamesForestRoot2008R2[$i])\Virtual Hard Disks\$($DCNamesForestRoot2008R2[$i]).ps1" -Value "Set-ItemProperty -Path 'HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name DefaultPassword -Value `"C0mplex`""
			Add-Content -Path "$VMPath\$($DCNamesForestRoot2008R2[$i])\Virtual Hard Disks\$($DCNamesForestRoot2008R2[$i]).ps1" -Value "Set-ItemProperty -Path 'HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name DefaultDomain -Value `".`""
			Add-Content -Path "$VMPath\$($DCNamesForestRoot2008R2[$i])\Virtual Hard Disks\$($DCNamesForestRoot2008R2[$i]).ps1" -Value "New-PSDrive -PSProvider Registry -Name HKU -Root HKEY_USERS"
			Add-Content -Path "$VMPath\$($DCNamesForestRoot2008R2[$i])\Virtual Hard Disks\$($DCNamesForestRoot2008R2[$i]).ps1" -Value "Set-ItemProperty -Path 'HKU:\.DEFAULT\Control Panel\Keyboard' -Name InitialKeyboardIndicators -Value 2147483650"
			
			# mount VHD
			Write-Debug -Message "Identifying the VM disk at $($DCNamesForestRoot2008R2[$i])"
			$driveb4 = (Get-PSDrive).Name
			Write-Debug -Message "Mounting the VM disk at $($DCNamesForestRoot2008R2[$i])"
			Mount-VHD -Path "$VMPath\$($DCNamesForestRoot2008R2[$i])\Virtual Hard Disks\$($DCNamesForestRoot2008R2[$i]).vhdx"
			$driveat = (Get-PSDrive).name
			$drive = (Compare-Object -ReferenceObject $driveb4 -DifferenceObject $driveat).inputobject[-1] + ':'
			New-Item -Path $drive\SetupTemp -ItemType Directory | Out-Null
			Write-Debug -Message "Changing directory to VM disk at $($DCNamesForestRoot2008R2[$i])"
			Set-Location -Path $drive\SetupTemp | Out-Null
			Write-Debug -Message "Copying setup files to VM disk at $($DCNamesForestRoot2008R2[$i])"
			Copy-Item -Path "$VMPath\$($DCNamesForestRoot2008R2[$i])\Virtual Hard Disks\$($DCNamesForestRoot2008R2[$i]).cmd" -Destination . | Out-Null
			Copy-Item -Path "$VMPath\$($DCNamesForestRoot2008R2[$i])\Virtual Hard Disks\$($DCNamesForestRoot2008R2[$i]).ps1" -Destination . | Out-Null
			Copy-Item -Path "$VMPath\DCPromo-$NetBIOSFR.cmd" -Destination . | Out-Null
			Copy-Item -Path "$VMPath\DCPromo-$NetBIOSFR.ps1" -Destination . | Out-Null
			Copy-Item -Path "$VMPath\DCPromo-$NetBIOSFR.txt" -Destination . | Out-Null
			Copy-Item -Path "$VMPath\ADCARE-FR.cmd" -Destination . | Out-Null
			Copy-Item -Path "$VMPath\ADCARE-FR.ps1" -Destination . | Out-Null
			Copy-Item -Path "$VMPath\ADCARETrust-*.cmd" -Destination . | Out-Null
			Copy-Item -Path "$VMPath\DCPromo-Replica-$NetBIOSFR.txt" -Destination . | Out-Null
			Copy-Item -Path "$VMPath\DCPromo-Replica-$NetBIOSFR.cmd" -Destination . | Out-Null
			Copy-Item -Path "$VMPath\DCPromo-Replica-$NetBIOSFR.ps1" -Destination . | Out-Null
			Copy-Item -Path "$VMPath\Remove-AutoLogin.cmd" -Destination . | Out-Null
			Copy-Item -Path "$VMPath\Remove-AutoLogin.ps1" -Destination . | Out-Null
			Write-Debug -Message "Changing directoy to C:"
			Set-Location -Path c: | Out-Null
			Write-Debug -Message "Unmounting VM disk at $($DCNamesForestRoot2008R2[$i])"
			Dismount-VHD -Path "$VMPath\$($DCNamesForestRoot2008R2[$i])\Virtual Hard Disks\$($DCNamesForestRoot2008R2[$i]).vhdx"
		}
		
		## FR2012R2 ##
		for ($i = 0; $i -lt $DCNamesForestRoot2012R2.count; $i++)
		{
			
			New-Item -Name "$($DCNamesForestRoot2012R2[$i]).cmd" -ItemType File -Path "$VMPath\$($DCNamesForestRoot2012R2[$i])\Virtual Hard Disks\" | Out-Null
			Add-Content -Path "$VMPath\$($DCNamesForestRoot2012R2[$i])\Virtual Hard Disks\$($DCNamesForestRoot2012R2[$i]).cmd" -Value "powershell.exe -file $($DCNamesForestRoot2012R2[$i]).ps1"
			
			New-Item -Name "$($DCNamesForestRoot2012R2[$i]).ps1" -ItemType File -Path "$VMPath\$($DCNamesForestRoot2012R2[$i])\Virtual Hard Disks\" | Out-Null
			Add-Content -Path "$VMPath\$($DCNamesForestRoot2012R2[$i])\Virtual Hard Disks\$($DCNamesForestRoot2012R2[$i]).ps1" -Value "Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled false"
			Add-Content -Path "$VMPath\$($DCNamesForestRoot2012R2[$i])\Virtual Hard Disks\$($DCNamesForestRoot2012R2[$i]).ps1" -Value "Set-ItemProperty -Path `"HKLM:\System\CurrentControlSet\Control\Terminal Server`"-name `"fDenyTSConnections`" -Value 0"
			Add-Content -Path "$VMPath\$($DCNamesForestRoot2012R2[$i])\Virtual Hard Disks\$($DCNamesForestRoot2012R2[$i]).ps1" -Value "Enable-NetFirewallRule -DisplayGroup `"Remote Desktop`""
			Add-Content -Path "$VMPath\$($DCNamesForestRoot2012R2[$i])\Virtual Hard Disks\$($DCNamesForestRoot2012R2[$i]).ps1" -Value "Set-ItemProperty -Path `"HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp`" -name `"UserAuthentication`" -Value 1"
			Add-Content -Path "$VMPath\$($DCNamesForestRoot2012R2[$i])\Virtual Hard Disks\$($DCNamesForestRoot2012R2[$i]).ps1" -Value "Disable-NetAdapterBinding -InterfaceAlias ethernet -ComponentID ms_tcpip6"
			Add-Content -Path "$VMPath\$($DCNamesForestRoot2012R2[$i])\Virtual Hard Disks\$($DCNamesForestRoot2012R2[$i]).ps1" -Value "New-NetIPAddress -InterfaceAlias ethernet -IPAddress 192.168.6.24$($i + 4) -PrefixLength 24 -DefaultGateway 192.168.6.254"
			Add-Content -Path "$VMPath\$($DCNamesForestRoot2012R2[$i])\Virtual Hard Disks\$($DCNamesForestRoot2012R2[$i]).ps1" -Value "Set-DnsClientServerAddress -InterfaceAlias ethernet -ResetServerAddresses"
			Add-Content -Path "$VMPath\$($DCNamesForestRoot2012R2[$i])\Virtual Hard Disks\$($DCNamesForestRoot2012R2[$i]).ps1" -Value "Set-DnsClientServerAddress -InterfaceAlias ethernet -ServerAddresses `"192.168.6.241,192.168.6.242,192.168.6.243`""
			Add-Content -Path "$VMPath\$($DCNamesForestRoot2012R2[$i])\Virtual Hard Disks\$($DCNamesForestRoot2012R2[$i]).ps1" -Value "Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools"
			Add-Content -Path "$VMPath\$($DCNamesForestRoot2012R2[$i])\Virtual Hard Disks\$($DCNamesForestRoot2012R2[$i]).ps1" -Value "Set-ItemProperty -Path 'HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name AutoAdminLogon -Value 1"
			Add-Content -Path "$VMPath\$($DCNamesForestRoot2012R2[$i])\Virtual Hard Disks\$($DCNamesForestRoot2012R2[$i]).ps1" -Value "Set-ItemProperty -Path 'HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name DefaultUserName -Value `"Administrator`""
			Add-Content -Path "$VMPath\$($DCNamesForestRoot2012R2[$i])\Virtual Hard Disks\$($DCNamesForestRoot2012R2[$i]).ps1" -Value "Set-ItemProperty -Path 'HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name DefaultPassword -Value `"C0mplex`""
			Add-Content -Path "$VMPath\$($DCNamesForestRoot2012R2[$i])\Virtual Hard Disks\$($DCNamesForestRoot2012R2[$i]).ps1" -Value "Set-ItemProperty -Path 'HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name DefaultDomain -Value `".`""
			Add-Content -Path "$VMPath\$($DCNamesForestRoot2012R2[$i])\Virtual Hard Disks\$($DCNamesForestRoot2012R2[$i]).ps1" -Value "New-PSDrive -PSProvider Registry -Name HKU -Root HKEY_USERS"
			Add-Content -Path "$VMPath\$($DCNamesForestRoot2012R2[$i])\Virtual Hard Disks\$($DCNamesForestRoot2012R2[$i]).ps1" -Value "Set-ItemProperty -Path 'HKU:\.DEFAULT\Control Panel\Keyboard' -Name InitialKeyboardIndicators -Value 2147483650"
			Add-Content -Path "$VMPath\$($DCNamesForestRoot2012R2[$i])\Virtual Hard Disks\$($DCNamesForestRoot2012R2[$i]).ps1" -Value "Rename-Computer -NewName $($DCNamesForestRoot2012R2[$i]) -Restart"
			
			New-Item -Name "DomJoin.cmd" -ItemType File -Path "$VMPath\$($DCNamesForestRoot2012R2[$i])\Virtual Hard Disks\" | Out-Null
			Add-Content -Path "$VMPath\$($DCNamesForestRoot2012R2[$i])\Virtual Hard Disks\DomJoin.cmd" -Value "powershell.exe -Executionpolicy bypass -file DomJoin.ps1"
			New-Item -Name "DomJoin.ps1" -ItemType File -Path "$VMPath\$($DCNamesForestRoot2012R2[$i])\Virtual Hard Disks\" | Out-Null
			Add-Content -Path "$VMPath\$($DCNamesForestRoot2012R2[$i])\Virtual Hard Disks\DomJoin.ps1" -Value "Add-Computer -DomainName `"ADS-CENTER.DE`" -Credential (New-Object System.Management.Automation.PSCredential `"ADS\Administrator`", (ConvertTo-SecureString -AsPlainText -Force -String `"C0mplex`")) -Restart"
			
			
			# mount VHD
			Write-Debug -Message "Identifyin the VM disk at $($DCNamesForestRoot2012R2[$i])"
			$driveb4 = (Get-PSDrive).Name
			Write-Debug -Message "Mounting the VM disk at $($DCNamesForestRoot2012R2[$i])"
			Mount-VHD -Path "$VMPath\$($DCNamesForestRoot2012R2[$i])\Virtual Hard Disks\$($DCNamesForestRoot2012R2[$i]).vhdx"
			$driveat = (Get-PSDrive).name
			$drive = (Compare-Object -ReferenceObject $driveb4 -DifferenceObject $driveat).inputobject[-1] + ':'
			New-Item -Path $drive\SetupTemp -ItemType Directory | Out-Null
			Write-Debug -Message "Changin directory to VM disk at $($DCNamesForestRoot2012R2[$i])"
			Set-Location -Path $drive\SetupTemp | Out-Null
			Write-Debug -Message "Copying setup files to VM disk at $($DCNamesForestRoot2012R2[$i])"
			Copy-Item -Path "$VMPath\$($DCNamesForestRoot2012R2[$i])\Virtual Hard Disks\$($DCNamesForestRoot2012R2[$i]).ps1" -Destination . | Out-Null
			Copy-Item -Path "$VMPath\$($DCNamesForestRoot2012R2[$i])\Virtual Hard Disks\$($DCNamesForestRoot2012R2[$i]).cmd" -Destination . | Out-Null
			Copy-Item -Path "$VMPath\$($DCNamesForestRoot2012R2[$i])\Virtual Hard Disks\DomJoin.cmd" -Destination . | Out-Null
			Copy-Item -Path "$VMPath\$($DCNamesForestRoot2012R2[$i])\Virtual Hard Disks\DomJoin.ps1" -Destination . | Out-Null
			Copy-Item -Path "$VMPath\Remove-AutoLogin.cmd" -Destination . | Out-Null
			Copy-Item -Path "$VMPath\Remove-AutoLogin.ps1" -Destination . | Out-Null
			Write-Debug -Message "Changing directoy to C:"
			Set-Location -Path c: | Out-Null
			reg load HKLM\VM $drive\Windows\System32\config\SOFTWARE
			Set-ItemProperty -Path 'HKLM:\vm\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name AutoAdminLogon -Value 1
			Set-ItemProperty -Path 'HKLM:\vm\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name DefaultUserName -Value "Administrator"
			Set-ItemProperty -Path 'HKLM:\vm\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name DefaultPassword -Value "C0mplex"
			Set-ItemProperty -Path 'HKLM:\vm\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name DefaultDomain -Value "."
			Set-ItemProperty -Path 'HKLM:\vm\Microsoft\Windows\CurrentVersion\RunOnce' -Name "$($Computername).cmd" -Value "C:\SetupTemp\$Computername.cmd"
			reg unload HKLM\VM
			Write-Debug -Message "Unmounting VM disk at $($DCNamesForestRoot2012R2[$i])"
			Dismount-VHD -Path "$VMPath\$($DCNamesForestRoot2012R2[$i])\Virtual Hard Disks\$($DCNamesForestRoot2012R2[$i]).vhdx"
		}
		
		## FR2016 ##
		for ($i = 0; $i -lt $DCNamesForestRoot2016.count; $i++)
		{
			New-Item -Name "$($DCNamesForestRoot2016[$i]).ps1" -ItemType File -Path "$VMPath\$($DCNamesForestRoot2016[$i])\Virtual Hard Disks\" | Out-Null
			New-Item -Name "$($DCNamesForestRoot2016[$i]).cmd" -ItemType File -Path "$VMPath\$($DCNamesForestRoot2016[$i])\Virtual Hard Disks\" | Out-Null
			Add-Content -Path "$VMPath\$($DCNamesForestRoot2016[$i])\Virtual Hard Disks\$($DCNamesForestRoot2016[$i]).ps1" -Value "Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled false"
			Add-Content -Path "$VMPath\$($DCNamesForestRoot2016[$i])\Virtual Hard Disks\$($DCNamesForestRoot2016[$i]).ps1" -Value "Set-ItemProperty -Path `"HKLM:\System\CurrentControlSet\Control\Terminal Server`"-name `"fDenyTSConnections`" -Value 0"
			Add-Content -Path "$VMPath\$($DCNamesForestRoot2016[$i])\Virtual Hard Disks\$($DCNamesForestRoot2016[$i]).ps1" -Value "Enable-NetFirewallRule -DisplayGroup `"Remote Desktop`""
			Add-Content -Path "$VMPath\$($DCNamesForestRoot2016[$i])\Virtual Hard Disks\$($DCNamesForestRoot2016[$i]).ps1" -Value "Set-ItemProperty -Path `"HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp`" -name `"UserAuthentication`" -Value 1"
			Add-Content -Path "$VMPath\$($DCNamesForestRoot2016[$i])\Virtual Hard Disks\$($DCNamesForestRoot2016[$i]).ps1" -Value "Disable-NetAdapterBinding -InterfaceAlias ethernet -ComponentID ms_tcpip6"
			Add-Content -Path "$VMPath\$($DCNamesForestRoot2016[$i])\Virtual Hard Disks\$($DCNamesForestRoot2016[$i]).ps1" -Value "New-NetIPAddress -InterfaceAlias ethernet -IPAddress 192.168.6.24$($i + 7) -PrefixLength 24 -DefaultGateway 192.168.6.254"
			Add-Content -Path "$VMPath\$($DCNamesForestRoot2016[$i])\Virtual Hard Disks\$($DCNamesForestRoot2016[$i]).ps1" -Value "Set-DnsClientServerAddress -InterfaceAlias ethernet -ResetServerAddresses"
			Add-Content -Path "$VMPath\$($DCNamesForestRoot2016[$i])\Virtual Hard Disks\$($DCNamesForestRoot2016[$i]).ps1" -Value "Set-DnsClientServerAddress -InterfaceAlias ethernet -ServerAddresses `"192.168.6.241,192.168.6.242,192.168.6.243`""
			Add-Content -Path "$VMPath\$($DCNamesForestRoot2016[$i])\Virtual Hard Disks\$($DCNamesForestRoot2016[$i]).ps1" -Value "Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools"
			Add-Content -Path "$VMPath\$($DCNamesForestRoot2016[$i])\Virtual Hard Disks\$($DCNamesForestRoot2016[$i]).ps1" -Value "Set-ItemProperty -Path 'HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name AutoAdminLogon -Value 1"
			Add-Content -Path "$VMPath\$($DCNamesForestRoot2016[$i])\Virtual Hard Disks\$($DCNamesForestRoot2016[$i]).ps1" -Value "Set-ItemProperty -Path 'HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name DefaultUserName -Value `"Administrator`""
			Add-Content -Path "$VMPath\$($DCNamesForestRoot2016[$i])\Virtual Hard Disks\$($DCNamesForestRoot2016[$i]).ps1" -Value "Set-ItemProperty -Path 'HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name DefaultPassword -Value `"C0mplex`""
			Add-Content -Path "$VMPath\$($DCNamesForestRoot2016[$i])\Virtual Hard Disks\$($DCNamesForestRoot2016[$i]).ps1" -Value "Set-ItemProperty -Path 'HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name DefaultDomain -Value `".`""
			Add-Content -Path "$VMPath\$($DCNamesForestRoot2016[$i])\Virtual Hard Disks\$($DCNamesForestRoot2016[$i]).ps1" -Value "New-PSDrive -PSProvider Registry -Name HKU -Root HKEY_USERS"
			Add-Content -Path "$VMPath\$($DCNamesForestRoot2016[$i])\Virtual Hard Disks\$($DCNamesForestRoot2016[$i]).ps1" -Value "Set-ItemProperty -Path 'HKU:\.DEFAULT\Control Panel\Keyboard' -Name InitialKeyboardIndicators -Value 2147483650"
			Add-Content -Path "$VMPath\$($DCNamesForestRoot2016[$i])\Virtual Hard Disks\$($DCNamesForestRoot2016[$i]).ps1" -Value "Rename-Computer -NewName $($DCNamesForestRoot2016[$i]) -Restart"
			Add-Content -Path "$VMPath\$($DCNamesForestRoot2016[$i])\Virtual Hard Disks\$($DCNamesForestRoot2016[$i]).cmd" -Value "powershell.exe -file $($DCNamesForestRoot2016[$i]).ps1"
			
			New-Item -Name "DomJoin.cmd" -ItemType File -Path "$VMPath\$($DCNamesForestRoot2016[$i])\Virtual Hard Disks\" | Out-Null
			Add-Content -Path "$VMPath\$($DCNamesForestRoot2016[$i])\Virtual Hard Disks\DomJoin.cmd" -Value "powershell.exe -Executionpolicy bypass -file DomJoin.ps1"
			New-Item -Name "DomJoin.ps1" -ItemType File -Path "$VMPath\$($DCNamesForestRoot2016[$i])\Virtual Hard Disks\" | Out-Null
			Add-Content -Path "$VMPath\$($DCNamesForestRoot2016[$i])\Virtual Hard Disks\DomJoin.ps1" -Value "Add-Computer -DomainName `"ADS-CENTER.DE`" -Credential (New-Object System.Management.Automation.PSCredential `"ADS\Administrator`", (ConvertTo-SecureString -AsPlainText -Force -String `"C0mplex`")) -Restart"
			
			# mount VHD
			Write-Debug -Message "Identifying the VM disk at $($DCNamesForestRoot2016[$i])"
			$driveb4 = (Get-PSDrive).Name
			Write-Debug -Message "Mounting the VM disk at $($DCNamesForestRoot2016[$i])"
			Mount-VHD -Path "$VMPath\$($DCNamesForestRoot2016[$i])\Virtual Hard Disks\$($DCNamesForestRoot2016[$i]).vhdx"
			$driveat = (Get-PSDrive).name
			$drive = (Compare-Object -ReferenceObject $driveb4 -DifferenceObject $driveat).inputobject[-1] + ':'
			New-Item -Path $drive\SetupTemp -ItemType Directory | Out-Null
			Write-Debug -Message "Changing directory to VM disk at $($DCNamesForestRoot2016[$i])"
			Set-Location -Path $drive\SetupTemp | Out-Null
			Write-Debug -Message "Copying setup files to VM disk at $($DCNamesForestRoot2016[$i])"
			Copy-Item -Path "$VMPath\$($DCNamesForestRoot2016[$i])\Virtual Hard Disks\$($DCNamesForestRoot2016[$i]).ps1" -Destination . | Out-Null
			Copy-Item -Path "$VMPath\$($DCNamesForestRoot2016[$i])\Virtual Hard Disks\$($DCNamesForestRoot2016[$i]).cmd" -Destination . | Out-Null
			Copy-Item -Path "$VMPath\$($DCNamesForestRoot2016[$i])\Virtual Hard Disks\DomJoin.cmd" -Destination . | Out-Null
			Copy-Item -Path "$VMPath\$($DCNamesForestRoot2016[$i])\Virtual Hard Disks\DomJoin.ps1" -Destination . | Out-Null
			Copy-Item -Path "$VMPath\Remove-AutoLogin.cmd" -Destination . | Out-Null
			Copy-Item -Path "$VMPath\Remove-AutoLogin.ps1" -Destination . | Out-Null
			Write-Debug -Message "Changing directoy to C:"
			Set-Location -Path c: | Out-Null
			reg load HKLM\VM $drive\Windows\System32\config\SOFTWARE
			Set-ItemProperty -Path 'HKLM:\vm\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name AutoAdminLogon -Value 1
			Set-ItemProperty -Path 'HKLM:\vm\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name DefaultUserName -Value "Administrator"
			Set-ItemProperty -Path 'HKLM:\vm\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name DefaultPassword -Value "C0mplex"
			Set-ItemProperty -Path 'HKLM:\vm\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name DefaultDomain -Value "."
			Set-ItemProperty -Path 'HKLM:\vm\Microsoft\Windows\CurrentVersion\RunOnce' -Name "$($Computername).cmd" -Value "C:\SetupTemp\$Computername.cmd"
			reg unload HKLM\VM
			Write-Debug -Message "Unmounting VM disk at $($DCNamesForestRoot2016[$i])"
			Dismount-VHD -Path "$VMPath\$($DCNamesForestRoot2016[$i])\Virtual Hard Disks\$($DCNamesForestRoot2016[$i]).vhdx"
		}

## FRVR ##
New-Item -Name ADS-FRVR.cmd -ItemType File -Path "$VMPath\ADS-FRVR\Virtual Hard Disks\" | Out-Null
New-Item -Name ADS-FRVR.ps1 -ItemType File -Path "$VMPath\ADS-FRVR\Virtual Hard Disks\" | Out-Null
		Add-Content -Path "$VMPath\ADS-FRVR\Virtual Hard Disks\ADS-FRVR.cmd" -value "Powershell.exe -executionpolicy bypass -file ADS-FRVR.ps1"
		Add-Content -Path "$VMPath\ADS-FRVR\Virtual Hard Disks\ADS-FRVR.ps1" -value "Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled false"
		Add-Content -Path "$VMPath\ADS-FRVR\Virtual Hard Disks\ADS-FRVR.ps1" -value "Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server'-name `"fDenyTSConnections`" -Value 0"
		Add-Content -Path "$VMPath\ADS-FRVR\Virtual Hard Disks\ADS-FRVR.ps1" -value "Enable-NetFirewallRule -DisplayGroup `"Remote Desktop`""
		Add-Content -Path "$VMPath\ADS-FRVR\Virtual Hard Disks\ADS-FRVR.ps1" -value "Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -name `"UserAuthentication`" -Value 1"
		Add-Content -Path "$VMPath\ADS-FRVR\Virtual Hard Disks\ADS-FRVR.ps1" -Value "New-PSDrive -PSProvider Registry -Name HKU -Root HKEY_USERS"
		Add-Content -Path "$VMPath\ADS-FRVR\Virtual Hard Disks\ADS-FRVR.ps1" -Value "Set-ItemProperty -Path 'HKU:\.DEFAULT\Control Panel\Keyboard' -Name InitialKeyboardIndicators -Value 2147483650"
		Add-Content -Path "$VMPath\ADS-FRVR\Virtual Hard Disks\ADS-FRVR.ps1" -value "Disable-NetAdapterBinding -InterfaceAlias * -ComponentID ms_tcpip6,ms_rspndr,ms_lltdio,ms_lldp,ms_implat,ms_msclient,ms_pacer,ms_server"
		Add-Content -Path "$VMPath\ADS-FRVR\Virtual Hard Disks\ADS-FRVR.ps1" -value "New-NetIPAddress -InterfaceAlias ethernet -IPAddress 192.168.6.254 -PrefixLength 24"
		Add-Content -Path "$VMPath\ADS-FRVR\Virtual Hard Disks\ADS-FRVR.ps1" -value "Rename-NetAdapter -InterfaceAlias ethernet -NewName `"192.168.6.0`""
		Add-Content -Path "$VMPath\ADS-FRVR\Virtual Hard Disks\ADS-FRVR.ps1" -value "New-NetIPAddress -InterfaceAlias `"ethernet 2`" -IPAddress 192.168.7.254 -PrefixLength 24"
		Add-Content -Path "$VMPath\ADS-FRVR\Virtual Hard Disks\ADS-FRVR.ps1" -value "Rename-NetAdapter -InterfaceAlias `"ethernet 2`" -NewName `"192.168.7.0`""
		Add-Content -Path "$VMPath\ADS-FRVR\Virtual Hard Disks\ADS-FRVR.ps1" -value "New-NetIPAddress -InterfaceAlias `"ethernet 3`" -IPAddress 192.168.8.254 -PrefixLength 24"
		Add-Content -Path "$VMPath\ADS-FRVR\Virtual Hard Disks\ADS-FRVR.ps1" -value "Rename-NetAdapter -InterfaceAlias `"ethernet 3`" -NewName `"192.168.8.0`""
		Add-Content -Path "$VMPath\ADS-FRVR\Virtual Hard Disks\ADS-FRVR.ps1" -value "New-NetIPAddress -InterfaceAlias `"ethernet 4`" -IPAddress 192.168.9.254 -PrefixLength 24"
		Add-Content -Path "$VMPath\ADS-FRVR\Virtual Hard Disks\ADS-FRVR.ps1" -value "Rename-NetAdapter -InterfaceAlias `"ethernet 4`" -NewName `"192.168.9.0`""
		Add-Content -Path "$VMPath\ADS-FRVR\Virtual Hard Disks\ADS-FRVR.ps1" -value "New-NetIPAddress -InterfaceAlias `"ethernet 5`" -IPAddress 192.168.10.254 -PrefixLength 24"
		Add-Content -Path "$VMPath\ADS-FRVR\Virtual Hard Disks\ADS-FRVR.ps1" -value "Rename-NetAdapter -InterfaceAlias `"ethernet 5`" -NewName `"192.168.10.0`""
		Add-Content -Path "$VMPath\ADS-FRVR\Virtual Hard Disks\ADS-FRVR.ps1" -value "New-NetIPAddress -InterfaceAlias `"ethernet 6`" -IPAddress 192.168.11.254 -PrefixLength 24"
		Add-Content -Path "$VMPath\ADS-FRVR\Virtual Hard Disks\ADS-FRVR.ps1" -value "Rename-NetAdapter -InterfaceAlias `"ethernet 6`" -NewName `"192.168.11.0`""
		Add-Content -Path "$VMPath\ADS-FRVR\Virtual Hard Disks\ADS-FRVR.ps1" -value "New-NetIPAddress -InterfaceAlias `"ethernet 7`" -IPAddress 192.168.12.254 -PrefixLength 24"
		Add-Content -Path "$VMPath\ADS-FRVR\Virtual Hard Disks\ADS-FRVR.ps1" -value "Rename-NetAdapter -InterfaceAlias `"ethernet 7`" -NewName `"192.168.12.0`""
		Add-Content -Path "$VMPath\ADS-FRVR\Virtual Hard Disks\ADS-FRVR.ps1" -value "New-NetIPAddress -InterfaceAlias `"ethernet 8`" -IPAddress 192.168.13.254 -PrefixLength 24"
		Add-Content -Path "$VMPath\ADS-FRVR\Virtual Hard Disks\ADS-FRVR.ps1" -value "Rename-NetAdapter -InterfaceAlias `"ethernet 8`" -NewName `"192.168.13.0`""
		Add-Content -Path "$VMPath\ADS-FRVR\Virtual Hard Disks\ADS-FRVR.ps1" -value "Install-WindowsFeature -Name Routing -IncludeManagementTools"
		Add-Content -Path "$VMPath\ADS-FRVR\Virtual Hard Disks\ADS-FRVR.ps1" -value "Rename-Computer -NewName FRVR -Restart"
		
		# mount VHD
		$driveb4 = (Get-PSDrive).Name
		Mount-VHD -Path "$VMPath\ADS-FRVR\Virtual Hard Disks\ADS-FRVR.vhdx"
		$driveat = (Get-PSDrive).name
		$drive = (Compare-Object -ReferenceObject $driveb4 -DifferenceObject $driveat).inputobject[-1] + ':'
		New-Item -Path $drive\SetupTemp -ItemType Directory | Out-Null
		Set-Location -Path $drive\SetupTemp | Out-Null
		Copy-Item -Path "$VMPath\ADS-FRVR\Virtual Hard Disks\ADS-FRVR.cmd" -Destination . | Out-Null
		Copy-Item -Path "$VMPath\ADS-FRVR\Virtual Hard Disks\ADS-FRVR.ps1" -Destination . | Out-Null
		Copy-Item -Path "$VMPath\Remove-AutoLogin.cmd" -Destination . | Out-Null
		Copy-Item -Path "$VMPath\Remove-AutoLogin.ps1" -Destination . | Out-Null
		Set-Location -Path c: | Out-Null
		reg load HKLM\VM $drive\Windows\System32\config\SOFTWARE
		Set-ItemProperty -Path 'HKLM:\vm\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name AutoAdminLogon -Value 1
		Set-ItemProperty -Path 'HKLM:\vm\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name DefaultUserName -Value "Administrator"
		Set-ItemProperty -Path 'HKLM:\vm\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name DefaultPassword -Value "C0mplex"
		Set-ItemProperty -Path 'HKLM:\vm\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name DefaultDomain -Value "."
		Set-ItemProperty -Path 'HKLM:\vm\Microsoft\Windows\CurrentVersion\RunOnce' -Name "$($Computername).cmd" -Value "C:\SetupTemp\$Computername.cmd"
		reg unload HKLM\VM
		Dismount-VHD -Path "$VMPath\ADS-FRVR\Virtual Hard Disks\ADS-FRVR.vhdx"
		
		
		## 2008 DCs ##
		for ($i = 1; $i -le $DCNames2008R2.count; $i++)
		{
			New-Item -Name "$($DCNames2008R2[$i - 1]).cmd" -ItemType File -Path "$VMPath\$($DCNames2008R2[$i - 1])\Virtual Hard Disks\" | Out-Null
			Add-Content -Path "$VMPath\$($DCNames2008R2[$i - 1])\Virtual Hard Disks\$($DCNames2008R2[$i - 1]).cmd" -value "netsh interface ipv6 delete dnsserver `"Local Area Connection`" ::1"
			Add-Content -Path "$VMPath\$($DCNames2008R2[$i - 1])\Virtual Hard Disks\$($DCNames2008R2[$i - 1]).cmd" -value "netsh interface ipv4 set address `"Local Area Connection`" static 192.168.6.$i 255.255.255.0 192.168.6.254 1"
			Add-Content -Path "$VMPath\$($DCNames2008R2[$i - 1])\Virtual Hard Disks\$($DCNames2008R2[$i - 1]).cmd" -value "netsh interface ipv4 set dns `"Local Area Connection`" static 192.168.6.241"
			Add-Content -Path "$VMPath\$($DCNames2008R2[$i - 1])\Virtual Hard Disks\$($DCNames2008R2[$i - 1]).cmd" -value "netsh interface ipv4 add dns `"Local Area Connection`" address=192.168.6.242 validate=no"
			Add-Content -Path "$VMPath\$($DCNames2008R2[$i - 1])\Virtual Hard Disks\$($DCNames2008R2[$i - 1]).cmd" -value "netsh interface ipv4 add dns `"Local Area Connection`" address=192.168.6.243 validate=no"
			Add-Content -Path "$VMPath\$($DCNames2008R2[$i - 1])\Virtual Hard Disks\$($DCNames2008R2[$i - 1]).cmd" -value "netdom renamecomputer localhost /newname:$($DCNames2008R2[$i - 1]) /Force /Reboot"
			
			# mount VHD
			$driveb4 = (Get-PSDrive).Name
			Mount-VHD -Path "$VMPath\$($DCNames2008R2[$i - 1])\Virtual Hard Disks\$($DCNames2008R2[$i - 1]).vhdx"
			$driveat = (Get-PSDrive).name
			$drive = (Compare-Object -ReferenceObject $driveb4 -DifferenceObject $driveat).inputobject[-1] + ':'
			New-Item -Path $drive\SetupTemp -ItemType Directory | Out-Null
			Set-Location -Path $drive\SetupTemp | Out-Null
			Copy-Item -Path "$VMPath\$($DCNames2008R2[$i - 1])\Virtual Hard Disks\$($DCNames2008R2[$i - 1]).cmd" -Destination . | Out-Null
			Copy-Item -Path "$VMPath\DCpromo-*.*" -Destination . | Out-Null
			Copy-Item -Path "$VMPath\Remove-AutoLogin.cmd" -Destination . | Out-Null
			Copy-Item -Path "$VMPath\Remove-AutoLogin.ps1" -Destination . | Out-Null
			Copy-Item -Path "$VMPath\RestartServices.cmd" -Destination . | Out-Null
			Copy-Item -Path "$VMPath\RestartServices.ps1" -Destination . | Out-Null
			Set-Location -Path c: | Out-Null
			reg load HKLM\VM $drive\Windows\System32\config\SOFTWARE
			Set-ItemProperty -Path 'HKLM:\vm\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name AutoAdminLogon -Value 1
			Set-ItemProperty -Path 'HKLM:\vm\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name DefaultUserName -Value "Administrator"
			Set-ItemProperty -Path 'HKLM:\vm\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name DefaultPassword -Value "C0mplex"
			Set-ItemProperty -Path 'HKLM:\vm\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name DefaultDomain -Value "."
			Set-ItemProperty -Path 'HKLM:\vm\Microsoft\Windows\CurrentVersion\RunOnce' -Name "$($Computername).cmd" -Value "C:\SetupTemp\$Computername.cmd"
			reg unload HKLM\VM
			Dismount-VHD -Path "$VMPath\$($DCNames2008R2[$i - 1])\Virtual Hard Disks\$($DCNames2008R2[$i - 1]).vhdx"
		}
		
		## 2012 ##
		for ($i = $DCNames2008R2.count + 1; $i -le $DCNames2008R2.count + $DCNames2012R2.count; $i++)
		{
			New-Item -Name "$($DCNames2012R2[$i - ($DCNames2008R2.count) - 1]).cmd" -ItemType File -Path "$VMPath\$($DCNames2012R2[$i - ($DCNames2008R2.count) - 1])\Virtual Hard Disks\"
			Add-Content -Path "$VMPath\$($DCNames2012R2[$i - ($DCNames2008R2.count) - 1])\Virtual Hard Disks\$($DCNames2012R2[$i - ($DCNames2008R2.count) - 1]).cmd" -Value "powershell.exe -executionpolicy bypass -file $($DCNames2012R2[$i - ($DCNames2008R2.count) - 1]).ps1"
			
			New-Item -Name "$($DCNames2012R2[$i - ($DCNames2008R2.count) - 1]).ps1" -ItemType File -Path "$VMPath\$($DCNames2012R2[$i - ($DCNames2008R2.count) - 1])\Virtual Hard Disks\" | Out-Null
			Add-Content -Path "$VMPath\$($DCNames2012R2[$i - ($DCNames2008R2.count) - 1])\Virtual Hard Disks\$($DCNames2012R2[$i - ($DCNames2008R2.count) - 1]).ps1" -Value "Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled false"
			Add-Content -Path "$VMPath\$($DCNames2012R2[$i - ($DCNames2008R2.count) - 1])\Virtual Hard Disks\$($DCNames2012R2[$i - ($DCNames2008R2.count) - 1]).ps1" -Value "Set-ItemProperty -Path `'HKLM:\System\CurrentControlSet\Control\Terminal Server`' -name `"fDenyTSConnections`" -Value 0"
			Add-Content -Path "$VMPath\$($DCNames2012R2[$i - ($DCNames2008R2.count) - 1])\Virtual Hard Disks\$($DCNames2012R2[$i - ($DCNames2008R2.count) - 1]).ps1" -Value "Enable-NetFirewallRule -DisplayGroup `"Remote Desktop`""
			Add-Content -Path "$VMPath\$($DCNames2012R2[$i - ($DCNames2008R2.count) - 1])\Virtual Hard Disks\$($DCNames2012R2[$i - ($DCNames2008R2.count) - 1]).ps1" -Value "Set-ItemProperty -Path `'HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp`' -name `"UserAuthentication`" -Value 1"
			Add-Content -Path "$VMPath\$($DCNames2012R2[$i - ($DCNames2008R2.count) - 1])\Virtual Hard Disks\$($DCNames2012R2[$i - ($DCNames2008R2.count) - 1]).ps1" -Value "Disable-NetAdapterBinding -InterfaceAlias ethernet -ComponentID ms_tcpip6"
			Add-Content -Path "$VMPath\$($DCNames2012R2[$i - ($DCNames2008R2.count) - 1])\Virtual Hard Disks\$($DCNames2012R2[$i - ($DCNames2008R2.count) - 1]).ps1" -Value "New-NetIPAddress -InterfaceAlias ethernet -IPAddress 192.168.6.$i -PrefixLength 24 -DefaultGateway 192.168.6.254"
			Add-Content -Path "$VMPath\$($DCNames2012R2[$i - ($DCNames2008R2.count) - 1])\Virtual Hard Disks\$($DCNames2012R2[$i - ($DCNames2008R2.count) - 1]).ps1" -Value "Set-DnsClientServerAddress -InterfaceAlias ethernet -ResetServerAddresses"
			Add-Content -Path "$VMPath\$($DCNames2012R2[$i - ($DCNames2008R2.count) - 1])\Virtual Hard Disks\$($DCNames2012R2[$i - ($DCNames2008R2.count) - 1]).ps1" -Value "Set-DnsClientServerAddress -InterfaceAlias ethernet -ServerAddresses `"192.168.6.241,192.168.6.242,192.168.6.243`""
			Add-Content -Path "$VMPath\$($DCNames2012R2[$i - ($DCNames2008R2.count) - 1])\Virtual Hard Disks\$($DCNames2012R2[$i - ($DCNames2008R2.count) - 1]).ps1" -Value "Rename-Computer -NewName $($DCNames2012R2[$i - ($DCNames2008R2.count) - 1]) -Restart"
			
			New-Item -Name "DomJoin.cmd" -ItemType File -Path "$VMPath\$($DCNames2012R2[$i - ($DCNames2008R2.count) - 1])\Virtual Hard Disks\" | Out-Null
			Add-Content -Path "$VMPath\$($DCNames2012R2[$i - ($DCNames2008R2.count) - 1])\Virtual Hard Disks\DomJoin.cmd" -Value "powershell.exe -Executionpolicy bypass -file DomJoin.ps1"
			New-Item -Name "DomJoin.ps1" -ItemType File -Path "$VMPath\$($DCNames2012R2[$i - ($DCNames2008R2.count) - 1])\Virtual Hard Disks\" | Out-Null
			Add-Content -Path "$VMPath\$($DCNames2012R2[$i - ($DCNames2008R2.count) - 1])\Virtual Hard Disks\DomJoin.ps1" -Value "Add-Computer -DomainName `"`$(((Get-Item -Path 'C:\SetupTemp\S*.cmd').Name.Split(`"-`"))[0])`" -Credential (New-Object System.Management.Automation.PSCredential `"`$(((Get-Item -Path 'C:\SetupTemp\S*.cmd').Name.Split(`"-`"))[0])\Administrator`", (ConvertTo-SecureString -AsPlainText -Force -String `"C0mplex`")) -Restart"
			
			
			# mount VHD
			$driveb4 = (Get-PSDrive).Name
			Mount-VHD -Path "$VMPath\$($DCNames2012R2[$i - ($DCNames2008R2.count) - 1])\Virtual Hard Disks\$($DCNames2012R2[$i - ($DCNames2008R2.count) - 1]).vhdx"
			$driveat = (Get-PSDrive).name
			$drive = (Compare-Object -ReferenceObject $driveb4 -DifferenceObject $driveat).inputobject[-1] + ':'
			New-Item -Path $drive\SetupTemp -ItemType Directory | Out-Null
			Set-Location -Path $drive\SetupTemp | Out-Null
			Copy-Item -Path "$VMPath\$($DCNames2012R2[$i - ($DCNames2008R2.count) - 1])\Virtual Hard Disks\$($DCNames2012R2[$i - ($DCNames2008R2.count) - 1]).cmd" -Destination . | Out-Null
			Copy-Item -Path "$VMPath\$($DCNames2012R2[$i - ($DCNames2008R2.count) - 1])\Virtual Hard Disks\$($DCNames2012R2[$i - ($DCNames2008R2.count) - 1]).ps1" -Destination . | Out-Null
			Copy-Item -Path "$VMPath\$($DCNames2012R2[$i - ($DCNames2008R2.count) - 1])\Virtual Hard Disks\DomJoin.cmd" -Destination . | Out-Null
			Copy-Item -Path "$VMPath\$($DCNames2012R2[$i - ($DCNames2008R2.count) - 1])\Virtual Hard Disks\DomJoin.ps1" -Destination . | Out-Null
			Copy-Item -Path "$VMPath\Remove-AutoLogin.cmd" -Destination . | Out-Null
			Copy-Item -Path "$VMPath\Remove-AutoLogin.ps1" -Destination . | Out-Null
			Set-Location -Path c: | Out-Null
			reg load HKLM\VM $drive\Windows\System32\config\SOFTWARE
			Set-ItemProperty -Path 'HKLM:\vm\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name AutoAdminLogon -Value 1
			Set-ItemProperty -Path 'HKLM:\vm\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name DefaultUserName -Value "Administrator"
			Set-ItemProperty -Path 'HKLM:\vm\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name DefaultPassword -Value "C0mplex"
			Set-ItemProperty -Path 'HKLM:\vm\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name DefaultDomain -Value "."
			Set-ItemProperty -Path 'HKLM:\vm\Microsoft\Windows\CurrentVersion\RunOnce' -Name "$($Computername).cmd" -Value "C:\SetupTemp\$Computername.cmd"
			reg unload HKLM\VM
			Dismount-VHD -Path "$VMPath\$($DCNames2012R2[$i - ($DCNames2008R2.count) - 1])\Virtual Hard Disks\$($DCNames2012R2[$i - ($DCNames2008R2.count) - 1]).vhdx"
		}
		
		##Server 2016 ##
		for ($i = $DCNames2008R2.count + $DCNames2012R2.count + 1; $i -le $DCNames2008R2.count + $DCNames2012R2.count + $DCNames2016.count; $i++)
		{
			New-Item -Name "$($DCNames2016[$i - ($DCNames2008R2.count + $DCNames2012R2.count) - 1]).cmd" -ItemType File -Path "$VMPath\$($DCNames2016[$i - ($DCNames2008R2.count + $DCNames2012R2.count) - 1])\Virtual Hard Disks"
			Add-Content -Path "$VMPath\$($DCNames2016[$i - ($DCNames2008R2.count + $DCNames2012R2.count) - 1])\Virtual Hard Disks\$($DCNames2016[$i - ($DCNames2008R2.count + $DCNames2012R2.count) - 1]).cmd" -Value "powershell.exe -file $($DCNames2016[$i - ($DCNames2008R2.count + $DCNames2012R2.count) - 1]).ps1"
			
			New-Item -Name "$($DCNames2016[$i - ($DCNames2008R2.count + $DCNames2012R2.count) - 1]).ps1" -ItemType File -Path "$VMPath\$($DCNames2016[$i - ($DCNames2008R2.count + $DCNames2012R2.count) - 1])\Virtual Hard Disks" | Out-Null
			Add-Content -Path "$VMPath\$($DCNames2016[$i - ($DCNames2008R2.count + $DCNames2012R2.count) - 1])\Virtual Hard Disks\$($DCNames2016[$i - ($DCNames2008R2.count + $DCNames2012R2.count) - 1]).ps1" -Value "Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled false"
			Add-Content -Path "$VMPath\$($DCNames2016[$i - ($DCNames2008R2.count + $DCNames2012R2.count) - 1])\Virtual Hard Disks\$($DCNames2016[$i - ($DCNames2008R2.count + $DCNames2012R2.count) - 1]).ps1" -Value "Set-ItemProperty -Path `'HKLM:\System\CurrentControlSet\Control\Terminal Server`'-name `"fDenyTSConnections`" -Value 0"
			Add-Content -Path "$VMPath\$($DCNames2016[$i - ($DCNames2008R2.count + $DCNames2012R2.count) - 1])\Virtual Hard Disks\$($DCNames2016[$i - ($DCNames2008R2.count + $DCNames2012R2.count) - 1]).ps1" -Value "Enable-NetFirewallRule -DisplayGroup `"Remote Desktop`""
			Add-Content -Path "$VMPath\$($DCNames2016[$i - ($DCNames2008R2.count + $DCNames2012R2.count) - 1])\Virtual Hard Disks\$($DCNames2016[$i - ($DCNames2008R2.count + $DCNames2012R2.count) - 1]).ps1" -Value "Set-ItemProperty -Path `'HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp`' -name `"UserAuthentication`" -Value 1"
			Add-Content -Path "$VMPath\$($DCNames2016[$i - ($DCNames2008R2.count + $DCNames2012R2.count) - 1])\Virtual Hard Disks\$($DCNames2016[$i - ($DCNames2008R2.count + $DCNames2012R2.count) - 1]).ps1" -Value "Disable-NetAdapterBinding -InterfaceAlias ethernet -ComponentID ms_tcpip6"
			Add-Content -Path "$VMPath\$($DCNames2016[$i - ($DCNames2008R2.count + $DCNames2012R2.count) - 1])\Virtual Hard Disks\$($DCNames2016[$i - ($DCNames2008R2.count + $DCNames2012R2.count) - 1]).ps1" -Value "New-NetIPAddress -InterfaceAlias ethernet -IPAddress 192.168.6.$i -PrefixLength 24 -DefaultGateway 192.168.6.254"
			Add-Content -Path "$VMPath\$($DCNames2016[$i - ($DCNames2008R2.count + $DCNames2012R2.count) - 1])\Virtual Hard Disks\$($DCNames2016[$i - ($DCNames2008R2.count + $DCNames2012R2.count) - 1]).ps1" -Value "Set-DnsClientServerAddress -InterfaceAlias ethernet -ResetServerAddresses"
			Add-Content -Path "$VMPath\$($DCNames2016[$i - ($DCNames2008R2.count + $DCNames2012R2.count) - 1])\Virtual Hard Disks\$($DCNames2016[$i - ($DCNames2008R2.count + $DCNames2012R2.count) - 1]).ps1" -Value "Set-DnsClientServerAddress -InterfaceAlias ethernet -ServerAddresses `"192.168.6.241,192.168.6.242,192.168.6.243`""
			Add-Content -Path "$VMPath\$($DCNames2016[$i - ($DCNames2008R2.count + $DCNames2012R2.count) - 1])\Virtual Hard Disks\$($DCNames2016[$i - ($DCNames2008R2.count + $DCNames2012R2.count) - 1]).ps1" -Value "Rename-Computer -NewName $($DCNames2016[$i - ($DCNames2008R2.count + $DCNames2012R2.count) - 1]) -Restart"
			
			New-Item -Name "DomJoin.cmd" -ItemType File -Path "$VMPath\$($DCNames2016[$i - ($DCNames2008R2.count + $DCNames2012R2.count) - 1])\Virtual Hard Disks\" | Out-Null
			Add-Content -Path "$VMPath\$($DCNames2016[$i - ($DCNames2008R2.count + $DCNames2012R2.count) - 1])\Virtual Hard Disks\DomJoin.cmd" -Value "powershell.exe -Executionpolicy bypass -file DomJoin.ps1"
			New-Item -Name "DomJoin.ps1" -ItemType File -Path "$VMPath\$($DCNames2016[$i - ($DCNames2008R2.count + $DCNames2012R2.count) - 1])\Virtual Hard Disks\" | Out-Null
			Add-Content -Path "$VMPath\$($DCNames2016[$i - ($DCNames2008R2.count + $DCNames2012R2.count) - 1])\Virtual Hard Disks\DomJoin.ps1" -Value "Add-Computer -DomainName `"`$(((Get-Item -Path 'C:\SetupTemp\S*.cmd').Name.Split(`"-`"))[0])`" -Credential (New-Object System.Management.Automation.PSCredential `"`$(((Get-Item -Path 'C:\SetupTemp\S*.cmd').Name.Split(`"-`"))[0])\Administrator`", (ConvertTo-SecureString -AsPlainText -Force -String `"C0mplex`")) -Restart"
			
			
			# mount VHD
			$driveb4 = (Get-PSDrive).Name
			Mount-VHD -Path "$VMPath\$($DCNames2016[$i - ($DCNames2008R2.count + $DCNames2012R2.count) - 1])\Virtual Hard Disks\$($DCNames2016[$i - ($DCNames2008R2.count + $DCNames2012R2.count) - 1]).vhdx"
			$driveat = (Get-PSDrive).name
			$drive = (Compare-Object -ReferenceObject $driveb4 -DifferenceObject $driveat).inputobject[-1] + ':'
			New-Item -Path $drive\SetupTemp -ItemType Directory | Out-Null
			Set-Location -Path $drive\SetupTemp | Out-Null
			Copy-Item -Path "$VMPath\$($DCNames2016[$i - ($DCNames2008R2.count + $DCNames2012R2.count) - 1])\Virtual Hard Disks\$($DCNames2016[$i - ($DCNames2008R2.count + $DCNames2012R2.count) - 1]).cmd" -Destination . | Out-Null
			Copy-Item -Path "$VMPath\$($DCNames2016[$i - ($DCNames2008R2.count + $DCNames2012R2.count) - 1])\Virtual Hard Disks\$($DCNames2016[$i - ($DCNames2008R2.count + $DCNames2012R2.count) - 1]).ps1" -Destination . | Out-Null
			Copy-Item -Path "$VMPath\$($DCNames2016[$i - ($DCNames2008R2.count + $DCNames2012R2.count) - 1])\Virtual Hard Disks\DomJoin.cmd" -Destination . | Out-Null
			Copy-Item -Path "$VMPath\$($DCNames2016[$i - ($DCNames2008R2.count + $DCNames2012R2.count) - 1])\Virtual Hard Disks\DomJoin.ps1" -Destination . | Out-Null
			Copy-Item -Path "$VMPath\Remove-AutoLogin.cmd" -Destination . | Out-Null
			Copy-Item -Path "$VMPath\Remove-AutoLogin.ps1" -Destination . | Out-Null
			Set-Location -Path c: | Out-Null
			reg load HKLM\VM $drive\Windows\System32\config\SOFTWARE
			Set-ItemProperty -Path 'HKLM:\vm\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name AutoAdminLogon -Value 1
			Set-ItemProperty -Path 'HKLM:\vm\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name DefaultUserName -Value "Administrator"
			Set-ItemProperty -Path 'HKLM:\vm\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name DefaultPassword -Value "C0mplex"
			Set-ItemProperty -Path 'HKLM:\vm\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name DefaultDomain -Value "."
			Set-ItemProperty -Path 'HKLM:\vm\Microsoft\Windows\CurrentVersion\RunOnce' -Name "$($Computername).cmd" -Value "C:\SetupTemp\$Computername.cmd"
			reg unload HKLM\VM
			Dismount-VHD -Path "$VMPath\$($DCNames2016[$i - ($DCNames2008R2.count + $DCNames2012R2.count) - 1])\Virtual Hard Disks\$($DCNames2016[$i - ($DCNames2008R2.count + $DCNames2012R2.count) - 1]).vhdx"
		}
		
		
		## Win7 ##
		for ($i = $DCNames2008R2.count + $DCNames2012R2.count + $DCNames2016.count + 1; $i -le $DCNames2008R2.count + $DCNames2012R2.count + $DCNames2016.count + $NamesWin7.count; $i++)
		{
			New-Item -Name "$($NamesWin7[$i - ($DCNames2008R2.count + $DCNames2012R2.count + $DCNames2016.count) - 1]).cmd" -ItemType File -Path "$VMPath\$($NamesWin7[$i - ($DCNames2008R2.count + $DCNames2012R2.count + $DCNames2016.count) - 1])\Virtual Hard Disks" | Out-Null
			Add-Content -Path "$VMPath\$($NamesWin7[$i - ($DCNames2008R2.count + $DCNames2012R2.count + $DCNames2016.count) - 1])\Virtual Hard Disks\$($NamesWin7[$i - ($DCNames2008R2.count + $DCNames2012R2.count + $DCNames2016.count) - 1]).cmd" -Value "netsh interface ipv6 delete dnsserver `"Local Area Connection`" ::1"
			Add-Content -Path "$VMPath\$($NamesWin7[$i - ($DCNames2008R2.count + $DCNames2012R2.count + $DCNames2016.count) - 1])\Virtual Hard Disks\$($NamesWin7[$i - ($DCNames2008R2.count + $DCNames2012R2.count + $DCNames2016.count) - 1]).cmd" -Value "netsh interface ipv4 set address `"Local Area Connection`" static 192.168.6.$i 255.255.255.0 192.168.6.254 1"
			Add-Content -Path "$VMPath\$($NamesWin7[$i - ($DCNames2008R2.count + $DCNames2012R2.count + $DCNames2016.count) - 1])\Virtual Hard Disks\$($NamesWin7[$i - ($DCNames2008R2.count + $DCNames2012R2.count + $DCNames2016.count) - 1]).cmd" -Value "netsh interface ipv4 set dns `"Local Area Connection`" static 192.168.6.241"
			Add-Content -Path "$VMPath\$($NamesWin7[$i - ($DCNames2008R2.count + $DCNames2012R2.count + $DCNames2016.count) - 1])\Virtual Hard Disks\$($NamesWin7[$i - ($DCNames2008R2.count + $DCNames2012R2.count + $DCNames2016.count) - 1]).cmd" -Value "netsh interface ipv4 add dns `"Local Area Connection`" 192.168.6.242"
			Add-Content -Path "$VMPath\$($NamesWin7[$i - ($DCNames2008R2.count + $DCNames2012R2.count + $DCNames2016.count) - 1])\Virtual Hard Disks\$($NamesWin7[$i - ($DCNames2008R2.count + $DCNames2012R2.count + $DCNames2016.count) - 1]).cmd" -Value "netsh interface ipv4 add dns `"Local Area Connection`" 192.168.6.243"
			Add-Content -Path "$VMPath\$($NamesWin7[$i - ($DCNames2008R2.count + $DCNames2012R2.count + $DCNames2016.count) - 1])\Virtual Hard Disks\$($NamesWin7[$i - ($DCNames2008R2.count + $DCNames2012R2.count + $DCNames2016.count) - 1]).cmd" -Value "netdom renamecomputer localhost /newname:$($NamesWin7[$i - ($DCNames2008R2.count + $DCNames2012R2.count + $DCNames2016.count) - 1]) /Force /Reboot"
			
			New-Item -Name "DomJoin.cmd" -ItemType File -Path "$VMPath\$($NamesWin7[$i - ($DCNames2008R2.count + $DCNames2012R2.count + $DCNames2016.count) - 1])\Virtual Hard Disks\" | Out-Null
			Add-Content -Path "$VMPath\$($NamesWin7[$i - ($DCNames2008R2.count + $DCNames2012R2.count + $DCNames2016.count) - 1])\Virtual Hard Disks\DomJoin.cmd" -Value "powershell.exe -Executionpolicy bypass -file C:\SetupTemp\DomJoin.ps1"
			New-Item -Name "DomJoin.ps1" -ItemType File -Path "$VMPath\$($NamesWin7[$i - ($DCNames2008R2.count + $DCNames2012R2.count + $DCNames2016.count) - 1])\Virtual Hard Disks\" | Out-Null
			Add-Content -Path "$VMPath\$($NamesWin7[$i - ($DCNames2008R2.count + $DCNames2012R2.count + $DCNames2016.count) - 1])\Virtual Hard Disks\DomJoin.ps1" -Value "Add-Computer -DomainName `"`$(((Get-Item -Path 'C:\SetupTemp\S*.cmd').Name.Split(`"-`"))[0])`" -Credential (New-Object System.Management.Automation.PSCredential `"`$(((Get-Item -Path 'C:\SetupTemp\S*.cmd').Name.Split(`"-`"))[0])\Administrator`", (ConvertTo-SecureString -AsPlainText -Force -String `"C0mplex`")) -Restart"
			
			# mount VHD
			$driveb4 = (Get-PSDrive).Name
			Mount-VHD -Path "$VMPath\$($NamesWin7[$i - ($DCNames2008R2.count + $DCNames2012R2.count + $DCNames2016.count) - 1])\Virtual Hard Disks\$($NamesWin7[$i - ($DCNames2008R2.count + $DCNames2012R2.count + $DCNames2016.count) - 1]).vhdx"
			$driveat = (Get-PSDrive).name
			$drive = (Compare-Object -ReferenceObject $driveb4 -DifferenceObject $driveat).inputobject[-1] + ':'
			New-Item -Path $drive\SetupTemp -ItemType Directory | Out-Null
			Set-Location -Path $drive\SetupTemp | Out-Null
			Copy-Item -Path "$VMPath\$($NamesWin7[$i - ($DCNames2008R2.count + $DCNames2012R2.count + $DCNames2016.count) - 1])\Virtual Hard Disks\$($NamesWin7[$i - ($DCNames2008R2.count + $DCNames2012R2.count + $DCNames2016.count) - 1]).cmd" -Destination . | Out-Null
			Copy-Item -Path "$VMPath\$($NamesWin7[$i - ($DCNames2008R2.count + $DCNames2012R2.count + $DCNames2016.count) - 1])\Virtual Hard Disks\DomJoin.cmd" -Destination . | Out-Null
			Copy-Item -Path "$VMPath\$($NamesWin7[$i - ($DCNames2008R2.count + $DCNames2012R2.count + $DCNames2016.count) - 1])\Virtual Hard Disks\DomJoin.ps1" -Destination . | Out-Null
			Set-Location -Path c: | Out-Null
			Dismount-VHD -Path "$VMPath\$($NamesWin7[$i - ($DCNames2008R2.count + $DCNames2012R2.count + $DCNames2016.count) - 1])\Virtual Hard Disks\$($NamesWin7[$i - ($DCNames2008R2.count + $DCNames2012R2.count + $DCNames2016.count) - 1]).vhdx"
		}
		
		##Win 10 ##
		for ($i = $DCNames2008R2.count + $DCNames2012R2.count + $DCNames2016.count + $NamesWin7.count + 1; $i -le $DCNames2008R2.count + $DCNames2012R2.count + $DCNames2016.count + $NamesWin7.count + $NamesWin10.count; $i++)
		{
			New-Item -Name "$($NamesWin10[$i - ($DCNames2016.count + $DCNames2008R2.count + $DCNames2012R2.count + $NamesWin7.count) - 1]).ps1" -ItemType File -Path "$VMPath\$($NamesWin10[$i - ($DCNames2016.count + $DCNames2008R2.count + $DCNames2012R2.count + $NamesWin7.count) - 1])\Virtual Hard Disks\" | Out-Null
			New-Item -Name "$($NamesWin10[$i - ($DCNames2016.count + $DCNames2008R2.count + $DCNames2012R2.count + $NamesWin7.count) - 1]).cmd" -ItemType File -Path "$VMPath\$($NamesWin10[$i - ($DCNames2016.count + $DCNames2008R2.count + $DCNames2012R2.count + $NamesWin7.count) - 1])\Virtual Hard Disks\" | Out-Null
			Add-Content -Path "$VMPath\$($NamesWin10[$i - ($DCNames2016.count + $DCNames2008R2.count + $DCNames2012R2.count + $NamesWin7.count) - 1])\Virtual Hard Disks\$($NamesWin10[$i - ($DCNames2016.count + $DCNames2008R2.count + $DCNames2012R2.count + $NamesWin7.count) - 1]).ps1" -Value "Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled false"
			Add-Content -Path "$VMPath\$($NamesWin10[$i - ($DCNames2016.count + $DCNames2008R2.count + $DCNames2012R2.count + $NamesWin7.count) - 1])\Virtual Hard Disks\$($NamesWin10[$i - ($DCNames2016.count + $DCNames2008R2.count + $DCNames2012R2.count + $NamesWin7.count) - 1]).ps1" -Value "Set-ItemProperty -Path `'HKLM:\System\CurrentControlSet\Control\Terminal Server`'-name `"fDenyTSConnections`" -Value 0"
			Add-Content -Path "$VMPath\$($NamesWin10[$i - ($DCNames2016.count + $DCNames2008R2.count + $DCNames2012R2.count + $NamesWin7.count) - 1])\Virtual Hard Disks\$($NamesWin10[$i - ($DCNames2016.count + $DCNames2008R2.count + $DCNames2012R2.count + $NamesWin7.count) - 1]).ps1" -Value "Enable-NetFirewallRule -DisplayGroup `"Remote Desktop`""
			Add-Content -Path "$VMPath\$($NamesWin10[$i - ($DCNames2016.count + $DCNames2008R2.count + $DCNames2012R2.count + $NamesWin7.count) - 1])\Virtual Hard Disks\$($NamesWin10[$i - ($DCNames2016.count + $DCNames2008R2.count + $DCNames2012R2.count + $NamesWin7.count) - 1]).ps1" -Value "Set-ItemProperty -Path `'HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp`' -name `"UserAuthentication`" -Value 1"
			Add-Content -Path "$VMPath\$($NamesWin10[$i - ($DCNames2016.count + $DCNames2008R2.count + $DCNames2012R2.count + $NamesWin7.count) - 1])\Virtual Hard Disks\$($NamesWin10[$i - ($DCNames2016.count + $DCNames2008R2.count + $DCNames2012R2.count + $NamesWin7.count) - 1]).ps1" -Value "Disable-NetAdapterBinding -InterfaceAlias ethernet -ComponentID ms_tcpip6"
			Add-Content -Path "$VMPath\$($NamesWin10[$i - ($DCNames2016.count + $DCNames2008R2.count + $DCNames2012R2.count + $NamesWin7.count) - 1])\Virtual Hard Disks\$($NamesWin10[$i - ($DCNames2016.count + $DCNames2008R2.count + $DCNames2012R2.count + $NamesWin7.count) - 1]).ps1" -Value "New-NetIPAddress -InterfaceAlias ethernet -IPAddress 192.168.6.$i -PrefixLength 24 -DefaultGateway 192.168.6.254"
			Add-Content -Path "$VMPath\$($NamesWin10[$i - ($DCNames2016.count + $DCNames2008R2.count + $DCNames2012R2.count + $NamesWin7.count) - 1])\Virtual Hard Disks\$($NamesWin10[$i - ($DCNames2016.count + $DCNames2008R2.count + $DCNames2012R2.count + $NamesWin7.count) - 1]).ps1" -Value "Set-DnsClientServerAddress -InterfaceAlias ethernet -ResetServerAddresses"
			Add-Content -Path "$VMPath\$($NamesWin10[$i - ($DCNames2016.count + $DCNames2008R2.count + $DCNames2012R2.count + $NamesWin7.count) - 1])\Virtual Hard Disks\$($NamesWin10[$i - ($DCNames2016.count + $DCNames2008R2.count + $DCNames2012R2.count + $NamesWin7.count) - 1]).ps1" -Value "Set-DnsClientServerAddress -InterfaceAlias ethernet -ServerAddresses `"192.168.6.241,192.168.6.242,192.168.6.243`""
			Add-Content -Path "$VMPath\$($NamesWin10[$i - ($DCNames2016.count + $DCNames2008R2.count + $DCNames2012R2.count + $NamesWin7.count) - 1])\Virtual Hard Disks\$($NamesWin10[$i - ($DCNames2016.count + $DCNames2008R2.count + $DCNames2012R2.count + $NamesWin7.count) - 1]).ps1" -Value "Rename-Computer -NewName $($NamesWin10[$i - ($DCNames2016.count + $DCNames2008R2.count + $DCNames2012R2.count + $NamesWin7.count) - 1]) -Restart"
			Add-Content -Path "$VMPath\$($NamesWin10[$i - ($DCNames2016.count + $DCNames2008R2.count + $DCNames2012R2.count + $NamesWin7.count) - 1])\Virtual Hard Disks\$($NamesWin10[$i - ($DCNames2016.count + $DCNames2008R2.count + $DCNames2012R2.count + $NamesWin7.count) - 1]).cmd" -Value "powershell.exe -executionpolicy bypass -file c:\SetupTemp\$($NamesWin10[$i - ($DCNames2016.count + $DCNames2008R2.count + $DCNames2012R2.count + $NamesWin7.count) - 1]).ps1"
			
			New-Item -Name "DomJoin.cmd" -ItemType File -Path "$VMPath\$($NamesWin10[$i - ($DCNames2016.count + $DCNames2008R2.count + $DCNames2012R2.count + $NamesWin7.count) - 1])\Virtual Hard Disks\" | Out-Null
			Add-Content -Path "$VMPath\$($NamesWin10[$i - ($DCNames2016.count + $DCNames2008R2.count + $DCNames2012R2.count + $NamesWin7.count) - 1])\Virtual Hard Disks\DomJoin.cmd" -Value "powershell.exe -Executionpolicy bypass -file C:\SetupTemp\DomJoin.ps1"
			New-Item -Name "DomJoin.ps1" -ItemType File -Path "$VMPath\$($NamesWin10[$i - ($DCNames2016.count + $DCNames2008R2.count + $DCNames2012R2.count + $NamesWin7.count) - 1])\Virtual Hard Disks\" | Out-Null
			Add-Content -Path "$VMPath\$($NamesWin10[$i - ($DCNames2016.count + $DCNames2008R2.count + $DCNames2012R2.count + $NamesWin7.count) - 1])\Virtual Hard Disks\DomJoin.ps1" -Value "Add-Computer -DomainName `"`$(((Get-Item -Path 'C:\SetupTemp\S*.cmd').Name.Split(`"-`"))[0])`" -Credential (New-Object System.Management.Automation.PSCredential `"`$(((Get-Item -Path 'C:\SetupTemp\S*.cmd').Name.Split(`"-`"))[0])\Administrator`", (ConvertTo-SecureString -AsPlainText -Force -String `"C0mplex`")) -Restart"
			
			# mount VHD
			$driveb4 = (Get-PSDrive).Name
			Mount-VHD -Path "$VMPath\$($NamesWin10[$i - ($DCNames2016.count + $DCNames2008R2.count + $DCNames2012R2.count + $NamesWin7.count) - 1])\Virtual Hard Disks\$($NamesWin10[$i - ($DCNames2016.count + $DCNames2008R2.count + $DCNames2012R2.count + $NamesWin7.count) - 1]).vhdx"
			$driveat = (Get-PSDrive).name
			$drive = (Compare-Object -ReferenceObject $driveb4 -DifferenceObject $driveat).inputobject[-1] + ':'
			New-Item -Path $drive\SetupTemp -ItemType Directory | Out-Null
			Set-Location -Path $drive\SetupTemp | Out-Null
			Copy-Item -Path "$VMPath\$($NamesWin10[$i - ($DCNames2016.count + $DCNames2008R2.count + $DCNames2012R2.count + $NamesWin7.count) - 1])\Virtual Hard Disks\$($NamesWin10[$i - ($DCNames2016.count + $DCNames2008R2.count + $DCNames2012R2.count + $NamesWin7.count) - 1]).ps1" -Destination . | Out-Null
			Copy-Item -Path "$VMPath\$($NamesWin10[$i - ($DCNames2016.count + $DCNames2008R2.count + $DCNames2012R2.count + $NamesWin7.count) - 1])\Virtual Hard Disks\$($NamesWin10[$i - ($DCNames2016.count + $DCNames2008R2.count + $DCNames2012R2.count + $NamesWin7.count) - 1]).cmd" -Destination . | Out-Null
			Copy-Item -Path "$VMPath\$($NamesWin10[$i - ($DCNames2016.count + $DCNames2008R2.count + $DCNames2012R2.count + $NamesWin7.count) - 1])\Virtual Hard Disks\DomJoin.cmd" -Destination . | Out-Null
			Copy-Item -Path "$VMPath\$($NamesWin10[$i - ($DCNames2016.count + $DCNames2008R2.count + $DCNames2012R2.count + $NamesWin7.count) - 1])\Virtual Hard Disks\DomJoin.ps1" -Destination . | Out-Null
			Dismount-VHD -Path "$VMPath\$($NamesWin10[$i - ($DCNames2016.count + $DCNames2008R2.count + $DCNames2012R2.count + $NamesWin7.count) - 1])\Virtual Hard Disks\$($NamesWin10[$i - ($DCNames2016.count + $DCNames2008R2.count + $DCNames2012R2.count + $NamesWin7.count) - 1]).vhdx"
		}
		
		## VM creation ##
		## Forest Root ##
		for ($i = 0; $i -lt $DCNamesForestRoot2008R2.count; $i++)
		{
			new-vm -Name "$($DCNamesForestRoot2008R2[$i])" -MemoryStartupBytes 1024MB -Path $VMPath -VHDPath "$VMPath\$($DCNamesForestRoot2008R2[$i])\Virtual Hard Disks\$($DCNamesForestRoot2008R2[$i]).vhdx" -SwitchName Private-1 | Out-Null
		}
		for ($i = 0; $i -lt $DCNamesForestRoot2012R2.count; $i++)
		{
			new-vm -Name "$($DCNamesForestRoot2012R2[$i])" -MemoryStartupBytes 1024MB -Path $VMPath -VHDPath "$VMPath\$($DCNamesForestRoot2012R2[$i])\Virtual Hard Disks\$($DCNamesForestRoot2012R2[$i]).vhdx" -SwitchName Private-1 -Generation 2 | Out-Null
		}
		for ($i = 0; $i -lt $DCNamesForestRoot2016.count; $i++)
		{
			new-vm -Name "$($DCNamesForestRoot2016[$i])" -MemoryStartupBytes 1024MB -Path $VMPath -VHDPath "$VMPath\$($DCNamesForestRoot2016[$i])\Virtual Hard Disks\$($DCNamesForestRoot2016[$i]).vhdx" -SwitchName Private-1 -Generation 2 | Out-Null
		}
		
		## subdom ##
		for ($i = 0; $i -lt $DCNames2008R2.count; $i++)
		{
			new-vm -Name "$($DCNames2008R2[$i])" -MemoryStartupBytes 1024MB -Path $VMPath -VHDPath "$VMPath\$($DCNames2008R2[$i])\Virtual Hard Disks\$($DCNames2008R2[$i]).vhdx" -SwitchName Private-1 | Out-Null
		}
		for ($i = 0; $i -lt $DCNames2012R2.count; $i++)
		{
			new-vm -Name "$($DCNames2012R2[$i])" -MemoryStartupBytes 1024MB -Path $VMPath -VHDPath "$VMPath\$($DCNames2012R2[$i])\Virtual Hard Disks\$($DCNames2012R2[$i]).vhdx" -SwitchName Private-1 -Generation 2 | Out-Null
		}
		for ($i = 0; $i -lt $DCNames2016.count; $i++)
		{
			new-vm -Name "$($DCNames2016[$i])" -MemoryStartupBytes 1024MB -Path $VMPath -VHDPath "$VMPath\$($DCNames2016[$i])\Virtual Hard Disks\$($DCNames2016[$i]).vhdx" -SwitchName Private-1 -Generation 2 | Out-Null
		}
		for ($i = 0; $i -lt $NamesWin7.count; $i++)
		{
			new-vm -Name "$($NamesWin7[$i])" -MemoryStartupBytes 1024MB -Path $VMPath -VHDPath "$VMPath\$($NamesWin7[$i])\Virtual Hard Disks\$($NamesWin7[$i]).vhdx" -SwitchName Private-1 | Out-Null
		}
		for ($i = 0; $i -lt $NamesWin10.count; $i++)
		{
			new-vm -Name "$($NamesWin10[$i])" -MemoryStartupBytes 1024MB -Path $VMPath -VHDPath "$VMPath\$($NamesWin10[$i])\Virtual Hard Disks\$($NamesWin10[$i]).vhdx" -SwitchName Private-1 -Generation 2 | Out-Null
		}
		
		
		## VR ##
		New-VM -Name "ADS-FRVR" -MemoryStartupBytes 1024MB -Path $VMPath -VHDPath "$VMPath\ADS-FRVR\Virtual Hard Disks\ADS-FRVR.vhdx" -SwitchName Private-1 -Generation 2 | Out-Null
		Add-VMNetworkAdapter -VMName "ADS-FRVR" -SwitchName Private-1
		Add-VMNetworkAdapter -VMName "ADS-FRVR" -SwitchName Private-1
		Add-VMNetworkAdapter -VMName "ADS-FRVR" -SwitchName Private-1
		Add-VMNetworkAdapter -VMName "ADS-FRVR" -SwitchName Private-1
		Add-VMNetworkAdapter -VMName "ADS-FRVR" -SwitchName Private-1
		Add-VMNetworkAdapter -VMName "ADS-FRVR" -SwitchName Private-1
		Add-VMNetworkAdapter -VMName "ADS-FRVR" -SwitchName Private-1
		
		### Add setup disk to vms ###
		$VMList = (Get-VM -Name ADS*, SUB*).name
		$coreCount = [system.math]::Floor(((Get-CimInstance -ClassName Win32_Processor).NumberOfLogicalProcessors | Measure-Object -Sum).sum / 3)
		
		foreach ($VM in $VMList)
		{
			Set-VMMemory -VMName $VM -DynamicMemoryEnabled $true -StartupBytes 1024MB
			Set-VMProcessor -VMName $VM -Count $coreCount
		}
		
	} #process
	
	
	
	End
	{
	}
}