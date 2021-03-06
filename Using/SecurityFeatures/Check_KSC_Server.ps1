<#  AMP Input: 
    $MinKSAllowedVersion
    $MinAgentVersion

    AMP Output:
    $ErrorCount
#>

[int]$ErrorCount = 0

$KSC_Server_Service = Get-Service -Name "Kaspersky Security Service" -ErrorAction SilentlyContinue
$KSC_Agent_Service = Get-Service -Name "klnagent" -ErrorAction SilentlyContinue

if ($KSC_Server_Service) 
{
    # Kaspersky Security Service Versionscheck
    $KSC_Service_EXEPath = ((Get-WmiObject -Class Win32_Service).where{ $PSItem.Name -EQ $KSC_Server_Service.Name}).PathName
    $KSC_Server_Version = (Get-ItemProperty -Path $KSC_Service_EXEPath.replace('"',"")).VersionInfo
    
    $KSSInstalledVersionArray = $KSC_Server_Version.FileVersion.Split(".")
    $KSSRequiredVersionArray = $MinKSAllowedVersion.Split(".")

    if ([int]$KSSInstalledVersionArray[0] -ge [int]$KSSRequiredVersionArray[0])
    {
        if ([int]$KSSInstalledVersionArray[1] -ge [int]$KSSRequiredVersionArray[1])
        {
            if ([int]$KSSInstalledVersionArray[2] -ge [int]$KSSRequiredVersionArray[2])
            {
                if ([int]$KSSInstalledVersionArray[3] -ge [int]$KSSRequiredVersionArray[3])
                {
    
                }
                else { Write-Host "Die KSC_Server_Version ist alt und nicht aktuell.`nGeforderte Verion: $MinKSAllowedVersion"; $ErrorCount++ }
            }
            else { Write-Host "Die KSC_Server_Version ist alt und nicht aktuell.`nGeforderte Verion: $MinKSAllowedVersion"; $ErrorCount++ }
        }
        else { Write-Host "Die KSC_Server_Version ist alt und nicht aktuell.`nGeforderte Verion: $MinKSAllowedVersion"; $ErrorCount++ }
    }
    else { Write-Host "Die KSC_Server_Version ist alt und nicht aktuell.`nGeforderte Verion: $MinKSAllowedVersion"; $ErrorCount++ }

    # Kaspersky Agent Versionscheck
    $KSC_Agent_EXEPath = ((Get-WmiObject -Class Win32_Service).where{ $PSItem.Name -EQ $KSC_Agent_Service.Name}).PathName
    $KSC_Agent_Version = (Get-ItemProperty -Path $KSC_Agent_EXEPath.replace('"',"")).VersionInfo

    $AgentInstalledVersionArray = $KSC_Agent_Version.FileVersion.Split(".")
    $AgentRequiredVersionArray = $MinAgentVersion.Split(".")

    if ([int]$AgentInstalledVersionArray[0] -ge [int]$AgentRequiredVersionArray[0])
    {
        if ([int]$AgentInstalledVersionArray[1] -ge [int]$AgentRequiredVersionArray[1])
        {
            if ([int]$AgentInstalledVersionArray[2] -ge [int]$AgentRequiredVersionArray[2])
            {
                if ([int]$AgentInstalledVersionArray[3] -ge [int]$AgentRequiredVersionArray[3])
                {
    
                }
                else { Write-Host "Die KSC_Agent_Version ist alt und nicht aktuell.`nGeforderte Verion: $MinAgentVersion"; $ErrorCount++ }
            }
            else { Write-Host "Die KSC_Agent_Version ist alt und nicht aktuell.`nGeforderte Verion: $MinAgentVersion"; $ErrorCount++ }
        }
        else { Write-Host "Die KSC_Agent_Version ist alt und nicht aktuell.`nGeforderte Verion: $MinAgentVersion"; $ErrorCount++ }
    }
    else { Write-Host "Die KSC_Agent_Version ist alt und nicht aktuell.`nGeforderte Verion: $MinAgentVersion"; $ErrorCount++ }

    if ($ErrorCount -gt 0) 
    {
        Write-Host ""
        Write-Host ""
    }
    Write-Host "Server-Name    : $($KSC_Server_Version.ProductName)"
    Write-Host "Server-Version : $($KSC_Server_Version.FileVersion)"
    Write-Host "Agent-Name     : $($KSC_Agent_Version.FileDescription)"
    Write-Host "Agent-Version  : $($KSC_Agent_Version.FileVersion)"
    Write-Host ""
    Write-Host ""
}
else
{
    Write-Host "Der Service Kaspersky Security Service wurde nicht gefunden"
    Write-Host ""
    Write-Host ""
    $ErrorCount++
}