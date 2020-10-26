try { 
    $ComputerSystemInfo = Get-WmiObject -Class Win32_ComputerSystem -ErrorAction Stop
        
    switch ($ComputerSystemInfo.Model) { 
            
        # Check for Hyper-V Machine Type 
        "Virtual Machine" 
        { 
            $MachineType="Hyper-V VM" 
        } 

        # Check for VMware Machine Type 
        "VMware Virtual Platform" 
        { 
            $MachineType="VMware VM" 
        } 

        # Check for Oracle VM Machine Type 
        "VirtualBox" 
        { 
            $MachineType="VM" 
        } 

        # Otherwise it is a physical Box 
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