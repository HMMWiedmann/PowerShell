[int]$CountExpired = 0
$CurrentDate = Get-Date
$Certificates = Get-ChildItem -Path Cert:\LocalMachine\My

foreach ($Cert in $Certificates)
{
    $DiffDate = $Cert.NotAfter - $CurrentDate

    if($DiffDate.Days -le $DaysToExpired)
    {
        Write-Host "Cert $($Cert.FriendlyName) will expire in $($DiffDate.Days) Days"
        Write-Host "Thumbprint : " ($Cert.Thumbprint)
        # Write-Host "IsValid    : " (Test-Certificate -Cert $Cert -Policy SSL)
        $CountExpired++
    }
    else
    {
        Write-Host "Cert $($Cert.FriendlyName) has $($DiffDate.Days) Days left"
    }
}