# Schritt 1: LCM Config Erstellen (LCM-Part.ps1)
# Schritt 2: LCM Config setzen
# Schritt 3: DSC Part Config an den Client Pushen
# Schritt 4: DSC Config anwenden

$ConfigPath = "$($env:SystemDrive)\DSC\Config"
$LCMConfigPath = "$($env:SystemDrive)\DSC\LCMConfig"

# Schritt 1
$DefaultLocation = Get-Location
Set-Location -Path $PSScriptRoot
. .\LCM-Part.ps1

# Schritt 2
Set-DscLocalConfigurationManager -Path $LCMConfigPath -Verbose -Force

# Schritt 3
Publish-DscConfiguration -Path "$ConfigPath\Text1" -ComputerName $env:COMPUTERNAME -Verbose
Publish-DscConfiguration -Path "$ConfigPath\Text2" -ComputerName $env:COMPUTERNAME -Verbose
Publish-DscConfiguration -Path "$ConfigPath\Text3" -ComputerName $env:COMPUTERNAME -Verbose

# Schritt 4
Start-DscConfiguration -UseExisting -Verbose -Wait

Set-Location -Path $DefaultLocation