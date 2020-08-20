$PageFileResults = Get-CimInstance -ClassName Win32_PageFileUsage
$CompSysResults = Get-CimInstance -ClassName Win32_Computersystem -Namespace 'root\cimv2'

$PageFileStats = [PSCustomObject]@{
    Computer = $env:COMPUTERNAME
    FilePath = $PageFileResults.Description
    AutoManagedPageFile = $CompSysResults.AutomaticManagedPagefile
    "TotalRamSize(in MB)" = ($CompSysResults.TotalPhysicalMemory / 1mb) 
    "TotalSize(in MB)" = $PageFileResults.AllocatedBaseSize
    "CurrentUsage(in MB)"  = $PageFileResults.CurrentUsage
    "PeakUsage(in MB)" = $PageFileResults.PeakUsage
    TempPageFileInUse = $PageFileResults.TempPageFile
}

$PageFileStats

if ($PageFileStats.AutoManagedPageFile -eq $true) 
{
    
}