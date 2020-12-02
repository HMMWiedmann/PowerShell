<#  AMP Input: 
    $MinAllowedVersion

    AMP Output:
    $ErrorCount
#>

[int]$ErrorCount = 0

$KasperskyServer = Get-WmiObject -Class Win32_Product | Where-Object -Property Caption -Like "Kaspersky Security Center * Administrationsserver"

if ($KasperskyServer) 
{    
    $VersionInfo = (Get-ItemProperty -Path "C:\Program Files (x86)\Kaspersky Lab\Kaspersky Security Center\klserver.exe").VersionInfo

    $InstalledVersionArray = $VersionInfo.FileVersion.Split(".")
    $RequiredVersionArray = $MinAllowedVersion.Split(".")

    if ([int]$InstalledVersionArray[0] -ge [int]$RequiredVersionArray[0])
    {
        if ([int]$InstalledVersionArray[1] -ge [int]$RequiredVersionArray[1])
        {
            if ([int]$InstalledVersionArray[2] -ge [int]$RequiredVersionArray[2])
            {
                if ([int]$InstalledVersionArray[3] -ge [int]$RequiredVersionArray[3])
                {
    
                }
                else { Write-Host "Die KSC_Version ist alt und nicht aktuell.`nGeforderte Verion: $MinAllowedVersion"; $ErrorCount++ }
            }
            else { Write-Host "Die KSC_Version ist alt und nicht aktuell.`nGeforderte Verion: $MinAllowedVersion"; $ErrorCount++ }
        }
        else { Write-Host "Die KSC_Version ist alt und nicht aktuell.`nGeforderte Verion: $MinAllowedVersion"; $ErrorCount++ }
    }
    else { Write-Host "Die KSC_Version ist alt und nicht aktuell.`nGeforderte Verion: $MinAllowedVersion"; $ErrorCount++ }

    if ($ErrorCount -gt 0) 
    {
        Write-Host ""
        Write-Host ""
    }

    "Name    : $($KasperskyServer.Caption)"
    "Version : $($VersionInfo.FileVersion)"
    Write-Host ""
    Write-Host ""
}
else
{
    Write-Host "Kein KSC gefunden!"
    $ErrorCount++
}