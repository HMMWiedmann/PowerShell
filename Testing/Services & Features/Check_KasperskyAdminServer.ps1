$InstalledSoftware = Get-WmiObject -Class Win32_Product
$KasperskyServer = $InstalledSoftware.Where{ $PSItem.Name -like "Kaspersky Security Center * Administrationsserver" }

if ($KasperskyServer) 
{
    "Caption: $($KasperskyServer.Caption)"
    "Version: $($KasperskyServer.Version)"
    Exit 0
}
else
{
    $false
    Exit 1001
}