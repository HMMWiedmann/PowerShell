$HyperVHosts = Get-ADComputer -Filter { dnshostname -like "*hyperv*" }
$SwitchName = "INTERNAL"

Invoke-Command -ComputerName $HyperVHosts.DNSHostName -ScriptBlock{

    # $VMs = (Get-VM).where{ $PSitem.Name -NotLike "*05" -and $PSitem.Name -NotLike "*06"}
    # $VMs = (Get-VM).where{ $PSItem.Name -like "*01" -and $PSItem.Name -like "*02" }

    $NetAdapter = Get-VMNetworkAdapter -VMName $VMs.vmname

    Connect-VMNetworkAdapter -VMNetworkAdapter $NetAdapter -SwitchName $using:SwitchName
}