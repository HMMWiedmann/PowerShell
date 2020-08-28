$ADDSRole = (Get-WindowsFeature -Name "AD-Domain-Services").InstallState
$DNSRole = (Get-WindowsFeature -Name "DNS").InstallState
$DHCPRole = (Get-WindowsFeature -Name "DHCP").InstallState
$ADCSRole = (Get-WindowsFeature -Name "ADCS-Cert-Authority").InstallState
$WebserverRole = (Get-WindowsFeature -Name "Webserver").InstallState