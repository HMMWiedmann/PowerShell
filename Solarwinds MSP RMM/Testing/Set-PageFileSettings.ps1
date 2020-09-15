function Set-PageFileInfo 
{
    [CmdletBinding()]
    Param(
            [Parameter(Mandatory)]
            [ValidatePattern('^[A-Z]$')]
            [String]$DriveLetter,
        
            [Parameter(Mandatory)]
            [ValidateRange(0,[int64]::MaxValue)]
            [Int64]$InitialSize,
        
            [Parameter(Mandatory)]
            [ValidateRange(0,[int64]::MaxValue)]
            [Int64]$MaximumSize
    )

    if ($MaximumSize -gt (Get-CimInstance -ClassName win32_logicaldisk | Where-Object -Property DeviceID -Like "$($DriveLetter)*").Freespace) 
    {
        Write-Host "Not enough available storage on $DriveLetter"
        exit 1001
    }

    try 
    {
        $computersys = Get-WmiObject Win32_ComputerSystem -EnableAllPrivileges;
        $computersys.AutomaticManagedPagefile = $False;
        $computersys.Put();
        $pagefile = Get-WmiObject -Query "Select * From Win32_PageFileSetting Where Name like '%pagefile.sys'";
        $pagefile.InitialSize = $InitialSize;
        $pagefile.MaximumSize = $MaximumSize;
        $pagefile.Put();
    
        Write-Host "Successfully configured the pagefile on drive letter $DriveLetter"
        Write-Host "InitialSize = $InitialSize | Maximumsize = $MaximumSize"
        Write-Host "Pagefile configuration changed on computer '$Env:COMPUTERNAME'. The computer must be restarted for the changes to take effect."
    } 
    catch 
    {
        Write-Host "Could not change Pagefile Settings!"
        Exit 1001
    }    
}

try {
    $CompSysResults = Get-CimInstance -ClassName Win32_Computersystem -Namespace 'root\cimv2'

    if ($CompSysResults.TotalPhysicalMemory -gt 31gb)
    {
        Set-PageFileInfo -DriveLetter C -InitialSize 32.768 -MaximumSize 32.768
    }
    elseif ($CompSysResults.TotalPhysicalMemory -gt 23gb) 
    {
        Set-PageFileInfo -DriveLetter C -InitialSize 24.576 -MaximumSize 24.576
    }
    elseif ($CompSysResults.TotalPhysicalMemory -gt 19gb) 
    {
        Set-PageFileInfo -DriveLetter C -InitialSize 20.480 -MaximumSize 20.480
    }
    elseif ($CompSysResults.TotalPhysicalMemory -gt 15gb) 
    {
        Set-PageFileInfo -DriveLetter C -InitialSize 16384 -MaximumSize 16384
    }
    elseif ($CompSysResults.TotalPhysicalMemory -gt 11.5gb) 
    {
        Set-PageFileInfo -DriveLetter C -InitialSize 12288 -MaximumSize 12288
    }
    elseif ($CompSysResults.TotalPhysicalMemory -gt 7gb) 
    {
        Set-PageFileInfo -DriveLetter C -InitialSize 8192 -MaximumSize 8192
    }
    elseif ($CompSysResults.TotalPhysicalMemory -gt 3gb) 
    {
        Set-PageFileInfo -DriveLetter C -InitialSize 4096 -MaximumSize 4096
    }
}
catch {
    Write-Host "Something went wrong: $($PSItem.Exception.Message)"
    Exit 1001    
}