<#
	.SYNOPSIS
		Checks the if GPOs are fully replicated.

	.DESCRIPTION
		Compares the list of GPOs on the PDC-E with the other
        RWDCs in the current domain.

	.EXAMPLE
		Get-SysvolReplicationStatus

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
$RWDCs = $RWDCs.replace(".$((Get-ADDomain).DNSRoot)","")
foreach ($DC in $RWDCs)
{
    $msDFSR = (Get-ADObject -Identity "CN=SYSVOL Subscription,CN=Domain System Volume,CN=DFSR-LocalSettings,CN=$DC,$((Get-ADDomain).DomainControllersContainer)" -Properties msDFSR-Enabled).'msDFSR-Enabled'
    if ($msDFSR -eq $True)
    {
        Write-Verbose "msDFSR-Enabled is set to $msDFSR"
    } else {
        $MetaData = ((Get-ADReplicationAttributeMetadata `        -Object "CN=SYSVOL Subscription,CN=Domain System Volume,CN=DFSR-LocalSettings,CN=$DC,$((Get-ADDomain).DomainControllersContainer)" `        -Server $DC).where{ $PSItem.Attributename -eq "msDFSR-Enabled"})
        Write-Host -ForegroundColor White -BackgroundColor Black "+----------------------------------------------------------------------------------------------------+"
        Write-Host -ForegroundColor Red -BackgroundColor Black "msDFSR-Enabled on the domain controller $DC is set to $msDFSR!"
        Write-Host -ForegroundColor Yellow -BackgroundColor Black "msDFSR-Enabled was set to $msDFSR at $($MetaData.LastOriginatingChangeTime) on $($MetaData.Server)"
        Write-Host -ForegroundColor Red -BackgroundColor Black "Sysvol replication is not functional!"
        Write-Host -ForegroundColor White -BackgroundColor Black "+----------------------------------------------------------------------------------------------------+"
        [ValidateSet("yes","y","no","n")]$FixIt = Read-Host -Prompt "Do you want to fix it (y/n)?"
        if ($FixIt -eq "yes" -or $FixIt -eq "y")
        {
            Set-ADObject `            -Identity "CN=SYSVOL Subscription,CN=Domain System Volume,CN=DFSR-LocalSettings,CN=$DC,$((Get-ADDomain).DomainControllersContainer)" `            -Replace @{ "msDFSR-Enabled"=$True } `            -Server $DC
            Write-Output "msDFSR-Enabled was set to True on $DC"
        }
    }
}
}