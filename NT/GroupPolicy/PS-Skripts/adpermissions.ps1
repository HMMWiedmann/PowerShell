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
		# Param1 help description
		[Parameter(Mandatory = $true,
				   ValueFromPipeline = $true,
				   ValueFromPipelineByPropertyName = $true,
				   Position = 0)]
		[ValidateSet("Schema", "Configuration", "Default Naming Context")]
		[System.String]$Searchbase,
		# Param2 help description

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