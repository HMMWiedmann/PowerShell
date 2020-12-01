<#  AMP Input: 
    $MinKESAllowedVersion
    $MinAgentVersion

    AMP Output:
    $ErrorCount
#>

[int]$ErrorCount = 0

$KSC_Client_Service = Get-Service -Name "Kaspersky Endpoint Security Service" -ErrorAction SilentlyContinue
$KSC_Agent_Service = Get-Service -Name "klnagent" -ErrorAction SilentlyContinue

if ($KSC_Client_Service) 
{
    $KSC_Service_EXEPath = ((Get-WmiObject -Class Win32_Service).where{ $PSItem.Name -EQ $KSC_Client_Service.Name}).PathName
    $KSC_Client_Version = (Get-ItemProperty -Path $KSC_Service_EXEPath.Split('"')[1]).VersionInfo

    $KESInstalledVersionArray = $KSC_Client_Version.FileVersion.Split(".")
    $KESRequiredVersionArray = $MinKESAllowedVersion.Split(".")

    if ([int]$KESInstalledVersionArray[0] -lt [int]$KESRequiredVersionArray[0].Replace('*',0))
    {
        if ([int]$KESInstalledVersionArray[1] -lt [int]$KESRequiredVersionArray[1].Replace('*',0))
        {
            if ([int]$KESInstalledVersionArray[2] -lt [int]$KESRequiredVersionArray[2].Replace('*',0))
            {
                if ([int]$KESInstalledVersionArray[3] -lt [int]$KESRequiredVersionArray[3].Replace('*',0))
                {
    
                }
                else { Write-Host "Die KSC_Client_Version ist alt und nicht aktuell.`nGeforderte Verion: $MinKESAllowedVersion"; $ErrorCount++ }
            }
            else { Write-Host "Die KSC_Client_Version ist alt und nicht aktuell.`nGeforderte Verion: $MinKESAllowedVersion"; $ErrorCount++ }
        }
        else { Write-Host "Die KSC_Client_Version ist alt und nicht aktuell.`nGeforderte Verion: $MinKESAllowedVersion"; $ErrorCount++ }
    }
    else { Write-Host "Die KSC_Client_Version ist alt und nicht aktuell.`nGeforderte Verion: $MinKESAllowedVersion"; $ErrorCount++ }

    if ($KSC_Client_Version.FileVersion -lt $MinKESAllowedVersion) 
    {
        Write-Host "Die installierte Version ist zu niedrig."
        $ErrorCount++
    }

    $KSC_Agent_EXEPath = ((Get-WmiObject -Class Win32_Service).where{ $PSItem.Name -EQ $KSC_Agent_Service.Name}).PathName
    $KSC_Agent_Version = (Get-ItemProperty -Path $KSC_Agent_EXEPath.replace('"',"")).VersionInfo

    $AgentInstalledVersionArray = $KSC_Agent_Version.FileVersion.Split(".")
    $AgentRequiredVersionArray = $MinAgentVersion.Split(".")

    if ([int]$AgentInstalledVersionArray[0] -lt [int]$AgentRequiredVersionArray[0].Replace('*',0))
    {
        if ([int]$AgentInstalledVersionArray[1] -lt [int]$AgentRequiredVersionArray[1].Replace('*',0))
        {
            if ([int]$AgentInstalledVersionArray[2] -lt [int]$AgentRequiredVersionArray[2].Replace('*',0))
            {
                if ([int]$AgentInstalledVersionArray[3] -lt [int]$AgentRequiredVersionArray[3].Replace('*',0))
                {
    
                }
                else { Write-Host "Die KSC_Agent_Version ist alt und nicht aktuell.`nGeforderte Verion: $MinAgentVersion"; $ErrorCount++ }
            }
            else { Write-Host "Die KSC_Agent_Version ist alt und nicht aktuell.`nGeforderte Verion: $MinAgentVersion"; $ErrorCount++ }
        }
        else { Write-Host "Die KSC_Agent_Version ist alt und nicht aktuell.`nGeforderte Verion: $MinAgentVersion"; $ErrorCount++ }
    }
    else { Write-Host "Die KSC_Agent_Version ist alt und nicht aktuell.`nGeforderte Verion: $MinAgentVersion"; $ErrorCount++ }

    $AntiVirusProduct = (Get-CimInstance -Namespace root/SecurityCenter2 -ClassName AntiVirusProduct) | Where-Object -Property Displayname -Like "*Kaspersky*"
    switch ($AntiVirusProduct.productState)
    {
        "262144" {$defstatus = "Up to date" ;$rtstatus = "Disabled"}
        "262160" {$defstatus = "Out of date" ;$rtstatus = "Disabled"}
        "266240" {$defstatus = "Up to date" ;$rtstatus = "Enabled"}
        "266256" {$defstatus = "Out of date" ;$rtstatus = "Enabled"}
        "393216" {$defstatus = "Up to date" ;$rtstatus = "Disabled"}
        "393232" {$defstatus = "Out of date" ;$rtstatus = "Disabled"}
        "393488" {$defstatus = "Out of date" ;$rtstatus = "Disabled"}
        "397312" {$defstatus = "Up to date" ;$rtstatus = "Enabled"}
        "397328" {$defstatus = "Out of date" ;$rtstatus = "Enabled"}
        "397584" {$defstatus = "Out of date" ;$rtstatus = "Enabled"}
        default {$defstatus = "Unknown" ;$rtstatus = "Unknown"}
    }

    if ($defstatus -ne "Up to date" -or $rtstatus -ne "Enabled") 
    {
        Write-Host "Die Definitionsdatenbank ist nicht aktuell."
        $ErrorCount++
    }
    if ($KSC_Agent_Version.FileVersion -lt $MinAgentVersion) 
    {
        Write-Host "Die KSC_Agent_Version ist alt und nicht aktuell.`n"
        $ErrorCount++
    }
    if ($ErrorCount -gt 0) 
    {
        Write-Host ""
        Write-Host ""
    }

    Write-Host "KES-Name      : $($KSC_Client_Version.ProductName)"
    Write-Host "KES-Version   : $($KSC_Client_Version.FileVersion)"
    Write-Host "Def. Status   : $($defstatus)"
    Write-Host "Protection    : $($rtstatus)"
    Write-Host "Agent-Name    : $($KSC_Agent_Version.FileDescription)"
    Write-Host "Agent-Version : $($KSC_Agent_Version.FileVersion)"
    Write-Host ""
    Write-Host ""
}
else
{
    Write-Host "Es wurde keine KES Version gefunden"
    Write-Host ""
    Write-Host ""
    $ErrorCount++
}