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