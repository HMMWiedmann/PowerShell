$CountExpired = 0
$deadline = (Get-Date).AddDays($DaysToExpired)

Get-ChildItem -Path Cert:\LocalMachine\My | ForEach-Object {
    If ($PSItem.NotAfter -le $deadline) 
    {
        $PSItem | Select-Object Issuer, Subject, NotAfter, @{Label="Expires In (Days)";Expression={($PSItem.NotAfter - (Get-Date)).Days}}
        $CountExpired = $CountExpired + 1
    }
}

If ($CountExpired -gt 0)
{
    Write-Host("You Have $CountExpired Certificates Expiring in less than $DaysToExpired Days.")
}
else{
    Write-Host("No Certificates Expiring in less than $DaysToExpired Days.")
}