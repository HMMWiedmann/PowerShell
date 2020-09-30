<#
.Synopsis
   Documents the permissions on AD objects.
.DESCRIPTION
   Documents the permissions on AD objects.
   Works for all three manadtory partitions.
   Each AD object will have a corresponding object for security
   documentation.
.EXAMPLE
   Get-ADPermissions -Searchbase 'Default Naming Context' -Path C:\ADRights
.EXAMPLE
   Get-ADPerm -Searchbase 'Default Naming Context' -Path C:\ADRights
.OUTPUTS
   Text files
.NOTES
   Version 1.0.0 - 08/03/2017 Martin Handl - initial version
#>
function Get-ADPermissions
{
	[CmdletBinding()]
	[Alias("Get-ADPerm")]
	[OutputType([String])]
	Param
	(
		# Naming Context to be documented
		[Parameter(Mandatory = $true,
				   ValueFromPipeline = $true,
				   ValueFromPipelineByPropertyName = $true,
				   Position = 0)]
		[ValidateSet("Schema", "Configuration", "Default Naming Context")]
		[System.String]$Searchbase,
		# Destination path

		[Parameter(Mandatory = $true,
				   ValueFromPipeline = $true,
				   ValueFromPipelineByPropertyName = $true,
				   Position = 1)]
		[System.String]$Path
	)
	
	Begin
	{
		Import-Module -Name ActiveDirectory -ErrorVariable importerror
		if ($importerror -eq $true)
		{
			Write-Host "Module Active Directory not found."; Break
		}
		
		switch ($Searchbase)
		{
			'Schema' { ($Sb = $((Get-ADRootDSE).schemaNamingContext)) }
			'Configuration' { ($Sb = $((Get-ADRootDSE).configurationNamingContext)) }
			'Default Naming Context' { ($Sb = $((Get-ADDomain).DistinguishedName)) }
		}
		
		$ContentPresent = Get-ChildItem -Path $Path
		if (!($ContentPresent -eq $null))
		{
			Write-Host "Zipping present content on $Path."
			Compress-Archive -Path $Path -DestinationPath "$Path\$(get-date -Format HHmmssddMMyy).zip"
			Remove-Item -Path $Path -Include *txt -Recurse
		}
		
	}
	Process
	{
		$ADObjects = Get-ADObject -Filter { objectclass -like "*" } -SearchBase $Sb
		foreach ($Object in $ADObjects)
		{
			$aclobj = Get-Acl "AD:\$($Object.DistinguishedName)"
			(ConvertFrom-SddlString -Sddl $aclobj.Sddl).DiscretionaryAcl.split(":").split(",") | Out-File -FilePath $Path\$($Object.ObjectClass + "." + $Object.Name).txt -Force
		}
	}
	End
	{
	}
}
<#
.SYNOPSIS
		Checks the attribute options of a DC

	.DESCRIPTION
		Checks if the attribute options at the DCs NTDS settings
        is set to any value but 1. If a different value is detected
        will it be reset to 1.

	.EXAMPLE
		Get-ADDomainControllerOptions

	.INPUTS
		System.String

	.OUTPUTS
		System.String

	.NOTES
		Version 1.0.0 - 08/01/2017 - Martin Handl - initial

	.LINK
		about_functions_advanced

	.LINK
		about_comment_based_help

	.LINK
		about_functions_advanced_parameters

	.LINK
		about_functions_advanced_methods
#>
function Get-ADDomainControllerOptions
{
	[CmdletBinding()]
	[OutputType([System.String])]
	Param
	()
	
	Begin
	{
		Import-Module -Name ActiveDirectory -ErrorVariable failed
		if ($failed.count -gt 0)
		{
			Write-Host -ForegroundColor Red -BackgroundColor Black "Module ActiveDirectory not fount on this host!"; Return
		}
		$DCs = (Get-ADDomain).ReplicaDirectoryServers
		foreach ($DC in $DCs)
		{
			$portopen = Test-NetConnection -ComputerName $DC -Port 5985
			if ($portopen.TcpTestSucceeded -eq $false)
			{
				Write-Host "Windows Remote Management not accessible on $DC."
				$exit = Read-Host -Prompt "Do you want to exit (y/n)?"
				if ($exit -eq "yes" -or $exit -eq "y")
				{
					exit
				}
			}
		}
	}
	Process
	{
		foreach ($DC in $DCs)
		{
			$object = Invoke-Command -ComputerName $DC -ScriptBlock {
				(Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\NTDS\Parameters")."Machine DN Name"
			}
			
			$options = (Get-ADObject -Identity $object -Properties options -Server $DC).options
			if (!($options -eq 1))
			{
				Set-ADObject -Identity $object -Replace @{ options = 1 } -Server $DC
				Write-Host "Attribute options on $DC was set to 1."
			}
		}
	}
	End
	{
	}
}
<#
	.SYNOPSIS
		Checks the if GPOs are fully replicated.

	.DESCRIPTION
		Compares the list of GPOs on the PDC-E with the other
        RWDCs in the current domain.

	.EXAMPLE
		Get-GPOReplicationStatus

	.INPUTS
		System.String

	.OUTPUTS
		System.String

	.NOTES
		Version 1.0.0 - 08/01/2017 - Martin Handl - initial

	.LINK
		about_functions_advanced

	.LINK
		about_comment_based_help

	.LINK
		about_functions_advanced_parameters

	.LINK
		about_functions_advanced_methods
#>
function Get-GPOReplicationStatus
{
	[CmdletBinding()]
	[Alias('Get-GPOR')]
	[OutputType([system.string])]
	Param
	()
	
	Begin
	{
		Import-Module -Name GroupPolicy -ErrorVariable failed
		if ($failed.count -gt 0)
		{
			Write-Host -ForegroundColor Red -BackgroundColor Black "Module GroupPolicy not fount on this host!"
		}
	}
	Process
	{
		$PDCE = (Get-ADDomain).PDCEmulator
		$RWDCs = ((Get-ADDomain).ReplicaDirectoryServers).where{ $PSItem -notlike $((Get-ADDomain).PDCEmulator) }
		$PDCEGPO = (Get-GPO -All -Server $PDCE).DisplayName | Sort-Object
		foreach ($DC in $RWDCs)
		{
			Write-Host -ForegroundColor Yellow -BackgroundColor Black "Querying $DC"
			$DCGPO = (Get-GPO -All -Server $DC).DisplayName
			$result = Compare-Object -ReferenceObject $PDCEGPO -DifferenceObject $DCGPO
			if ($($result.Inputobject.count) -eq 1)
			{
				Write-Host -ForegroundColor Red -BackgroundColor Black "Policy $($result.InputObject) is missing on $DC"
			}
			elseif ($($result.Inputobject.count) -gt 1)
				{
					$result.ForEach{ Write-Host -ForegroundColor Red -BackgroundColor Black "Policy $($PSItem.InputObject) is missing on $DC" }
				}
				else
				{
					Write-Host "The domain controller $DC is in sync with the $PDCE concerning group policy objects."
				}
			}
		}
		End
		{
		}
	}
<#
	.SYNOPSIS
		Checks the if GPOs are in sync.

	.DESCRIPTION
		Checks both: user version + computer version of a GPO.
		Sysvol version and DSversion are compared to discover
		errors in the GPO replication process.

	.PARAMETER  GPOName
		this parameter takes a single GPO by it's display name
		to investigate.

	.PARAMETER  All
		this parameter is a switch parameter. Therefore all
		GPOs in this domain will be checked for repliacation
		issues.

	.PARAMETER  DCName
		this parameter is takes a hostname or FQDN of an Domain
        Controller

	.EXAMPLE
		Get-GPOSyncStatus -All -DCName VGPDC-05
		
	.EXAMPLE
		Get-GPOSyncStatus -All -DCName VGPDC-05 -Verbose

	.EXAMPLE
		Get-GPOSyncStatus -GPOName "Default Domain Policy" -DCName VGPDC-05

    .EXAMPLE
		Get-GPOSyncStatus -GPOName "Default Domain Policy" -DCName VGPDC-05 -Verbose

	.INPUTS
		System.String

	.OUTPUTS
		System.String

	.NOTES
		Version 1.0.0 - 03/28/2017 - Martin Handl - initial
        Version 1.0.1 - 08/01/2017 - Martin Handl - Parameter DCName added

	.LINK
		about_functions_advanced

	.LINK
		about_comment_based_help

	.LINK
		about_functions_advanced_parameters

	.LINK
		about_functions_advanced_methods
#>
	function Get-GPOSyncStatus
	{
		[CmdletBinding()]
		param (
			# Switch parameter for all group policies
			[Parameter(Position = 0)]
			[System.String]$GPOName,
			[Parameter(Position = 1)]
			[switch]$All,
			# target DC

			[Parameter(Position = 2, Mandatory = $true)]
			[System.String]$DCName
		)
		begin
		{
			Import-Module -Name GroupPolicy -ErrorVariable failed
			if ($failed.count -gt 0)
			{
				Write-Host -ForegroundColor Red -BackgroundColor Black "Module GroupPolicy not fount on this host!"
			}
		}
		process
		{
			if ($All -eq $true)
			{
				$allGpo = (Get-GPO -All -Server $DCName).DisplayName
				foreach ($gpo in $allGpo)
				{
					$UDSVersion = (Get-GPO -Name $gpo -Server $DCName).User.DSVersion
					$USysVolVersion = (Get-GPO -Name $gpo -Server $DCName).User.SysvolVersion
					$UResult = $UDSVersion -eq $USysVolVersion
					if ($UResult -eq $true)
					{
						Write-Verbose "User portion of policy `"$gpo`" is ok."
					}
					else
					{
						Write-Host -ForegroundColor Yellow -BackgroundColor Black "User portion of policy `"$gpo`" is NOT ok. INVESTIGATE!"
					}
					$CDSVersion = (Get-GPO -Name $gpo -Server $DCName).Computer.DSVersion
					$CSysVolVersion = (Get-GPO -Name $gpo -Server $DCName).Computer.SysvolVersion
					$CResult = $CDSVersion -eq $CSysVolVersion
					if ($CResult -eq $true)
					{
						Write-Verbose "Computer portion of policy `"$gpo`" is ok."
					}
					else
					{
						Write-Host -ForegroundColor Red -BackgroundColor Black "Computer portion of policy `"$gpo`" is NOT ok. INVESTIGATE!"
						Get-GPO -Name $GPO
					}
				}
			}
			else
			{
				$UDSVersion = (Get-GPO -Name $GPOName -Server ((Get-ADDomain).PDCEmulator)).User.DSVersion
				$USysVolVersion = (Get-GPO -Name $GPOName -Server ((Get-ADDomain).PDCEmulator)).User.SysvolVersion
				$UResult = $UDSVersion -eq $USysVolVersion
				if ($UResult -eq $true)
				{
					Write-Verbose "User portion of policy `"$GPOName`" is ok."
				}
				else
				{
					Write-Host -ForegroundColor Yellow -BackgroundColor Black "User portion of policy `"$GPOName`" is NOT ok. INVESTIGATE!"
				}
				$CDSVersion = (Get-GPO -Name $GPOName).Computer.DSVersion
				$CSysVolVersion = (Get-GPO -Name $GPOName).Computer.SysvolVersion
				$CResult = $CDSVersion -eq $CSysVolVersion
				if ($CResult -eq $true)
				{
					Write-Verbose "Computer portion of policy `"$GPOName`" is ok."
				}
				else
				{
					Write-Host -ForegroundColor Red -BackgroundColor Black "Computer portion of policy `"$GPOName`" is NOT ok. INVESTIGATE!"
					Get-GPO -Name $GPOName
				}
			}
		}
		
		end
		{
			
		}
	}
<#
	.SYNOPSIS
		Checks the if GPOs are fully replicated.

	.DESCRIPTION
		Compares the list of GPOs on the PDC-E with the other
        RWDCs in the current domain.

	.EXAMPLE
		Get-GPOReplicationStatus

	.INPUTS
		System.String

	.OUTPUTS
		System.String

	.NOTES
		Version 1.0.0 - 08/01/2017 - Martin Handl - initial

	.LINK
		about_functions_advanced

	.LINK
		about_comment_based_help

	.LINK
		about_functions_advanced_parameters

	.LINK
		about_functions_advanced_methods
#>
	function Get-SysvolReplicationStatus
	{
		[CmdletBinding()]
		Param
		()
		$RWDCs = (Get-ADDomain).ReplicaDirectoryServers
		$RWDCs = $RWDCs.replace(".$((Get-ADDomain).DNSRoot)", "")
		foreach ($DC in $RWDCs)
		{
			$msDFSR = (Get-ADObject -Identity "CN=SYSVOL Subscription,CN=Domain System Volume,CN=DFSR-LocalSettings,CN=$DC,$((Get-ADDomain).DomainControllersContainer)" -Properties msDFSR-Enabled).'msDFSR-Enabled'
			if ($msDFSR -eq $True)
			{
				Write-Verbose "msDFSR-Enabled is set to $msDFSR"
			}
			else
			{
				$MetaData = ((Get-ADReplicationAttributeMetadata `
																 -Object "CN=SYSVOL Subscription,CN=Domain System Volume,CN=DFSR-LocalSettings,CN=$DC,$((Get-ADDomain).DomainControllersContainer)" `
																 -Server $DC).where{ $PSItem.Attributename -eq "msDFSR-Enabled" })
				Write-Host -ForegroundColor White -BackgroundColor Black "+----------------------------------------------------------------------------------------------------+"
				Write-Host -ForegroundColor Red -BackgroundColor Black "msDFSR-Enabled on the domain controller $DC is set to $msDFSR!"
				Write-Host -ForegroundColor Yellow -BackgroundColor Black "msDFSR-Enabled was set to $msDFSR at $($MetaData.LastOriginatingChangeTime) on $($MetaData.Server)"
				Write-Host -ForegroundColor Red -BackgroundColor Black "Sysvol replication is not functional!"
				Write-Host -ForegroundColor White -BackgroundColor Black "+----------------------------------------------------------------------------------------------------+"
				[ValidateSet("yes", "y", "no", "n")]$FixIt = Read-Host -Prompt "Do you want to fix it (y/n)?"
				if ($FixIt -eq "yes" -or $FixIt -eq "y")
				{
					Set-ADObject `
								 -Identity "CN=SYSVOL Subscription,CN=Domain System Volume,CN=DFSR-LocalSettings,CN=$DC,$((Get-ADDomain).DomainControllersContainer)" `
								 -Replace @{ "msDFSR-Enabled" = $True } `
								 -Server $DC
					Write-Output "msDFSR-Enabled was set to True on $DC"
				}
			}
		}
	}
<#
.Synopsis
   Fetches all group poplicy events with an
   activityID from the log.
.DESCRIPTION
   Fetches all group poplicy events with an
   activityID from the log. Two views are possible:
   normal and detailed.
.EXAMPLE
   Get-GPOActivityID -Computername host4711 -Detailed
.EXAMPLE
   Get-GPOActID -Server host4711
.NOTES
   Version 1.0.1 - 08/04/2017 Martin Handl - initial
#>
	function Get-GPOActivityID
	{
		[CmdletBinding(SupportsShouldProcess = $true)]
		[Alias("Get-GPOActID")]
		[OutputType([System.String])]
		Param
		(
			# hostname of target system
			[Parameter(Mandatory = $true,
					   ValueFromPipeline = $true,
					   ValueFromPipelineByPropertyName = $true,
					   Position = 0)]
			[ValidateNotNull()]
			[ValidateNotNullOrEmpty()]
			[Alias("server")]
			$Computername,
			# detailed view of events

			[Parameter(Mandatory = $false,
					   Position = 1)]
			[Alias("computer")]
			[switch]$Detailed
		)
		
		Begin
		{
			$PortOpen = Test-NetConnection -ComputerName $Computername -Port 135
			do
			{
				Write-Host -ForegroundColor Yellow -BackgroundColor Black "Probing RCP port - please wait."
			}
			until (!($PortOpen -eq $null))
			
			if ($PortOpen.TcpTestSucceeded -eq $false)
			{
				Write-Host -ForegroundColor Yellow -BackgroundColor Black "Computer not found or RPC-Port is not accessible."
				Write-Host -ForegroundColor Yellow -BackgroundColor Black "Terminating script."
				Break
			}
			else { }
			
		}
		Process
		{
			$uniqueGUIDs = ((Get-WinEvent `
										  -ComputerName $Computername `
										  -LogName 'Microsoft-Windows-GroupPolicy/Operational').where{ $PSItem.ActivityID -like "*" } `
				| Select-Object -ExpandProperty ActivityID -Unique).GUID
			Write-Host "Found $($uniqueGUIDs.LongLength) unique activityIDs on computer $Computername."
			
			switch ($detailed)
			{
				'True' {
					foreach ($GUID in $uniqueGUIDs)
					{
						Write-Host "`n`n+-------------------------------------------------------+"
						Write-Host "End of ActivityID $GUID"
						Write-Host "+-------------------------------------------------------+"
						Get-WinEvent `
									 -ComputerName $Computername `
									 -FilterXPath "*[System/Correlation/@ActivityID='{$GUID}']" `
									 -LogName 'Microsoft-Windows-GroupPolicy/Operational'
						Write-Host "+-------------------------------------------------------+"
						Write-Host "Start of ActivityID $GUID"
						Write-Host "+-------------------------------------------------------+"
					}
				}
				Default
				{
					foreach ($GUID in $uniqueGUIDs)
					{
						$actevents = Get-WinEvent `
												  -ComputerName $Computername `
												  -FilterXPath "*[System/Correlation/@ActivityID='{$GUID}']" `
												  -LogName 'Microsoft-Windows-GroupPolicy/Operational'
						Write-Host "`n+-------------------------------------------------------------------------------------------------------------+"
						Write-Host "ActivityID $GUID startet on $($actevents[-1].TimeCreated) local time with the eventID $($actevents[-1].Id)"
						Write-Host "ActivityID $GUID endet on   $($actevents[0].TimeCreated) local time with the eventID $($actevents[0].Id)"
						Write-Host "+>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> This took $([system.math]::Round(($actevents[0].TimeCreated - $actevents[-1].TimeCreated).TotalMilliseconds, 2)) milliseconds. <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<+"
						Write-Host "+-------------------------------------------------------------------------------------------------------------+`n"
					}
				}
			}
		}
		End
		{
		}
	}
<#
.Synopsis
   Checks the Eventlog "Group Policy/Operational" for fatal errors.
.DESCRIPTION
   Checks the Eventlog "Group Policy/Operational" for fatal errors.
   Based on the activityID the whole process till the error will be
   displayed.
.EXAMPLE
   Get-GPFatalError -Computername Host4711
.EXAMPLE
   Get-GPFE -Computer Host4711
.NOTES
   Version 1.0.0 - 08/03/2017 Martin Handl - initial
#>
	function Get-GPFatalError
	{
		[CmdletBinding(SupportsShouldProcess = $true)]
		[Alias("Get-GPFE")]
		Param
		(
			# name of the target computer
			[Parameter(Mandatory = $true,
					   ValueFromPipeline = $true,
					   ValueFromPipelineByPropertyName = $true,
					   ValueFromRemainingArguments = $false,
					   Position = 0)]
			[Alias("Computer")]
			$Computername
		)
		
		Begin
		{
			$PortOpen = Test-NetConnection -ComputerName $Computername -Port 135
			do
			{
				Write-Host -ForegroundColor Yellow -BackgroundColor Black "Probing RCP port - please wait."
			}
			until (!($PortOpen -eq $null))
			
			if ($PortOpen.TcpTestSucceeded -eq $false)
			{
				Write-Host -ForegroundColor Yellow -BackgroundColor Black "Computer not found or RPC-Port is not accessible."
				Write-Host -ForegroundColor Yellow -BackgroundColor Black "Terminating script."
				Break
			}
			else { }
		}
		Process
		{
			$errorIDs = Get-WinEvent `
									 -ComputerName $Computername `
									 -FilterXPath "*[System[Provider[@Name='Microsoft-Windows-GroupPolicy'] and (EventID=7017)]]" `
									 -LogName 'Microsoft-Windows-GroupPolicy/Operational' `
									 -ErrorAction SilentlyContinue
			
			$actIDs = (Get-WinEvent `
									-ComputerName $Computername `
									-FilterXPath "*[System[Provider[@Name='Microsoft-Windows-GroupPolicy'] and (EventID=7017)]]" `
									-LogName 'Microsoft-Windows-GroupPolicy/Operational' `
									-ErrorAction SilentlyContinue).Activityid.guid
			
			if (!($errorIDs -eq $null))
			{
				if ($actIDs.LongLength -gt 0)
				{
					Write-Host "$($actIDs.LongLength) ActivityIDs has been found."
					for ($Event = 0; $Event -lt $actIDs.LongLength; $Event++)
					{
						Write-Host "Created on: $(($errorIDs[$Event]).TimeCreated) with the ActivityID: $($actIDs[$Event]) ++>>++ number $Event"
					}
					
					$number = Read-Host -Prompt "Which to investigate?"
					$result = Get-WinEvent `
										   -ComputerName $Computername `
										   -FilterXPath "*[System/Correlation/@ActivityID='{$($actIDs[$number])}']" `
										   -LogName 'Microsoft-Windows-GroupPolicy/Operational'
					$result | Out-GridView
				}
				else
				{
					Write-Host "Just one activityID has been found."
					Write-Host "Created on $($errorIDs.TimeCreated) with the ActivityID: $($actIDs) "
					$result = Get-WinEvent `
										   -ComputerName $Computername `
										   -FilterXPath "*[System/Correlation/@ActivityID='{$actIDs}']" `
										   -LogName 'Microsoft-Windows-GroupPolicy/Operational'
					$result | Out-GridView
				}
			}
			else
			{
				
				Write-Host "`n`n+-------------------- Lucky you! --------------------+"
				Write-Host "`nNo fatal group policy event was detected on $Computername!"
				Write-Host "`nGroup policy does seem to work fine on $Computername!"
				Write-Host "+----------------- Enjoy your day. ------------------+"
				
			}
		}
		End
		{
		}
	}