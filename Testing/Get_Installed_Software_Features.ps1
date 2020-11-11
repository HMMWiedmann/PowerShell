# Windows Features
$InstalledFeatures = Get-WindowsFeature | Where-Object -Property installed

$CheckFeaturesList = "ADCS-Cert-Authority,AD-Domain-Services,ADFS-Federation,DHCP,DNS,FS-FileServer,Hyper-V,Routing,Web-Server,WDS,UpdateServices"
$Features = $CheckFeaturesList.Split(",")
Write-Host "Installed Features are:"
foreach($Feature in $Features)
{
    if ($InstalledFeatures.Name -contains $Feature){Write-Host " $Feature"}
}

# Kaspersky Admin Server
$InstalledSoftware = Get-CimInstance -ClassName Win32_Product
$KasperskyServer = $InstalledSoftware.Where{ $PSItem.Name -like "Kaspersky Security Center * Administrationsserver" }

if ($null -eq $KasperskyServer) 
{
    Write-Host "Kein Kaspersky Administartionsserver"
}

# SQL Server