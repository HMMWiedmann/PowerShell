$InstalledSoftware = Get-CimInstance -ClassName Win32_Product
$KasperskyServer = $InstalledSoftware.Where{ $PSItem.Name -like "Kaspersky Security Center * Administrationsserver" }

if ($null -eq $KasperskyServer) 
{
    Write-Host "Kein Kaspersky Administartionsserver"
}