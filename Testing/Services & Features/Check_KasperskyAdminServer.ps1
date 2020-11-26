$InstalledSoftware = Get-WmiObject -Class Win32_Product
$KasperskyServer = $InstalledSoftware.Where{ $PSItem.Name -like "Kaspersky Security Center * Administrationsserver" }

if ($KasperskyServer) 
{
    if ($KasperskyServer.Version -lt "12.*.*.*") 
    {
        Write-Host "Die Kasperskyversion ist zu alt."
        "Caption: $($KasperskyServer.Caption)"
        "Version: $($KasperskyServer.Version)"
        Exit 1001
    }
    else 
    {
        "Caption: $($KasperskyServer.Caption)"
        "Version: $($KasperskyServer.Version)"
        Exit 0
    }
}
else
{
    $false
    Exit 1001
}