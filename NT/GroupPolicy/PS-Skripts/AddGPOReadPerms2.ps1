$allGPOs = get-gpo -all
foreach ($gpo in $allGPOs)
{
# first read the GPO permissions to find out if Authn Users and Domain Computers is missing
$perm1 = Get-GPPermissions -Guid $gpo.id -TargetName “Authenticated Users” -TargetType group -ErrorAction SilentlyContinue
$perm2 = Get-GPPermissions -Guid $gpo.id -TargetName (Get-ADGroup “$((Get-ADDomain).DomainSID)-515”).Name -TargetType group -ErrorAction SilentlyContinue
if ($perm1 -eq $null -and $perm2 -eq $null) # if no authn users or domain computers is found, then add Authn Users read perm
{
Set-GPPermissions -Guid $gpo.Id -PermissionLevel GpoRead -TargetName “Authenticated Users” -TargetType Group
Write-Host $gpo.DisplayName “has been modified to grant Authenticated Users read access”
}
}