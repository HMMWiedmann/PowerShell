function Add-VMSwitch4VMs 
{
    param 
    (
        # VMSwitchName
        [Parameter(Mandatory = $true)]
        [string]
        $VMSwitchName
    )

    $Switchstate = Get-VMSwitch -Name $VMSwitchName

    if ($Switchstate -eq $null) 
    {
        $pNICs = Get-NetAdapter -Physical | Where-Object -Property Status -eq "UP"
        New-VMSwitch -Name $VMSwitchName -NetAdapterName $pNICs.Name
    }
}