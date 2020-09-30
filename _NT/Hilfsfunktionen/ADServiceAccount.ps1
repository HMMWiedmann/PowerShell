# Get-ADServiceAccount -Filter * | Remove-ADServiceAccount

Add-KdsRootKey -EffectiveTime (Get-Date).AddHours(-10)

$SQLAgentName   = "T1-SQLAgent"
$SQLEngineName  = "T1-SQLEngine"
$SQLServerGroup = "T1-SQLServers"

New-ADServiceAccount -Name $SQLAgentName -PrincipalsAllowedToRetrieveManagedPassword $SQLServerGroup -DNSHostName ($SQLAgentName + "." + $env:USERDNSDOMAIN) -ManagedPasswordIntervalInDays 30 -Server (Get-ADDomain).PDCEmulator
New-ADServiceAccount -Name $SQLEngineName -PrincipalsAllowedToRetrieveManagedPassword $SQLServerGroup -DNSHostName ($SQLEngineName + "." + $env:USERDNSDOMAIN) -ManagedPasswordIntervalInDays 30 -Server (Get-ADDomain).PDCEmulator

$state = (Get-WindowsFeature -Name RSAT-AD-Powershell).Installstate

if ($state -ne "Installed") 
{
    Install-WindowsFeature -Name RSAT-AD-Powershell
    
    Install-ADServiceAccount -Identity $SQLAgentName -Force
    Install-ADServiceAccount -Identity $SQLEngineName -Force

    Test-ADServiceAccount -Identity $SQLAgentName
    Test-ADServiceAccount -Identity $SQLEngineName
}
else 
{
    Install-ADServiceAccount -Identity $SQLAgentName -Force
    Install-ADServiceAccount -Identity $SQLEngineName -Force

    Test-ADServiceAccount -Identity $SQLAgentName
    Test-ADServiceAccount -Identity $SQLEngineName
}