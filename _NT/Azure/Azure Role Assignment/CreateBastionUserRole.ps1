
$myRole = Get-AzRoleDefinition -Name "Owner"

$myRole.Id = $null 
$myRole.Actions.RemoveRange(0,$myRole.Actions.Count)
$myRole.AssignableScopes.Clear()
$myRole.IsCustom = $true

$myRole.Name = "Bastion User"
$myRole.Description = "Can access virtual machines through the corresponding Azure Bastion."


$myRole.Actions.Add("Microsoft.Compute/virtualMachines/*/read")
$myRole.Actions.Add("Microsoft.Network/networkInterfaces/*/read")
$myRole.Actions.Add("Microsoft.Network/bastionHosts/*/read")

$myRole.AssignableScopes.Add("/subscriptions/62fc591f-f014-46df-9ef8-27aeaf9705f5")


New-AzRoleDefinition -Role $myRole

New-AzRoleAssignment -RoleDefinitionName "Bastion User" -SignInName "DJaegle@azure-hybrid.de" `
 -Scope "/subscriptions/62fc591f-f014-46df-9ef8-27aeaf9705f5"