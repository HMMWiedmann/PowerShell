try 
{ 
    $ComputerSystemInfo = Get-WmiObject -Class Win32_ComputerSystem -ErrorAction Stop
        
    switch ($ComputerSystemInfo.Model) 
    { 
        "Microsoft Corporation Virtual Machine" { $MachineType = "HyperV VM" }
        "Virtual Machine" { $MachineType = "VM" } 
        "VMware Virtual Platform" { $MachineType = "VMware VM" } 
        "VMware, Inc. VMware Virtual Platform" { $MachineType = "VMware VM" }
        "VirtualBox" { $MachineType = "VM" } 
        default { $MachineType="Physical" }
    }

    Write-Host "MachineType  : " ($MachineType)
    Write-Host "Computername : " ($ComputerSystemInfo.PSComputername)
    Write-Host "Manufacturer : " ($ComputerSystemInfo.Manufacturer)
    Write-Host "Model        : " ($ComputerSystemInfo.Model)
}
catch [Exception] 
{ 
    Write-Output ($_.Exception.Message)
} 