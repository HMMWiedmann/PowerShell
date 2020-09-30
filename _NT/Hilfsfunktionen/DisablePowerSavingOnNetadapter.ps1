function Set-NetAdapterPowerSaving 
{
    [CmdletBinding()]
    param (
        # Netadapter Name
        [Parameter(Manatory=$true)]
        [string]
        $NetAdapterName,

        # Enabled or Disbabled
        [Parameter(Mandatory=$true)]
        [bool]
        $Enabled
    )
    
    begin 
    {
        $NetadapterSetting = Get-NetAdapterPowerManagement -Name $NetAdapterName
    }
    
    process 
    {     
        if($Enabled -eq $false)
        {
            $NetadapterSetting.AllowComputerToTurnOffDevice = 'Disabled'
        }
        elseif ($Enabled -eq $true) 
        {
            $NetadapterSetting.AllowComputerToTurnOffDevice = 'Enabled'
        }
    }
    
    end 
    {
        $NetadapterSetting | Set-NetAdapterPowerManagement
    }
}