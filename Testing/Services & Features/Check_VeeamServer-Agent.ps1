[int]$ErrorCount = 0

$InstalledSoftware = Get-WmiObject -Class Win32_Product
$VeeamServer = $InstalledSoftware.Where{ $PSItem.Name -like "*Veeam*Backup*Server*" }
$VeeamAgent = $InstalledSoftware.Where{ $PSItem.Name -like "*Veeam*Agent*Windows*" }

if ($VeeamServer) 
{
    if ($VeeamServer.Version -lt "10.0.1.*") 
    {
        Write-Host "Die Veeam Serverversion ist zu alt."
        "Caption: $($VeeamServer.Caption)"
        "Version: $($VeeamServer.Version)"
        $ErrorCount++
    }
    else 
    {
        "Caption: $($VeeamServer.Caption)"
        "Version: $($VeeamServer.Version)"        
    }
}
else
{
    Write-Host "Veeam Backup & Replication not installed"
    $ErrorCount++
}

if ($VeeamAgent) 
{
    if ($VeeamAgent.Version -lt "4.*.*.*") 
    {
        Write-Host "Die Veeam Serverversion ist zu alt."
        "Caption: $($VeeamAgent.Caption)"
        "Version: $($VeeamAgent.Version)"
        $ErrorCount++
    }
    else 
    {
        "Caption: $($VeeamAgent.Caption)"
        "Version: $($VeeamAgent.Version)"        
    }
}
else
{
    Write-Host "Veeam Agent not installed"
    $ErrorCount++
}

# Check ErrorCount
if ($ErrorCount -gt 0) 
{
    #Exit 1001    
}
else 
{
    #Exit 0    
}