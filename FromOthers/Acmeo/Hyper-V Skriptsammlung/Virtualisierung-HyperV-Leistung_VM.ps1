###################################################################################
##                                                                               ##
##    Die acmeo cloud-distribution GmbH & Co. KG uebernimmt keine Haftung        ##
##    fuer unmittelbare und mittelbare Schaeden aus der Benutzung von            ##
##    durch acmeo selbst erstelltem Programmcode (bspw. Skripte,                 ##
##    Bibliotheken, Programmteile, Programme). Die Benutzung des als             ##
##    Beta-Version herausgegebenen Programmcodes geschieht auf eigene Gefahr.    ##
##                                                                               ##
##    Erstellt von: Sebastian-Nicolae Matei                                      ##
##    Fragen an: support@acmeo.eu                                                ##
##                                                                               ##
##    Leistungsueberwachung aller VMs. Dieses Skript kann als taegliche          ##
##    Sicherheitspruefung oder 24/7-Ueberpruefung genutzt werden.                ##
##                                                                               ##
###################################################################################

#Abfrage aller am Host gelisteter VMs
$arroVM = Get-VM;

#Abrufen der einzelnen VMs als Objekt. Ausgabe der Leistungsinformationen ueber Eigenschaften des Objekts.
foreach ($oVM in $arroVM)
{
    #Leistungsueberwachung aktivieren
    Enable-VMResourceMetering -VMName $oVM.VMName;
    Write-Host "||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||";
    Write-Host "Name: " $oVM.VMName;
    Write-Host "Zustand: " $oVM.State;
    Write-Host "Heartbeat: " $oVM.Heartbeat;
    Write-Host "Betriebsstatus: " $oVM.OperationalStatus;
    Write-Host "CPU - Anzahl: "$oVM.ProcessorCount;
    Write-Host "CPU - Nutzung (%): " $oVM.CPUUsage;

    #Leistungsdaten zur VM abrufen
    $oMeasure = Measure-VM -VMName $oVM.VMName;
    Write-Host "CPU - Nutzung - Durchschnitt (MHz): " $oMeasure.AvgCPU;

    #Hardwareinformationen zur CPU abrufen und ausgeben
    $oCPU = Get-VMProcessor -VMName $oVM.Name;
    if ($oCPU.CompatibilityForMigrationEnabled -eq $TRUE)
    {
        Write-Host "CPU - Kompatibilitaet fuer Migration aktiviert: Ja";
    }
    else
    {
        Write-Host "CPU - Kompatibilitaet fuer Migration aktiviert: Nein";
    }
    if ($oCPU.CompatibilityForOlderOperatingSystemsEnabled -eq $TRUE)
    {
        Write-Host "CPU - Kompatibilitaet fuer aeltere Betriebssysteme aktiviert: Ja";
    }
    else
    {
        Write-Host "CPU - Kompatibilitaet fuer aeltere Betriebssysteme aktiviert: Nein";
    }

    #Ermitteln der Leistungsdaten zum RAM und Ausgabe an das Dashboard
    $nRes = $oVM.MemoryAssigned/1024/1024;
    Write-Host "Speicher - Zugewiesen (MB): " $nRes;
    Write-Host "Speicher - durchschnittliche Nutzung (MB): " $oMeasure.AvgRAM;
    $oMemory = Get-VMMemory -VMName $oVM.VMName;
    $nRes = $oMemory.Startup/1024/1024;
    Write-Host "Speicher - Bedarf nach Einschalten (MB): " $nRes.ToString();
    $nRes = $oMemory.Minimum/1024/1024;
    Write-Host "Speicher - Bedarf Minimal (MB): " $nRes.ToString();
    $nRes = [decimal]::round($oMeasure.TotalDisk/1024);
    Write-Host "Speicher - Festplattenkapazitaet (GB): " $nRes;
    if ($oVM.DynamicMemoryEnabled -eq $TRUE)
    {
        Write-Host "Speicher - Dynamischer Speicher: Ein";
    }
    else
    {
        Write-Host "Speicher - Dynamischer Speicher: Aus";
    }

    #Ausgabe der Informationen zur Replikation an das Dashboard
    Write-Host "Replikationsmodus: " $oVm.ReplicationMode;
    Write-Host "Replikationszustand: " $oVm.ReplicationState;
    Write-Host "Replikationsstatus:" $oVM.ReplicationHealth;
    Write-Host "||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||";
}