try { 
    $ComputerSystemInfo = Get-WmiObject -Class Win32_ComputerSystem -ErrorAction Stop
        
    switch ($ComputerSystemInfo.Model) { 
        "Microsoft Corporation Virtual Machine"
        {
            $MachineType = "HyperV VM"
        }
        "Virtual Machine" 
        { 
            $MachineType="VM" 
        } 
        "VMware Virtual Platform"
        { 
            $MachineType="VMware VM" 
        } 
        "VMware, Inc. VMware Virtual Platform"
        {
            $MachineType="VMware VM"
        }
        "VirtualBox" 
        { 
            $MachineType="VM" 
        } 
        default 
        { 
            $MachineType="Physical" 
        } 
    }
        
    # Building MachineTypeInfo Object 
    $MachineTypeInfo = New-Object -TypeName PSObject -Property ([ordered]@{ 
        ComputerName=$ComputerSystemInfo.PSComputername 
        Type=$MachineType 
        Manufacturer=$ComputerSystemInfo.Manufacturer 
        Model=$ComputerSystemInfo.Model 
        }) 
    $MachineTypeInfo 
    } 
catch [Exception] 
{ 
    Write-Output ($_.Exception.Message)
} 