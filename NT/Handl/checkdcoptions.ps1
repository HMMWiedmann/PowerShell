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
    foreach ($DC in $DCs)     {        $object = Invoke-Command -ComputerName $DC -ScriptBlock {        (Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\NTDS\Parameters")."Machine DN Name"}        $options = (Get-ADObject -Identity $object -Properties options -Server $DC).options            if (!($options -eq 1))            {                Set-ADObject -Identity $object -Replace @{ options = 1} -Server $DC                Write-Host "Attribute options on $DC was set to 1."            }    }
    }
    End
    {
    }
}