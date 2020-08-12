$NetAdapter = Get-NetAdapter
# IP-Adressen 
Remove-NetIPAddress -InterfaceIndex $NetAdapter.InterfaceIndex
# Gateway 
Remove-NetRoute -InterfaceIndex $NetAdapter.InterfaceIndex
# DNS
Set-DnsClientServerAddress -ResetServerAddresses