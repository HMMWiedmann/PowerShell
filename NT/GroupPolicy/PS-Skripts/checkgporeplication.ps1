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
			else
			{
				$result.ForEach{ Write-Host -ForegroundColor Red -BackgroundColor Black "Policy $($PSItem.InputObject) is missing on $DC" }
			}
		}
	}
	End
	{
	}
}
