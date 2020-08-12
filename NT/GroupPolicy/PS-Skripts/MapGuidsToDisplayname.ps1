<#
.SYNOPSIS

.DESCRIPTION

.PARAMETER rootdir

.EXAMPLE

#>

param(
    [parameter(Mandatory=$true)]
    [String]$rootdir
    )

    $results = @{}
    Get-ChildItem -Recurse -Include backup.xml $rootdir | ForEach-Object{
        $guid = $PSItem.Directory.Name
        $x = [xml](Get-Content $PSItem)
        $dn = $x.GroupPolicyBackupScheme.GroupPolicyObject.GroupPolicyCoreSettings.DisplayName.InnerText
        # $dn + "`t" + $guid
        $results.Add($dn, $guid)
    }
$results | Format-Table Name, Value -AutoSize