# Quelle: https://stackoverflow.com/questions/6239647/using-powershell-credentials-without-being-prompted-for-a-password

Read-Host -AsSecureString | ConvertTo-SecureString | Out-File -Path C:\Temp\SecurePWD.txt

$username = "domain01\admin01"
$password = Get-Content 'C:\mysecurestring.txt' | ConvertTo-SecureString
$cred = new-object -typename System.Management.Automation.PSCredential `
         -argumentlist $username, $password

$serverNameOrIp = "192.168.1.1"
Restart-Computer -ComputerName $serverNameOrIp `
                 -Authentication default `
                 -Credential $cred
                 <any other parameters relevant to you>