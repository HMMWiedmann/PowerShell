#Abfrage aller am Host gelisteter VMs
$VMs = Get-VM;

#Abrufen der einzelnen VMs als Objekt. Ausgabe der Leistungsinformationen ueber Eigenschaften des Objekts.
foreach ($VM in $VMs)
{
    $MeasureOfVM = Measure-VM -VMName $VM.VMName;
    $Memory = Get-VMMemory -VMName $VM.VMName;
    $UsedRam = $VM.MemoryDemand/1mb    
    $AssingedRam = $VM.MemoryAssigned/1mb
    $StartUpRam = $Memory.Startup/1024/1024;
    $MinimumRam = $Memory.Minimum/1024/1024;
    $DiskSize = [decimal]::round($MeasureOfVM.TotalDisk/1024);

    if ($VM.State -eq "Running") 
    {
        #Leistungsueberwachung aktivieren
        Enable-VMResourceMetering -VMName $VM.VMName;
        Write-Host "||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||";
        Write-Host "Name: " $VM.VMName;
        Write-Host "Zustand: " $VM.State;
        #Write-Host "Heartbeat: " $VM.Heartbeat;
        Write-Host "Betriebsstatus: " $VM.OperationalStatus;
        Write-Host "CPU - Anzahl: "$VM.ProcessorCount;
        Write-Host "CPU - Nutzung (%): " $VM.CPUUsage;

        #Leistungsdaten zur VM abrufen
        Write-Host "CPU - Nutzung - Durchschnitt (MHz): " $MeasureOfVM.AvgCPU;
        
        #Ermitteln der Leistungsdaten zum RAM und Ausgabe an das Dashboard
        Write-Host "Speicher - Zugewiesen (MB): " $AssingedRam;
        Write-Host "Speicher - durchschnittliche Nutzung (MB): " $MeasureOfVM.AvgRAM;
        Write-Host "Speicher - aktuelle Nutzung (MB): " $UsedRam.ToString();
        Write-Host "Speicher - Festplattenkapazitaet (GB): " $DiskSize;


        if ($VM.DynamicMemoryEnabled -eq $TRUE)
        {
            Write-Host "Speicher - Dynamischer Speicher: Ein";
            Write-Host "Speicher - Bedarf nach Einschalten (MB): " $StartUpRam.ToString();
            Write-Host "Speicher - Bedarf Minimal (MB): " $MinimumRam.ToString();
        }
        else
        {
            Write-Host "Speicher - Dynamischer Speicher: Aus";
        }

        #Ausgabe der Informationen zur Replikation an das Dashboard
        Write-Host "Replikationsmodus: " $VM.ReplicationMode;
        Write-Host "Replikationszustand: " $VM.ReplicationState;
        Write-Host "Replikationsstatus:" $VM.ReplicationHealth;
        Write-Host "||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||";
    }
    else 
    {
        Write-Host "||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||";
        Write-Host ""
        Write-Host "$($VM.VMName) ist gestoppt!"
        Write-Host ""
        Write-Host "||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||";
    }
}