<#  AMP Input: 
    $MinAgentVersion

    AMP Output:
    $ErrorCount
#>

[int]$ErrorCount = 0

$Veeam_BR_Service = Get-Service -Name "VeeamBackupSvc" -ErrorAction SilentlyContinue

if ($Veeam_BR_Service) 
{
    Add-PSSnapin -Name VeeamPSSnapIn -ErrorAction SilentlyContinue

    $Veeam_BR_Service_EXEPath = ((Get-WmiObject -Class Win32_Service).where{ $PSItem.Name -EQ $Veeam_BR_Service.Name}).PathName
    $Veeam_BR_Service_Version = (Get-ItemProperty -Path $Veeam_BR_Service_EXEPath.replace('"',"")).VersionInfo

    $InstalledVersionArray = $Veeam_BR_Service_Version.FileVersion.Split(".")
    $RequiredVersionArray = $MinAgentVersion.Split(".")

    if ([int]$InstalledVersionArray[0] -lt [int]$RequiredVersionArray[0].Replace('*',0))
    {
        if ([int]$InstalledVersionArray[1] -lt [int]$RequiredVersionArray[1].Replace('*',0))
        {
            if ([int]$InstalledVersionArray[2] -lt [int]$RequiredVersionArray[2].Replace('*',0))
            {
                if ([int]$InstalledVersionArray[3] -lt [int]$RequiredVersionArray[3].Replace('*',0))
                {
    
                }
                else { Write-Host "Die Veeam Backup & Replication Version ist alt und nicht aktuell.`nGeforderte Verion: $MinAgentVersion"; $ErrorCount++ }
            }
            else { Write-Host "Die Veeam Backup & Replication Version ist alt und nicht aktuell.`nGeforderte Verion: $MinAgentVersion"; $ErrorCount++ }
        }
        else { Write-Host "Die Veeam Backup & Replication Version ist alt und nicht aktuell.`nGeforderte Verion: $MinAgentVersion"; $ErrorCount++ }
    }
    else { Write-Host "Die Veeam Backup & Replication Version ist alt und nicht aktuell.`nGeforderte Verion: $MinAgentVersion"; $ErrorCount++ }

    if ($ErrorCount -gt 0) 
    {
        Write-Host ""
        Write-Host ""
    }
    if ((Get-VBRInstalledLicense).Edition -eq "Community") 
    {
        $ErrorCount = 0
    }

    Write-Host "Agent-Name    : $($Veeam_BR_Service_Version.ProductName)"
    Write-Host "Agent-Version : $($Veeam_BR_Service_Version.FileVersion)"
    Write-Host ""
    Write-Host ""
}
else
{
    Write-Host "Der Veeam Backup & Replication wurde nicht gefunden"
    Write-Host ""
    Write-Host ""
    $ErrorCount++
}