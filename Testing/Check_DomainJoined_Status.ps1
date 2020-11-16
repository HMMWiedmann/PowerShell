if ((Get-WmiObject -ClassName win32_computersystem).partofdomain -eq $true) 
{
    write-host "Client ist Mitglied einer Domaene"
    Write-Host $env:USERDNSDOMAIN
}
else 
{
    Write-Host "Der Status konnte nicht ermittelt werden"    
}