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
		[Parameter(Position = 0)]
		[System.String]$GPOName,
		[Parameter(Position = 1)]
		[switch]$All,
		[Parameter(Position = 2,Mandatory = $true)]
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