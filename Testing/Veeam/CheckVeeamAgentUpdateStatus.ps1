$MinVersionVeeamAgent # Veeam Agent for Microsoft Windows
$VeeamAgentNeedUpdate = $false
$InstalledSoftware = Get-CimInstance -ClassName Win32_Product
$VeeamAgent = $InstalledSoftware.Where{ $PSItem.Name -like "*Veeam Agent*" }

if ($VeeamAgent.Version -lt $MinVersionVeeamAgent)
{
    Write-Output "Info: Veeam Agent for Microsoft Windows - Installierte Version ist niedriger oder nicht installiert"
    $VeeamAgentNeedUpdate = $true
}
else {
    Write-Output "Info: Veeam Agent for Microsoft Windows - Installierte Version ist höher"
}