# Exchange 
Add-PSSnapin *exchange* -ErrorAction SilentlyContinue
$CheckExchangeSnapin = Get-PSSnapin *exchange* -ea 0
if ($CheckExchangeSnapin) 
{ 
    if (Get-ExchangeServer){$ExchangeServer = $true}
}

# Veeam
# Backup & Replication
# Agent

# Windows Features
$InstalledFeatures = Get-WindowsFeature | Where-Object -Property installed
$CheckFeaturesList = "ADCS-Cert-Authority,AD-Domain-Services,ADFS-Federation,DHCP,DNS,FS-FileServer,Hyper-V,Routing,Web-Server,WDS,UpdateServices"
$Features = $CheckFeaturesList.Split(",")

# Kaskersky Admin Server
$InstalledSoftware = Get-CimInstance -ClassName Win32_Product
$KasperskyServer = $InstalledSoftware.Where{ $PSItem.Name -like "Kaspersky Security Center * Administrationsserver" }

# SQL Server


# Ausgabe
Write-Host "Gefunde Services:"
if ($ExchangeServer)  { Write-Host "  Exchange Server" }
if ($KasperskyServer) { Write-Host "  Kaspersky Admin Server" }

Write-Host "`n`n"
Write-Host "Installed Features are:"
foreach($Feature in $Features)
{
    if ($InstalledFeatures.Name -contains $Feature){Write-Host " $Feature"}
}