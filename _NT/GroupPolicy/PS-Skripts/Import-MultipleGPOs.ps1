<#	
	.NOTES
	===========================================================================
	 Created on:   	27.02.2017
	 Created by:   	R.Merdian
	 Organization: 	NT Systems
	 Filename:     	Import-MultipleGPOs.ps1
	 Version:       2.0.0.1
	 Modified:      23.08.2017
	===========================================================================
	.DESCRIPTION 
		!! This script overwrites all existing policies. !!  
		Imports all policies in a specific folder.

#>
[CmdletBinding()]
param
(
	[Parameter(Mandatory = $true)]
	[string]$GPOPath
)

# Leere Table wird erzeugt
$GPOPSobj = @()
# GuIDs
Get-ChildItem -Recurse -Include backup.xml $GPOPath | ForEach-Object {
    $Guid = $PSItem.Directory.Name
    $XML = [xml](Get-Content $PSItem)
    $PolicyName = $XML.GroupPolicyBackupScheme.GroupPolicyObject.GroupPolicyCoreSettings.DisplayName.InnerText
    $ExportItem = New-Object PSObject
    $ExportItem | Add-Member -MemberType NoteProperty -name "Name" -value $PolicyName
    $ExportItem | Add-Member -MemberType NoteProperty -name "GuID" -value $Guid
    $GPOPSobj += $ExportItem
}

# GPOs werden importiert
$GPOPSobj.ForEach{Import-GPO -BackupId $PSItem.GuID -TargetName $PSItem.Name -path $GPOPath -CreateIfNeeded | Select-Object DisplayName}