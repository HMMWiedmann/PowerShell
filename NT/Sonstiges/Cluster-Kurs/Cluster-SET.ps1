New-VMSwitch -Name SETSwitch -NetAdapterName "Datacenter-1","Datacenter-2" -EnableEmbeddedTeaming $true -AllowManagementOS $false

Add-VMNetworkAdapter -SwitchName SETSwitch -Name SMB-1 -ManagementOS
Add-VMNetworkAdapter -SwitchName SETSwitch -Name SMB-2 -ManagementOS

Get-NetAdapter
Enable-NetAdapter "vEthernet (SMB-1)","vEthernet (SMB-2)"

Set-VMNetworkAdapterTeamMapping -VMNetworkAdapterName "SMB-1" -ManagementOS -PhysicalNetAdapterName "Datacenter-1"
Set-VMNetworkAdapterTeamMapping -VMNetworkAdapterName "SMB-2" -ManagementOS -PhysicalNetAdapterName "Datacenter-2"