if ((Get-WmiObject -ClassName win32_computersystem).partofdomain -eq $true) 
{
    write-host "Client ist Mitglied einer Domaene"
    Write-Host $env:USERDNSDOMAIN
} elseif ($env:USERDOMAIN -eq $env:COMPUTERNAME -or $env:USERDOMAIN -eq "WORKGROUP" -or $env:USERDOMAIN -like "*WO*") 
{
    Write-Host "Client ist nicht Mitglied einer Domaene"
    $env:USERDOMAIN
}
else 
{
    Write-Host "Der Status konnte nicht ermittelt werden"    
}