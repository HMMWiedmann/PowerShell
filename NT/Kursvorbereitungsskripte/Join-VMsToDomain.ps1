$LocalCred = Get-Credential
$DomCred = Get-Credential
$VMName = (Get-VM -Name *).Name
$DomainName = "ADS-CENTER.DE"

Invoke-Command -VMName $VMName -Credential $LocalCred -ScriptBlock{ Add-Computer -DomainName $using:DomainName -Credential $using:DomCred -Force -Restart }