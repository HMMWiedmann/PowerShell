$RAMData = Get-CIMInstance Win32_OperatingSystem
$Value = [Math]::Round($RAMData.FreePhysicalMemory/$RAMData.TotalVisibleMemorySize,2)
$AvailableRAMInPercent = $Value * 100