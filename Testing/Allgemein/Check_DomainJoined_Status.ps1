if ((Get-WmiObject -ClassName win32_computersystem).partofdomain -eq $true) 
{
    write-host "Client ist Mitglied einer Domaene"
    Write-Host $env:USERDNSDOMAIN
}
elseif ((Get-WmiObject -ClassName win32_computersystem).partofdomain -eq $false)
{
    write-host "Client ist kein Mitglied einer Domaene"
}
else 
{
    Write-Host "Der Status konnte nicht ermittelt werden"    
}