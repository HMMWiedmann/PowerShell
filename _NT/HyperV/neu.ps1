$nics = Get-NetAdapter -Physical | where status -ne up

New-VMSwitch -Name SET -NetAdapterName $nics.Name 

Set-VMHost -VirtualMachinePath V:\ -VirtualHardDiskPath V:\
Set-VMHost -EnableEnhancedSessionMode $true

Disable-NetAdapter -Name $nics.name -Confirm:$false