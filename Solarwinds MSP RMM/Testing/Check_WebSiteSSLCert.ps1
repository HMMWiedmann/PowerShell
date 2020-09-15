$Thumbprint = (Get-WebBinding -Port 443).certificatehash

Get-ChildItem -Path Cert:\LocalMachine\My | Where-Object -Property Thumbprint -EQ $Thumbprint